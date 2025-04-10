import 'package:uuid/uuid.dart';

class Schedule {
  final String id;
  String title;
  String description;
  DateTime startTime;
  DateTime endTime;
  bool isAllDay;
  String? location;
  List<String> participants;
  bool isRecurring;
  String? recurrenceRule;
  String? reminderType; // none, 5min, 15min, 30min, 1hour
  DateTime createdAt;

  Schedule({
    String? id,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.location,
    List<String>? participants,
    this.isRecurring = false,
    this.recurrenceRule,
    this.reminderType,
    DateTime? createdAt,
  }) : 
    id = id ?? const Uuid().v4(),
    participants = participants ?? [],
    createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isAllDay': isAllDay ? 1 : 0,
      'location': location,
      'participants': participants.join('|'),
      'isRecurring': isRecurring ? 1 : 0,
      'recurrenceRule': recurrenceRule,
      'reminderType': reminderType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      isAllDay: map['isAllDay'] == 1,
      location: map['location'],
      participants: map['participants'].toString().split('|').where((s) => s.isNotEmpty).toList(),
      isRecurring: map['isRecurring'] == 1,
      recurrenceRule: map['recurrenceRule'],
      reminderType: map['reminderType'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}