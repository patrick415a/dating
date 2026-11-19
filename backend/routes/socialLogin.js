const express = require('express');
const bcrypt = require('bcrypt');
const { createPublicKey, randomBytes, timingSafeEqual, verify } = require('node:crypto');
const { Op, Transaction } = require('sequelize');
const sequelize = require('../config/database');
const User = require('../models/User');
const SocialIdentity = require('../models/SocialIdentity');

const router = express.Router();
const redirectUri = new URL(process.env.DATING_OAUTH_REDIRECT_URI || 'http://localhost:3001/');
const oauthRedirects = new Map([[redirectUri.origin, redirectUri.href]]);
if (!redirectUri.port) {
  const otherHost = new Map([
    ['heartbreakkid.co.kr', 'www.heartbreakkid.co.kr'],
    ['www.heartbreakkid.co.kr', 'heartbreakkid.co.kr'],
  ]).get(redirectUri.hostname);
  if (otherHost) {
    const alternate = new URL(redirectUri);
    alternate.hostname = otherHost;
    oauthRedirects.set(alternate.origin, alternate.href);
  }
}
const pending = new Map();
const providers = new Map([
  ['google', {
    id: process.env.DATING_GOOGLE_CLIENT_ID,
    secret: process.env.DATING_GOOGLE_CLIENT_SECRET,
    authorize: 'https://accounts.google.com/o/oauth2/v2/auth',
    token: 'https://oauth2.googleapis.com/token',
    userInfo: 'https://openidconnect.googleapis.com/v1/userinfo',
    scope: 'openid email profile',
  }],
  ['kakao', {
    id: process.env.DATING_KAKAO_CLIENT_ID,
    secret: process.env.DATING_KAKAO_CLIENT_SECRET,
    authorize: 'https://kauth.kakao.com/oauth/authorize',
    token: 'https://kauth.kakao.com/oauth/token',
    userInfo: 'https://kapi.kakao.com/v2/user/me',
  }],
]);

