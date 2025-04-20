import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Service để lấy thông tin hóa đơn từ Firestore
class BillService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Truy vấn danh sách hóa đơn của người dùng
  Stream<QuerySnapshot> getBillsByUser(String phoneNumber) {
    return _firestore
        .collection('users')
        .doc(phoneNumber)
        .collection('bills')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Truy vấn tất cả hóa đơn đã thanh toán
  Stream<QuerySnapshot> getPaidBills() {
    return _firestore
        .collectionGroup('bills')
        .where('isPaid', isEqualTo: true)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Định dạng số tiền theo tiền tệ Việt Nam
  String formatCurrency(double value) {
    final format = NumberFormat('#,##0', 'vi_VN');
    return '${format.format(value)} VND';
  }
}
