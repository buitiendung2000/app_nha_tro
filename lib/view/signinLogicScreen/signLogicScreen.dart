import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/authScreen/mobileLoginScreen.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/homeScreen/homeScreen.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/userRegister/userRegistraionScreen.dart';

class SignInLogicScreen extends StatelessWidget {
  const SignInLogicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // ✅ Người dùng đã đăng nhập → Kiểm tra trạng thái đăng ký từ Firestore
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot
                    .data!.phoneNumber) // 🔥 Dùng số điện thoại làm documentId
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                // ✅ Đã đăng ký → Lưu FCM Token rồi chuyển đến HomeScreen
                saveLandlordFCMToken(snapshot.data!.phoneNumber!).then((_) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                });

                // ✅ Trả về widget tạm thời để tránh lỗi trong FutureBuilder
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else {
                // ❌ Chưa đăng ký → Chuyển đến màn hình đăng ký
                return const UserRegistrationScreen();
              }
            },
          );
        } else {
          // ❌ Người dùng chưa đăng nhập → Chuyển đến màn hình đăng nhập
          return const MobileLoginScreen();
        }
      },
    );
  }
}

// ✅ Hàm lưu FCM Token cho chủ trọ
Future<void> saveLandlordFCMToken(String landlordId) async {
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('landlords')
          .doc(landlordId)
          .set({
        'fcmToken': token,
      }, SetOptions(merge: true));
      debugPrint('✅ FCM Token đã lưu thành công cho chủ trọ');
    }
  } catch (e) {
    debugPrint('❌ Lỗi khi lưu FCM Token: $e');
  }
}
