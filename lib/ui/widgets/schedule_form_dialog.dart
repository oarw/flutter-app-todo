import 'package:flutter/material.dart';
import '../../core/models/schedule.dart';

class ScheduleFormDialog extends StatefulWidget {
  final Schedule? schedule;
  final DateTime? initialDate;
  final Function(Schedule) onSubmit;

  const ScheduleFormDialog({
    super.key,
    this.schedule,
    this.initialDate,
    required this.onSubmit,
  });

  @override
  State<ScheduleFormDialog> createState() => _ScheduleFormDialogState();
}

class _ScheduleFormDialogState extends State<ScheduleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _participantController = TextEditingController();
  final List<String> _participants = [];
  
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  bool _isAllDay = false;
  bool _isRecurring = false;
  String? _recurrenceRule;
  String? _reminderType;

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      _titleController.text = widget.schedule!.title;
      _descriptionController.text = widget.schedule!.description;
      _locationController.text = widget.schedule!.location ?? '';
      _participants.addAll(widget.schedule!.participants);
      _startDate = widget.schedule!.startTime;
      _startTime = TimeOfDay.fromDateTime(widget.schedule!.startTime);
      _endDate = widget.schedule!.endTime;
      _endTime = TimeOfDay.fromDateTime(widget.schedule!.endTime);
      _isAllDay = widget.schedule!.isAllDay;
      _isRecurring = widget.schedule!.isRecurring;
      _recurrenceRule = widget.schedule!.recurrenceRule;
      _reminderType = widget.schedule!.reminderType;
    } else {
      final initialDate = widget.initialDate ?? DateTime.now();
      _startDate = initialDate;
      _startTime = TimeOfDay.now();
      _endDate = initialDate;
      _endTime = TimeOfDay.fromDateTime(
        initialDate.add(const Duration(hours: 1)),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _participantController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectStartTime() async {
    if (_isAllDay) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (pickedTime != null) {
      setState(() {
        _startTime = pickedTime;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _endDate = pickedDate;
      });
    }
  }

  Future<void> _selectEndTime() async {
    if (_isAllDay) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (pickedTime != null) {
      setState(() {
        _endTime = pickedTime;
      });
    }
  }

  void _addParticipant() {
    if (_participantController.text.isNotEmpty) {
      setState(() {
        _participants.add(_participantController.text);
        _participantController.clear();
      });
    }
  }

  void _removeParticipant(int index) {
    setState(() {
      _participants.removeAt(index);
    });
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final schedule = Schedule(
        id: widget.schedule?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        startTime: _isAllDay
            ? DateTime(_startDate.year, _startDate.month, _startDate.day)
            : _combineDateAndTime(_startDate, _startTime),
        endTime: _isAllDay
            ? DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59)
            : _combineDateAndTime(_endDate, _endTime),
        isAllDay: _isAllDay,
        location: _locationController.text.isEmpty ? null : _locationController.text,
        participants: _participants,
        isRecurring: _isRecurring,
        recurrenceRule: _recurrenceRule,
        reminderType: _reminderType,
        createdAt: widget.schedule?.createdAt,
      );

      widget.onSubmit(schedule);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.schedule == null ? '新建日程' : '编辑日程'),
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
                  labelText: '日程标题',
                  hintText: '输入日程标题',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入日程标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '日程描述',
                  hintText: '输入日程描述',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('全天日程'),
                value: _isAllDay,
                onChanged: (value) {
                  setState(() {
                    _isAllDay = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectStartDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '开始日期',
                        ),
                        child: Text(
                          '${_startDate.month}/${_startDate.day}',
                        ),
                      ),
                    ),
                  ),
                  if (!_isAllDay) ...[  
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _selectStartTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: '开始时间',
                          ),
                          child: Text(
                            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectEndDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '结束日期',
                        ),
                        child: Text(
                          '${_endDate.month}/${_endDate.day}',
                        ),
                      ),
                    ),
                  ),
                  if (!_isAllDay) ...[  
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _selectEndTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: '结束时间',
                          ),
                          child: Text(
                            '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: '地点',
                  hintText: '输入地点（可选）',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _participantController,
                      decoration: const InputDecoration(
                        labelText: '参与者',
                        hintText: '添加参与者',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addParticipant,
                  ),
                ],
              ),
              if (_participants.isNotEmpty) ...[  
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(
                    _participants.length,
                    (index) => Chip(
                      label: Text(_participants[index]),
                      onDeleted: () => _removeParticipant(index),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _reminderType,
                decoration: const InputDecoration(
                  labelText: '提醒',
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('不提醒')),
                  DropdownMenuItem(value: '5min', child: Text('5分钟前')),
                  DropdownMenuItem(value: '15min', child: Text('15分钟前')),
                  DropdownMenuItem(value: '30min', child: Text('30分钟前')),
                  DropdownMenuItem(value: '1hour', child: Text('1小时前')),
                ],
                onChanged: (value) {
                  setState(() {
                    _reminderType = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('重复日程'),
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value;
                    if (!value) {
                      _recurrenceRule = null;
                    }
                  });
                },
              ),
              if (_isRecurring) ...[  
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _recurrenceRule,
                  decoration: const InputDecoration(
                    labelText: '重复规则',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('每天')),
                    DropdownMenuItem(value: 'weekly', child: Text('每周')),
                    DropdownMenuItem(value: 'monthly', child: Text('每月')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _recurrenceRule = value;
                    });
                  },
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
          child: Text(widget.schedule == null ? '创建' : '保存'),
        ),
      ],
    );
  }
}