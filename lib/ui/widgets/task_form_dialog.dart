import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/task.dart';
import '../../core/services/ai_service.dart';

class TaskFormDialog extends StatefulWidget {
  final Task? task;
  final Function(Task) onSubmit;

  const TaskFormDialog({
    super.key,
    this.task,
    required this.onSubmit,
  });

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subtaskController = TextEditingController();
  DateTime? _dueDate;
  int _priority = 2;
  final List<String> _subtasks = [];
  bool _isLoading = false;
  String? _aiSuggestion;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _dueDate = widget.task!.dueDate;
      _priority = widget.task!.priority;
      _subtasks.addAll(widget.task!.subtasks);
      _aiSuggestion = widget.task!.aiSuggestion;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _getAISuggestion() async {
    if (_descriptionController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final suggestion = await AIService.instance.getTaskSuggestions(
        _descriptionController.text,
      );
      setState(() {
        _aiSuggestion = suggestion;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取AI建议失败: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _dueDate = pickedDate;
      });
    }
  }

  void _addSubtask() {
    if (_subtaskController.text.isNotEmpty) {
      setState(() {
        _subtasks.add(_subtaskController.text);
        _subtaskController.clear();
      });
    }
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtasks.removeAt(index);
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.task?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _dueDate,
        priority: _priority,
        subtasks: _subtasks,
        aiSuggestion: _aiSuggestion,
        isCompleted: widget.task?.isCompleted ?? false,
        createdAt: widget.task?.createdAt,
        completedAt: widget.task?.completedAt,
      );

      widget.onSubmit(task);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.task == null ? '新建任务' : '编辑任务'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '任务标题',
                  hintText: '输入任务标题',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入任务标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '任务描述',
                  hintText: '输入任务描述',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _priority,
                      decoration: const InputDecoration(
                        labelText: '优先级',
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('低')),
                        DropdownMenuItem(value: 2, child: Text('中')),
                        DropdownMenuItem(value: 3, child: Text('高')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _priority = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '截止日期',
                        ),
                        child: Text(
                          _dueDate == null
                              ? '选择日期'
                              : '${_dueDate!.month}/${_dueDate!.day}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      decoration: const InputDecoration(
                        labelText: '子任务',
                        hintText: '输入子任务',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addSubtask,
                  ),
                ],
              ),
              if (_subtasks.isNotEmpty) ...[  
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(
                    _subtasks.length,
                    (index) => Chip(
                      label: Text(_subtasks[index]),
                      onDeleted: () => _removeSubtask(index),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (_descriptionController.text.isNotEmpty) ...[  
                ElevatedButton.icon(
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('获取AI建议'),
                  onPressed: _isLoading ? null : _getAISuggestion,
                ),
              ],
              if (_isLoading) ...[  
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              if (_aiSuggestion != null) ...[  
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text('AI建议'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _aiSuggestion!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.task == null ? '创建' : '保存'),
        ),
      ],
    );
  }
}