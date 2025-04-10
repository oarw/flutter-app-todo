import 'package:flutter/material.dart';
import 'task_screen.dart';
import 'schedule_screen.dart';
import 'pomodoro_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const TaskScreen(),
    const ScheduleScreen(),
    const PomodoroScreen(),
    const StatisticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.task_alt),
            label: '任务',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: '日程',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer),
            label: '番茄钟',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),
            label: '统计',
          ),
        ],
      ),
    );
  }
}