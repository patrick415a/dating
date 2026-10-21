const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const {Sequelize, DataTypes, Op} = require('sequelize');
const bcrypt = require('bcrypt');
const sequelize = require('./config/database');
const User = require('./models/User');
const Match = require('./models/Match');
const Diary = require('./models/Diary');
const Admin = require('./models/Admin');
require('dotenv').config();

const app = express();

const multer = require('multer');
const path = require('path');
const fs = require('fs');

// 업로드 폴더가 없으면 자동 생성
if(!fs.existsSync('uploads')) fs.mkdirSync('uploads');

// 외부에서 업로드된 사진을 url로 볼 수 있게 설정

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname))
});

const upload = multer({storage});

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

// 회원가입
app.post('/api/signup', upload.array('photos', 3), async (req, res) => {
  const { email, password, nickname, age, gender, photos, bio } = req.body;

  if (!email || !password || !nickname || !age || !gender) {
    return res.status(400).json({success: false, message: '필수 항목을 모두 입력해주세요'});
  }

  
  // 트랜잭션을 위해서 단독 커넥션 하나를 빌려옵니다
  const t = await sequelize.transaction();
  
  try {
    // 사진처리
    let profile_image_main = req.files[0] ? `/uploads/${req.files[0].filename}` : null;
    let profile_image_sub1 = req.files[1] ? `/uploads/${req.files[1].filename}` : null;
    let profile_image_sub2 = req.files[2] ? `/uploads/${req.files[2].filename}` : null;

    const hashedPassword = await bcrypt.hash(password, 10);
    
    const newUser = await User.create({
      email, 
      password: hashedPassword, 
      nickname, 
      age, 
      gender, 
      bio, 
      profile_image_main, 
      profile_image_sub1, 
      profile_image_sub2,
      status: 'PENDING'
    }, { transaction: t });

    await t.commit();

    res.json({
      success: true,
      message: '회원가입이 완료되었습니다! 승인여부 확인 후 2-3일 내로 처리해드리겠습니다',
      newUserId: newUser.id
    });
  } catch(error){
    await t.rollback();
    console.error(error);
    if(error.code === 'SequelizeUniqueConstrantError'){
      return res.status(409).json({success: false, message: '이미 가입된 정보가 존재합니다'});
    }

    res.status(500).json({success: false, message: '회원가입 처리 중 서버 에러가 발생하였습니다'});
  }
});

// 로그인
app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({success: false, message: '필수 항목을 모두 입력해주세요'});
  }

  try{
    const user = await User.findOne({
      where: { email }
    });

    if(!user){
      return res.status(401).json({success: false, message: '잘못된 이메일 또는 비밀번호입니다'});
    }

    // add bcrypt
    const isMatch = await bcrypt.compare(password, user.password);

    if(!isMatch){
      return res.status(401).json({success: false, message: '잘못된 이메일 또는 비밀번호입니다'})
    }

    // 관리자가 승인하지 않은 상태라면
    if(user.status === 'PENDING'){
      return res.status(403).json({success: false, message: '승인이 진행중입니다. 조금만 기다려주세요'});
    }

    // 영구정지 당한 상태라면
    if(user.status === 'BANNED'){
      return res.status(403).json({success: false, message: '이용 수칙 위반으로 영구 정지된 계정입니다'});
    }

    // 모든 관문을 통과했다면 정상 로그인 성공
    return res.json({success: true, message: '로그인 성공', user});
  }catch (e){
    console.error('로그인에러 :', e);
    return res.status(500).json({success: false, message: '서버 에러가 발생하였습니다'});
  }
});

// 매칭 수락 및 포인트 차감 (트랜잭션)
app.post('/api/match/accept', async (req, res) => {
  const {match_id, user_id} = req.body;

  const t = await sequelize.transaction();

  try {
    // 수락 누른 사람의 정보 가져오기
    const user = await User.findByPk(user_id);
    // 돈이 없으면 실행 안되게
    if(user.points < 10000){
      throw new Error('포인트가 부족합니다. 충전해주세요');
    }

    // 내 포인트에서 10000점을 뺍니다.
    await user.update({points: (user.points - 10000)}, {transaction: t});

    // 매칭 상태를요청에서 수락으로 변경
    await Match.update({status: 'ACCEPTED'}, {where: {id: match_id}}, {transaction: t});

    await t.commit();

    res.json({success: true, message: '수락 완료! 연락처가 열렸습니다'});
  }catch(error){
    await t.rollback();
    res.status(400).json({success: false, message: error.message});
  }
});

