import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AllBillsScreen extends StatelessWidget {
  const AllBillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tất cả hóa đơn phòng trọ')),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('users').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có hóa đơn nào.'));
          }

          // ✅ Lấy danh sách users từ Firestore
          final users = snapshot.data!.docs;

          // ✅ Sắp xếp danh sách theo roomNo từ nhỏ đến lớn
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
              final phoneNumber = data['phoneNumber'] ?? 'Không xác định';
              final roomNumber = data['roomNo'] ?? 'Không xác định';

              if (phoneNumber == 'Không xác định') return const SizedBox();

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(phoneNumber)
                    .collection('bills')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, billSnapshot) {
                  if (billSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(); // Đang tải
                  }
                  if (!billSnapshot.hasData ||
                      billSnapshot.data!.docs.isEmpty) {
                    return const SizedBox(); // Không hiển thị nếu không có hóa đơn
                  }

                  final bills = billSnapshot.data!.docs;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ExpansionTile(
                      leading: const Icon(Icons.home, color: Colors.blue),
                      title: Text(
                        'Phòng trọ số: $roomNumber',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle:
                          Text('Tên: ${data['fullName'] ?? 'Không có tên'}'),
                      children: bills.map((bill) {
                        final data = bill.data() as Map<String, dynamic>;

                        // ✅ Đọc dữ liệu từ Firestore
                        double startElectric =
                            data['startElectric']?.toDouble() ?? 0;
                        double endElectric =
                            data['endElectric']?.toDouble() ?? 0;
                        double electricTotal =
                            data['electricTotal']?.toDouble() ?? 0;
                        double pricePerKw = data['pricePerKw']?.toDouble() ?? 0;

                        double startWater = data['startWater']?.toDouble() ?? 0;
                        double endWater = data['endWater']?.toDouble() ?? 0;
                        double waterTotal = data['waterTotal']?.toDouble() ?? 0;
                        double pricePerM3 = data['pricePerM3']?.toDouble() ?? 0;

                        double roomCharge = data['roomCharge']?.toDouble() ?? 0;
                        double otherCharge =
                            data['otherCharge']?.toDouble() ?? 0;

                        double grandTotal = data['grandTotal']?.toDouble() ?? 0;

                        Timestamp? createdAt = data['timestamp'] as Timestamp?;
                        String formattedDate = createdAt != null
                            ? DateFormat('dd/MM/yyyy')
                                .format(createdAt.toDate())
                            : 'Không xác định';

                        final String? note = data['note'];

                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            leading: const Icon(Icons.receipt_long,
                                color: Colors.blue, size: 40),
                            title: Text('Ngày: $formattedDate',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🔌 Thông tin tiền điện
                                const Text('💡 Điện',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text('Số điện đầu: $startElectric'),
                                Text('Số điện cuối: $endElectric'),
                                Text(
                                    'Giá mỗi kW: ${_formatCurrency(pricePerKw)}'),
                                Text(
                                    'Tổng tiền điện: ${_formatCurrency(electricTotal)}'),

                                const SizedBox(height: 8),

                                // 🚰 Thông tin tiền nước
                                const Text('🚰 Nước',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text('Số nước đầu: $startWater'),
                                Text('Số nước cuối: $endWater'),
                                Text(
                                    'Giá mỗi m³: ${_formatCurrency(pricePerM3)}'),
                                Text(
                                    'Tổng tiền nước: ${_formatCurrency(waterTotal)}'),

                                const SizedBox(height: 8),

                                // 🏠 Tiền phòng
                                const Text('🏠 Tiền phòng',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                    'Tiền phòng: ${_formatCurrency(roomCharge)}'),

                                const SizedBox(height: 8),

                                // ➕ Khoản thu khác
                                const Text('📝 Khoản thu khác',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                    'Khoản khác: ${_formatCurrency(otherCharge)}'),

                                const SizedBox(height: 8),

                                // 🗒️ Ghi chú
                                if (note != null && note.isNotEmpty) ...[
                                  const Text('🗒️ Ghi chú',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(note),
                                  const SizedBox(height: 8),
                                ],

                                // 💰 Tổng hóa đơn
                                Text(
                                  'Tổng hóa đơn: ${_formatCurrency(grandTotal)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _deleteBill(context, phoneNumber, bill.id),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// ✅ Định dạng số tiền
  String _formatCurrency(double value) {
    final format = NumberFormat('#,##0', 'vi_VN');
    return '${format.format(value)} VND';
  }

  /// ✅ Xóa hóa đơn
  Future<void> _deleteBill(
      BuildContext context, String phoneNumber, String billId) async {
    bool confirmDelete = await _showConfirmDialog(context);
    if (confirmDelete) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .collection('bills')
          .doc(billId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa hóa đơn thành công!')),
      );
    }
  }

  /// ✅ Hộp thoại xác nhận xóa
  Future<bool> _showConfirmDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: const Text('Bạn có chắc muốn xóa hóa đơn này không?'),
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
