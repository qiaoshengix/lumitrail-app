import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/pages/analyze_page.dart';
import 'package:app/pages/main_shell.dart';

void main() {
  testWidgets(
      'AnalyzePage upload 阶段 AppBar 标题为拍照分析且无返回按钮',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AnalyzePage())),
    );
    await tester.pump();

    expect(find.text('拍照分析'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
  });

  testWidgets('结果阶段 AppBar 显示返回按钮与标题分析结果', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AnalyzePage())),
    );
    await tester.pump();

    final state = tester.state<AnalyzePageState>(find.byType(AnalyzePage));
    state.enterResultPhaseForTest();
    await tester.pump();

    expect(find.text('分析结果'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
  });

  testWidgets('点击返回按钮回到上传阶段', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AnalyzePage())),
    );
    await tester.pump();

    final state = tester.state<AnalyzePageState>(find.byType(AnalyzePage));
    state.enterResultPhaseForTest();
    await tester.pump();

    expect(find.text('分析结果'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('拍照分析'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
  });

  testWidgets('结果阶段 PopScope canPop 为 false 拦截系统返回键', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AnalyzePage())),
    );
    await tester.pump();

    expect(
      tester.widget<PopScope>(find.byType(PopScope)).canPop,
      isTrue,
    );

    final state = tester.state<AnalyzePageState>(find.byType(AnalyzePage));
    state.enterResultPhaseForTest();
    await tester.pump();

    expect(
      tester.widget<PopScope>(find.byType(PopScope)).canPop,
      isFalse,
    );
  });

  testWidgets('切换标签离开拍照页时重置分析结果阶段', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MainShell()),
    );
    await tester.pump();

    // 进入结果阶段
    final state = tester.state<AnalyzePageState>(find.byType(AnalyzePage));
    state.enterResultPhaseForTest();
    await tester.pump();

    expect(find.text('分析结果'), findsOneWidget);

    // 切换到穿搭标签
    await tester.tap(find.text('穿搭'));
    await tester.pumpAndSettle();

    // 切回拍照标签
    await tester.tap(find.text('拍照'));
    await tester.pumpAndSettle();

    // 应显示上传阶段标题，而非分析结果
    expect(find.text('拍照分析'), findsOneWidget);
    expect(find.text('分析结果'), findsNothing);
  });
}
