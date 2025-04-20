import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/controller/provider/homeProvider/homeProvider.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/chatPageScreen/chatPage.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/homeScreen/allBillScreen/allBillScreen.dart' show AllBillsScreen;
import 'package:tinh_tien_dien_nuoc_phong_tro/view/homeScreen/feedBackSummaryScreen.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/pendingInvoices/pendingInvoicesScreen.dart';
 
import 'package:tinh_tien_dien_nuoc_phong_tro/view/homeScreen/profileScreen/profile_management_screen.dart';
 
 
import 'package:tinh_tien_dien_nuoc_phong_tro/view/authScreen/returnRoom/returnRoomScreen.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/homeScreen/revenueScreen.dart';
 
import 'package:tinh_tien_dien_nuoc_phong_tro/view/roomDetailsScreen/roomDetailsScreen.dart';
 // import các màn hình con

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    final menuItems = [
      _MenuItem(
          "Quản lý hồ sơ trọ", Icons.group, const ProfileManagementScreen()),
      _MenuItem("Doanh thu", Icons.attach_money, const RevenueScreen()),
      _MenuItem("Tạo hóa đơn", Icons.receipt, RoomDetailsScreen()),
      _MenuItem("Xem hóa đơn", Icons.list_alt, const AllBillsScreen()),
      _MenuItem(
          "Hóa đơn cần xử lý", Icons.pending_actions, const PendingBillsPage(),
          showDot: provider.hasPendingBills),
      _MenuItem("Trò chuyện", Icons.chat, const ChatPage(),
          showDot: provider.hasUnreadMessages),
      _MenuItem("Tổng hợp góp ý", Icons.feedback, const FeedbackSummaryScreen(),
          showDot: provider.hasUnprocessedFeedback),
      _MenuItem("Đơn trả phòng", Icons.assignment, const ReturnRoomScreen(),
          showDot: provider.hasReturnRoom),
      // ... các mục khác không cần dot
      _MenuItem("Đăng xuất", Icons.logout, null),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trang chủ - Chủ trọ"),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: menuItems.map((item) {
          return GestureDetector(
            onTap: () {
              if (item.route == null) {
                // sign-out logic có thể gọi provider hoặc vẫn dùng trực tiếp
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/signIn');
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item.route!),
                );
              }
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, size: 40, color: Colors.teal),
                        const SizedBox(height: 10),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  if (item.showDot)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child:
                          CircleAvatar(radius: 6, backgroundColor: Colors.red),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Widget? route;
  final bool showDot;
  const _MenuItem(this.title, this.icon, this.route, {this.showDot = false});
}
