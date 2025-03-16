import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:tinh_tien_dien_nuoc_phong_tro/controller/provider/authProvider/mobileAuthProvider.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/authScreen/mobileLoginScreen.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/homeScreen/homeScreen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 Xử lý thông báo nền: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ Đăng ký xử lý thông báo khi ứng dụng ở chế độ nền
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Khởi tạo thông báo và xin quyền thông báo
  await setupFirebaseMessaging();

  runApp(const MyApp());
}

Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // ✅ Xin quyền nhận thông báo trên iOS
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

  // ✅ Lấy FCM Token để sử dụng cho thông báo
  String? token = await messaging.getToken();
  debugPrint('🔥 FCM Token: $token');

  // ✅ Xử lý thông báo khi ứng dụng đang mở (foreground)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint(
        '🔔 Nhận thông báo khi đang mở ứng dụng: ${message.notification?.title}');

    if (message.notification != null) {
      // Hiển thị thông báo dạng snackbar hoặc dialog
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

  // ✅ Xử lý khi người dùng nhấn vào thông báo từ trạng thái nền hoặc đã bị đóng
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint(
        '🔔 Người dùng nhấn vào thông báo: ${message.notification?.title}');
    // 👉 Chuyển đến màn hình cần thiết khi nhấn vào thông báo
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  });
}

// ✅ Dùng GlobalKey để xử lý thông báo từ mọi nơi trong ứng dụng
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MobileAuthProvider>(
          create: (_) => MobileAuthProvider(),
        ),
      ],
      child: Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey:
                navigatorKey, // ✅ Thêm navigatorKey để xử lý thông báo
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasData) {
                    return const HomeScreen();
                  } else {
                    return const MobileLoginScreen();
                  }
                }
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
