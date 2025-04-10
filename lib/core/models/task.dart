import 'package:uuid/uuid.dart';

class Task {
  final String id;
  String title;
  String description;
  DateTime? dueDate;
  bool isCompleted;
  List<String> subtasks;
  int priority; // 1-3: Low, Medium, High
  String? aiSuggestion;
  DateTime createdAt;
  DateTime? completedAt;

  Task({
    String? id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.isCompleted = false,
    List<String>? subtasks,
    this.priority = 2,
    this.aiSuggestion,
    DateTime? createdAt,
    this.completedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    subtasks = subtasks ?? [],
    createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'subtasks': subtasks.join('|'),
      'priority': priority,
      'aiSuggestion': aiSuggestion,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      isCompleted: map['isCompleted'] == 1,
      subtasks: map['subtasks'].toString().split('|').where((s) => s.isNotEmpty).toList(),
      priority: map['priority'],
      aiSuggestion: map['aiSuggestion'],
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
    );
  }
}