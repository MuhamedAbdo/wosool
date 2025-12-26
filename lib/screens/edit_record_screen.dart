import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart';

class EditRecordScreen extends StatefulWidget {
  const EditRecordScreen({super.key});

  @override
  State<EditRecordScreen> createState() => _EditRecordScreenState();
}

class _EditRecordScreenState extends State<EditRecordScreen> {
  late dynamic recordKey;
  late DailyRecord oldRecord;
  Map<String, double> updatedStatuses = {};
  bool isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      recordKey = args['key'];
      oldRecord = args['record'];
      updatedStatuses = Map<String, double>.from(oldRecord.workersStatus);
      isInitialized = true;
    }
  }

  // حساب الإجمالي بناءً على السعر وقت التسجيل
  double _calculateTotal() {
    double totalTrips = updatedStatuses.values.fold(0.0, (a, b) => a + b);
    return totalTrips * oldRecord.priceAtTime;
  }

  void _addTemporaryWorker() {
    TextEditingController tempNameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("إضافة عامل للسجل"),
        content: TextField(
          controller: tempNameCtrl,
          decoration: const InputDecoration(hintText: "اسم العامل"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () {
              if (tempNameCtrl.text.isNotEmpty) {
                setState(
                  () => updatedStatuses[tempNameCtrl.text] = 1.0,
                ); // القيمة الافتراضية 1
                Navigator.pop(context);
              }
            },
            child: const Text("إضافة"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "تعديل البيانات",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _addTemporaryWorker,
            icon: const Icon(Icons.person_add_alt_1, color: Colors.orange),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.event_note,
                  color: Colors.blueAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  "تعديل سجل: ${DateFormat('yyyy-MM-dd').format(oldRecord.date)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: updatedStatuses.length,
              itemBuilder: (context, index) {
                String name = updatedStatuses.keys.elementAt(index);
                double status = updatedStatuses[name]!;
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        children: [1.0, 0.5, 0.0]
                            .map(
                              (val) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: ChoiceChip(
                                  label: Text(val.toString()),
                                  selected: status == val,
                                  selectedColor: Colors.blueAccent,
                                  onSelected: (_) => setState(
                                    () => updatedStatuses[name] = val,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => updatedStatuses.remove(name)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // البانل السفلي كما في الصفحة الرئيسية
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    double total = _calculateTotal();
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "الإجمالي المعدل: ${total.toStringAsFixed(2)} جنيه",
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: () {
              final box = Hive.box<DailyRecord>('attendance');
              box.put(
                recordKey,
                DailyRecord(
                  date: oldRecord.date,
                  workersStatus: updatedStatuses,
                  priceAtTime: oldRecord.priceAtTime,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("تم التحديث وحفظ التعديلات")),
              );
              Navigator.pop(context);
            },
            child: const Text(
              "حفظ التعديلات",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
