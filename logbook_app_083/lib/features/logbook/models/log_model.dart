import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String date;

  @HiveField(4)
  final String authorId;

  @HiveField(5)
  final String teamId; // BARU

  @HiveField(6)
  final String category; // BARU

  LogModel({
    this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.authorId,
    required this.teamId,
    this.category = 'Umum',
  });

  Map<String, dynamic> toMap() => {
    '_id': id != null ? ObjectId.fromHexString(id!) : ObjectId(),
    'title': title,
    'description': description,
    'date': date,
    'category': category,
    'authorId': authorId,
    'teamId': teamId,
  };

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: (map['_id'] as ObjectId?)?.oid,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Pribadi',
      date: map['date'] ?? '',
      authorId: map['authorId'] ?? 'unknown_user', // Cegah error null
      teamId: map['teamId'] ?? 'no_team',
    );
  }
}