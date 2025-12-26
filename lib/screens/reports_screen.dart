import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/attendance.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? selectedMonth;

  // --- وظيفة إنشاء ومشاركة ملف PDF ---
  Future<void> _generatePdf(Box<DailyRecord> box, DateTime month) async {
    // التأكد من تهيئة القنوات البرمجية لمنع MissingPluginException
    WidgetsFlutterBinding.ensureInitialized();

    try {
      final pdf = pw.Document();

      // تجهيز البيانات وترتيبها حسب التاريخ
      final monthKeys = box.keys.where((k) {
        final r = box.get(k);
        return r?.date.year == month.year && r?.date.month == month.month;
      }).toList();
      monthKeys.sort((a, b) => box.get(a)!.date.compareTo(box.get(b)!.date));

      // تحميل الخطوط لدعم اللغة العربية (Almarai هو الأنسب للتقارير)
      final font = await PdfGoogleFonts.almaraiRegular();
      final fontBold = await PdfGoogleFonts.almaraiBold();

      pdf.addPage(
        pw.MultiPage(
          textDirection: pw.TextDirection.rtl, // اتجاه النص العام
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          build: (pw.Context context) {
            return [
              // الهيدر (العنوان ولوجو بسيط)
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "تقرير شهر: ${DateFormat('MMMM yyyy', 'ar').format(month)}",
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "تطبيق وُصول",
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // الجدول بتنسيق اليمين لليسار
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellAlignment: pw.Alignment.center,

                // خاصية تحويل اتجاه الجدول بالكامل (RTL)
                tableDirection: pw.TextDirection.rtl,

                // العناوين مرتبة من اليمين
                headers: ['ملاحظات', 'المبلغ', 'عدد الحضور', 'التاريخ', 'م'],

                data: List.generate(monthKeys.length, (index) {
                  final record = box.get(monthKeys[index])!;
                  double totalAtt = record.workersStatus.values.fold(
                    0.0,
                    (a, b) => a + b,
                  );
                  int halfTrips = record.workersStatus.values
                      .where((v) => v == 0.5)
                      .length;
                  double amount = totalAtt * record.priceAtTime;

                  // البيانات مرتبة لتطابق العناوين من اليمين
                  return [
                    halfTrips > 0 ? "يوجد $halfTrips ركاب (0.5)" : "-",
                    "${amount.toStringAsFixed(1)} ج",
                    totalAtt.toString(),
                    DateFormat('yyyy/MM/dd').format(record.date),
                    (index + 1).toString(),
                  ];
                }),
              ),

              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 20),
                child: pw.Divider(),
              ),

              // الإجمالي النهائي
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  "الإجمالي النهائي للشهر: ${monthKeys.fold(0.0, (double sum, key) => sum + (box.get(key)!.workersStatus.values.fold(0.0, (a, b) => a + b) * box.get(key)!.priceAtTime)).toStringAsFixed(2)} جنيه مصري",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ];
          },
        ),
      );

      // أمر الطباعة والمشاركة (يعرض نافذة المعاينة والطباعة)
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Report_${DateFormat('MM_yyyy').format(month)}',
      );
    } catch (e) {
      debugPrint("خطأ في ملف PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("فشل في إنشاء الملف: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<DailyRecord>('attendance');
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          selectedMonth == null ? "التقارير الشهرية" : "تفاصيل الشهر",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: selectedMonth != null
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.blueAccent,
                ),
                onPressed: () => setState(() => selectedMonth = null),
              )
            : null,
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<DailyRecord> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text("لا توجد سجلات حالياً"));
          }
          return selectedMonth == null
              ? _buildMonthsList(box)
              : _buildMonthDetails(box, selectedMonth!);
        },
      ),
    );
  }

  Widget _buildMonthDetails(Box<DailyRecord> box, DateTime month) {
    final monthKeys = box.keys.where((k) {
      final r = box.get(k);
      return r?.date.year == month.year && r?.date.month == month.month;
    }).toList();

    double totalAmt = 0;
    double totalTrips = 0;

    for (var k in monthKeys) {
      final r = box.get(k)!;
      double trips = r.workersStatus.values.fold(0.0, (a, b) => a + b);
      totalTrips += trips;
      totalAmt += (trips * r.priceAtTime);
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "إحصائيات الشهر",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_sweep,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _confirmDeleteMonth(box, month),
                  ),
                ],
              ),
              const Divider(height: 30),
              _rowInfo("إجمالي النقلات", totalTrips.toString()),
              _rowInfo(
                "سعر الرحلة",
                "${box.get(monthKeys.first)?.priceAtTime ?? 0}",
              ),
              const Divider(height: 30),
              Text(
                "${totalAmt.toStringAsFixed(2)} ج",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: monthKeys.length,
            itemBuilder: (context, i) {
              final key = monthKeys[i];
              final record = box.get(key)!;
              double dayTotal =
                  record.workersStatus.values.fold(0.0, (a, b) => a + b) *
                  record.priceAtTime;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  title: Text(
                    DateFormat('EEEE, d MMM', 'ar').format(record.date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("المبلغ: ${dayTotal.toStringAsFixed(1)} ج"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.blue,
                          size: 22,
                        ),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/edit',
                          arguments: {'key': key, 'record': record},
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                        onPressed: () => box.delete(key),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () => _generatePdf(box, month),
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text(
              "مشاركة تقرير PDF",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _rowInfo(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    ),
  );

  void _confirmDeleteMonth(Box<DailyRecord> box, DateTime month) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("حذف السجلات"),
        content: const Text(
          "سيتم حذف كافة سجلات هذا الشهر نهائياً. هل أنت متأكد؟",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () {
              final keys = box.keys.where((k) {
                final r = box.get(k);
                return r?.date.year == month.year &&
                    r?.date.month == month.month;
              }).toList();
              for (var k in keys) {
                box.delete(k);
              }
              Navigator.pop(c);
              setState(() => selectedMonth = null);
            },
            child: const Text("حذف الكل", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthsList(Box<DailyRecord> box) {
    final months = box.values
        .map((e) => DateTime(e.date.year, e.date.month))
        .toSet()
        .toList();
    months.sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: months.length,
      itemBuilder: (c, i) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ListTile(
          leading: const Icon(Icons.calendar_month, color: Colors.blueAccent),
          title: Text(
            DateFormat('MMMM yyyy', 'ar').format(months[i]),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => setState(() => selectedMonth = months[i]),
        ),
      ),
    );
  }
}
