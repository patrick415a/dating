const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const User = require('./User');

module.exports = sequelize.define('SocialIdentity', {
  provider: { type: DataTypes.STRING(12), primaryKey: true },
  subject: { type: DataTypes.STRING(255), primaryKey: true },
  userId: {
    type: DataTypes.BIGINT,
    allowNull: false,
    references: { model: User, key: 'id' },
    onDelete: 'CASCADE',
  },
}, { tableName: 'social_identities', timestamps: false });
