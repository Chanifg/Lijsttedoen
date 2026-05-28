import 'package:isar/isar.dart';

part 'todo_model.g.dart';

@collection
class TodoModel {
  Id id; // Isar ID (int)

  String title;
  String description;
  bool isDone;
  String dueTime;
  String dueDate;
  String category;
  bool isDeadline;
  String? deadlineDate;
  String? deadlineTime;
  String? completedAt;

  TodoModel({
    this.id = Isar.autoIncrement,
    required this.title,
    required this.description,
    this.isDone = false,
    this.dueTime = '12:00',
    this.dueDate = '',
    this.category = 'Work',
    this.isDeadline = false,
    this.deadlineDate,
    this.deadlineTime,
    this.completedAt,
  }) {
    if (dueDate.isEmpty) {
      dueDate = _getTodayDateString();
    }
  }

  static String _getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // Konversi ke Map untuk disimpan ke SharedPreferences / Backup
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isDone': isDone ? 1 : 0,
      'dueTime': dueTime,
      'dueDate': dueDate,
      'category': category,
      'isDeadline': isDeadline ? 1 : 0,
      'deadlineDate': deadlineDate,
      'deadlineTime': deadlineTime,
      'completedAt': completedAt,
    };
  }

  // Konversi dari Map ke TodoModel
  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      isDone: (map['isDone'] as int) == 1,
      dueTime: (map['dueTime'] as String?) ?? '12:00',
      dueDate: (map['dueDate'] as String?) ?? _getTodayDateString(),
      category: (map['category'] as String?) ?? 'Work',
      isDeadline: map['isDeadline'] == null ? false : (map['isDeadline'] as int) == 1,
      deadlineDate: map['deadlineDate'] as String?,
      deadlineTime: map['deadlineTime'] as String?,
      completedAt: map['completedAt'] as String?,
    );
  }
}
