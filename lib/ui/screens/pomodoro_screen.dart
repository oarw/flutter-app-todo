import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/pomodoro_provider.dart';
import '../../core/providers/task_provider.dart';
import '../../core/models/task.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  Task? _selectedTask;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  Widget _buildTimer() {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, child) {
        final timeStr = provider.formatTime(provider.remainingSeconds);
        final progress = provider.remainingSeconds /
            (provider.currentSession?.duration ?? PomodoroProvider.defaultWorkDuration) /
            60;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.2),
                  ),
                ),
                Text(
                  timeStr,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!provider.isRunning && provider.remainingSeconds == 0) ...[  
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始专注'),
                    onPressed: _selectedTask == null
                        ? null
                        : () {
                            provider.startNewSession(
                              taskId: _selectedTask!.id,
                            );
                          },
                  ),
                ] else if (provider.isRunning) ...[  
                  ElevatedButton.icon(
                    icon: const Icon(Icons.pause),
                    label: const Text('暂停'),
                    onPressed: () {
                      provider.pauseSession();
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: const Text('停止'),
                    onPressed: () {
                      provider.stopCurrentSession();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                ] else ...[  
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('继续'),
                    onPressed: () {
                      provider.resumeSession();
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: const Text('停止'),
                    onPressed: () {
                      provider.stopCurrentSession();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskSelector() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        if (taskProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final incompleteTasks = taskProvider.incompleteTasks;

        if (incompleteTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '没有待完成的任务',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5),
                      ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '选择要专注的任务',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: incompleteTasks.length,
                itemBuilder: (context, index) {
                  final task = incompleteTasks[index];
                  return Card(
                    child: ListTile(
                      leading: Radio<Task>(
                        value: task,
                        groupValue: _selectedTask,
                        onChanged: (Task? value) {
                          setState(() {
                            _selectedTask = value;
                          });
                        },
                      ),
                      title: Text(task.title),
                      subtitle: task.description.isNotEmpty
                          ? Text(
                              task.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatistics() {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, child) {
        final stats = provider.getSessionStatistics(
          DateTime.now().subtract(const Duration(days: 7)),
          DateTime.now(),
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '本周统计',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    '专注次数',
                    stats['total_sessions'].toString(),
                    Icons.timer,
                  ),
                  _buildStatItem(
                    '完成率',
                    '${(((stats['completed_sessions'] ?? 0) / (stats['total_sessions'] ?? 1)) * 100).toStringAsFixed(1)}%',
                    Icons.check_circle,
                  ),
                  _buildStatItem(
                    '专注时间',
                    '${stats['total_minutes']}分钟',
                    Icons.access_time,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('番茄钟'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: _buildTimer(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStatistics(),
          ),
          Expanded(
            flex: 2,
            child: _buildTaskSelector(),
          ),
        ],
      ),
    );
  }
}