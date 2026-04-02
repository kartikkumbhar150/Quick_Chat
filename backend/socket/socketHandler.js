const Message = require('../models/Message');
const Conversation = require('../models/Conversation');
const Group = require('../models/Group');
const User = require('../models/User');
const jwt = require('jsonwebtoken');

// Map userId -> socketId for online tracking
const onlineUsers = new Map();

const socketHandler = (io) => {
  // Auth middleware for socket
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      if (!token) return next(new Error('Authentication error'));

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.userId = decoded.id;
      next();
    } catch (err) {
      next(new Error('Authentication error'));
    }
  });

  io.on('connection', async (socket) => {
    const userId = socket.userId;
    console.log(`🟢 User connected: ${userId} [${socket.id}]`);

    // Track online user
    onlineUsers.set(userId, socket.id);

    // Update DB online status
    await User.findByIdAndUpdate(userId, { isOnline: true, lastSeen: new Date() });

    // Broadcast online status to all users
    socket.broadcast.emit('user_online', { userId });

    // ── Join conversation rooms ──────────────────────────────────────────────
    socket.on('join_conversation', async ({ conversationId }) => {
      socket.join(`conversation:${conversationId}`);
      console.log(`User ${userId} joined conversation:${conversationId}`);
    });

    socket.on('join_group', async ({ groupId }) => {
      socket.join(`group:${groupId}`);
      console.log(`User ${userId} joined group:${groupId}`);
    });

    // ── Send message (DM) ────────────────────────────────────────────────────
    socket.on('send_message', async ({ conversationId, content, type = 'text', mediaUrl }) => {
      try {
        const conversation = await Conversation.findOne({
          _id: conversationId,
          participants: userId,
        });
        if (!conversation) return;

        const message = await Message.create({
          conversationId,
          sender: userId,
          content,
          type,
          mediaUrl,
          readBy: [{ user: userId }],
        });

        await message.populate('sender', 'username profileImage');

        // Update last message
        conversation.lastMessage = message._id;
        await conversation.save();

        // Emit to all participants in the room
        io.to(`conversation:${conversationId}`).emit('new_message', {
          conversationId,
          message,
        });

        // Notify offline recipients (push notification placeholder)
        conversation.participants.forEach((participantId) => {
          if (participantId.toString() !== userId) {
            const recipientSocketId = onlineUsers.get(participantId.toString());
            if (!recipientSocketId) {
              // TODO: Trigger push notification
            }
          }
        });
      } catch (err) {
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // ── Send group message ───────────────────────────────────────────────────
    socket.on('send_group_message', async ({ groupId, content, type = 'text', mediaUrl }) => {
      try {
        const group = await Group.findOne({ _id: groupId, 'members.user': userId });
        if (!group) return;

        const message = await Message.create({
          groupId,
          sender: userId,
          content,
          type,
          mediaUrl,
          readBy: [{ user: userId }],
        });

        await message.populate('sender', 'username profileImage');

        group.lastMessage = message._id;
        await group.save();

        io.to(`group:${groupId}`).emit('new_group_message', { groupId, message });
      } catch (err) {
        socket.emit('error', { message: 'Failed to send group message' });
      }
    });

    // ── Typing indicators ────────────────────────────────────────────────────
    socket.on('typing_start', ({ conversationId, groupId }) => {
      const room = conversationId ? `conversation:${conversationId}` : `group:${groupId}`;
      socket.to(room).emit('typing_start', { userId, conversationId, groupId });
    });

    socket.on('typing_stop', ({ conversationId, groupId }) => {
      const room = conversationId ? `conversation:${conversationId}` : `group:${groupId}`;
      socket.to(room).emit('typing_stop', { userId, conversationId, groupId });
    });

    // ── Read receipts ────────────────────────────────────────────────────────
    socket.on('message_read', async ({ conversationId }) => {
      try {
        await Message.updateMany(
          { conversationId, 'readBy.user': { $ne: userId } },
          { $push: { readBy: { user: userId, readAt: new Date() } } }
        );
        io.to(`conversation:${conversationId}`).emit('messages_read', { conversationId, userId });
      } catch (err) {
        console.error('Read receipt error:', err);
      }
    });

    // ── Disconnect ───────────────────────────────────────────────────────────
    socket.on('disconnect', async () => {
      console.log(`🔴 User disconnected: ${userId}`);
      onlineUsers.delete(userId);
      await User.findByIdAndUpdate(userId, { isOnline: false, lastSeen: new Date() });
      socket.broadcast.emit('user_offline', { userId, lastSeen: new Date() });
    });
  });
};

module.exports = socketHandler;
