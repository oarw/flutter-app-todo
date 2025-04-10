import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final AIService _ai = AIService.instance;
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Task> get incompleteTasks => _tasks.where((task) => !task.isCompleted).toList();
  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();

  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _db.getAllTasks();
      _error = null;
    } catch (e) {
      _error = '加载任务失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(Task task) async {
    try {
      await _db.createTask(task);
      _tasks.add(task);
      notifyListeners();

      // 获取AI建议
      try {
        final suggestion = await _ai.getTaskSuggestions(task.description);
        task.aiSuggestion = suggestion;
        await updateTask(task);
      } catch (e) {
        debugPrint('获取AI建议失败: $e');
      }
    } catch (e) {
      _error = '添加任务失败: $e';
      notifyListeners();
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _db.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
      }
    } catch (e) {
      _error = '更新任务失败: $e';
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _db.deleteTask(taskId);
      _tasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
    } catch (e) {
      _error = '删除任务失败: $e';
      notifyListeners();
    }
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    try {
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = _tasks[taskIndex];
        task.isCompleted = !task.isCompleted;
        task.completedAt = task.isCompleted ? DateTime.now() : null;
        await _db.updateTask(task);
        notifyListeners();
      }
    } catch (e) {
      _error = '更新任务状态失败: $e';
      notifyListeners();
    }
  }

  Future<void> addSubtask(String taskId, String subtask) async {
    try {
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = _tasks[taskIndex];
        task.subtasks.add(subtask);
        await _db.updateTask(task);
        notifyListeners();
      }
    } catch (e) {
      _error = '添加子任务失败: $e';
      notifyListeners();
    }
  }

  Future<void> removeSubtask(String taskId, String subtask) async {
    try {
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = _tasks[taskIndex];
        task.subtasks.remove(subtask);
        await _db.updateTask(task);
        notifyListeners();
      }
    } catch (e) {
      _error = '删除子任务失败: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}