import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/roomDetailsScreen/elec_input_screen.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  State<ProfileManagementScreen> createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  late Stream<QuerySnapshot> _usersStream;

  @override
  void initState() {
    super.initState();
    _usersStream = FirebaseFirestore.instance.collection('users').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý hồ sơ cá nhân phòng trọ')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có hồ sơ nào'));
          }

          // ✅ Lấy danh sách users từ Firestore
          final users = snapshot.data!.docs;

          // ✅ Sắp xếp danh sách theo số phòng từ nhỏ đến lớn
          users.sort((a, b) {
            final roomNoA = int.tryParse(a['roomNo']?.toString() ?? '0') ?? 0;
            final roomNoB = int.tryParse(b['roomNo']?.toString() ?? '0') ?? 0;
            return roomNoA.compareTo(roomNoB);
          });

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;

              final roomNo = data['roomNo']?.toString() ?? 'Không xác định';
              final fullName = data['fullName'] ?? 'Không có';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading:
                      const Icon(Icons.person, size: 40, color: Colors.blue),
                  title: Text(
                    roomNo == 'Không xác định'
                        ? 'Chủ hộ'
                        : 'Phòng trọ số: $roomNo',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Tên: $fullName'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteUser(user.id),
                  ),
                  onTap: () {
                    _showUserDetails(data, user.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 🗑️ Xóa người dùng
  Future<void> _deleteUser(String userId) async {
    bool confirmDelete = await _showConfirmDialog();
    if (confirmDelete) {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa hồ sơ thành công')),
      );
    }
  }

  /// 🛠️ Hiển thị chi tiết hồ sơ
  void _showUserDetails(Map<String, dynamic> userData, String userId) {
    final TextEditingController roomNoController =
        TextEditingController(text: userData['roomNo']?.toString());
    final TextEditingController fullNameController =
        TextEditingController(text: userData['fullName']);
    final TextEditingController dobController = TextEditingController(
      text: userData['dob'] is Timestamp
          ? DateFormat('dd/MM/yyyy')
              .format((userData['dob'] as Timestamp).toDate())
          : userData['dob'] ?? '',
    );

    final TextEditingController genderController =
        TextEditingController(text: userData['gender']);
    final TextEditingController idNumberController =
        TextEditingController(text: userData['idNumber']);
    final TextEditingController phoneController =
        TextEditingController(text: userData['phoneNumber']);
    final TextEditingController emailController =
        TextEditingController(text: userData['email']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Chi tiết hồ sơ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: roomNoController,
                    decoration: const InputDecoration(labelText: 'Phòng trọ'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: fullNameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dobController,
                    decoration: const InputDecoration(labelText: 'Ngày sinh'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await _updateUserInfo(
                        userId,
                        roomNoController.text,
                        fullNameController.text,
                        dobController.text,
                        genderController.text,
                        idNumberController.text,
                        phoneController.text,
                        emailController.text,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Lưu thay đổi'),
                  ),
                  const SizedBox(height: 10),
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.green),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UsageInputScreen(phoneNumber: userData['phoneNumber']),

                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 🔥 Cập nhật thông tin người dùng
  Future<void> _updateUserInfo(
    String userId,
    String roomNo,
    String fullName,
    String dob,
    String gender,
    String idNumber,
    String phone,
    String email,
  ) async {
    Timestamp? dobTimestamp;
    if (dob.isNotEmpty) {
      dobTimestamp = Timestamp.fromDate(DateFormat('dd/MM/yyyy').parse(dob));
    }

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'roomNo': roomNo,
      'fullName': fullName,
      'dob': dobTimestamp,
      'gender': gender,
      'idNumber': idNumber,
      'phoneNumber': phone,
      'email': email,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật thành công')),
    );
  }

  /// ✅ Xác nhận xóa hồ sơ
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
