import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/colors.dart';
import 'core/network/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/property_provider.dart';
import 'providers/verification_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/notification_provider.dart';
import 'core/network/socket_service.dart';
import 'screens/incoming_call_screen.dart';
import 'screens/splash_screen.dart';

// Global navigator key so ApiClient can navigate on 401 and Socket can push incoming calls
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wire 401 handler: clears token and pops back to root
  ApiClient.onUnauthorized = () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  };

  // Global In-App Incoming Call Listener
  SocketService.instance.onIncomingCall.listen((callData) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(callData: callData),
          fullscreenDialog: true,
        ),
      );
    }
  });

  // Global In-App Push Notification Toast Banner
  SocketService.instance.onNotificationPush.listen((data) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      final title = data['title'] ?? 'Notification';
      final msg = data['message'] ?? '';
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
              if (msg.isNotEmpty)
                Text(msg, style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  });

  // Global In-App Chat Message Toast Banner
  SocketService.instance.onMessageReceived.listen((msgData) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      final senderName = msgData['senderName'] ?? 'New Message';
      final content = msgData['content'] ?? '';
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.chat_bubble_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💬 $senderName', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
                    if (content.isNotEmpty)
                      Text(content, style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  });

  runApp(const HometrustApp());
}

class HometrustApp extends StatelessWidget {
  const HometrustApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()..fetchAll()),
        ChangeNotifierProvider(create: (_) => VerificationProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Hometrust',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.accentGold,
            surface: AppColors.surface,
          ),
          fontFamily: 'sans-serif',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