// 노쇼 신고 접수
app.post('/api/match/noshow', async(req, res) => {
  const { match_id, target_user_id } = req.body;

  // 해당 건을 노쇼 상태로 바꿈
  await Match.update({status: 'NO_SHOW'}, {where: {id: match_id}});

  const targetUser = await User.findByPk(target_user_id);
  // 기존 노쇼횟수에 1을 더함..
  const newCount = targetUser.no_show_count + 1;

  if(newCount >= 3){
    await targetUser.update({no_show_count: newCount, status: 'BANNED'});
  }else {
    await targetUser.update({no_show_count: newCount});
  }

  res.json({success: true, message: '신고 접수 완료! 강력하게 제재하겠습니다'});
});

app.get('/api/mypage/:user_id', async(req, res) => {
  const userId = req.params.user_id;

  // 유저 프로필 정보 찾기
  const user = await User.findByPk(userId);

  // 만남에 관련된 것을 모두 셉니다
  const receivedLikes = await Match.count({
    where: {receiver_id: userId, status: 'REQUESTED'}
  });

  // 성사 된 매칭 개수
  const matchCount = await Match.count({
    where: { [Op.or]: [{sender_id: userId}, {receiver_id: userId}], status: 'ACCEPTED'}
  });

  // 작성 일기 개수
  const diaryCount = await Diary.count({
    where: {user_id: userId}
  });

  res.json({
    ...user.toJSON(),
    receivedLikes: receivedLikes,
    matches: matchCount,
    diaries: diaryCount
  });
});

// admin start
app.post('/api/admin/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    const admin = await Admin.findOne({where: {email}});

    if(!admin){
      return res.status(401).json({success: false, message: '등록된 관리자 이메일이 아닙니다'});
    }

    const isMatch = await bcrypt.compare(password, admin.password);

    if(!isMatch){
      return res.status(401).json({success: false, message: '비밀번호가 일치하지 않습니다'});
    }

    res.json({success: true, name: admin.name, message: '관리자 대시보드에 로그인 하였습니다'});

  }catch(e) {
    console.error('어드민 로그인 에러: ', e);
    return res.status(500).json({success: false, message: '서버 에러가 발생하였습니다(어드민 로그인 실패)'});
  }

});
// admin end

// 유저 목록 조회
app.get('/api/admin/users', async (req, res) => {
  try {
    const users = await User.findAll({order: [['id', 'DESC']]});
    res.json({success: true, users});
  }catch(e){
    console.error('유저 목록 조회 에러: ', e);
    return res.status(500).json({success: false, message: '서버 에러가 발생하였습니다(유저 목록 조회 실패)'});
  }
});

// 유저 승인
app.patch('/api/admin/users/:id/approve', async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);

    if(!user){
      return res.status(404).json({success: false, message: '유저를 찾을 수 없습니다'});
    }

    await user.update({status: 'ACTIVE'})
    res.json({success: true, message: '승인 완료하였습니다'});
  }catch(e){
    console.error('승인 처리 실패: ', e);
    return res.status(500).json({success: false, message: '서버 에러가 발생하였습니다(승인 처리 실패)'});
  }
});

// 2차 회원가입
app.patch('/api/users/:id/secondary-signup', async (req, res) => {
  const userId = req.params.id;
  const { phone_number, occupation, address } = req.body;

  try {
    const user = await User.findByPk(userId);

    if(!user){
      return res.status(404).json({success: false, message: '유저를 찾을 수 없습니다'});
    }

    await user.update({phone_number, occupation, address});
    res.json({success: true, message: '추가 정보 입력이 완료되었습니다'});
  }catch (e){
    console.error('추가 정보 입력 실패: ', e);
    return res.status(500).json({success: false, message: '서버 에러가 발생하였습니다(추가 정보 입력 실패)'});
  }
});


const PORT = 3000;
app.listen(PORT, async () => {
  await sequelize.authenticate();
  // 👉 1. 기존에 꼬여있는 테이블들을 밀어버리기 위해 '관계 보호 장치'를 잠시 끕니다.
  // await sequelize.query('SET FOREIGN_KEY_CHECKS = 0');
  // 👉 2. 에러 없이 모든 테이블을 싹 지우고 완벽한 구조로 다시 만듭니다.
  // await sequelize.sync({ force: true }); 
  // 👉 3. 테이블이 예쁘게 만들어졌으니 '관계 보호 장치'를 다시 켭니다.
  // await sequelize.query('SET FOREIGN_KEY_CHECKS = 1');
  await sequelize.sync({alter: true});

  // add 관리자 계정이 db에 하나도 없으면 자동으로 생성
  const adminCount = await Admin.count();
  if(adminCount === 0){
    const hashedAdminPassword = await bcrypt.hash(process.env.DB_ADMINPASSWORD, 10);
    await Admin.create({
      email: 'test@test.com',
      password: hashedAdminPassword,
      name: '최고관리자'
    });
    console.log('기본 관리자 계정 생성완료(test@test.com)');
  }

  console.log("✅ 데이터베이스 연결 및 초기화 동기화 완료");
  console.log(`🚀 백엔드 서버가 http://localhost:${PORT} 에서 열심히 돌아가고 있습니다`);
});