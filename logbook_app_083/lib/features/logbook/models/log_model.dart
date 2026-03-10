import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  final ObjectId? id; // Penanda unik global dari MongoDB
  final String title;
  final DateTime date;
  final String description;
  final String category;

  LogModel({
    this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.category,
  });

  // [REVERT] Membongkar "Kardus" (BSON/Map) kembali menjadi objek Flutter
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] is ObjectId
          ? map['_id'] as ObjectId
          : (map['_id'] is String ? ObjectId.parse(map['_id']) : null),
      title: map['title'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      description: map['description'] ?? '',
      category: map['category'] ?? 'Pribadi',
    );
  }

  // [CONVERT] Memasukkan data ke "Kardus" (BSON/Map) untuk dikirim ke Cloud
  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(), // Buat ID otomatis jika belum ada
      'title': title,
      'description': description,
      'date': date.toIso8601String(), // Simpan tanggal dalam format standar
      'category': category,
    };
  }
}