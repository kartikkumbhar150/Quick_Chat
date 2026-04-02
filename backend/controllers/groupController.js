const Group = require('../models/Group');
const Message = require('../models/Message');
const User = require('../models/User');
const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// @GET /api/groups  — groups current user is member of
const getGroups = async (req, res) => {
  try {
    const groups = await Group.find({ 'members.user': req.user._id, isActive: true })
      .populate('members.user', 'username profileImage isOnline')
      .populate('admin', 'username profileImage')
      .populate({ path: 'lastMessage', populate: { path: 'sender', select: 'username' } })
      .sort({ updatedAt: -1 });

    res.status(200).json({ success: true, groups });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @POST /api/groups
const createGroup = async (req, res) => {
  try {
    const { name, description, memberIds } = req.body;

    if (!name)
      return res.status(400).json({ success: false, message: 'Group name is required' });

    const members = [{ user: req.user._id, role: 'admin' }];
    if (memberIds && Array.isArray(memberIds)) {
      for (const id of memberIds) {
        if (id !== req.user._id.toString()) {
          members.push({ user: id, role: 'member' });
        }
      }
    }

    const group = await Group.create({
      name,
      description: description || '',
      admin: req.user._id,
      members,
    });

    await group.populate('members.user', 'username profileImage');
    await group.populate('admin', 'username profileImage');

    res.status(201).json({ success: true, message: 'Group created', group });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @GET /api/groups/:id
const getGroup = async (req, res) => {
  try {
    const group = await Group.findOne({ _id: req.params.id, 'members.user': req.user._id })
      .populate('members.user', 'username profileImage isOnline lastSeen bio')
      .populate('admin', 'username profileImage');

    if (!group)
      return res.status(404).json({ success: false, message: 'Group not found or access denied' });

    res.status(200).json({ success: true, group });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @PUT /api/groups/:id
const updateGroup = async (req, res) => {
  try {
    const group = await Group.findById(req.params.id);
    if (!group)
      return res.status(404).json({ success: false, message: 'Group not found' });

    if (group.admin.toString() !== req.user._id.toString())
      return res.status(403).json({ success: false, message: 'Only admin can update group info' });

    const { name, description } = req.body;
    if (name) group.name = name;
    if (description !== undefined) group.description = description;
    await group.save();

    await group.populate('members.user', 'username profileImage');
    await group.populate('admin', 'username profileImage');

    res.status(200).json({ success: true, message: 'Group updated', group });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @DELETE /api/groups/:id
const deleteGroup = async (req, res) => {
  try {
    const group = await Group.findById(req.params.id);
    if (!group)
      return res.status(404).json({ success: false, message: 'Group not found' });

    if (group.admin.toString() !== req.user._id.toString())
      return res.status(403).json({ success: false, message: 'Only admin can delete the group' });

    await Message.deleteMany({ groupId: req.params.id });
    await group.deleteOne();

    res.status(200).json({ success: true, message: 'Group deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @POST /api/groups/:id/members
const addMembers = async (req, res) => {
  try {
    const group = await Group.findById(req.params.id);
    if (!group)
      return res.status(404).json({ success: false, message: 'Group not found' });

    if (group.admin.toString() !== req.user._id.toString())
      return res.status(403).json({ success: false, message: 'Only admin can add members' });

    const { memberIds } = req.body;
    if (!memberIds || !Array.isArray(memberIds))
      return res.status(400).json({ success: false, message: 'memberIds array is required' });

    const existingIds = group.members.map((m) => m.user.toString());
    for (const id of memberIds) {
      if (!existingIds.includes(id)) {
        group.members.push({ user: id, role: 'member' });
      }
    }
    await group.save();
    await group.populate('members.user', 'username profileImage');

    res.status(200).json({ success: true, message: 'Members added', group });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @DELETE /api/groups/:id/members/:userId
const removeMember = async (req, res) => {
  try {
    const group = await Group.findById(req.params.id);
    if (!group)
      return res.status(404).json({ success: false, message: 'Group not found' });

    if (group.admin.toString() !== req.user._id.toString())
      return res.status(403).json({ success: false, message: 'Only admin can remove members' });

    if (req.params.userId === group.admin.toString())
      return res.status(400).json({ success: false, message: 'Cannot remove admin from group' });

    group.members = group.members.filter((m) => m.user.toString() !== req.params.userId);
    await group.save();

    res.status(200).json({ success: true, message: 'Member removed' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @POST /api/groups/:id/leave
const leaveGroup = async (req, res) => {
  try {
    const group = await Group.findById(req.params.id);
    if (!group)
      return res.status(404).json({ success: false, message: 'Group not found' });

    if (group.admin.toString() === req.user._id.toString())
      return res.status(400).json({ success: false, message: 'Admin must transfer ownership before leaving' });

    group.members = group.members.filter((m) => m.user.toString() !== req.user._id.toString());
    await group.save();

    res.status(200).json({ success: true, message: 'You left the group' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @PUT /api/groups/:id/avatar
const updateGroupAvatar = async (req, res) => {
  try {
    const group = await Group.findById(req.params.id);
    if (!group)
      return res.status(404).json({ success: false, message: 'Group not found' });

    if (group.admin.toString() !== req.user._id.toString())
      return res.status(403).json({ success: false, message: 'Only admin can update group image' });

    if (!req.file)
      return res.status(400).json({ success: false, message: 'No image file provided' });

    const result = await new Promise((resolve, reject) => {
      cloudinary.uploader
        .upload_stream({ folder: 'quick_chat/groups', transformation: [{ width: 400, height: 400, crop: 'fill' }] },
          (err, result) => (err ? reject(err) : resolve(result)))
        .end(req.file.buffer);
    });

    group.groupImage = result.secure_url;
    await group.save();

    res.status(200).json({ success: true, message: 'Group image updated', group });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getGroups, createGroup, getGroup, updateGroup, deleteGroup,
  addMembers, removeMember, leaveGroup, updateGroupAvatar,
};
