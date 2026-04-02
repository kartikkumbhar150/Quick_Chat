const express = require('express');
const router = express.Router();
const {
  getConversationMessages, getGroupMessages,
  sendConversationMessage, sendGroupMessage,
  editMessage, deleteMessage, markAsRead,
} = require('../controllers/messageController');
const { protect } = require('../middleware/auth');

router.use(protect);

router.get('/conversation/:conversationId', getConversationMessages);
router.get('/group/:groupId', getGroupMessages);
router.post('/conversation/:conversationId', sendConversationMessage);
router.post('/group/:groupId', sendGroupMessage);
router.put('/:conversationId/read', markAsRead);
router.put('/:messageId', editMessage);
router.delete('/:messageId', deleteMessage);

module.exports = router;
