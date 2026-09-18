import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/main.dart';
import 'package:app/pages/main_shell.dart';
import 'package:app/pages/login_page.dart';

void main() {
  setUp(() {
    // 防止 SharedPreferences 命中未 mock 的 MethodChannel
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MainApp 启动时显示 loading 占位', (tester) async {
    await tester.pumpWidget(const MainApp());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('已登录时启动直接进入主页', (tester) async {
    SharedPreferences.setMockInitialValues({'jwt_token': 'fake_token'});

    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('未登录时启动显示登录页', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);
  });
}
