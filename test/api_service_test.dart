import 'package:app/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiResponse', () {
    test('接受数值状态码并保留服务端业务错误信息', () {
      final response = ApiResponse<LoginData>.fromJson(
        {'code': 20001, 'message': '用户名或密码错误', 'data': null},
        LoginData.fromJson,
      );

      expect(response.code, 20001);
      expect(response.message, '用户名或密码错误');
      expect(response.data, isNull);
    });

    test('缺少有效状态码时抛出响应格式异常', () {
      expect(
        () => ApiResponse<LoginData>.fromJson(
          {'message': '操作成功'},
          LoginData.fromJson,
        ),
        throwsA(isA<ApiResponseFormatException>()),
      );
    });
  });

  group('LoginData', () {
    test('接受服务端的数值用户 ID', () {
      final data = LoginData.fromJson({
        'token': 'jwt-token',
        'userId': 3,
        'username': 'demo_user',
        'nickname': '体验用户',
      });

      expect(data.userId, 3);
      expect(data.username, 'demo_user');
    });

    test('缺失登录字段时抛出响应格式异常', () {
      expect(
        () => LoginData.fromJson({'token': 'jwt-token', 'userId': 3}),
        throwsA(isA<ApiResponseFormatException>()),
      );
    });
  });
}
