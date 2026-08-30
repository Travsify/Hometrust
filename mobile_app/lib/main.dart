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
