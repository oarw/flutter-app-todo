import 'package:flutter/foundation.dart';
import '../models/schedule.dart';
import '../services/database_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ScheduleProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  List<Schedule> _schedules = [];
  bool _isLoading = false;
  String? _error;

  List<Schedule> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ScheduleProvider() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _notifications.initialize(initializationSettings);
  }

  Future<void> loadSchedules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _schedules = await _db.getAllSchedules();
      _error = null;
    } catch (e) {
      _error = '加载日程失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSchedule(Schedule schedule) async {
    try {
      await _db.createSchedule(schedule);
      _schedules.add(schedule);
      await _scheduleNotification(schedule);
      notifyListeners();
    } catch (e) {
      _error = '添加日程失败: $e';
      notifyListeners();
    }
  }

  Future<void> updateSchedule(Schedule schedule) async {
    try {
      await _db.updateSchedule(schedule);
      final index = _schedules.indexWhere((s) => s.id == schedule.id);
      if (index != -1) {
        _schedules[index] = schedule;
        await _updateNotification(schedule);
        notifyListeners();
      }
    } catch (e) {
      _error = '更新日程失败: $e';
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _db.deleteSchedule(scheduleId);
      await _cancelNotification(scheduleId);
      _schedules.removeWhere((schedule) => schedule.id == scheduleId);
      notifyListeners();
    } catch (e) {
      _error = '删除日程失败: $e';
      notifyListeners();
    }
  }

  Future<void> _scheduleNotification(Schedule schedule) async {
    if (schedule.reminderType == null) return;

    final minutes = _getReminderMinutes(schedule.reminderType!);
    if (minutes == null) return;

    final scheduledTime = schedule.startTime.subtract(Duration(minutes: minutes));
    if (scheduledTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'schedule_channel',
      '日程提醒',
      channelDescription: '日程开始前的提醒通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.schedule(
      schedule.id.hashCode,
      '日程提醒',
      '${schedule.title} 将在 ${minutes} 分钟后开始',
      scheduledTime,
      details,
    );
  }

  Future<void> _updateNotification(Schedule schedule) async {
    await _cancelNotification(schedule.id);
    await _scheduleNotification(schedule);
  }

  Future<void> _cancelNotification(String scheduleId) async {
    await _notifications.cancel(scheduleId.hashCode);
  }

  int? _getReminderMinutes(String reminderType) {
    switch (reminderType) {
      case '5min':
        return 5;
      case '15min':
        return 15;
      case '30min':
        return 30;
      case '1hour':
        return 60;
      default:
        return null;
    }
  }

  List<Schedule> getSchedulesForDay(DateTime date) {
    return _schedules.where((schedule) {
      final scheduleDate = DateTime(
        schedule.startTime.year,
        schedule.startTime.month,
        schedule.startTime.day,
      );
      final targetDate = DateTime(
        date.year,
        date.month,
        date.day,
      );
      return scheduleDate == targetDate;
    }).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}