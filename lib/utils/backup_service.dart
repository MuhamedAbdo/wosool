import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/attendance.dart'; // تأكد من صحة المسار

class BackupService {
  static Future<String?> createBackup() async {
    try {
      // First, let's check if there's actual data to backup
      final settingsBox = await Hive.openBox('settings');
      final attendanceBox = await Hive.openBox<DailyRecord>('attendance');

      print('Settings box has ${settingsBox.length} items');
      print('Attendance box has ${attendanceBox.length} items');

      if (settingsBox.isEmpty && attendanceBox.isEmpty) {
        await _reopenHive();
        return '❌ لا توجد بيانات للنسخ الاحتياطي';
      }

      // Try the new direct backup method first
      final backupData = await _createDirectBackup();
      if (backupData != null) {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'حفظ النسخة الاحتياطية',
          fileName:
              'wosool_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
          type: FileType.custom,
          allowedExtensions: ['zip'],
          bytes: backupData,
        );

        await _reopenHive();
        return outputFile != null
            ? "✅ تم حفظ النسخة بنجاح"
            : "⚠️ تم إلغاء الحفظ";
      }

      // Fallback to the old method
      final localPath = await _createLocalBackupFile();
      if (localPath == null) return '❌ فشل إنشاء الملف المؤقت';

      final file = File(localPath);
      final Uint8List fileBytes = await file.readAsBytes();

      if (fileBytes.isEmpty) {
        await _reopenHive();
        return '❌ فشل: ملف النسخة الاحتياطية فارغ';
      }

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ النسخة الاحتياطية',
        fileName: 'wosool_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
        bytes: fileBytes,
      );

      await _reopenHive();

      if (await file.exists()) {
        await file.delete();
      }

