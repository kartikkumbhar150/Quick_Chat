const express = require('express');
const router = express.Router();
const {
  getMe, updateMe, updateAvatar, deleteMe,
  searchUsers, getUserByUsername, blockUser, unblockUser,
} = require('../controllers/userController');
const { protect } = require('../middleware/auth');
const upload = require('../middleware/upload');

// All protected
router.use(protect);

router.get('/search', searchUsers);
router.get('/me', getMe);
router.put('/me', updateMe);
router.put('/me/avatar', upload.single('avatar'), updateAvatar);
router.delete('/me', deleteMe);
router.get('/:username', getUserByUsername);
router.post('/block/:userId', blockUser);
router.delete('/block/:userId', unblockUser);

module.exports = router;
