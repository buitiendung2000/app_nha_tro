import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // ✅ Lấy số điện thoại từ Firebase Auth
      String? phoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;
      if (phoneNumber == null) {
        setState(() => isLoading = false);
        return;
      }

      // ✅ Lấy dữ liệu từ Firestore theo số điện thoại
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        print('❌ Không tìm thấy dữ liệu cho số điện thoại: $phoneNumber');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('❌ Lỗi khi tải dữ liệu: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateUserData() async {
    try {
      String? phoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;
      if (phoneNumber == null || userData == null) return;

      // ✅ Cập nhật dữ liệu Firestore theo số điện thoại
      await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .update(userData!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đã cập nhật thông tin thành công!')),
      );
    } catch (e) {
      print('❌ Lỗi khi cập nhật dữ liệu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Lỗi khi cập nhật thông tin!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userData == null) {
      return const Scaffold(
        body: Center(child: Text('❌ Không có dữ liệu hồ sơ!')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý trang cá nhân')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: userData?['roomNo'] ?? '',
                decoration: const InputDecoration(labelText: 'Phòng trọ số'),
                readOnly: true,
                onChanged: (value) => setState(() {
                  userData?['roomNo'] = value;
                }),
              ),
              const SizedBox(height: 10),

              // ✅ Họ và tên
              TextFormField(
                initialValue: userData?['fullName'] ?? '',
                decoration: const InputDecoration(labelText: 'Họ và tên'),
                readOnly: true,
                onChanged: (value) => setState(() {
                  userData?['fullName'] = value;
                }),
              ),
              const SizedBox(height: 10),
              // ✅ Ngày sinh
              TextFormField(
                initialValue: userData?['dob'] ?? '',
                decoration: const InputDecoration(labelText: 'Ngày sinh'),
                onChanged: (value) => setState(() {
                  userData?['dob'] = value;
                }),
              ),
              const SizedBox(height: 10),

              TextFormField(
                initialValue: userData?['gender'] ?? '',
                decoration: const InputDecoration(labelText: 'Giới tính'),
                onChanged: (value) => setState(() {
                  userData?['gender'] = value;
                }),
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: userData?['idNumber'] ?? '',
                decoration: const InputDecoration(
                    labelText: 'Số định danh cá nhân / CCCD'),
                onChanged: (value) => setState(() {
                  userData?['idNumber'] = value;
                }),
              ),
              const SizedBox(height: 10),
              // ✅ Số điện thoại (không cho chỉnh sửa)
              TextFormField(
                initialValue: userData?['phoneNumber'] ?? '',
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                readOnly: true,
              ),
              const SizedBox(height: 10),

              // ✅ Email
              TextFormField(
                initialValue: userData?['email'] ?? '',
                decoration: const InputDecoration(labelText: 'Email'),
                onChanged: (value) => setState(() {
                  userData?['email'] = value;
                }),
              ),
               const SizedBox(height: 10),
                 TextFormField(
                initialValue: userData?['permanentAddress'] ?? '',
                decoration: const InputDecoration(labelText: 'Nơi thường trú'),
                onChanged: (value) => setState(() {
                  userData?['permanentAddress'] = value;
                }),
              ),
             
              const SizedBox(height: 10),
              TextFormField(
                initialValue: userData?['temporaryAddress'] ?? '',
                decoration: const InputDecoration(labelText: 'Nơi tạm trú'),
                onChanged: (value) => setState(() {
                  userData?['temporaryAddress'] = value;
                }),
              ),
              const SizedBox(height: 10),
              // ✅ Địa chỉ hiện tại
              TextFormField(
                initialValue: userData?['currentAddress'] ?? '',
                decoration: const InputDecoration(labelText: 'Nơi ở hiện tại'),
                onChanged: (value) => setState(() {
                  userData?['currentAddress'] = value;
                }),
              ),
              const SizedBox(height: 10),

              // ✅ Công việc
              TextFormField(
                initialValue: userData?['job'] ?? '',
                decoration: const InputDecoration(labelText: 'Công việc'),
                onChanged: (value) => setState(() {
                  userData?['job'] = value;
                }),
              ),
               const SizedBox(height: 10),

              // ✅ Công việc
              TextFormField(
                initialValue: userData?['householdOwner'] ?? '',
                decoration: const InputDecoration(labelText: 'Tên chủ hộ'),
                onChanged: (value) => setState(() {
                  userData?['householdOwner'] = value;
                }),
              ),
              const SizedBox(height: 10),

              // ✅ Công việc
              TextFormField(
                initialValue: userData?['relationship'] ?? '',
                decoration: const InputDecoration(labelText: 'Quan hệ chủ hộ'),
                onChanged: (value) => setState(() {
                  userData?['relationship'] = value;
                }),
              ),
              const SizedBox(height: 20),

              // ✅ Nút cập nhật
              ElevatedButton(
                onPressed: _updateUserData,
                child: const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
