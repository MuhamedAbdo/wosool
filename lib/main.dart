import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // مطلوب للـ Timer في شاشة الـ Splash

// استيراد الموديلات والشاشات
import 'models/attendance.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/edit_record_screen.dart';
import 'providers/theme_provider.dart';

void main() async {
  // التأكد من تهيئة كل إضافات النظام قبل تشغيل التطبيق
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة اللغة العربية للتواريخ
  await initializeDateFormatting('ar', null);

  // تهيئة قاعدة بيانات Hive
  await Hive.initFlutter();

  // تسجيل الـ Adapter الخاص بموديل الحضور
  if (!Hive.isAdapterRegistered(DailyRecordAdapter().typeId)) {
    Hive.registerAdapter(DailyRecordAdapter());
  }

  // فتح الصناديق (Boxes) المطلوبة
  await Hive.openBox('settings');
  await Hive.openBox<DailyRecord>('attendance');

  runApp(const WosoolApp());
}

class WosoolApp extends StatelessWidget {
  const WosoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'وُصول',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            // نقطة الانطلاق هي شاشة الـ Splash
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/home': (context) => const HomeScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/reports': (context) => const ReportsScreen(),
              '/edit': (context) => const EditRecordScreen(),
            },
          );
        },
      ),
    );
  }
}

// --- شاشة الـ Splash Screen في نفس الملف أو يمكنك نقلها لملف منفصل ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // مؤقت لمدة 3 ثوانٍ ثم الانتقال للشاشة الرئيسية
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // تأكد من وجود الصورة في مسار assets/images/logo.png
            // وتعريفها في ملف pubspec.yaml
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                // في حال عدم وجود الصورة يظهر أيقونة افتراضية بدلاً من توقف التطبيق
                return const Icon(
                  Icons.directions_bus,
                  size: 100,
                  color: Colors.blueAccent,
                );
              },
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            const Text(
              "جاري التحميل ....",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
