import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/chat/group_chat_screen.dart';
import 'screens/group/create_group_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'models/conversation_model.dart';
import 'models/group_model.dart';

void main() {
  runApp(const QuickChatApp());
}

class QuickChatApp extends StatelessWidget {
  const QuickChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'Quick Chat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _AppStartup(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignupScreen(),
          '/home': (_) => const HomeScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/create-group': (_) => const CreateGroupScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/chat') {
            final conv = settings.arguments as ConversationModel;
            return MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv));
          }
          if (settings.name == '/group-chat') {
            final group = settings.arguments as GroupModel;
            return MaterialPageRoute(builder: (_) => GroupChatScreen(group: group));
          }
          if (settings.name == '/otp') {
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => OtpScreen(userId: args['userId']!, email: args['email']!),
            );
          }
          return null;
        },
      ),
    );
  }
}

class _AppStartup extends StatelessWidget {
  const _AppStartup();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        switch (auth.status) {
          case AuthStatus.unknown:
            return const Scaffold(
              backgroundColor: AppTheme.background,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('⚡', style: TextStyle(fontSize: 64)),
                    SizedBox(height: 16),
                    Text('Quick Chat',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
              ),
            );
          case AuthStatus.authenticated:
            return const HomeScreen();
          case AuthStatus.unauthenticated:
            return const LoginScreen();
        }
      },
    );
  }
}
