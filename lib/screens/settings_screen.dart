import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final box = Hive.box('settings');
  final _workerCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _priceCtrl.text = box.get('tripPrice', defaultValue: 65.0).toString();
  }

  // دالة لإظهار حوار تعديل الاسم
  void _showEditDialog(int index, List<String> workers) {
    TextEditingController editCtrl = TextEditingController(
      text: workers[index],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("تعديل اسم العامل", textAlign: TextAlign.center),
        content: TextField(
          controller: editCtrl,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "الاسم الجديد",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A80F0),
            ),
            onPressed: () {
              if (editCtrl.text.isNotEmpty) {
                setState(() {
                  workers[index] = editCtrl.text;
                  box.put('workers', workers);
                });
                Navigator.pop(context);
              }
            },
            child: const Text("تحديث", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> workers = box
        .get('workers', defaultValue: <String>[])
        .cast<String>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: CustomWosoolAppBar(
        title: "الإعدادات",
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),

            // قسم إعداد سعر الرحلة
            const Text(
              " إعدادات التكلفة",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF4A80F0),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                controller: _priceCtrl,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: "سعر الرحلة (جنيه)",
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    box.put('tripPrice', double.tryParse(v) ?? 65.0),
              ),
            ),

            const SizedBox(height: 30),

            // قسم إضافة عامل جديد
            const Text(
              " إضافة عامل أساسي",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF4A80F0),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Color(0xFF4A80F0),
                      size: 30,
                    ),
                    onPressed: () {
                      if (_workerCtrl.text.isNotEmpty) {
                        workers.add(_workerCtrl.text);
                        box.put('workers', workers);
                        _workerCtrl.clear();
                        setState(() {});
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _workerCtrl,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        hintText: "اكتب اسم العامل هنا",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // قائمة العمال مع خيارات التعديل والحذف
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: workers.length,
                itemBuilder: (c, i) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      workers[i],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    leading: const Icon(
                      Icons.person_outline,
                      color: Colors.grey,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // أيقونة التعديل الجديدة
                        IconButton(
                          icon: const Icon(
                            Icons.edit_note,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () => _showEditDialog(i, workers),
                        ),
                        // أيقونة الحذف
                        IconButton(
                          icon: const Icon(
                            Icons.delete_sweep_outlined,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            setState(() {
                              workers.removeAt(i);
                              box.put('workers', workers);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
