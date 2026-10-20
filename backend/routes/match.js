const express = require('express');
const router = express.Router();

const { User, MatchRequest, PointHistory, sequelize } = require('../models');

// 매칭 요청 api
router.post('/request', async (req, res) => {
  try {
    const { senderId, receiverId } = req.body;

    // 이미 진행중인 사항이 있는지 확인
    const existing = await MatchRequest.findOne({
      where: {
        sender_id: senderId,
        receiver_id: receiverId
      }
    });

    // 이미 진행중이면
    if(existing) {
      return res.status(400).json({success: false, message: '이미 요청을 보냈습니다'});
    }

    // 새 요청(PENDING) 저장
    await MatchRequest.create({
      sender_id: senderId,
      receiver_id: receiverId,
      status: 'PENDING'
    });

    res.json({success: true, message: '요청 완료'});
  }catch (e){
    console.error(e);
    res.status(500).json({success: false, message: '요청 실패'});
  }
});

// 수락 및 거절
router.post('/response', async (req, res) => {
  try {
    const { requestId, responderId, action } = req.body;

    // 매칭 정보 찾기
    const request = await MatchRequest.findByPk(requestId);

    // 요청이 없거나 내가 아니면 튕겨냄
    if(!request || request.receiver_id !== responderId){
      return res.status(400).json({success: false, message: '유효 하지 않은 요청입니다'})
    }

    // 거절
    if(action === 'REJECT'){
      await request.update({status: 'REJECTED'});
      return res.json({success: true, message: '요청이 거절되었습니다'});
    }

    // 수락
    if(action === 'ACCEPT'){
      await request.update({status: 'ACCEPTED'});
    }

    await MatchRequest.update({status: 'REJECTED'}, {where: {receiver_id: responderId, status: PENDING}});
    return res.json({success: true, message: '매칭이 수락 되었습니다. 약속을 잡아보세요!'});

  }catch (e){
    console.error(e);
    res.status(500).json({success: false, message: '서버 에러'});
  }
});

// 만남 완료
router.post('./complete', async(req, res) => {
  const MATCH_COST = 10000;
  const t = await sequelize.transaction();
  try {
    const { requestId } = req.body;
    const request = await MatchRequest.findByPk(requestId, {transaction: t});

    if(!request || request.status !== 'ACCEPTED'){
      throw new Error('정상적인 만남 완료 대상이 아닙니다');
    };

    const sender = await User.findByPk(request.sender_id, {transaction: t});
    const receiver = await User.findByPk(request.receiver_id, {transaction: t});

    if(sender.points < MATCH_COST || receiver.points < MATCH_COST){
      throw new Error('포인트가 부족하여 만남을 완료할 수 없습니다. 충전이 필요합니다');
    };

    // 매칭 상태 최종 단계인 complete로 변경
    await request.update({status: 'COMPLETE'}, {transaction: t});

    // 포인트 차감 영수증 양쪽 유저에게 만들어 저장 
    await PointHistory.bulkCreate([
      {
        user_id: sender.id,
        amount: -MATCH_COST,
        reason: '만남 완료 발신'
      },
      {
        user_id: receiver.id,
        amount: -MATCH_COST,
        reason: '만남 완료 발신'
      }
    ], {transaction: t});

    await t.commit();
    res.json({success: true, message: '만남 완료! 양쪽 포인트가 차감되었습니다'});
  }catch(e){
    await t.rollback();
    res.status(400).json({success: false, message: error.message});
  }
});

module.exports = router;