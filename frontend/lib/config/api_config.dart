class ApiConfig {
  // Change this to your backend IP/hostname when deploying
  static const String baseUrl = 'http://192.168.1.100:5000'; // Android emulator → localhost
  // static const String baseUrl = 'http://localhost:5000'; // iOS simulator

  // Auth
  static const String signup = '/api/auth/signup';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String resendOtp = '/api/auth/resend-otp';
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';

  // Users
  static const String me = '/api/users/me';
  static const String meAvatar = '/api/users/me/avatar';
  static const String searchUsers = '/api/users/search';

  // Conversations
  static const String conversations = '/api/conversations';

  // Messages
  static const String messages = '/api/messages';

  // Groups
  static const String groups = '/api/groups';

  // Socket
  static const String socketUrl = baseUrl;
}
