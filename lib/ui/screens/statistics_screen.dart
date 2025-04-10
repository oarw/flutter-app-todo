import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/statistics_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = '周';
  bool _isLoadingInsights = false;
  String? _productivityInsights;

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case '周':
        return now.subtract(const Duration(days: 7));
      case '月':
        return DateTime(now.year, now.month - 1, now.day);
      case '年':
        return DateTime(now.year - 1, now.month, now.day);
      default:
        return now.subtract(const Duration(days: 7));
    }
  }

  Future<void> _loadProductivityInsights() async {
    if (_isLoadingInsights) return;

    setState(() {
      _isLoadingInsights = true;
    });

    try {
      final insights = await context
          .read<StatisticsProvider>()
          .getProductivityInsights(_startDate, DateTime.now());
      setState(() {
        _productivityInsights = insights;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取生产力洞察失败: $e')),
      );
    } finally {
      setState(() {
        _isLoadingInsights = false;
      });
    }
  }

  Widget _buildPeriodSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: '周', label: Text('本周')),
        ButtonSegment(value: '月', label: Text('本月')),
        ButtonSegment(value: '年', label: Text('本年')),
      ],
      selected: {_selectedPeriod},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          _selectedPeriod = newSelection.first;
        });
      },
    );
  }

  Widget _buildTaskStatistics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: context
          .read<StatisticsProvider>()
          .getTaskStatistics(_startDate, DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              '加载统计数据失败: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final stats = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '任务统计',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      '总任务数',
                      stats['total_tasks'].toString(),
                      Icons.task_alt,
                    ),
                    _buildStatItem(
                      '完成率',
                      '${stats['completion_rate']}%',
                      Icons.check_circle,
                    ),
                    _buildStatItem(
                      '平均完成时间',
                      '${stats['average_completion_time'].toStringAsFixed(1)}小时',
                      Icons.timer,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '任务优先级分布',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildPriorityDistribution(stats['tasks_by_priority']),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPomodoroStatistics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: context
          .read<StatisticsProvider>()
          .getPomodoroStatistics(_startDate, DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              '加载统计数据失败: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final stats = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '专注统计',
                  style: Theme.of(context).textTheme.titleLarge,
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
                      '总专注时间',
                      '${stats['total_focus_time']}分钟',
                      Icons.access_time,
                    ),
                    _buildStatItem(
                      '平均时长',
                      '${stats['average_session_length'].toStringAsFixed(1)}分钟',
                      Icons.trending_up,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '每日专注次数',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildDailySessionChart(stats['daily_sessions']),
              ],
            ),
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
          size: 32,
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

  Widget _buildPriorityDistribution(Map<String, int> distribution) {
    final total = distribution['high']! +
        distribution['medium']! +
        distribution['low']!;
    if (total == 0) return const Text('暂无数据');

    return Column(
      children: [
        _buildPriorityBar('高', distribution['high']! / total,
            Theme.of(context).colorScheme.error),
        const SizedBox(height: 8),
        _buildPriorityBar('中', distribution['medium']! / total,
            Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        _buildPriorityBar('低', distribution['low']! / total,
            Theme.of(context).colorScheme.secondary),
      ],
    );
  }

  Widget _buildPriorityBar(String label, double percentage, Color color) {
    return Row(
      children: [
        SizedBox(width: 40, child: Text(label)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${(percentage * 100).toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildDailySessionChart(Map<String, int> dailySessions) {
    if (dailySessions.isEmpty) return const Text('暂无数据');

    final maxSessions =
        dailySessions.values.reduce((max, value) => max > value ? max : value);

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dailySessions.length,
        itemBuilder: (context, index) {
          final date = dailySessions.keys.elementAt(index);
          final sessions = dailySessions[date]!;
          final height = maxSessions > 0
              ? (sessions / maxSessions) * 150
              : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(sessions.toString()),
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: height,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date.split('-')[2],
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductivityInsights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI生产力洞察',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoadingInsights ? null : _loadProductivityInsights,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingInsights)
              const Center(child: CircularProgressIndicator())
            else if (_productivityInsights != null)
              Text(_productivityInsights!)
            else
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('获取AI洞察'),
                  onPressed: _loadProductivityInsights,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计分析'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          _buildTaskStatistics(),
          const SizedBox(height: 16),
          _buildPomodoroStatistics(),
          const SizedBox(height: 16),
          _buildProductivityInsights(),
        ],
      ),
    );
  }
}