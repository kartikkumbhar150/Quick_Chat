const User = require('../models/User');
const cloudinary = require('cloudinary').v2;

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// @GET /api/users/me
const getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('-password -otp -otpExpiry');
    res.status(200).json({ success: true, user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @PUT /api/users/me
const updateMe = async (req, res) => {
  try {
    const { bio, status, username } = req.body;
    const updates = {};

    if (bio !== undefined) updates.bio = bio;
    if (status !== undefined) updates.status = status;
    if (username !== undefined) {
      const taken = await User.findOne({ username, _id: { $ne: req.user._id } });
      if (taken)
        return res.status(409).json({ success: false, message: 'Username already taken' });
      updates.username = username;
    }

    const user = await User.findByIdAndUpdate(req.user._id, updates, {
      new: true,
      runValidators: true,
    }).select('-password -otp -otpExpiry');

    res.status(200).json({ success: true, message: 'Profile updated', user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @PUT /api/users/me/avatar
const updateAvatar = async (req, res) => {
  try {
    if (!req.file)
      return res.status(400).json({ success: false, message: 'No image file provided' });

    // Upload to Cloudinary from buffer
    const result = await new Promise((resolve, reject) => {
      cloudinary.uploader
        .upload_stream({ folder: 'quick_chat/avatars', transformation: [{ width: 400, height: 400, crop: 'fill' }] },
          (err, result) => (err ? reject(err) : resolve(result)))
        .end(req.file.buffer);
    });

    const user = await User.findByIdAndUpdate(
      req.user._id,
      { profileImage: result.secure_url },
      { new: true }
    ).select('-password -otp -otpExpiry');

    res.status(200).json({ success: true, message: 'Profile image updated', user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @DELETE /api/users/me
const deleteMe = async (req, res) => {
  try {
    await User.findByIdAndDelete(req.user._id);
    res.status(200).json({ success: true, message: 'Account deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @GET /api/users/search?q=username
const searchUsers = async (req, res) => {
  try {
    const { q } = req.query;
    if (!q || q.trim().length < 1)
      return res.status(400).json({ success: false, message: 'Search query is required' });

    const users = await User.find({
      username: { $regex: q.trim(), $options: 'i' },
      _id: { $ne: req.user._id },
      isVerified: true,
    })
      .select('username profileImage bio status isOnline lastSeen')
      .limit(20);

    res.status(200).json({ success: true, users });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @GET /api/users/:username
const getUserByUsername = async (req, res) => {
  try {
    const user = await User.findOne({ username: req.params.username, isVerified: true })
      .select('username profileImage bio status isOnline lastSeen createdAt');

    if (!user)
      return res.status(404).json({ success: false, message: 'User not found' });

    res.status(200).json({ success: true, user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @POST /api/users/block/:userId
const blockUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const me = await User.findById(req.user._id);

    if (me.blockedUsers.includes(userId))
      return res.status(400).json({ success: false, message: 'User already blocked' });

    me.blockedUsers.push(userId);
    await me.save();

    res.status(200).json({ success: true, message: 'User blocked' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @DELETE /api/users/block/:userId
const unblockUser = async (req, res) => {
  try {
    const { userId } = req.params;
    await User.findByIdAndUpdate(req.user._id, { $pull: { blockedUsers: userId } });
    res.status(200).json({ success: true, message: 'User unblocked' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { getMe, updateMe, updateAvatar, deleteMe, searchUsers, getUserByUsername, blockUser, unblockUser };
