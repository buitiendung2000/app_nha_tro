import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:intl/intl.dart';

class UsageInputScreen extends StatefulWidget {
  final String phoneNumber;
  const UsageInputScreen({super.key, required this.phoneNumber});

  @override
  State<UsageInputScreen> createState() => _UsageInputScreenState();
}

class _UsageInputScreenState extends State<UsageInputScreen> {
  final _startElectricController = TextEditingController();
  final _endElectricController = TextEditingController();
  final _pricePerKwController = TextEditingController();
  final _startWaterController = TextEditingController();
  final _endWaterController = TextEditingController();
  final _pricePerM3Controller = TextEditingController();
  final _roomChargeController = TextEditingController();
  final _otherChargeController = TextEditingController();
  final _noteController = TextEditingController();

  double _electricTotal = 0;
  double _waterTotal = 0;
  double _roomCharge = 0;
  double _otherCharge = 0;
  double _otherTotal = 0;
  double _grandTotal = 0;

  final _formatter = NumberFormat('#,###', 'vi_VN');

  String roomNo = '';

  @override
  void initState() {
    super.initState();
    _fetchRoomNo();
  }

  Future<void> _fetchRoomNo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.phoneNumber)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          roomNo = data?['roomNo']?.toString() ?? '';
        });
      }
    } catch (e) {
      print('Lỗi khi lấy số phòng: $e');
    }
  }

  double _parseValue(String input) {
    return double.tryParse(input) ?? 0;
  }

  double _evaluateExpression(String input) {
    try {
      Parser p = Parser();
      Expression exp = p.parse(input);
      ContextModel cm = ContextModel();
      return exp.evaluate(EvaluationType.REAL, cm);
    } catch (_) {
      return 0;
    }
  }

  void _calculateElectricConsumption() {
    final start = _parseValue(_startElectricController.text);
    final end = _parseValue(_endElectricController.text);
    final price = _parseValue(_pricePerKwController.text);

    setState(() {
      _electricTotal = (end > start) ? (end - start) * price : 0;
      _calculateGrandTotal();
    });
  }

  void _calculateWaterConsumption() {
    final start = _parseValue(_startWaterController.text);
    final end = _parseValue(_endWaterController.text);
    final price = _parseValue(_pricePerM3Controller.text);

    setState(() {
      _waterTotal = (end > start) ? (end - start) * price : 0;
      _calculateGrandTotal();
    });
  }

  void _calculateGrandTotal() {
    _roomCharge = _evaluateExpression(_roomChargeController.text);
    _otherCharge = _evaluateExpression(_otherChargeController.text);
    _otherTotal = _roomCharge + _otherCharge;

    setState(() {
      _grandTotal = _electricTotal + _waterTotal + _otherTotal;
    });
  }

  Future<void> _saveDataToFirebase() async {
    final phoneNumber = widget.phoneNumber.trim();

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy số điện thoại!')),
      );
      return;
    }

    if (_electricTotal <= 0 &&
        _waterTotal <= 0 &&
        _roomCharge <= 0 &&
        _otherCharge <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dữ liệu không hợp lệ!')),
      );
      return;
    }

    try {
      final billData = {
        'startElectric': _parseValue(_startElectricController.text),
        'endElectric': _parseValue(_endElectricController.text),
        'electricTotal': _electricTotal,
        'pricePerKw': _parseValue(_pricePerKwController.text),
        'startWater': _parseValue(_startWaterController.text),
        'endWater': _parseValue(_endWaterController.text),
        'waterTotal': _waterTotal,
        'pricePerM3': _parseValue(_pricePerM3Controller.text),
        'roomCharge': _roomCharge,
        'otherCharge': _otherCharge,
        'otherTotal': _otherTotal,
        'note': _noteController.text,
        'grandTotal': _grandTotal,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .collection('bills')
          .add(billData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lưu dữ liệu thành công!')),
      );

      _clearFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu dữ liệu: $e')),
      );
    }
  }

  void _clearFields() {
    _startElectricController.clear();
    _endElectricController.clear();
    _pricePerKwController.clear();
    _startWaterController.clear();
    _endWaterController.clear();
    _pricePerM3Controller.clear();
    _roomChargeController.clear();
    _otherChargeController.clear();
    _noteController.clear();

    setState(() {
      _electricTotal = 0;
      _waterTotal = 0;
      _roomCharge = 0;
      _otherCharge = 0;
      _otherTotal = 0;
      _grandTotal = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập thông tin sử dụng'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Phòng trọ số: $roomNo',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal),
                  ),
                ),
                const Divider(height: 30, thickness: 1),
                _buildSection('🔋 Điện', [
                  _buildInputField(_startElectricController, 'Số điện đầu',
                      _calculateElectricConsumption),
                  _buildInputField(_endElectricController, 'Số điện cuối',
                      _calculateElectricConsumption),
                  _buildInputField(_pricePerKwController, 'Giá mỗi kW',
                      _calculateElectricConsumption),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tổng tiền điện: ${_formatter.format(_electricTotal)} đ',
                      style: const TextStyle(
                          color: Colors.teal, fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
                _buildSection('🚰 Nước', [
                  _buildInputField(_startWaterController, 'Số nước đầu',
                      _calculateWaterConsumption),
                  _buildInputField(_endWaterController, 'Số nước cuối',
                      _calculateWaterConsumption),
                  _buildInputField(_pricePerM3Controller, 'Giá mỗi m³',
                      _calculateWaterConsumption),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tổng tiền nước: ${_formatter.format(_waterTotal)} đ',
                      style: const TextStyle(
                          color: Colors.teal, fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
                _buildSection('💰 Phí khác', [
                  _buildInputField(_roomChargeController, 'Tiền phòng',
                      _calculateGrandTotal),
                  _buildInputField(
                      _otherChargeController, 'Phí khác', _calculateGrandTotal),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tổng khoản phí khác: ${_formatter.format(_otherTotal)} đ',
                      style: const TextStyle(
                          color: Colors.teal, fontWeight: FontWeight.w600),
                    ),
                  ),
                  _buildInputField(
                      _noteController, 'Ghi chú', _calculateGrandTotal,
                      isNumber: false),
                ]),
                const SizedBox(height: 10),
                Text('Tổng tiền: ${_formatter.format(_grandTotal)} đ',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _saveDataToFirebase,
                    icon: const Icon(Icons.save),
                    label: const Text('Lưu dữ liệu',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInputField(
      TextEditingController controller, String label, VoidCallback onChanged,
      {bool isNumber = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.teal),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.teal),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.teal, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
