import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:tinh_tien_dien_nuoc_phong_tro/controller/provider/authProvider/mobileAuthProvider.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/controller/provider/homeProvider/homeProvider.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/controller/provider/profileProvider/profileProvider.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/controller/provider/revenue_provider/revenue_provider.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/authScreen/mobileLoginScreen.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/homeScreen/homeScreen.dart';

/// Xử lý thông báo nền
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 Xử lý thông báo nền: ${message.messageId}');
}

Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Xin quyền nhận thông báo trên iOS
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    debugPrint('🔔 Đã được cấp quyền nhận thông báo!');
  } else {
    debugPrint('❌ Không được cấp quyền nhận thông báo!');
  }

  // Lấy FCM Token để sử dụng cho thông báo
  String? token = await messaging.getToken();
  debugPrint('🔥 FCM Token: $token');

  // Xử lý thông báo khi ứng dụng đang mở (foreground)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint(
        '🔔 Nhận thông báo khi đang mở ứng dụng: ${message.notification?.title}');
    if (message.notification != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: Text(message.notification!.title ?? 'Thông báo'),
          content:
              Text(message.notification!.body ?? 'Nội dung không xác định'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  });

  // Xử lý khi người dùng nhấn vào thông báo từ trạng thái nền hoặc đã bị đóng
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint(
        '🔔 Người dùng nhấn vào thông báo: ${message.notification?.title}');
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  });
}

// Dùng GlobalKey để xử lý navigation từ mọi nơi trong ứng dụng
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Đăng ký xử lý thông báo khi ứng dụng ở chế độ nền
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Khởi tạo thông báo và xin quyền nhận thông báo
  await setupFirebaseMessaging();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MobileAuthProvider>(
          create: (_) => MobileAuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeProvider(),
          child: const MyApp(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(),
          child: const MyApp(),
        ),
        ChangeNotifierProvider(
          create: (_) => RevenueProvider(),
          child: const MyApp(),
        ),
      ],
      child: Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

/// Màn hình Splash sẽ hiển thị trong vài giây trước khi chuyển hướng
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Hiển thị splash trong 3 giây rồi chuyển đến màn hình đăng nhập hoặc home
    Future.delayed(const Duration(seconds: 3), () {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Người dùng đã đăng nhập -> chuyển đến HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Người dùng chưa đăng nhập -> chuyển đến MobileLoginScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MobileLoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sử dụng hình splash từ assets
      body: Center(
        child: Image.asset(
          'assets/images/splash.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
