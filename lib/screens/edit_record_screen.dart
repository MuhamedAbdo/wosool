import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../widgets/custom_app_bar.dart'; // تأكد من استيراد الـ Widget المخصص

class EditRecordScreen extends StatefulWidget {
  const EditRecordScreen({super.key});

  @override
  State<EditRecordScreen> createState() => _EditRecordScreenState();
}

class _EditRecordScreenState extends State<EditRecordScreen> {
  late DailyRecord record;
  late Map<String, Map<String, bool>> editableStatus;
  bool isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      record = ModalRoute.of(context)!.settings.arguments as DailyRecord;

      // تحويل القيم الرقمية المخزنة إلى نظام الأزرار (ذهاب/عودة)
      editableStatus = {};
      record.workersStatus.forEach((name, value) {
        editableStatus[name] = {
          "am": value >= 0.5, // إذا كان 0.5 أو 1.0 يعتبر ذهاب
          "pm": value == 1.0, // إذا كان 1.0 يعتبر ذهاب وعودة
        };
      });
      isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      // --- استخدام الـ AppBar المخصص الجديد ---
      appBar: CustomWosoolAppBar(
        title: "تعديل الحضور",
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(left: 16, bottom: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A80F0),
                minimumSize: const Size(50, 50),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: _saveChanges,
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط عرض التاريخ بشكل منسق
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF4A80F0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFF4A80F0).withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.edit_calendar,
                      color: Color(0xFF4A80F0),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "سجل يوم: ${record.date.year}-${record.date.month}-${record.date.day}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.drive_eta,
                        color: Color(0xFF4A80F0),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "السائق: ${record.driverName}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: editableStatus.length,
              itemBuilder: (context, index) {
                String name = editableStatus.keys.elementAt(index);
                return _buildEditWorkerCard(name);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditWorkerCard(String name) {
    bool am = editableStatus[name]!["am"]!;
    bool pm = editableStatus[name]!["pm"]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2D3142),
              ),
            ),
          ),
          _tripButton(
            label: "ذهاب",
            icon: Icons.wb_sunny_outlined,
            isSelected: am,
            color: Colors.amber.shade700,
            onTap: () => setState(() => editableStatus[name]!["am"] = !am),
          ),
          const SizedBox(width: 10),
          _tripButton(
            label: "عودة",
            icon: Icons.nightlight_round_outlined,
            isSelected: pm,
            color: Colors.indigo.shade700,
            onTap: () => setState(() => editableStatus[name]!["pm"] = !pm),
          ),
        ],
      ),
    );
  }

  Widget _tripButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    // تحديث البيانات في الكائن الحالي
    record.workersStatus.clear();

    editableStatus.forEach((name, status) {
      double val = 0;
      if (status["am"] == true) val += 0.5;
      if (status["pm"] == true) val += 0.5;
      record.workersStatus[name] = val;
    });

    // حفظ التغييرات في Hive
    record.save();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تم تحديث السجل بنجاح", textAlign: TextAlign.center),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20),
      ),
    );
    Navigator.pop(context);
  }
}
