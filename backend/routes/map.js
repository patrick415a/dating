// exporess와 라우터(경로 관리 기능) 불러오기
const express = require('express');
const router = express.Router();

const { User, MatchRequest } = require('../models');
const { sequelize } = require('../config/database');

const { Op } = require('sequelize');

router.get('/nearby', async (req, res) => {
  try {
    const { lat, lng, radius, userId } = req.query;
    const radiusInMeter = parseFloat(radius) * 1000;
    // 지구 둥글기를 반영한 정밀 거리 계산 함수 (ST_Distance_Sphere)를 SQL 문장으로 만듭니다
    const distanceQuery = sequelize.literal(`ST_Distance_Sphere(point(logitude, latitude), point(${lng}, ${lat}))`);

    // 조건에 맞는 사람들 찾아오기
    const nearbyUsers = await User.findAll({
      where: {
        // 검색 할 사람 중에서 나를 제외
        id: {[Op.ne]: userId},
        // 
        [Op.and]: sequelize.where(distanceQuery, '<=', radiusInMeter)
      },
      attributes: [
        'id', 'nickname', 'gender', 'bio', [distanceQuery, 'distanceValue']
      ]
    });

    res.json({success: true, users: nearbyUsers});
  }catch(e){
    console.error(e);
    res.status(500).json({success: false, message: ''});
  }
})