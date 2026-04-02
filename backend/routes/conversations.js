const express = require('express');
const router = express.Router();
const {
  getConversations, createConversation, getConversation, deleteConversation,
} = require('../controllers/conversationController');
const { protect } = require('../middleware/auth');

router.use(protect);

router.get('/', getConversations);
router.post('/', createConversation);
router.get('/:id', getConversation);
router.delete('/:id', deleteConversation);

module.exports = router;
