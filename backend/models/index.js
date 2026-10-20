//모델들을 불러와서 sequelize 객체와 연결해 줍니다.
const User = require('./User');
const MatchRequest = require('./MatchRequest');
const PointHistory = require('./PointHistory');

module.exports = {User, MatchRequest, PointHistory};