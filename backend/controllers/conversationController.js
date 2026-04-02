const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const User = require('../models/User');

// @GET /api/conversations  — all conversations for logged-in user
const getConversations = async (req, res) => {
  try {
    const conversations = await Conversation.find({ participants: req.user._id })
      .populate('participants', 'username profileImage isOnline lastSeen')
      .populate({ path: 'lastMessage', populate: { path: 'sender', select: 'username' } })
      .sort({ updatedAt: -1 });

    res.status(200).json({ success: true, conversations });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @POST /api/conversations  — start or get existing DM
const createConversation = async (req, res) => {
  try {
    const { participantId } = req.body;

    if (!participantId)
      return res.status(400).json({ success: false, message: 'participantId is required' });

    if (participantId === req.user._id.toString())
      return res.status(400).json({ success: false, message: 'Cannot start a conversation with yourself' });

    const participant = await User.findById(participantId);
    if (!participant)
      return res.status(404).json({ success: false, message: 'User not found' });

    // Check if conversation already exists
    let conversation = await Conversation.findOne({
      participants: { $all: [req.user._id, participantId], $size: 2 },
      isGroup: false,
    })
      .populate('participants', 'username profileImage isOnline lastSeen')
      .populate({ path: 'lastMessage', populate: { path: 'sender', select: 'username' } });

    if (!conversation) {
      conversation = await Conversation.create({
        participants: [req.user._id, participantId],
        isGroup: false,
      });
      conversation = await conversation.populate('participants', 'username profileImage isOnline lastSeen');
    }

    res.status(200).json({ success: true, conversation });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @GET /api/conversations/:id
const getConversation = async (req, res) => {
  try {
    const conversation = await Conversation.findOne({
      _id: req.params.id,
      participants: req.user._id,
    })
      .populate('participants', 'username profileImage isOnline lastSeen bio status')
      .populate({ path: 'lastMessage', populate: { path: 'sender', select: 'username' } });

    if (!conversation)
      return res.status(404).json({ success: false, message: 'Conversation not found' });

    res.status(200).json({ success: true, conversation });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @DELETE /api/conversations/:id
const deleteConversation = async (req, res) => {
  try {
    const conversation = await Conversation.findOne({
      _id: req.params.id,
      participants: req.user._id,
    });

    if (!conversation)
      return res.status(404).json({ success: false, message: 'Conversation not found' });

    await Message.deleteMany({ conversationId: req.params.id });
    await conversation.deleteOne();

    res.status(200).json({ success: true, message: 'Conversation deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { getConversations, createConversation, getConversation, deleteConversation };
