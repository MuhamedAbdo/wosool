import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
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
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: CustomWosoolAppBar(
        title: "التقارير الشهرية",
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf,
              color: Colors.white,
              size: 26,
            ),
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
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return _buildRecordCard(record);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(DailyRecord record) {
    double dailyTotal = 0;
    for (var val in record.workersStatus.values) {
      dailyTotal += (val * record.priceAtTime);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          intl.DateFormat('EEEE, d MMMM', 'ar').format(record.date),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
        subtitle: Text(
          "عدد العمال: ${record.workersStatus.length}  |  المبلغ: ${dailyTotal.toStringAsFixed(1)} ج.م",
          style: const TextStyle(fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.blueAccent),
              onPressed: () => Navigator.pushNamed(
                context,
                '/edit',
                arguments: record,
              ).then((_) => setState(() {})),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: Colors.redAccent,
              ),
              onPressed: () => _confirmDelete(record),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(DailyRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("حذف السجل", textAlign: TextAlign.right),
        content: const Text(
          "هل أنت متأكد من حذف سجل هذا اليوم نهائياً؟",
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
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

  Widget _buildMonthPicker() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF4A80F0).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFF4A80F0)),
            onPressed: () => setState(
              () => selectedMonth = DateTime(
                selectedMonth.year,
                selectedMonth.month - 1,
              ),
            ),
          ),
          Text(
            intl.DateFormat('MMMM yyyy', 'ar').format(selectedMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A80F0),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Color(0xFF4A80F0)),
            onPressed: () => setState(
              () => selectedMonth = DateTime(
                selectedMonth.year,
                selectedMonth.month + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- وظيفة إنشاء ومشاركة ملف PDF تدعم الخط العادي والعريض مع عكس اتجاه الجدول ---
  Future<void> _generateAndSharePdf(List<DailyRecord> records) async {
    final pdf = pw.Document();

    // 1. تحميل الخط العربي العادي
    final fontData = await rootBundle.load("assets/fonts/Amiri-Regular.ttf");
    final ttfRegular = pw.Font.ttf(fontData);

    // 2. تحميل الخط العربي العريض (Bold)
    final boldFontData = await rootBundle.load("assets/fonts/Amiri-Bold.ttf");
    final ttfBold = pw.Font.ttf(boldFontData);

    double monthlyTotalMoney = 0;
    double monthlyTotalAttendance = 0;

    // تجهيز بيانات الجدول بترتيب عكسي (من اليمين لليسار)
    List<List<String>> tableData = [];
    for (int i = 0; i < records.length; i++) {
      var r = records[i];
      double dailyAttendance = 0;
      for (var v in r.workersStatus.values) {
        dailyAttendance += v;
      }
      double dailyMoney = dailyAttendance * r.priceAtTime;

      monthlyTotalAttendance += dailyAttendance;
      monthlyTotalMoney += dailyMoney;

      tableData.add([
        "${dailyMoney.toStringAsFixed(1)} ج.م", // مبلغ النقل (أصبح في اليسار برمجياً ليظهر يمين الورقة)
        r.workersStatus.length.toString(), // عدد العمال
        intl.DateFormat('yyyy/MM/dd').format(r.date), // التاريخ
        (i + 1).toString(), // التسلسل (م)
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: ttfRegular,
          bold: ttfBold,
        ),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Center(
            child: pw.Text(
              "تقرير حضور وانتقالات وصول",
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Center(
            child: pw.Text(
              "لشهر: ${intl.DateFormat('MMMM yyyy', 'ar').format(selectedMonth)}",
              style: const pw.TextStyle(fontSize: 16),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            // الرؤوس بترتيب معكوس لتظهر من اليمين (م هي أقصى اليمين)
            headers: ["مبلغ النقل اليومي", "عدد العمال", "التاريخ", "م"],
            data: tableData,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueAccent,
            ),
            cellAlignment: pw.Alignment.center,
            // تحديد عرض الأعمدة حسب الترتيب الجديد (0 هو العمود الأول من جهة اليمين في العرض)
            columnWidths: {
              3: const pw.FixedColumnWidth(30), // عمود "م"
              2: const pw.FlexColumnWidth(), // عمود "التاريخ"
              1: const pw.FlexColumnWidth(), // عمود "عدد العمال"
              0: const pw.FlexColumnWidth(), // عمود "المبلغ"
            },
          ),
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "إجمالي الحضور الشهري: ${monthlyTotalAttendance.toStringAsFixed(1)} يوم",
              ),
              pw.Text(
                "إجمالي المبلغ الشهري: ${monthlyTotalMoney.toStringAsFixed(1)} ج.م",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final Uint8List pdfBytes = await pdf.save();
    final directory = await getTemporaryDirectory();
    final String fileName =
        "Wosool_Report_${intl.DateFormat('yyyy_MM').format(selectedMonth)}.pdf";
    final File file = File("${directory.path}/$fileName");
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          'تقرير شهر ${intl.DateFormat('MMMM yyyy', 'ar').format(selectedMonth)}',
    );
  }
}
