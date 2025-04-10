import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/schedule.dart';
import '../../core/providers/schedule_provider.dart';
import '../widgets/schedule_form_dialog.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().loadSchedules();
    });
  }

  void _showAddScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => ScheduleFormDialog(
        initialDate: _selectedDate,
        onSubmit: (schedule) {
          context.read<ScheduleProvider>().addSchedule(schedule);
        },
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month - 1,
                      _selectedDate.day,
                    );
                  });
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              Text(
                DateFormat('yyyy年MM月').format(_selectedDate),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month + 1,
                      _selectedDate.day,
                    );
                  });
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('日'),
              Text('一'),
              Text('二'),
              Text('三'),
              Text('四'),
              Text('五'),
              Text('六'),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month + (index - 1),
                    _selectedDate.day,
                  );
                });
              },
              itemBuilder: (context, index) {
                final currentMonth = DateTime(
                  _selectedDate.year,
                  _selectedDate.month + (index - 1),
                );
                return _buildMonthCalendar(currentMonth);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar(DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 42,
      itemBuilder: (context, index) {
        final dayNumber = index - firstWeekday + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox();
        }

        final date = DateTime(month.year, month.month, dayNumber);
        final isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;
        final isToday = date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        return Consumer<ScheduleProvider>(
          builder: (context, provider, child) {
            final hasSchedules = provider.schedules.any((schedule) {
              return schedule.startTime.year == date.year &&
                  schedule.startTime.month == date.month &&
                  schedule.startTime.day == date.day;
            });

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
              },
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        dayNumber.toString(),
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : null,
                        ),
                      ),
                    ),
                    if (hasSchedules)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScheduleList() {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.red),
                ),
                ElevatedButton(
                  onPressed: () {
                    provider.clearError();
                    provider.loadSchedules();
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        final schedules = provider.getSchedulesForDay(_selectedDate);

        if (schedules.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '当天没有日程',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                title: Text(schedule.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.isAllDay
                          ? '全天'
                          : '${DateFormat('HH:mm').format(schedule.startTime)} - ${DateFormat('HH:mm').format(schedule.endTime)}',
                    ),
                    if (schedule.location != null)
                      Text(
                        '📍 ${schedule.location!}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        showDialog(
                          context: context,
                          builder: (context) => ScheduleFormDialog(
                            schedule: schedule,
                            onSubmit: (updatedSchedule) {
                              provider.updateSchedule(updatedSchedule);
                            },
                          ),
                        );
                        break;
                      case 'delete':
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('删除日程'),
                            content: const Text('确定要删除这个日程吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () {
                                  provider.deleteSchedule(schedule.id);
                                  Navigator.pop(context);
                                },
                                child: const Text('删除'),
                              ),
                            ],
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('编辑'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('删除'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日程管理'),
      ),
      body: Column(
        children: [
          _buildCalendar(),
          Expanded(
            child: _buildScheduleList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddScheduleDialog,
        label: const Text('添加日程'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}