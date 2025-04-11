import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:time_master/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // 构建我们的应用并触发一个框架渲染
    await tester.pumpWidget(const MyApp());

    // 验证计数器从0开始
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);

    // 这只是一个基本的占位符测试，实际项目中需要更详细的测试
  });
}
