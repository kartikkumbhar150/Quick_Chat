const express = require('express');
const router = express.Router();
const {
  getGroups, createGroup, getGroup, updateGroup, deleteGroup,
  addMembers, removeMember, leaveGroup, updateGroupAvatar,
} = require('../controllers/groupController');
const { protect } = require('../middleware/auth');
const upload = require('../middleware/upload');

router.use(protect);

router.get('/', getGroups);
router.post('/', createGroup);
router.get('/:id', getGroup);
router.put('/:id', updateGroup);
router.delete('/:id', deleteGroup);
router.post('/:id/members', addMembers);
router.delete('/:id/members/:userId', removeMember);
router.post('/:id/leave', leaveGroup);
router.put('/:id/avatar', upload.single('groupImage'), updateGroupAvatar);

module.exports = router;
