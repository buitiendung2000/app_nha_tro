import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/homeScreen/allBillScreen.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/homeScreen/profileManagementScreen.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/homeScreen/profileScreen.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/roomDetailsScreen/roomDetailsScreen.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/signinLogicScreen/signLogicScreen.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/homeScreen/myBillScreen.dart'; // ✅ Import màn hình mới

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Hàm xử lý đăng xuất
  Future<void> signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInLogicScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng xuất: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Lấy số điện thoại từ Firebase
    String? phoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Home Screen', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),

            // ✅ Nút Quản lý hồ sơ cá nhân
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ),
              child: const Text('Quản lý hồ sơ cá nhân'),
            ),
            const SizedBox(height: 20),

            // ✅ Nút Quản lý hồ sơ cá nhân phòng trọ
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProfileManagementScreen()),
              ),
              child: const Text('Quản lý hồ sơ cá nhân phòng trọ'),
            ),
            const SizedBox(height: 20),

            // ✅ Nút Quản lý điện nước phòng trọ
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>   RoomDetailsScreen()),
              ),
              child: const Text('Quản lý điện nước phòng trọ'),
            ),
            const SizedBox(height: 20),

            // ✅ Nút Xem hóa đơn phòng trọ
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AllBillsScreen()),
              ),
              child: const Text('Xem hóa đơn phòng trọ'),
            ),
            const SizedBox(height: 20),

            // ✅ Nút Thanh toán hóa đơn phòng trọ
            ElevatedButton(
              onPressed: () {
                if (phoneNumber != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MyBillScreen(phoneNumber: phoneNumber),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Không tìm thấy số điện thoại')),
                  );
                }
              },
              child: const Text('Thanh toán hóa đơn phòng trọ'),
            ),
            const SizedBox(height: 20),

            // ✅ Nút Đăng xuất
            ElevatedButton(
              onPressed: () => signOut(context),
              child: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    );
  }
}