      return outputFile != null ? "✅ تم حفظ النسخة بنجاح" : "⚠️ تم إلغاء الحفظ";
    } catch (e) {
      await _reopenHive();
      return "❌ خطأ فني: $e";
    }
  }

  static Future<Uint8List?> _createDirectBackup() async {
    try {
      final settingsBox = await Hive.openBox('settings');
      final attendanceBox = await Hive.openBox<DailyRecord>('attendance');

      final archive = Archive();

      // Export settings data as JSON
      final settingsData = <String, dynamic>{};
      for (final key in settingsBox.keys) {
        settingsData[key.toString()] = settingsBox.get(key);
      }

      final settingsJson = jsonEncode(settingsData);
      final settingsBytes = utf8.encode(settingsJson);
      archive.addFile(
          ArchiveFile('settings.json', settingsBytes.length, settingsBytes));

      // Export attendance data as JSON
      final attendanceData = attendanceBox.values.toList();
      final attendanceJson =
          jsonEncode(attendanceData.map((record) => record.toJson()).toList());
      final attendanceBytes = utf8.encode(attendanceJson);
      archive.addFile(ArchiveFile(
          'attendance.json', attendanceBytes.length, attendanceBytes));

      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) return null;
      return Uint8List.fromList(zipData);
    } catch (e) {
      print('Error in direct backup: $e');
      return null;
    }
  }

  static Future<bool> restoreBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result == null || result.files.single.path == null) return false;

      final bytes = File(result.files.single.path!).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Check if this is the new JSON format backup
      bool isJsonFormat = false;
      Map<String, dynamic>? settingsData;
      List<dynamic>? attendanceData;

      for (final file in archive) {
        if (file.name == 'settings.json') {
          isJsonFormat = true;
          final content = utf8.decode(file.content);
          settingsData = jsonDecode(content);
        } else if (file.name == 'attendance.json') {
          isJsonFormat = true;
          final content = utf8.decode(file.content);
          attendanceData = jsonDecode(content);
        }
      }

      if (isJsonFormat && settingsData != null && attendanceData != null) {
        // Restore from JSON format
        await Hive.close();
        await _reopenHive();

        final settingsBox = await Hive.openBox('settings');
        final attendanceBox = await Hive.openBox<DailyRecord>('attendance');

        // Clear existing data
        await settingsBox.clear();
        await attendanceBox.clear();

        // Restore settings
        for (final entry in settingsData.entries) {
          await settingsBox.put(entry.key, entry.value);
        }

        // Restore attendance
        for (final recordData in attendanceData) {
          final record = DailyRecord.fromJson(recordData);
          await attendanceBox.add(record);
        }

        await _reopenHive();
        return true;
      }

      // Fallback to old file-based restore
      await Hive.close();
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory(appDir.path);

      if (dir.existsSync()) dir.deleteSync(recursive: true);
      dir.createSync();

      for (final file in archive) {
        final path = p.join(appDir.path, file.name);
        if (file.isFile) {
          File(path)
            ..createSync(recursive: true)
            ..writeAsBytesSync(file.content);
        }
      }

      await _reopenHive();
      return true;
    } catch (e) {
      try {
        await _reopenHive();
      } catch (_) {}
      return false;
    }
  }

  static Future<void> _reopenHive() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(DailyRecordAdapter().typeId)) {
      Hive.registerAdapter(DailyRecordAdapter());
    }
    await Hive.openBox('settings');
    await Hive.openBox<DailyRecord>('attendance');
  }

  static Future<String?> _createLocalBackupFile() async {
    try {
      // 1. إغلاق Hive لضمان كتابة البيانات من الرامات إلى القرص
      await Hive.close();

      // Wait a moment to ensure all data is properly written to disk
      await Future.delayed(const Duration(milliseconds: 500));

      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();
      final tempZipPath = p.join(tempDir.path, 'temp_backup.zip');

      if (await File(tempZipPath).exists()) await File(tempZipPath).delete();

      // Debug: Print the app directory path
      print('App directory path: ${appDir.path}');

      // Check if directory exists and has content
      final dir = Directory(appDir.path);
      if (!await dir.exists()) {
        print('App directory does not exist!');
        return null;
      }

      // List all files in the directory for debugging
      try {
        final files = await dir.list(recursive: true).toList();
        print('Found ${files.length} files in app directory:');
        for (final file in files) {
          print('  - ${file.path}');
        }
      } catch (e) {
        print('Error listing files: $e');
      }

      // تمرير مسار مجلد التطبيق بالكامل ليشمل القواعد والصور
      await compute(_createBackupInternal, [appDir.path, tempZipPath]);

      final resultFile = File(tempZipPath);
      final fileSize = await resultFile.length();
      print('Backup file size: $fileSize bytes');

      if (await resultFile.exists() && fileSize > 0) {
        return tempZipPath;
      }
      return null;
    } catch (e) {
      print('Error in _createLocalBackupFile: $e');
      return null;
    }
  }

  @pragma('vm:entry-point')
  static void _createBackupInternal(List<String> args) {
    final String sourceDir = args[0];
    final String zipPath = args[1];

    try {
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);

      final dir = Directory(sourceDir);
      if (dir.existsSync()) {
        int filesAdded = 0;
        // البحث بشكل تعامدي (recursive) لضمان الوصول لجميع الملفات والصور
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is File) {
            // استثناء ملفات القفل أو الملفات المؤقتة لتجنب الأخطاء
            if (entity.path.endsWith('.lock') ||
                entity.path.contains('temp_backup')) {
              continue;
            }

            // Check if file has content before adding
            final fileSize = entity.lengthSync();
            if (fileSize > 0) {
              final relativePath = p.relative(entity.path, from: sourceDir);
              encoder.addFile(entity, relativePath.replaceAll('\\', '/'));
              filesAdded++;
            }
          }
        }
        print('Added $filesAdded files to backup');
      }
      encoder.close(); // إغلاق الـ encoder ضروري جداً لسلامة ملف الـ Zip
    } catch (e) {
      print('Error in _createBackupInternal: $e');
    }
  }
}
