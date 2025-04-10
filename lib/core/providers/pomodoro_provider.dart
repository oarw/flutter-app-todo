import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/pomodoro.dart';
import '../services/database_service.dart';

class PomodoroProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  List<Pomodoro> _sessions = [];
  Timer? _timer;
  bool _isRunning = false;
  int _remainingSeconds = 0;
  Pomodoro? _currentSession;
  bool _isLoading = false;
  String? _error;

  // 默认设置
  static const int defaultWorkDuration = 25; // 分钟
  static const int defaultShortBreak = 5; // 分钟
  static const int defaultLongBreak = 15; // 分钟
  static const int sessionsUntilLongBreak = 4;

  List<Pomodoro> get sessions => _sessions;
  bool get isRunning => _isRunning;
  int get remainingSeconds => _remainingSeconds;
  Pomodoro? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSessions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sessions = await _db.getAllPomodoros();
      _error = null;
    } catch (e) {
      _error = '加载番茄钟记录失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startNewSession({
    required String taskId,
    int duration = defaultWorkDuration,
    bool isBreak = false,
  }) async {
    if (_isRunning) {
      await stopCurrentSession();
    }

    final newSession = Pomodoro(
      taskId: taskId,
      startTime: DateTime.now(),
      duration: duration,
      isBreak: isBreak,
    );

    try {
      await _db.createPomodoro(newSession);
      _currentSession = newSession;
      _remainingSeconds = duration * 60;
      _startTimer();
      _sessions.add(newSession);
      notifyListeners();
    } catch (e) {
      _error = '创建番茄钟会话失败: $e';
      notifyListeners();
    }
  }

  void _startTimer() {
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _completeCurrentSession();
      }
    });
  }

  Future<void> pauseSession() async {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();

    if (_currentSession != null) {
      try {
        await _db.updatePomodoro(_currentSession!);
      } catch (e) {
        _error = '暂停番茄钟会话失败: $e';
        notifyListeners();
      }
    }
  }

  void resumeSession() {
    if (_currentSession != null && _remainingSeconds > 0) {
      _startTimer();
    }
  }

  Future<void> stopCurrentSession() async {
    _timer?.cancel();
    _isRunning = false;

    if (_currentSession != null) {
      _currentSession!.endTime = DateTime.now();
      _currentSession!.isCompleted = false;

      try {
        await _db.updatePomodoro(_currentSession!);
        final index = _sessions.indexWhere((s) => s.id == _currentSession!.id);
        if (index != -1) {
          _sessions[index] = _currentSession!;
        }
      } catch (e) {
        _error = '停止番茄钟会话失败: $e';
      }
    }

    _currentSession = null;
    _remainingSeconds = 0;
    notifyListeners();
  }

  Future<void> _completeCurrentSession() async {
    _timer?.cancel();
    _isRunning = false;

    if (_currentSession != null) {
      _currentSession!.endTime = DateTime.now();
      _currentSession!.isCompleted = true;

      try {
        await _db.updatePomodoro(_currentSession!);
        final index = _sessions.indexWhere((s) => s.id == _currentSession!.id);
        if (index != -1) {
          _sessions[index] = _currentSession!;
        }
      } catch (e) {
        _error = '完成番茄钟会话失败: $e';
      }
    }

    _currentSession = null;
    _remainingSeconds = 0;
    notifyListeners();
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _db.deletePomodoro(sessionId);
      _sessions.removeWhere((session) => session.id == sessionId);
      notifyListeners();
    } catch (e) {
      _error = '删除番茄钟会话失败: $e';
      notifyListeners();
    }
  }

  Map<String, int> getSessionStatistics(DateTime startDate, DateTime endDate) {
    final filteredSessions = _sessions.where((session) {
      return session.startTime.isAfter(startDate) &&
          session.startTime.isBefore(endDate);
    }).toList();

    return {
      'total_sessions': filteredSessions.length,
      'completed_sessions': filteredSessions.where((s) => s.isCompleted).length,
      'total_minutes': filteredSessions.fold(0, (sum, session) {
        if (session.endTime != null) {
          return sum + session.duration;
        }
        return sum;
      }),
      'work_sessions': filteredSessions.where((s) => !s.isBreak).length,
      'break_sessions': filteredSessions.where((s) => s.isBreak).length,
    };
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}