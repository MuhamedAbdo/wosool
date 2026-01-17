import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final box = Hive.box('settings');
  final _workerCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _tempDriverCtrl = TextEditingController();
  bool _useTempDriver = false;

  @override
  void initState() {
    super.initState();
    _priceCtrl.text = box.get('tripPrice', defaultValue: 65.0).toString();
    _driverCtrl.text =
        Provider.of<ThemeProvider>(context, listen: false).mainDriver;
    _useTempDriver =
        Provider.of<ThemeProvider>(context, listen: false).useTempDriver;
    _tempDriverCtrl.text =
        Provider.of<ThemeProvider>(context, listen: false).tempDriver;
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
              if (editCtrl.text.isNotEmpty && editCtrl.text != workers[index]) {
                setState(() {
                  // تحديث العنصر في نفس الموقع بدلاً من إضافة جديد
                  workers[index] = editCtrl.text;
                  box.put('workers', workers);
                });
                Navigator.pop(context);
              } else if (editCtrl.text == workers[index]) {
                Navigator.pop(context); // لم يتم تغيير الاسم
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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // قسم المظهر
            _buildSectionCard(
              title: "المظهر",
              icon: Icons.palette,
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            themeProvider.isDarkMode
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF4A80F0),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            themeProvider.isDarkMode
                                ? "الوضع الليلي"
                                : "الوضع النهاري",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
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

            const SizedBox(height: 20),

            // قسم السائق
            _buildSectionCard(
              title: "إعدادات السائق",
              icon: Icons.drive_eta,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // السائق الرئيسي
                  TextField(
                    controller: _driverCtrl,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      labelText: "اسم السائق الرئيسي",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.drive_eta,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF4A80F0)),
                      filled: true,
                      fillColor:
                          Theme.of(context).inputDecorationTheme.fillColor,
                    ),
                    onChanged: (v) =>
                        box.put('mainDriver', v.isEmpty ? "غير محدد" : v),
                  ),
                  const SizedBox(height: 15),

                  // خيار السائق المؤقت
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "سائق مؤقت لليوم الحالي",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Switch(
                        value: _useTempDriver,
                        onChanged: (value) {
                          setState(() {
                            _useTempDriver = value;
                            box.put('useTempDriver', value);
                          });
                        },
                        activeThumbColor: const Color(0xFF4A80F0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // حقل إدخال السائق المؤقت
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _useTempDriver
                        ? TextField(
                            controller: _tempDriverCtrl,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            decoration: InputDecoration(
                              labelText: "اسم السائق المؤقت",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: Icon(Icons.person_add,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.orange.shade300
                                      : Colors.orange),
                              filled: true,
                              fillColor: Theme.of(context)
                                  .inputDecorationTheme
                                  .fillColor,
                            ),
                            onChanged: (v) => box.put('tempDriver', v),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // قسم التكلفة
            _buildSectionCard(
              title: "إعدادات التكلفة",
              icon: Icons.attach_money,
              child: TextField(
                controller: _priceCtrl,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  labelText: "سعر الرحلة (جنيه)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.attach_money,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.green.shade300
                          : Colors.green),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    box.put('tripPrice', double.tryParse(v) ?? 65.0),
              ),
            ),

            const SizedBox(height: 20),

            // قسم العمال
            _buildSectionCard(
              title: "إدارة العمال",
              icon: Icons.people,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // إضافة عامل جديد
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _workerCtrl,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          decoration: InputDecoration(
                            hintText: "اكتب اسم العامل هنا",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Theme.of(context)
                                .inputDecorationTheme
                                .fillColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A80F0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                        ),
                        onPressed: () {
                          if (_workerCtrl.text.isNotEmpty) {
                            List<String> workers = box.get('workers',
                                defaultValue: <String>[]).cast<String>();
                            workers.add(_workerCtrl.text);
                            box.put('workers', workers);
                            _workerCtrl.clear();
                            setState(() {});
                          }
                        },
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // قائمة العمال
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: box
                          .get('workers', defaultValue: <String>[])
                          .cast<String>()
                          .length,
                      itemBuilder: (context, index) {
                        List<String> workers = box.get('workers',
                            defaultValue: <String>[]).cast<String>();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              workers[index],
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                            leading: Icon(
                              Icons.person_outline,
                              color: Theme.of(context)
                                  .iconTheme
                                  .color
                                  ?.withOpacity(0.7),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_note,
                                      color: Colors.blueAccent),
                                  onPressed: () =>
                                      _showEditDialog(index, workers),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_sweep_outlined,
                                      color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() {
                                      workers.removeAt(index);
                                      box.put('workers', workers);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // زر حفظ الإعدادات
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 30),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A80F0),
                  minimumSize: const Size(double.infinity, 55),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _saveSettings,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "حفظ الإعدادات",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveSettings() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    // حفظ جميع الإعدادات في الـ Storage
    themeProvider.updateMainDriver(_driverCtrl.text);
    themeProvider.updateTempDriver(_tempDriverCtrl.text);
    themeProvider.updateUseTempDriver(_useTempDriver);
    box.put('tripPrice', double.tryParse(_priceCtrl.text) ?? 65.0);

    // إظهار رسالة نجاح
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "تم حفظ الإعدادات بنجاح",
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Helper method to build section cards
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).iconTheme.color,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF4A80F0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            child,
          ],
        ),
      ),
    );
  }
}
