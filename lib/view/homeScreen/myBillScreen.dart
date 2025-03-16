import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MyBillScreen extends StatelessWidget {
  final String phoneNumber;

  const MyBillScreen({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hóa đơn phòng trọ')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(phoneNumber)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy thông tin phòng.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final roomNumber = data['roomNo'] ?? 'Không xác định';

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(phoneNumber)
                .collection('bills')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, billSnapshot) {
              if (billSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!billSnapshot.hasData || billSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Chưa có hóa đơn nào.'));
              }

              final bills = billSnapshot.data!.docs;

              return ListView.builder(
                itemCount: bills.length,
                itemBuilder: (context, index) {
                  final bill = bills[index];
                  final data = bill.data() as Map<String, dynamic>;

                  double grandTotal = data['grandTotal']?.toDouble() ?? 0;
                  Timestamp? createdAt = data['timestamp'] as Timestamp?;
                  String formattedDate = createdAt != null
                      ? DateFormat('dd/MM/yyyy').format(createdAt.toDate())
                      : 'Không xác định';

                  final String? note = data['note'];
                  final bool isPaid = data['isPaid'] ?? false;

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ngày: $formattedDate',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _buildBillDetail('💡 Điện', [
                            'Số điện đầu: ${data['startElectric'] ?? 0}',
                            'Số điện cuối: ${data['endElectric'] ?? 0}',
                            'Giá mỗi kW: ${_formatCurrency(data['pricePerKw'] ?? 0)}',
                            'Tổng tiền điện: ${_formatCurrency(data['electricTotal'] ?? 0)}'
                          ]),
                          _buildBillDetail('🚰 Nước', [
                            'Số nước đầu: ${data['startWater'] ?? 0}',
                            'Số nước cuối: ${data['endWater'] ?? 0}',
                            'Giá mỗi m³: ${_formatCurrency(data['pricePerM3'] ?? 0)}',
                            'Tổng tiền nước: ${_formatCurrency(data['waterTotal'] ?? 0)}'
                          ]),
                          _buildBillDetail('🏠 Tiền phòng', [
                            'Tiền phòng: ${_formatCurrency(data['roomCharge'] ?? 0)}'
                          ]),
                          _buildBillDetail('📌 Khoản thu khác', [
                            'Khoản khác: ${_formatCurrency(data['otherCharge'] ?? 0)}'
                          ]),
                          if (note != null && note.isNotEmpty)
                            _buildBillDetail('🗒️ Ghi chú', [note]),
                          const SizedBox(height: 10),
                          Text(
                            'Tổng hóa đơn: ${_formatCurrency(grandTotal)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                        isPaid
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : data['isPending'] == true
                                  ? Row(
                                      children: const [
                                        Icon(Icons.hourglass_top,
                                            color: Colors.orange),
                                        SizedBox(width: 5),
                                        Text(
                                          'Đang chờ xử lý',
                                          style:
                                              TextStyle(color: Colors.orange),
                                        ),
                                      ],
                                    )
                                  : ElevatedButton(
                                      onPressed: () => _payBill(
                                        context,
                                        phoneNumber,
                                        bill.id,
                                        grandTotal,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      child: const Text('Thanh toán'),
                                    ),

                        ],
                      ),
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

  Widget _buildBillDetail(String title, List<String> details) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ...details.map((detail) => Text(detail)),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    final format = NumberFormat('#,##0', 'vi_VN');
    return '${format.format(value)} VND';
  }

    
 Future<void> _payBill(
    BuildContext context,
    String phoneNumber,
    String billId,
    double grandTotal,
  ) async {
    String? paymentMethod = await _showConfirmDialog(context, grandTotal);
    if (paymentMethod != null) {
      try {
        // ✅ Cập nhật Firestore: Thêm trạng thái isPending và paymentMethod
        await FirebaseFirestore.instance
            .collection('users')
            .doc(phoneNumber)
            .collection('bills')
            .doc(billId)
            .update({
          'isPending': true, // ✅ Đang chờ xử lý
          'paymentMethod': paymentMethod,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Thanh toán đang chờ xử lý bằng $paymentMethod!',
            ),
          ),
        );

        // ✅ Gửi thông báo đến chủ trọ
        await _sendNotification(
          title: 'Thanh toán phòng trọ',
          body:
              'Phòng trọ số $phoneNumber đã chọn thanh toán bằng $paymentMethod.',
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thanh toán: $e')),
        );
      }
    }
  }

  Future<void> _sendNotification({
    required String title,
    required String body,
  }) async {
    try {
      final tokenSnapshot = await FirebaseFirestore.instance
          .collection('admin') // ✅ Lấy token của chủ trọ
          .doc('fcmToken')
          .get();

      final String? token = tokenSnapshot.data()?['token'];

      if (token != null) {
        await FirebaseMessaging.instance.sendMessage(
          to: token,
          data: {
            'title': title,
            'body': body,
          },
        );
        debugPrint('🔔 Thông báo đã được gửi!');
      } else {
        debugPrint('⚠️ Không tìm thấy token.');
      }
    } catch (e) {
      debugPrint('❌ Lỗi gửi thông báo: $e');
    }
  }

  Future<String?> _showConfirmDialog(
    BuildContext context,
    double grandTotal,
  ) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Text(
          'Bạn có chắc chắn muốn thanh toán hóa đơn với tổng số tiền là ${_formatCurrency(grandTotal)} không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('Tiền mặt'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Tiền mặt'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('Chuyển khoản'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Chuyển khoản'),
          ),
        ],
      ),
    );
  }


}
