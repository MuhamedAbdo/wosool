import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/theme_provider.dart';
import '../utils/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box box;
  bool _isBoxInitialized = false;
  final _workerCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _tempDriverCtrl = TextEditingController();
  bool _useTempDriver = false;

  @override
  void initState() {
    super.initState();
    _initBox();
  }

  Future<void> _initBox() async {
    try {
      box = await Hive.openBox('settings');
      setState(() {
        _isBoxInitialized = true;
        // تحميل الإعدادات المحفوظة عند فتح الشاشة
        _priceCtrl.text = box.get('tripPrice', defaultValue: 65.0).toString();

        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        String savedDriver = themeProvider.mainDriver;
        _driverCtrl.text = savedDriver == "غير محدد" ? "" : savedDriver;

        _useTempDriver = themeProvider.useTempDriver;
        _tempDriverCtrl.text = themeProvider.tempDriver;
      });
    } catch (e) {
      print('Error opening settings box: $e');
      setState(() {
        _isBoxInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _workerCtrl.dispose();
    _priceCtrl.dispose();
    _driverCtrl.dispose();
    _tempDriverCtrl.dispose();
    super.dispose();
  }

  // دالة تعديل اسم العامل
  void _showEditDialog(int index, List<String> workers) {
    TextEditingController editCtrl =
        TextEditingController(text: workers[index]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("تعديل اسم العامل", textAlign: TextAlign.center),
        content: TextField(
          controller: editCtrl,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), hintText: "الاسم الجديد"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A80F0)),
            onPressed: () {
              if (editCtrl.text.isNotEmpty && editCtrl.text != workers[index]) {
                setState(() {
                  workers[index] = editCtrl.text;
                  if (_isBoxInitialized) {
                    box.put('workers', workers);
                  }
                });
                Navigator.pop(context);
              } else {
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomWosoolAppBar(
        title: "الإعدادات",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            // --- قسم تأمين البيانات (النسخ والاحتياطي) ---
            _buildSectionCard(
              title: "تأمين البيانات",
              icon: Icons.security,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("نسخة احتياطية محلياً"),
                    subtitle: const Text("حفظ ملف البيانات على ذاكرة الهاتف"),
                    leading: const Icon(Icons.backup, color: Colors.blue),
                    onTap: () async {
                      // استدعاء الخدمة المحدثة للنسخ
                      final res = await BackupService.createBackup();
                      if (res != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(res),
                          backgroundColor:
                              res.contains('✅') ? Colors.green : Colors.red,
                          duration: const Duration(seconds: 3),
                        ));
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("استعادة البيانات"),
                    subtitle: const Text("استرجاع البيانات من ملف سابق"),
                    leading: const Icon(Icons.restore, color: Colors.orange),
                    onTap: () async {
                      bool success = await BackupService.restoreBackup();
                      if (success) {
                        _showRestartDialog();
                      } else {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text(
                              "❌ لم يتم استعادة أي بيانات أو تم إلغاء العملية"),
                          backgroundColor: Colors.red,
                        ));
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // --- قسم المظهر ---
            _buildSectionCard(
              title: "المظهر",
              icon: Icons.palette,
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(themeProvider.isDarkMode
                          ? "الوضع الليلي"
                          : "الوضع النهاري"),
                      Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) => themeProvider.toggleTheme(),
                        activeThumbColor: const Color(0xFF4A80F0),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 15),

            // --- قسم إعدادات السائق ---
            _buildSectionCard(
              title: "إعدادات السائق",
              icon: Icons.drive_eta,
              child: Column(
                children: [
                  TextField(
                    controller: _driverCtrl,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: "اسم السائق الرئيسي",
                      hintText: "غير محدد",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon:
                          const Icon(Icons.drive_eta, color: Color(0xFF4A80F0)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("سائق مؤقت لليوم"),
                      Switch(
                        value: _useTempDriver,
                        onChanged: (value) =>
                            setState(() => _useTempDriver = value),
                        activeThumbColor: const Color(0xFF4A80F0),
                      ),
                    ],
                  ),
                  if (_useTempDriver)
                    TextField(
                      controller: _tempDriverCtrl,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        labelText: "اسم السائق المؤقت",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon:
                            const Icon(Icons.person_add, color: Colors.orange),
                        filled: true,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // --- قسم التكلفة ---
            _buildSectionCard(
              title: "إعدادات التكلفة",
              icon: Icons.attach_money,
              child: TextField(
                controller: _priceCtrl,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: "سعر الرحلة (جنيه)",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon:
                      const Icon(Icons.attach_money, color: Colors.green),
                  filled: true,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 15),

            // --- إدارة العمال ---
            _buildSectionCard(
              title: "إدارة العمال",
              icon: Icons.people,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _workerCtrl,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: "اضف عامل جديد",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            filled: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A80F0)),
                        onPressed: () async {
                          if (_workerCtrl.text.isNotEmpty) {
                            try {
                              if (_isBoxInitialized) {
                                List<String> workers = box.get('workers',
                                    defaultValue: <String>[]).cast<String>();
                                workers.add(_workerCtrl.text);
                                box.put('workers', workers);
                                _workerCtrl.clear();
                                setState(() {});
                              }
                            } catch (e) {
                              print('Error adding worker: $e');
                            }
                          }
                        },
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _isBoxInitialized
                          ? box
                              .get('workers', defaultValue: <String>[])
                              .cast<String>()
                              .length
                          : 0,
                      itemBuilder: (context, index) {
                        try {
                          if (!_isBoxInitialized) return const SizedBox();
                          List<String> workers = box.get('workers',
                              defaultValue: <String>[]).cast<String>();
                          return Card(
                            child: ListTile(
                              title: Text(workers[index]),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      icon: const Icon(Icons.edit_note,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          _showEditDialog(index, workers)),
                                  IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          workers.removeAt(index);
                                          if (_isBoxInitialized) {
                                            try {
                                              box.put('workers', workers);
                                            } catch (e) {
                                              print(
                                                  'Error removing worker: $e');
                                            }
                                          }
                                        });
                                      }),
                                ],
                              ),
                            ),
                          );
                        } catch (e) {
                          print('Error building worker list: $e');
                          return const SizedBox();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --- زر الحفظ النهائي ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A80F0),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _saveAndGoHome,
              child: const Text("حفظ الإعدادات",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _saveAndGoHome() {
    try {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

      String driverName = _driverCtrl.text.trim().isEmpty
          ? "غير محدد"
          : _driverCtrl.text.trim();

      themeProvider.updateMainDriver(driverName);
      themeProvider.updateTempDriver(_tempDriverCtrl.text);
      themeProvider.updateUseTempDriver(_useTempDriver);

      if (_isBoxInitialized) {
        box.put('tripPrice', double.tryParse(_priceCtrl.text) ?? 65.0);
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("تم الحفظ بنجاح"), backgroundColor: Colors.green));

      // العودة للرئيسية مع تنظيف الـ Stack لمنع ظهور شاشة بيضاء أو الرجوع للـ Splash
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      print('Error saving settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ حدث خطأ أثناء الحفظ"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("✅ نجحت الاستعادة",
            textAlign: TextAlign.center, style: TextStyle(color: Colors.green)),
        content: const Text(
            "تم تحديث البيانات بنجاح. يجب إغلاق التطبيق وفتحه يدوياً لتظهر البيانات الجديدة بشكل صحيح."),
        actions: [
          Center(
            child: TextButton(
                onPressed: () => exit(0),
                child: const Text("إغلاق التطبيق الآن",
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16))),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: const Color(0xFF4A80F0), size: 20),
            const SizedBox(width: 10),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}
