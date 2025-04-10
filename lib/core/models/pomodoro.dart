import 'package:uuid/uuid.dart';

class Pomodoro {
  final String id;
  String taskId;
  DateTime startTime;
  DateTime? endTime;
  int duration; // in minutes
  bool isBreak;
  bool isCompleted;
  String? notes;
  DateTime createdAt;

  Pomodoro({
    String? id,
    required this.taskId,
    required this.startTime,
    this.endTime,
    required this.duration,
    this.isBreak = false,
    this.isCompleted = false,
    this.notes,
    DateTime? createdAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration,
      'isBreak': isBreak ? 1 : 0,
      'isCompleted': isCompleted ? 1 : 0,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Pomodoro.fromMap(Map<String, dynamic> map) {
    return Pomodoro(
      id: map['id'],
      taskId: map['taskId'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      duration: map['duration'],
      isBreak: map['isBreak'] == 1,
      isCompleted: map['isCompleted'] == 1,
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}