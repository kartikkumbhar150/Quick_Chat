const Message = require('../models/Message');
const Conversation = require('../models/Conversation');
const Group = require('../models/Group');

// @GET /api/messages/conversation/:conversationId
const getConversationMessages = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 30;
    const skip = (page - 1) * limit;

    const conversation = await Conversation.findOne({
      _id: conversationId,
      participants: req.user._id,
    });
    if (!conversation)
      return res.status(404).json({ success: false, message: 'Conversation not found' });

    const messages = await Message.find({ conversationId, isDeleted: false })
      .populate('sender', 'username profileImage')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Message.countDocuments({ conversationId, isDeleted: false });

    res.status(200).json({
      success: true,
      messages: messages.reverse(),
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @GET /api/messages/group/:groupId
const getGroupMessages = async (req, res) => {
  try {
    const { groupId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 30;
    const skip = (page - 1) * limit;

    const group = await Group.findOne({ _id: groupId, 'members.user': req.user._id });
    if (!group)
      return res.status(404).json({ success: false, message: 'Group not found or access denied' });

    const messages = await Message.find({ groupId, isDeleted: false })
      .populate('sender', 'username profileImage')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Message.countDocuments({ groupId, isDeleted: false });

    res.status(200).json({
      success: true,
      messages: messages.reverse(),
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @POST /api/messages/conversation/:conversationId  — REST fallback (primary: Socket.IO)
const sendConversationMessage = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { content, type = 'text', mediaUrl } = req.body;

    const conversation = await Conversation.findOne({
      _id: conversationId,
      participants: req.user._id,
    });
    if (!conversation)
      return res.status(404).json({ success: false, message: 'Conversation not found' });

    const message = await Message.create({
      conversationId,
      sender: req.user._id,
      content,
      type,
      mediaUrl,
      readBy: [{ user: req.user._id }],
    });

    await message.populate('sender', 'username profileImage');
    conversation.lastMessage = message._id;
    await conversation.save();

    res.status(201).json({ success: true, message });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @POST /api/messages/group/:groupId
const sendGroupMessage = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { content, type = 'text', mediaUrl } = req.body;

    const group = await Group.findOne({ _id: groupId, 'members.user': req.user._id });
    if (!group)
      return res.status(404).json({ success: false, message: 'Group not found or access denied' });

    const message = await Message.create({
      groupId,
      sender: req.user._id,
      content,
      type,
      mediaUrl,
      readBy: [{ user: req.user._id }],
    });

    await message.populate('sender', 'username profileImage');
    group.lastMessage = message._id;
    await group.save();

    res.status(201).json({ success: true, message });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @PUT /api/messages/:messageId
const editMessage = async (req, res) => {
  try {
    const message = await Message.findOne({ _id: req.params.messageId, sender: req.user._id });
    if (!message)
      return res.status(404).json({ success: false, message: 'Message not found or unauthorized' });

    message.content = req.body.content || message.content;
    message.editedAt = new Date();
    await message.save();

    res.status(200).json({ success: true, message });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @DELETE /api/messages/:messageId
const deleteMessage = async (req, res) => {
  try {
    const message = await Message.findOne({ _id: req.params.messageId, sender: req.user._id });
    if (!message)
      return res.status(404).json({ success: false, message: 'Message not found or unauthorized' });

    message.isDeleted = true;
    message.deletedAt = new Date();
    message.content = '';
    await message.save();

    res.status(200).json({ success: true, message: 'Message deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @PUT /api/messages/:conversationId/read
const markAsRead = async (req, res) => {
  try {
    const { conversationId } = req.params;
    await Message.updateMany(
      { conversationId, 'readBy.user': { $ne: req.user._id } },
      { $push: { readBy: { user: req.user._id, readAt: new Date() } } }
    );
    res.status(200).json({ success: true, message: 'Messages marked as read' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getConversationMessages,
  getGroupMessages,
  sendConversationMessage,
  sendGroupMessage,
  editMessage,
  deleteMessage,
  markAsRead,
};
