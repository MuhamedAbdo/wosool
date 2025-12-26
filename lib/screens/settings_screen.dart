import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

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

  @override
  Widget build(BuildContext context) {
    List<String> workers = box
        .get('workers', defaultValue: <String>[])
        .cast<String>();
    return Scaffold(
      appBar: AppBar(title: const Text("الإعدادات")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: "سعر الرحلة (جنيه)"),
              keyboardType: TextInputType.number,
              onChanged: (v) =>
                  box.put('tripPrice', double.tryParse(v) ?? 65.0),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _workerCtrl,
                    decoration: const InputDecoration(
                      labelText: "إضافة اسم عامل",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_workerCtrl.text.isNotEmpty) {
                      workers.add(_workerCtrl.text);
                      box.put('workers', workers);
                      _workerCtrl.clear();
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: workers.length,
                itemBuilder: (c, i) => ListTile(
                  title: Text(workers[i]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      workers.removeAt(i);
                      box.put('workers', workers);
                      setState(() {});
                    },
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
