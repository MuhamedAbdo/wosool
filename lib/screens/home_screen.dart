import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/attendance.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/page_transitions.dart';
import '../providers/theme_provider.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box settingsBox;
  late Box<DailyRecord> attendanceBox;
  bool _isBoxesInitialized = false;

  Map<String, Map<String, bool>> currentAttendance = {};
  List<String> temporaryWorkers = [];
  DateTime selectedDate = DateTime.now();
  String temporaryDriver = "";
  bool isDateLocked = false;

  @override
  void initState() {
    super.initState();
    _initBoxes();
  }

  Future<void> _initBoxes() async {
    try {
      settingsBox = await Hive.openBox('settings');
      attendanceBox = await Hive.openBox<DailyRecord>('attendance');
      setState(() {
        _isBoxesInitialized = true;
      });
      _checkDateLock();
    } catch (e) {
      print('Error opening boxes: $e');
      setState(() {
        _isBoxesInitialized = false;
      });
    }
  }

  // فحص هل التاريخ له سجل محفوظ أم لا
  void _checkDateLock() {
    DailyRecord? existingRecord;
    try {
      // البحث عن السجل المطابق للتاريخ المختار بشكل طازج من الصندوق
      existingRecord = attendanceBox.values.firstWhere(
        (r) =>
            r.date.year == selectedDate.year &&
            r.date.month == selectedDate.month &&
            r.date.day == selectedDate.day,
      );
    } catch (e) {
      existingRecord = null;
    }

    if (existingRecord != null) {
      setState(() {
        isDateLocked = true;
        temporaryDriver = existingRecord!.driverName;

        currentAttendance.clear();
        temporaryWorkers.clear();

        List<String> permanentWorkers =
            settingsBox.get('workers', defaultValue: <String>[]).cast<String>();

        existingRecord.workersStatus.forEach((name, value) {
          currentAttendance[name] = {
            "am": value >= 0.5,
            "pm": value == 1.0,
          };
          if (!permanentWorkers.contains(name)) {
            temporaryWorkers.add(name);
          }
        });
      });
    } else {
      setState(() {
        isDateLocked = false;
        currentAttendance.clear();
        temporaryWorkers.clear();
        temporaryDriver = "";
      });
    }
  }

  void _addTemporaryWorker() {
    if (isDateLocked) return;
    TextEditingController tempNameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("إضافة عامل مؤقت اليوم", textAlign: TextAlign.center),
        content: TextField(
          controller: tempNameCtrl,
          textAlign: TextAlign.right,
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
                  String name = tempNameCtrl.text;
                  temporaryWorkers.add(name);
                  currentAttendance[name] = {"am": true, "pm": false};
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

  void _addTemporaryDriver() {
    if (isDateLocked) return;
    TextEditingController driverCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("إضافة سائق مؤقت اليوم", textAlign: TextAlign.center),
        content: TextField(
          controller: driverCtrl,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            hintText: "اسم السائق",
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
              if (driverCtrl.text.isNotEmpty) {
                setState(() {
                  temporaryDriver = driverCtrl.text;
                });
                Navigator.pop(context);
              }
            },
            child: const Text("تحديد"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBoxesInitialized) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomWosoolAppBar(
          title: "وُصول",
          leading: IconButton(
            icon: const Icon(Icons.analytics_outlined,
                color: Colors.white, size: 28),
            onPressed: () async {
              await Navigator.push(
                context,
                PageTransitions.slideTransition(const ReportsScreen(),
                    const RouteSettings(name: '/reports')),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined,
                  color: Colors.white, size: 28),
              onPressed: () async {
                await Navigator.push(
                  context,
                  PageTransitions.slideTransition(const SettingsScreen(),
                      const RouteSettings(name: '/settings')),
                );
              },
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    String currentDriver =
        temporaryDriver.isNotEmpty ? temporaryDriver : themeProvider.mainDriver;

    List<String> permanentWorkers =
        settingsBox.get('workers', defaultValue: <String>[]).cast<String>();

    List<String> allWorkers = isDateLocked
        ? currentAttendance.keys.toList()
        : [...permanentWorkers, ...temporaryWorkers];

    double price = settingsBox.get('tripPrice', defaultValue: 65.0);

    double effectiveWorkerCount = 0;
    currentAttendance.forEach((name, status) {
      if (status["am"] == true) effectiveWorkerCount += 0.5;
      if (status["pm"] == true) effectiveWorkerCount += 0.5;
    });
    double totalMoney = effectiveWorkerCount * price;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomWosoolAppBar(
        title: "وُصول",
        titleWidget: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "السائق: $currentDriver",
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.analytics_outlined,
              color: Colors.white, size: 28),
          onPressed: () async {
            // انتظار العودة من صفحة التقارير
            await Navigator.push(
              context,
              PageTransitions.slideTransition(
                  const ReportsScreen(), const RouteSettings(name: '/reports')),
            );
            // تحديث البيانات فور العودة
            _checkDateLock();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: Colors.white, size: 28),
            onPressed: () async {
              // انتظار العودة من صفحة الإعدادات
              await Navigator.push(
                context,
                PageTransitions.slideTransition(const SettingsScreen(),
                    const RouteSettings(name: '/settings')),
              );
              // تحديث البيانات فور العودة (في حال تم تغيير السائق أو السعر أو العمال)
              _checkDateLock();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildDriverSection(currentDriver),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: allWorkers.length,
              itemBuilder: (context, index) {
                String name = allWorkers[index];
                bool isTemp = temporaryWorkers.contains(name);
                currentAttendance.putIfAbsent(
                    name, () => {"am": false, "pm": false});
                return _buildWorkerCard(name, isTemp);
              },
            ),
          ),
          _buildBottomPanel(totalMoney, effectiveWorkerCount),
        ],
      ),
      floatingActionButton: isDateLocked
          ? null
          : FloatingActionButton(
              onPressed: _addTemporaryWorker,
              backgroundColor: Colors.orangeAccent,
              child: const Icon(Icons.person_add_alt_1, color: Colors.white),
            ),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime(2024),
            lastDate: DateTime(2030),
          );
          if (picked != null) {
            setState(() {
              selectedDate = picked;
              _checkDateLock();
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today,
                  color: Color(0xFF4A80F0), size: 18),
              const SizedBox(width: 10),
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'ar').format(selectedDate),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (isDateLocked) ...[
                const SizedBox(width: 10),
                const Icon(Icons.lock, color: Colors.orange, size: 18),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverSection(String currentDriver) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.drive_eta, color: Color(0xFF4A80F0), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "السائق اليوم: $currentDriver",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            if (!isDateLocked)
              IconButton(
                icon: Icon(
                  temporaryDriver.isEmpty ? Icons.person_add : Icons.clear,
                  color: temporaryDriver.isEmpty
                      ? const Color(0xFF4A80F0)
                      : Colors.red,
                  size: 20,
                ),
                onPressed: temporaryDriver.isEmpty
                    ? _addTemporaryDriver
                    : () => setState(() => temporaryDriver = ""),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCard(String name, bool isTemp) {
    bool am = currentAttendance[name]?["am"] ?? false;
    bool pm = currentAttendance[name]?["pm"] ?? false;

    return Opacity(
      opacity: isDateLocked ? 0.8 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  if (isTemp)
                    const Text("عامل مؤقت",
                        style: TextStyle(color: Colors.orange, fontSize: 11)),
                ],
              ),
            ),
            _tripButton(
                "ذهاب", Icons.wb_sunny_outlined, am, Colors.amber.shade700, () {
              setState(() => currentAttendance[name]!["am"] = !am);
            }),
            const SizedBox(width: 10),
            _tripButton("عودة", Icons.nightlight_round_outlined, pm,
                Colors.indigo.shade700, () {
              setState(() => currentAttendance[name]!["pm"] = !pm);
            }),
          ],
        ),
      ),
    );
  }

  Widget _tripButton(String label, IconData icon, bool isSelected, Color color,
      VoidCallback onTap) {
    return InkWell(
      onTap: isDateLocked ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(double totalMoney, double effectiveCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 15)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("العدد الفعلي: $effectiveCount عامل",
                  style: const TextStyle(fontSize: 15, color: Colors.grey)),
              Text(
                "${totalMoney.toStringAsFixed(1)} جنيه",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A80F0)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (isDateLocked)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(18)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  const Text("السجل محفوظ ومقفل",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A80F0),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: _saveDailyRecord,
              child: const Text("حفظ السجل النهائي",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  void _saveDailyRecord() {
    Map<String, double> finalData = {};
    currentAttendance.forEach((name, status) {
      double val = 0;
      if (status["am"] == true) val += 0.5;
      if (status["pm"] == true) val += 0.5;
      finalData[name] = val;
    });

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    String driverForToday =
        temporaryDriver.isNotEmpty ? temporaryDriver : themeProvider.mainDriver;

    attendanceBox.add(DailyRecord(
      date: selectedDate,
      workersStatus: finalData,
      priceAtTime: settingsBox.get('tripPrice', defaultValue: 65.0),
      driverName: driverForToday,
    ));

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("تم الحفظ بنجاح"), backgroundColor: Colors.green));
    _checkDateLock();
  }
}
