import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/controller/provider/profileProvider/profileProvider.dart';
 

class ProfileManagementScreen extends StatelessWidget {
  const ProfileManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProfileProvider>();
    final currencyFormatter = NumberFormat("#,##0", "vi_VN");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý hồ sơ cá nhân'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe0f7fa), Color(0xFF80deea)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: prov.usersStream,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('Chưa có hồ sơ nào'));
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final doc = docs[i];
                final data = doc.data()! as Map<String, dynamic>;
                final roomNo = data['roomNo']?.toString() ?? '—';
                final fullName = data['fullName'] ?? '—';

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade200, Colors.blue.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child:
                            Icon(Icons.person, size: 30, color: Colors.white),
                      ),
                    ),
                    title: Text(
                      roomNo == '—' ? 'Chủ hộ' : 'Phòng trọ số $roomNo',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text('Tên: $fullName'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                              context: ctx,
                              builder: (_) => AlertDialog(
                                title: const Text('Xác nhận'),
                                content:
                                    const Text('Bạn có chắc muốn xóa hồ sơ?'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Hủy')),
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Xóa',
                                          style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ) ??
                            false;
                        if (ok) {
                          await prov.deleteUser(doc.id);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Xóa thành công')));
                        }
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => ProfileEditScreen(
                            userId: doc.id,
                            userData: data,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ProfileEditScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const ProfileEditScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController roomNoC,
      nameC,
      dobC,
      genderC,
      idC,
      phoneC,
      emailC,
      permAddrC,
      tempAddrC,
      currAddrC,
      jobC,
      ownerC,
      relC;

  @override
  void initState() {
    super.initState();
    final d = widget.userData;
    roomNoC = TextEditingController(text: d['roomNo']?.toString());
    nameC = TextEditingController(text: d['fullName']);
    dobC = TextEditingController(
      text: d['dob'] is Timestamp
          ? DateFormat('dd/MM/yyyy').format((d['dob'] as Timestamp).toDate())
          : d['dob'] ?? '',
    );
    genderC = TextEditingController(text: d['gender']);
    idC = TextEditingController(text: d['idNumber']);
    phoneC = TextEditingController(text: d['phoneNumber']);
    emailC = TextEditingController(text: d['email']);
    permAddrC = TextEditingController(text: d['permanentAddress']);
    tempAddrC = TextEditingController(text: d['temporaryAddress']);
    currAddrC = TextEditingController(text: d['currentAddress']);
    jobC = TextEditingController(text: d['job']);
    ownerC = TextEditingController(text: d['householdOwner']);
    relC = TextEditingController(text: d['relationship']);
  }

  @override
  void dispose() {
    for (final c in [
      roomNoC,
      nameC,
      dobC,
      genderC,
      idC,
      phoneC,
      emailC,
      permAddrC,
      tempAddrC,
      currAddrC,
      jobC,
      ownerC,
      relC
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa hồ sơ'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTextField('Phòng trọ', roomNoC, readOnly: false),
              const SizedBox(height: 12),
              _buildTextField('Họ và tên', nameC),
              const SizedBox(height: 12),
              _buildDateField('Ngày sinh', dobC),
              const SizedBox(height: 12),
              _buildTextField('Giới tính', genderC),
              const SizedBox(height: 12),
              _buildTextField('CMND/CCCD', idC),
              const SizedBox(height: 12),
              _buildTextField('SĐT', phoneC),
              const SizedBox(height: 12),
              _buildTextField('Email', emailC),
              const SizedBox(height: 12),
              _buildTextField('Thường trú', permAddrC),
              const SizedBox(height: 12),
              _buildTextField('Tạm trú', tempAddrC),
              const SizedBox(height: 12),
              _buildTextField('Hiện tại', currAddrC),
              const SizedBox(height: 12),
              _buildTextField('Nghề nghiệp', jobC),
              const SizedBox(height: 12),
              _buildTextField('Chủ hộ', ownerC),
              const SizedBox(height: 12),
              _buildTextField('Quan hệ', relC),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Lưu thay đổi'),
                onPressed: () async {
                  await prov.updateUser(
                    userId: widget.userId,
                    roomNo: roomNoC.text,
                    fullName: nameC.text,
                    dobText: dobC.text,
                    gender: genderC.text,
                    idNumber: idC.text,
                    phone: phoneC.text,
                    email: emailC.text,
                    permanentAddress: permAddrC.text,
                    temporaryAddress: tempAddrC.text,
                    currentAddress: currAddrC.text,
                    job: jobC.text,
                    householdOwner: ownerC.text,
                    relationship: relC.text,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cập nhật thành công')));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController c,
      {bool readOnly = false}) {
    return TextField(
      controller: c,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController c) {
    return TextField(
      controller: c,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          c.text = DateFormat('dd/MM/yyyy').format(picked);
        }
      },
    );
  }
}
