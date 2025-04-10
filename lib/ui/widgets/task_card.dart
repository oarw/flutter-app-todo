import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getPriorityColor(BuildContext context) {
    switch (task.priority) {
      case 3:
        return Colors.red.withOpacity(0.8);
      case 2:
        return Colors.orange.withOpacity(0.8);
      case 1:
        return Colors.green.withOpacity(0.8);
      default:
        return Theme.of(context).colorScheme.primary.withOpacity(0.8);
    }
  }

  String _getPriorityText() {
    switch (task.priority) {
      case 3:
        return '高';
      case 2:
        return '中';
      case 1:
        return '低';
      default:
        return '中';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '优先级：${_getPriorityText()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (task.dueDate != null) ...[  
                          const SizedBox(width: 8),
                          Icon(
                            Icons.event,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MM/dd').format(task.dueDate!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                      color: task.isCompleted ? colorScheme.primary : null,
                    ),
                    onPressed: onToggleComplete,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted ? theme.disabledColor : null,
                ),
              ),
              if (task.description.isNotEmpty) ...[  
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (task.subtasks.isNotEmpty) ...[  
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: task.subtasks.map((subtask) {
                    return Chip(
                      label: Text(
                        subtask,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      backgroundColor: colorScheme.secondaryContainer,
                    );
                  }).toList(),
                ),
              ],
              if (task.aiSuggestion != null) ...[  
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.aiSuggestion!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('编辑'),
                    onPressed: onEdit,
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('删除'),
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}