import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/roomDetailsScreen/elec_input_screen.dart';

class RoomDetailsScreen extends StatefulWidget {
  const RoomDetailsScreen({super.key});

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  late Stream<List<QueryDocumentSnapshot>> _usersStream;

  @override
  void initState() {
    super.initState();
    _usersStream =
        FirebaseFirestore.instance.collection('users').snapshots().map(
      (snapshot) {
        // ✅ Sắp xếp theo roomNo tăng dần
        final sortedUsers = snapshot.docs
          ..sort((a, b) {
            final roomNoA = a['roomNo'] ?? double.infinity;
            final roomNoB = b['roomNo'] ?? double.infinity;
            return roomNoA.compareTo(roomNoB);
          });
        return sortedUsers;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý điện nước phòng trọ')),
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: _usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Chưa có hồ sơ nào'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.person, size: 40),
                  title: Text(
                    data['roomNo'] != null
                        ? 'Phòng trọ số: ${data['roomNo']}'
                        : 'Chủ hộ',
                  ),
                  subtitle: Text('Tên: ${data['fullName'] ?? 'Không có'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteUser(user.id),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UsageInputScreen(
                            phoneNumber: user['phoneNumber']),

                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🗑️ Xóa người dùng
  Future<void> _deleteUser(String userId) async {
    bool confirmDelete = await _showConfirmDialog();
    if (confirmDelete) {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa hồ sơ thành công')),
      );
    }
  }

  // ❓ Xác nhận xóa
  Future<bool> _showConfirmDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: const Text('Bạn có chắc muốn xóa hồ sơ này không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }
}