class LoginError extends Error {
  constructor(status, message, code) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

function providerConfig(name) {
  const provider = providers.get(name);
  if (!provider) throw new LoginError(404, '지원하지 않는 소셜 로그인입니다.');
  if (!provider.id || !provider.secret) {
    throw new LoginError(503, '소셜 로그인 서버 설정이 필요합니다.');
  }
  return provider;
}

function redirectForBrowserOrigin(req) {
  const callback = oauthRedirects.get(req.get('Origin'));
  if (!callback) {
    throw new LoginError(403, '로그인 화면 주소와 리다이렉트 설정이 일치하지 않습니다.');
  }
  return callback;
}

function randomToken() {
  return randomBytes(32).toString('base64url');
}

function isRandomToken(value) {
  return typeof value === 'string' && /^[A-Za-z0-9_-]{43}$/.test(value);
}

async function fetchJson(url, options) {
  try {
    const response = await fetch(url, { ...options, signal: AbortSignal.timeout(8000) });
    if (response.ok) return await response.json();
    if (response.status < 500 && response.status !== 429) {
      throw new LoginError(401, '소셜 로그인 인증을 확인하지 못했습니다. 다시 시도해 주세요.');
    }
  } catch (error) {
    if (error instanceof LoginError) throw error;
  }
  throw new LoginError(502, '소셜 로그인 제공자와 연결하지 못했습니다.');
}

function readAccount(provider, profile) {
  const kakao = profile?.kakao_account;
  const isGoogle = provider === 'google';
  const subject = isGoogle ? profile?.sub : profile?.id?.toString();
  const verified = isGoogle ? profile?.email_verified === true
    : kakao?.is_email_verified === true && kakao?.is_email_valid === true;
  const address = isGoogle ? profile?.email : kakao?.email;
  const email = verified && typeof address === 'string' ? address.trim().toLowerCase() : '';
  const name = isGoogle ? profile?.name : kakao?.profile?.nickname;

  if (typeof subject !== 'string' || !subject || subject.length > 100 || email.length > 255
      || (!isGoogle && !/^\d+$/.test(subject)) || (isGoogle && !email)) {
    throw new LoginError(400, '소셜 계정 정보를 확인하지 못했습니다.');
  }
  return { provider, subject, email, nickname: name?.trim().slice(0, 50) || (isGoogle ? '구글유저' : '카카오유저') };
}

async function findUser(account) {
  const { provider, subject, email, nickname } = account;
  const where = { provider, subject };
  const options = sequelize.getDialect() === 'sqlite' ? { type: Transaction.TYPES.IMMEDIATE } : {};
  return sequelize.transaction(options, async (transaction) => {
    const identity = await SocialIdentity.findOne({ where, transaction });
    if (identity) return User.findByPk(identity.userId, { transaction });

    const candidates = provider === 'kakao' ? [email, subject + '@kakao.com'].filter(Boolean) : [email];
    const oldAccounts = await User.findAll({ where: { email: { [Op.in]: candidates } }, transaction });
    let user;
    for (const oldAccount of oldAccounts) {
      // Before identities were persisted, social accounts used a hash of the provider subject.
      if (await bcrypt.compare(subject, oldAccount.password)) {
        user = oldAccount;
        break;
      }
    }
    const password = await bcrypt.hash(randomToken(), 10);
    if (user) {
      await user.update({ password }, { transaction });
    } else {
      if (oldAccounts.some((oldAccount) => oldAccount.email === email)) {
        throw new LoginError(409, '같은 이메일로 가입한 계정이 있습니다. 기존 방식으로 로그인해 주세요.');
      }
      user = await User.create({
        email: email || subject + '@kakao.invalid', password, nickname, age: 20, gender: 'M', status: 'PENDING',
      }, { transaction });
    }
    await SocialIdentity.create({ ...where, userId: user.id }, { transaction });
    return user;
  });
}

async function sendLogin(res, provider, profile) {
  const user = await findUser(readAccount(provider, profile));
  if (user.status === 'PENDING') {
    throw new LoginError(403, '프로필 검사 진행 중입니다. 조금만 기다려주세요!', 'PROFILE_REVIEW_PENDING');
  }
  if (user.status === 'BANNED') {
    throw new LoginError(403, '이용 수칙 위반으로 영구 정지된 계정입니다.');
  }
  const { password, ...publicUser } = user.toJSON();
  res.json({ success: true, user: publicUser });
}

router.use((req, res, next) => {
  res.set('Cache-Control', 'no-store');
  next();
});

router.post('/:provider/authorize', (req, res) => {
  const callback = redirectForBrowserOrigin(req);
  const provider = providerConfig(req.params.provider);
  const now = Date.now();
  for (const [state, attempt] of pending) {
    if (attempt.expiresAt <= now) pending.delete(state);
  }
  if (pending.size >= 2000) throw new LoginError(429, '잠시 후 다시 시도해 주세요.');

  const state = randomToken();
  const verifier = randomToken();
  pending.set(state, { provider: req.params.provider, verifier, callback, expiresAt: now + 600000 });
  const authorizationUrl = new URL(provider.authorize);
  authorizationUrl.search = new URLSearchParams({
    client_id: provider.id, redirect_uri: callback, response_type: 'code', state,
  });
  if (provider.scope) authorizationUrl.searchParams.set('scope', provider.scope);
  res.json({ authorizationUrl: authorizationUrl.href, verifier });
});

router.post('/complete', async (req, res) => {
  const callback = redirectForBrowserOrigin(req);
  const { code, state, verifier } = req.body || {};
  const attempt = pending.get(state);
  if (!attempt || attempt.expiresAt <= Date.now() || attempt.callback !== callback || !isRandomToken(verifier)
      || typeof code !== 'string' || !code.trim() || code.length > 2048
      || !timingSafeEqual(Buffer.from(attempt.verifier), Buffer.from(verifier))) {
    throw new LoginError(400, '소셜 로그인 요청이 만료되었습니다. 처음부터 다시 시도해 주세요.');
  }
  pending.delete(state);
  const provider = providerConfig(attempt.provider);
  const token = await fetchJson(provider.token, {
    method: 'POST',
    body: new URLSearchParams({
      grant_type: 'authorization_code', client_id: provider.id, client_secret: provider.secret,
      redirect_uri: attempt.callback, code,
    }),
  });
  if (!token?.access_token) throw new LoginError(502, '소셜 로그인 토큰을 받지 못했습니다.');
  const profile = await fetchJson(provider.userInfo, {
    headers: { Authorization: 'Bearer ' + token.access_token },
  });
  await sendLogin(res, attempt.provider, profile);
});

async function readGoogleIdToken(token, clientId) {
  try {
    const [rawHeader, rawClaims, signature, extra] = token.split('.');
    if (!rawHeader || !rawClaims || !signature || extra !== undefined) throw new Error();
    const header = JSON.parse(Buffer.from(rawHeader, 'base64url'));
    const claims = JSON.parse(Buffer.from(rawClaims, 'base64url'));
    if (header.alg !== 'RS256' || typeof header.kid !== 'string' || claims.aud !== clientId
        || !['accounts.google.com', 'https://accounts.google.com'].includes(claims.iss)
        || !Number.isFinite(claims.exp) || claims.exp * 1000 <= Date.now()) throw new Error();
    const { keys } = await fetchJson('https://www.googleapis.com/oauth2/v3/certs');
    const key = keys?.find(({ kid }) => kid === header.kid);
    if (!key || !verify('RSA-SHA256', Buffer.from(rawHeader + '.' + rawClaims),
      createPublicKey({ key, format: 'jwk' }), Buffer.from(signature, 'base64url'))) throw new Error();
    return claims;
  } catch (error) {
    if (error instanceof LoginError) throw error;
    throw new LoginError(401, 'Google 로그인 인증을 확인하지 못했습니다.');
  }
}

router.post('/native', async (req, res) => {
  const { provider: name, token } = req.body || {};
  if (typeof token !== 'string' || !token.trim() || token.length > 8192) {
    throw new LoginError(400, '소셜 로그인 인증 정보가 필요합니다.');
  }
  const provider = providerConfig(name);
  if (name === 'google') return sendLogin(res, name, await readGoogleIdToken(token, provider.id));

  const appId = process.env.DATING_KAKAO_APP_ID;
  if (!appId) throw new LoginError(503, '카카오 모바일 앱 ID 설정이 필요합니다.');
  const authorization = { headers: { Authorization: 'Bearer ' + token } };
  const tokenInfo = await fetchJson('https://kapi.kakao.com/v1/user/access_token_info', authorization);
  if (String(tokenInfo?.app_id) !== appId) throw new LoginError(401, '카카오 로그인 인증을 확인하지 못했습니다.');
  const profile = await fetchJson(provider.userInfo, authorization);
  if (String(tokenInfo.id) !== String(profile?.id)) throw new LoginError(401, '카카오 로그인 인증을 확인하지 못했습니다.');
  await sendLogin(res, name, profile);
});

router.use((error, req, res, next) => {
  if (error instanceof LoginError) {
    return res.status(error.status).json({ success: false, message: error.message, code: error.code });
  }
  console.error('Social login failed:', error.name);
  res.status(500).json({ success: false, message: '소셜 로그인 처리 중 문제가 발생했습니다.' });
});

module.exports = { router, oauthOrigins: [...oauthRedirects.keys()] };
