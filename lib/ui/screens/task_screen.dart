import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/task.dart';
import '../../core/providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_dialog.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => TaskFormDialog(
        onSubmit: (task) {
          context.read<TaskProvider>().addTask(task);
        },
      ),
    );
  }

  List<Task> _filterTasks(List<Task> tasks) {
    if (_searchQuery.isEmpty) return tasks;
    return tasks.where((task) {
      return task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             task.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '进行中'),
            Tab(text: '已完成'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索任务...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                if (taskProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (taskProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          taskProvider.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            taskProvider.clearError();
                            taskProvider.loadTasks();
                          },
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // 进行中的任务
                    _buildTaskList(
                      _filterTasks(taskProvider.incompleteTasks),
                      taskProvider,
                    ),
                    // 已完成的任务
                    _buildTaskList(
                      _filterTasks(taskProvider.completedTasks),
                      taskProvider,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        label: const Text('添加任务'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, TaskProvider taskProvider) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无任务',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TaskCard(
            task: task,
            onToggleComplete: () {
              taskProvider.toggleTaskCompletion(task.id);
            },
            onEdit: () {
              showDialog(
                context: context,
                builder: (context) => TaskFormDialog(
                  task: task,
                  onSubmit: (updatedTask) {
                    taskProvider.updateTask(updatedTask);
                  },
                ),
              );
            },
            onDelete: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('删除任务'),
                  content: const Text('确定要删除这个任务吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        taskProvider.deleteTask(task.id);
                        Navigator.pop(context);
                      },
                      child: const Text('删除'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}