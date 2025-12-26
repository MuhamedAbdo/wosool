import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final settingsBox = Hive.box('settings');
  final attendanceBox = Hive.box<DailyRecord>('attendance');

  Map<String, double?> currentStatuses = {};
  List<String> temporaryWorkers = [];
  DateTime selectedDate = DateTime.now();

  void _resetUI() {
    setState(() {
      currentStatuses = {};
      temporaryWorkers = [];
      selectedDate = DateTime.now();
    });
  }

  void _addTemporaryWorker() {
    TextEditingController tempNameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("إضافة عامل مؤقت اليوم", textAlign: TextAlign.center),
        content: TextField(
          controller: tempNameCtrl,
          decoration: const InputDecoration(
            hintText: "اسم العامل",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              if (tempNameCtrl.text.isNotEmpty) {
                setState(() {
                  temporaryWorkers.add(tempNameCtrl.text);
                  currentStatuses[tempNameCtrl.text] = 1.0;
                });
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
    List<String> permanentWorkers = settingsBox
        .get('workers', defaultValue: <String>[])
        .cast<String>();
    List<String> allWorkers = [...permanentWorkers, ...temporaryWorkers];
    double price = settingsBox.get('tripPrice', defaultValue: 65.0);

    double totalToday =
        currentStatuses.values
            .where((v) => v != null)
            .fold(0.0, (a, b) => a + (b ?? 0.0)) *
        price;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "تسجيل الحضور اليومي",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.blueAccent),
            onPressed: () => Navigator.pushNamed(context, '/reports'),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.blueAccent),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.blueAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat(
                        'EEEE, d MMMM yyyy',
                        'ar',
                      ).format(selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: allWorkers.length,
              itemBuilder: (context, index) {
                String name = allWorkers[index];
                bool isTemporary = temporaryWorkers.contains(name);
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
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (isTemporary)
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    "مؤقت",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (isTemporary)
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              onPressed: () => setState(() {
                                temporaryWorkers.remove(name);
                                currentStatuses.remove(name);
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [1.0, 0.5, 0.0].map((val) {
                          bool isSelected = currentStatuses[name] == val;
                          return ChoiceChip(
                            label: Text(
                              val == 1.0
                                  ? "يوم"
                                  : val == 0.5
                                  ? "نصف"
                                  : "غائب",
                            ),
                            selected: isSelected,
                            selectedColor: Colors.blueAccent,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                            onSelected: (_) =>
                                setState(() => currentStatuses[name] = val),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildBottomPanel(totalToday, price, allWorkers.length),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTemporaryWorker,
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
    );
  }

  Widget _buildBottomPanel(double total, double price, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "إجمالي اليوم:",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                "${total.toStringAsFixed(2)} جنيه",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: () {
              if (currentStatuses.length < count) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("برجاء تحديد حالة جميع العمال أولاً"),
                  ),
                );
                return;
              }

              // --- الحل الأول: منع التكرار ---
              final isDuplicate = attendanceBox.values.any(
                (record) =>
                    record.date.year == selectedDate.year &&
                    record.date.month == selectedDate.month &&
                    record.date.day == selectedDate.day,
              );

              if (isDuplicate) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("تنبيه", textAlign: TextAlign.center),
                    content: const Text(
                      "تم تسجيل حضور لهذا اليوم مسبقاً! يمكنك مراجعته من صفحة التقارير.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("حسناً"),
                      ),
                    ],
                  ),
                );
                return;
              }
              // ----------------------------

              attendanceBox.add(
                DailyRecord(
                  date: selectedDate,
                  workersStatus: currentStatuses.map((k, v) => MapEntry(k, v!)),
                  priceAtTime: price,
                ),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("تم حفظ السجل بنجاح")),
              );
              _resetUI();
            },
            child: const Text(
              "حفظ السجل النهائي",
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
