import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/pomodoro.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';

class StatisticsProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final AIService _ai = AIService.instance;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<Map<String, dynamic>> getTaskStatistics(DateTime startDate, DateTime endDate) async {
    try {
      final tasks = await _db.getAllTasks();
      final filteredTasks = tasks.where((task) {
        return task.createdAt.isAfter(startDate) && task.createdAt.isBefore(endDate);
      }).toList();

      final completedTasks = filteredTasks.where((task) => task.isCompleted).toList();
      final incompleteTasks = filteredTasks.where((task) => !task.isCompleted).toList();

      return {
        'total_tasks': filteredTasks.length,
        'completed_tasks': completedTasks.length,
        'completion_rate': filteredTasks.isEmpty ? 0 :
          (completedTasks.length / filteredTasks.length * 100).toStringAsFixed(1),
        'average_completion_time': completedTasks.isEmpty ? 0 :
          completedTasks.where((task) => task.completedAt != null).map((task) {
            return task.completedAt!.difference(task.createdAt).inHours;
          }).reduce((a, b) => a + b) / completedTasks.length,
        'tasks_by_priority': {
          'high': filteredTasks.where((task) => task.priority == 3).length,
          'medium': filteredTasks.where((task) => task.priority == 2).length,
          'low': filteredTasks.where((task) => task.priority == 1).length,
        },
      };
    } catch (e) {
      _error = '获取任务统计数据失败: $e';
      notifyListeners();
      return {};
    }
  }

  Future<Map<String, dynamic>> getPomodoroStatistics(DateTime startDate, DateTime endDate) async {
    try {
      final sessions = await _db.getAllPomodoros();
      final filteredSessions = sessions.where((session) {
        return session.startTime.isAfter(startDate) && session.startTime.isBefore(endDate);
      }).toList();

      final completedSessions = filteredSessions.where((session) => session.isCompleted).toList();
      final workSessions = filteredSessions.where((session) => !session.isBreak).toList();
      final breakSessions = filteredSessions.where((session) => session.isBreak).toList();

      return {
        'total_sessions': filteredSessions.length,
        'completed_sessions': completedSessions.length,
        'completion_rate': filteredSessions.isEmpty ? 0 :
          (completedSessions.length / filteredSessions.length * 100).toStringAsFixed(1),
        'total_focus_time': workSessions.fold(0, (sum, session) => sum + session.duration),
        'total_break_time': breakSessions.fold(0, (sum, session) => sum + session.duration),
        'average_session_length': workSessions.isEmpty ? 0 :
          workSessions.fold(0, (sum, session) => sum + session.duration) / workSessions.length,
        'daily_sessions': _getDailySessionCounts(filteredSessions, startDate, endDate),
      };
    } catch (e) {
      _error = '获取番茄钟统计数据失败: $e';
      notifyListeners();
      return {};
    }
  }

  Map<String, int> _getDailySessionCounts(List<Pomodoro> sessions, DateTime startDate, DateTime endDate) {
    final dailyCounts = <String, int>{};
    var currentDate = startDate;

    while (currentDate.isBefore(endDate)) {
      final dateStr = '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
      final count = sessions.where((session) {
        return session.startTime.year == currentDate.year &&
               session.startTime.month == currentDate.month &&
               session.startTime.day == currentDate.day;
      }).length;
      dailyCounts[dateStr] = count;
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dailyCounts;
  }

  Future<String> getProductivityInsights(DateTime startDate, DateTime endDate) async {
    try {
      final taskStats = await getTaskStatistics(startDate, endDate);
      final pomodoroStats = await getPomodoroStatistics(startDate, endDate);

      final completedTasks = (await _db.getAllTasks())
          .where((task) => task.isCompleted)
          .map((task) => task.title)
          .toList();

      final upcomingTasks = (await _db.getAllTasks())
          .where((task) => !task.isCompleted)
          .map((task) => task.title)
          .toList();

      final timeSpentData = {
        'focus_time': pomodoroStats['total_focus_time'] ?? 0,
        'break_time': pomodoroStats['total_break_time'] ?? 0,
      };

      return await _ai.getTimeManagementAdvice(
        completedTasks: completedTasks,
        upcomingTasks: upcomingTasks,
        timeSpentData: timeSpentData,
      );
    } catch (e) {
      _error = '获取生产力洞察失败: $e';
      notifyListeners();
      return '无法获取生产力洞察';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}