// ignore_for_file: use_build_context_synchronously
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
 
import 'package:tinh_tien_dien_nuoc_phong_tro/view/homeScreen/homeScreen.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/userRegister/userRegistraionScreen.dart';
import '../../../constants/constants.dart';
import '../../../view/authScreen/mobileLoginScreen.dart';
import '../../../view/authScreen/otpScreen.dart';
import '../../../view/signinLogicScreen/signLogicScreen.dart';
import '../../provider/authProvider/mobileAuthProvider.dart';

class MobileAuthServices {
  static Future<String?> getFCMToken() async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        print('FCM Token: $fcmToken');
        return fcmToken;
      }
    } catch (e) {
      print('Lỗi lấy FCM Token: $e');
    }
    return null;
  }

  static Future<void> checkAuthentication(BuildContext context) async {
    final user = auth.currentUser;
    if (user == null) {
      await Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
          child: const MobileLoginScreen(),
          type: PageTransitionType.rightToLeft,
        ),
        (route) => false,
      );
      return;
    }
    await checkUserRegistration(context: context);
  }

  static receiveOTP(
      {required BuildContext context, required String mobileNo}) async {
    try {
      await auth.verifyPhoneNumber(
        phoneNumber: mobileNo,
        verificationCompleted: (PhoneAuthCredential credentials) {
          log(credentials.toString());
        },
        verificationFailed: (FirebaseAuthException exception) {
          log(exception.toString());
          throw Exception(exception);
        },
        codeSent: (String verificationID, int? resendToken) {
          context
              .read<MobileAuthProvider>()
              .updateVerificationID(verificationID);
          Navigator.push(
            context,
            PageTransition(
              child: const OTPScreen(),
              type: PageTransitionType.rightToLeft,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationID) {},
      );
    } on FirebaseAuthException catch (e) {
      log(e.toString());
      throw Exception(e);
    }
  }

  static Future<void> verifyOTP(
      {required BuildContext context, required String otp}) async {
    try {
      AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: context.read<MobileAuthProvider>().verificationID!,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      await checkUserRegistration(context: context);
    } catch (e) {
      log('Lỗi xác thực OTP: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapOTPError(e))),
      );
    }
  }

  static String _mapOTPError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-verification-code':
          return 'Mã OTP không hợp lệ';
        case 'session-expired':
          return 'Phiên đăng nhập hết hạn';
        default:
          return 'Lỗi xác thực: ${error.code}';
      }
    }
    return 'Lỗi không xác định';
  }

  static Future<void> checkUserRegistration(
      {required BuildContext context}) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MobileLoginScreen()),
          (route) => false,
        );
        return;
      }

      final String? phoneNumber = user.phoneNumber;

      if (phoneNumber == null) {
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MobileLoginScreen()),
          (route) => false,
        );
        return;
      }

    

      String? fcmToken = await getFCMToken();

      final DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(phoneNumber);

      final DocumentSnapshot doc = await userDoc.get();

      if (doc.exists) {
        await userDoc.update({
          'fcmToken': fcmToken,
        });

        Navigator.pushAndRemoveUntil(
          context,
          PageTransition(
            child: const HomeScreen(),
            type: PageTransitionType.rightToLeft,
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          PageTransition(
            child: const UserRegistrationScreen(),
            type: PageTransitionType.rightToLeft,
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Lỗi checkUserRegistration: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi hệ thống, vui lòng thử lại')),
        );
      }
    }
  }
Future<void> signInAsOwner(BuildContext context) async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;

      // Bắt đầu xác thực số điện thoại
      await auth.verifyPhoneNumber(
        phoneNumber: '+84906950367',
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Đăng nhập tự động khi verificationComplete được gọi
          await auth.signInWithCredential(credential);

          // Chuyển đến HomeScreen sau khi đăng nhập thành công
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xác thực: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) async {
          // Dùng mã test cố định 123456
          PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: verificationId,
            smsCode: '123456',
          );

          await auth.signInWithCredential(credential);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập thất bại: $e')),
      );
    }
  }

  static signOut(BuildContext context) {
    auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (BuildContext context) {
        return const SignInLogicScreen();
      }),
      (route) => false,
    );
  }
}
