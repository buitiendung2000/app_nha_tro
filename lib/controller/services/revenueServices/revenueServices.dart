import 'package:cloud_firestore/cloud_firestore.dart';

/// Kết quả trả về từ RevenueService
class RevenueData {
  final double totalRevenue;
  final List<Map<String, dynamic>> bills;
  final Map<String, double> revenueByRoom;

  RevenueData({
    required this.totalRevenue,
    required this.bills,
    required this.revenueByRoom,
  });
}

/// Service chịu trách nhiệm tương tác với Firestore
class RevenueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lấy dữ liệu doanh thu cho [month]/[year]
  Future<RevenueData> fetchRevenue({
    required int month,
    required int year,
  }) async {
    // Xác định khoảng thời gian
    final startDate = DateTime(year, month, 1);
    final endDate =
        (month < 12) ? DateTime(year, month + 1, 1) : DateTime(year + 1, 1, 1);

    // Query hoá đơn đã thanh toán
    final snapshot = await _firestore
        .collectionGroup('bills')
        .where('isPaid', isEqualTo: true)
        .where('paidAt', isGreaterThanOrEqualTo: startDate)
        .where('paidAt', isLessThan: endDate)
        .get();

    double total = 0.0;
    final List<Map<String, dynamic>> billsList = [];
    final Map<String, double> roomRevenueMap = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      double amount = 0.0;
      if (data['grandTotal'] is int) {
        amount = (data['grandTotal'] as int).toDouble();
      } else if (data['grandTotal'] is double) {
        amount = data['grandTotal'] as double;
      }
      total += amount;
      billsList.add({
        'roomNo': data['roomNo']?.toString() ?? 'Chưa rõ',
        'grandTotal': amount,
      });

      final key = 'Phòng ${data['roomNo'] ?? '?'}';
      roomRevenueMap[key] = (roomRevenueMap[key] ?? 0.0) + amount;
    }

    return RevenueData(
      totalRevenue: total,
      bills: billsList,
      revenueByRoom: roomRevenueMap,
    );
  }
}
