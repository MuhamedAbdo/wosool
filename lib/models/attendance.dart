import 'package:hive/hive.dart';

part 'attendance.g.dart'; // سيتولد بعد تشغيل build_runner

@HiveType(typeId: 0)
class DailyRecord extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final Map<String, double> workersStatus; // اسم العامل : حالته (1.0, 0.5, 0.0)

  @HiveField(2)
  final double priceAtTime; // السعر وقت تسجيل هذه الرحلة

  @HiveField(3)
  final String driverName; // اسم السائق لهذا اليوم

  DailyRecord({
    required this.date,
    required this.workersStatus,
    required this.priceAtTime,
    required this.driverName,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'workersStatus': workersStatus,
      'priceAtTime': priceAtTime,
      'driverName': driverName,
    };
  }

  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    return DailyRecord(
      date: DateTime.parse(json['date']),
      workersStatus: Map<String, double>.from(json['workersStatus']),
      priceAtTime: json['priceAtTime'].toDouble(),
      driverName: json['driverName'],
    );
  }
}
