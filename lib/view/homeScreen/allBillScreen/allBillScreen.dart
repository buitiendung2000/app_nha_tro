      import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/controller/provider/billProvider/billProvider.dart';


class AllBillsScreen extends StatelessWidget {
  const AllBillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BillProvider>();
    final currencyFormatter = NumberFormat("#,##0", "vi_VN");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tất cả hóa đơn phòng trọ'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE1F5FE), Color(0xFFB3E5FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('users').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Chưa có hóa đơn nào.'));
            }

            // Lấy danh sách users từ Firestore
            final users = snapshot.data!.docs;

            // Sắp xếp danh sách theo roomNo từ nhỏ đến lớn
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
                  stream: prov.fetchBillsByUser(phoneNumber),
                  builder: (context, billSnapshot) {
                    if (billSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox(); // Đang tải
                    }
                    if (!billSnapshot.hasData ||
                        billSnapshot.data!.docs.isEmpty) {
                      return const SizedBox(); // Không hiển thị nếu không có hóa đơn
                    }

                    final bills = billSnapshot.data!.docs;
                    prov.calculateTotalRevenue(bills);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.home,
                              color: Colors.blue, size: 28),
                        ),
                        title: Text(
                          'Phòng trọ số: $roomNumber',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle:
                            Text('Tên: ${data['fullName'] ?? 'Không có tên'}'),
                        children: bills.map((bill) {
                          final billData = bill.data() as Map<String, dynamic>;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: billData['isPaid']
                                    ? [
                                        Colors.green.shade50,
                                        Colors.green.shade100
                                      ]
                                    : [Colors.red.shade50, Colors.red.shade100],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(2, 2),
                                )
                              ],
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.receipt_long,
                                  color: Colors.blue, size: 40),
                              title: Text(
                                  'Ngày: ${currencyFormatter.format(billData['timestamp'])}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Tổng hóa đơn: ${currencyFormatter.format(billData['grandTotal'])} VNĐ',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red)),
                                ],
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
      ),
    );
  }
}
