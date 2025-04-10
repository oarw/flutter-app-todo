import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _apiEndpoint = '/chat/completions';
  late String _apiKey;

  static final AIService instance = AIService._init();

  AIService._init();

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('openai_api_key') ?? '';
  }

  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openai_api_key', apiKey);
    _apiKey = apiKey;
  }

  Future<String> getTaskSuggestions(String taskDescription) async {
    if (_apiKey.isEmpty) {
      throw Exception('API key not set');
    }

    final prompt = '''
    作为一个任务管理专家，请帮我分析以下任务并提供建议：
    1. 如何将任务拆分成更小的可管理单元
    2. 估计每个子任务所需时间
    3. 建议的执行顺序
    4. 可能遇到的挑战和解决方案

    任务描述：$taskDescription
    ''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl + _apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '你是一个专业的任务管理和时间规划顾问。',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to get AI suggestions');
      }
    } catch (e) {
      throw Exception('Error communicating with AI service: $e');
    }
  }

  Future<String> getTimeManagementAdvice({
    required List<String> completedTasks,
    required List<String> upcomingTasks,
    required Map<String, int> timeSpentData,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('API key not set');
    }

    final prompt = '''
    基于以下信息，请提供时间管理建议：
    已完成的任务：${completedTasks.join(', ')}
    即将进行的任务：${upcomingTasks.join(', ')}
    各类活动花费的时间（分钟）：${timeSpentData.toString()}

    请分析：
    1. 时间利用效率
    2. 工作模式优化建议
    3. 如何更好地分配时间
    4. 改进建议
    ''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl + _apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '你是一个专业的时间管理顾问。',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to get time management advice');
      }
    } catch (e) {
      throw Exception('Error communicating with AI service: $e');
    }
  }
}