import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // الانتظار لمدة 3 ثوانٍ ثم الانتقال للشاشة الرئيسية
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // يمكنك تغيير اللون ليتناسب مع اللوجو
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // عرض الصورة (التي صممناها سابقاً)
            // ملاحظة: تأكد من إضافة الصورة في ملف pubspec.yaml
            Image.asset('assets/images/logo.png', width: 180, height: 180),
            const SizedBox(height: 30),
            // مؤشر تحميل بسيط
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
