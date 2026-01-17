import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import 'package:universal_html/html.dart' as html;

import '../models/attendance.dart';
import '../widgets/custom_app_bar.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final attendanceBox = Hive.box<DailyRecord>('attendance');
  DateTime selectedMonth = DateTime.now();

  List<DailyRecord> _getFilteredRecords() {
    return attendanceBox.values.where((record) {
      return record.date.year == selectedMonth.year &&
          record.date.month == selectedMonth.month;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Widget build(BuildContext context) {
    final records = _getFilteredRecords();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomWosoolAppBar(
        title: "التقارير الشهرية",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.picture_as_pdf, color: Colors.white, size: 26),
            onPressed:
                records.isEmpty ? null : () => _generateAndSharePdf(records),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildMonthPicker(),
          Expanded(
            child: records.isEmpty
                ? const Center(child: Text("لا توجد سجلات لهذا الشهر"))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: records.length,
                    itemBuilder: (context, index) =>
                        _buildRecordCard(records[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(DailyRecord record) {
    double dailyTotal = 0;
    double effectiveCount = 0;
    record.workersStatus.forEach((name, value) {
      dailyTotal += (value * record.priceAtTime);
      effectiveCount += value;
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: ListTile(
        title: Text(
          intl.DateFormat('EEEE, d MMMM', 'ar').format(record.date),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
            "الحضور الفعلي: ${effectiveCount.toStringAsFixed(1)} عامل | المبلغ: ${dailyTotal.toStringAsFixed(1)} ج.م"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.blueAccent),
              onPressed: () {
                Navigator.pushNamed(context, '/edit', arguments: record)
                    .then((_) => setState(() {}));
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined,
                  color: Colors.redAccent),
              onPressed: () => _confirmDelete(record),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthPicker() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.blueAccent),
            onPressed: () => setState(() => selectedMonth =
                DateTime(selectedMonth.year, selectedMonth.month - 1)),
          ),
          Text(
            intl.DateFormat('MMMM yyyy', 'ar').format(selectedMonth),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.blueAccent),
            onPressed: () => setState(() => selectedMonth =
                DateTime(selectedMonth.year, selectedMonth.month + 1)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(DailyRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("حذف السجل", textAlign: TextAlign.right),
        content: const Text("هل أنت متأكد من حذف هذا السجل نهائياً؟",
            textAlign: TextAlign.right),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء")),
          TextButton(
            onPressed: () {
              record.delete();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndSharePdf(List<DailyRecord> records) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdf = pw.Document();
      // تحميل الخط العادي والخط العريض بشكل منفصل
      final fontData = await rootBundle.load("assets/fonts/Amiri-Regular.ttf");
      final boldFontData = await rootBundle.load("assets/fonts/Amiri-Bold.ttf");
      final ttfRegular = pw.Font.ttf(fontData);
      final ttfBold = pw.Font.ttf(boldFontData);

      double monthlyTotalMoney = 0;
      double monthlyTotalAttendance = 0;

      List<List<String>> tableData = records.map((r) {
        double att = 0;
        r.workersStatus.values.forEach((v) => att += v);
        double money = att * r.priceAtTime;
        monthlyTotalAttendance += att;
        monthlyTotalMoney += money;
        return [
          "${money.toStringAsFixed(1)} ج.م",
          r.driverName,
          att.toStringAsFixed(1),
          intl.DateFormat('yyyy/MM/dd').format(r.date),
        ];
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          // تعريف الثيم بوجود الخطين العادي والعريض
          theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Center(
                child: pw.Text(
                    "تقرير وصول - ${intl.DateFormat('MMMM yyyy', 'ar').format(selectedMonth)}",
                    style: pw.TextStyle(fontSize: 20, font: ttfBold))),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ["المبلغ", "السائق", "الحضور", "التاريخ"],
              data: tableData,
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blueAccent),
              headerStyle: pw.TextStyle(color: PdfColors.white, font: ttfBold),
              cellStyle: pw.TextStyle(font: ttfRegular),
              cellAlignment: pw.Alignment.center,
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // تحديد الخط بشكل صريح لكل نص لتجنب المربعات
                pw.Text(
                    "إجمالي الحضور: ${monthlyTotalAttendance.toStringAsFixed(1)}",
                    style: pw.TextStyle(font: ttfBold, fontSize: 14)),
                pw.Text(
                    "إجمالي المبلغ: ${monthlyTotalMoney.toStringAsFixed(1)} ج.م",
                    style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 14,
                        color: PdfColors.blueAccent)),
              ],
            ),
          ],
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      if (mounted) Navigator.pop(context);

      if (kIsWeb) {
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download",
              "report_${intl.DateFormat('yyyy_MM').format(selectedMonth)}.pdf")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getTemporaryDirectory();
        final File file = File("${directory.path}/report.pdf");
        await file.writeAsBytes(pdfBytes);
        await Share.shareXFiles([XFile(file.path)]);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
  }
}
