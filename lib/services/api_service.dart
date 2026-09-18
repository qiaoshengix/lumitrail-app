import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 通过 --dart-define 或本地配置文件注入环境地址；默认不连接真实服务。
/// 地址不带结尾斜杠，开发、测试和生产环境使用同一配置入口。
const String _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.example.invalid',
);

/// 接口响应不符合约定时抛出，避免被界面误认为网络不可用。
class ApiResponseFormatException implements Exception {
  const ApiResponseFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// API 响应结构
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  ApiResponse({required this.code, required this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    final code = json['code'];
    if (code is! num) {
      throw const ApiResponseFormatException('服务端响应缺少有效状态码');
    }

    return ApiResponse(
      code: code.toInt(),
      message: json['message']?.toString() ?? '服务端未返回提示信息',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
    );
  }

  bool get isSuccess => code == 200;
}

/// 登录响应
class LoginData {
  final String token;
  final int userId;
  final String username;
  final String nickname;

  LoginData({
    required this.token,
    required this.userId,
    required this.username,
    required this.nickname,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final userId = json['userId'];
    final username = json['username'];
    final nickname = json['nickname'];

    if (token is! String ||
        userId is! num ||
        username is! String ||
        nickname is! String) {
      throw const ApiResponseFormatException('服务端登录响应字段不完整');
    }

    return LoginData(
      token: token,
      userId: userId.toInt(),
      username: username,
      nickname: nickname,
    );
  }
}

/// 认证 API 服务
class AuthApi {
  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';
  static const _nicknameKey = 'nickname';
  static LoginData? _memoryLoginData;

  // ==================== Token 持久化 ====================

  /// 保存失败时仍保留本次进程的登录态，避免认证成功后被本地存储异常中断。
  static Future<void> _saveLoginData(LoginData data) async {
    _memoryLoginData = data;
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_tokenKey, data.token),
        prefs.setInt(_userIdKey, data.userId),
        prefs.setString(_usernameKey, data.username),
        prefs.setString(_nicknameKey, data.nickname),
      ]);
    } on Object {
      // SharedPreferences 在个别设备不可用时，内存登录态仍可支撑本次使用。
    }
  }

  /// 获取已保存的 Token
  static Future<String?> getToken() async {
    if (_memoryLoginData != null) return _memoryLoginData!.token;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } on Object {
      return null;
    }
  }

  /// 获取已保存的用户 ID
  static Future<int?> getUserId() async {
    if (_memoryLoginData != null) return _memoryLoginData!.userId;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_userIdKey);
    } on Object {
      return null;
    }
  }

  /// 获取已保存的用户名
  static Future<String?> getUsername() async {
    if (_memoryLoginData != null) return _memoryLoginData!.username;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_usernameKey);
    } on Object {
      return null;
    }
  }

  /// 获取已保存的昵称
  static Future<String?> getNickname() async {
    if (_memoryLoginData != null) return _memoryLoginData!.nickname;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_nicknameKey);
    } on Object {
      return null;
    }
  }

  /// 是否已登录
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// 清除登录态
  static Future<void> logout() async {
    _memoryLoginData = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_tokenKey),
        prefs.remove(_userIdKey),
        prefs.remove(_usernameKey),
        prefs.remove(_nicknameKey),
      ]);
    } on Object {
      // 本地存储不可用时，内存中的登录态已清除。
    }
  }

  // ==================== API 请求 ====================

  /// 发送带认证头（可选）的请求
  static Future<http.Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    switch (method) {
      case 'POST':
        return http.post(uri, headers: headers, body: jsonEncode(body));
      case 'GET':
        return http.get(uri, headers: headers);
      default:
        throw ArgumentError('不支持的请求方法: $method');
    }
  }

  static ApiResponse<LoginData> _parseLoginResponse(http.Response response) {
    final responseBody = utf8.decode(response.bodyBytes, allowMalformed: true);
    final jsonStart = responseBody.indexOf('{');
    final jsonEnd = responseBody.lastIndexOf('}');
    if (jsonStart < 0 || jsonEnd < jsonStart) {
      throw const ApiResponseFormatException('服务端未返回登录结果');
    }

    // 部分 Android 网络栈会在响应体前后附加 BOM 或诊断字符；只解析完整 JSON 对象。
    final decoded = jsonDecode(responseBody.substring(jsonStart, jsonEnd + 1));
    if (decoded is! Map<String, dynamic>) {
      throw const ApiResponseFormatException('服务端响应格式错误');
    }
    return ApiResponse<LoginData>.fromJson(decoded, (data) {
      if (data is! Map<String, dynamic>) {
        throw const ApiResponseFormatException('服务端登录数据格式错误');
      }
      return LoginData.fromJson(data);
    });
  }

  // ==================== 认证接口 ====================

  /// 注册
  static Future<ApiResponse<LoginData>> register({
    required String username,
    required String password,
    required String nickname,
  }) async {
    final response = await _request(
      'POST',
      '/api/auth/register',
      body: {'username': username, 'password': password, 'nickname': nickname},
    );

    final apiResponse = _parseLoginResponse(response);

    if (apiResponse.isSuccess && apiResponse.data != null) {
      await _saveLoginData(apiResponse.data!);
    }

    return apiResponse;
  }

  /// 登录
  static Future<ApiResponse<LoginData>> login({
    required String username,
    required String password,
  }) async {
    final response = await _request(
      'POST',
      '/api/auth/login',
      body: {'username': username, 'password': password},
    );

    final apiResponse = _parseLoginResponse(response);

    if (apiResponse.isSuccess && apiResponse.data != null) {
      await _saveLoginData(apiResponse.data!);
    }

    return apiResponse;
  }
}

// ==================== 拍照分析数据模型 ====================

class AnalyzeData {
  final int? analysisId;
  final String? imageUrl;
  final String? sceneType;
  final VisualFeaturesData? visualFeatures;
  final List<PoseItemData>? poses;
  final FilterData? filter;
  final AngleData? angle;
  final String? tip;

  AnalyzeData({
    this.analysisId,
    this.imageUrl,
    this.sceneType,
    this.visualFeatures,
    this.poses,
    this.filter,
    this.angle,
    this.tip,
  });

  factory AnalyzeData.fromJson(Map<String, dynamic> json) {
    return AnalyzeData(
      analysisId: json['analysisId'] as int?,
      imageUrl: json['imageUrl'] as String?,
      sceneType: json['sceneType'] as String?,
      visualFeatures: json['visualFeatures'] != null
          ? VisualFeaturesData.fromJson(
              json['visualFeatures'] as Map<String, dynamic>,
            )
          : null,
      poses: json['poses'] != null
          ? (json['poses'] as List)
                .map((e) => PoseItemData.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      filter: json['filter'] != null
          ? FilterData.fromJson(json['filter'] as Map<String, dynamic>)
          : null,
      angle: json['angle'] != null
          ? AngleData.fromJson(json['angle'] as Map<String, dynamic>)
          : null,
      tip: json['tip'] as String?,
    );
  }
}

/// 视觉 AI 识别的 5 层画面特征
class VisualFeaturesData {
  final LightingFeatureData? lighting;
  final ColorFeatureData? color;
  final CompositionFeatureData? composition;
  final TextureFeatureData? texture;
  final DynamicsFeatureData? dynamics;

  VisualFeaturesData({
    this.lighting,
    this.color,
    this.composition,
    this.texture,
    this.dynamics,
  });

  factory VisualFeaturesData.fromJson(Map<String, dynamic> json) {
    return VisualFeaturesData(
      lighting: json['lighting'] != null
          ? LightingFeatureData.fromJson(
              json['lighting'] as Map<String, dynamic>,
            )
          : null,
      color: json['color'] != null
          ? ColorFeatureData.fromJson(json['color'] as Map<String, dynamic>)
          : null,
      composition: json['composition'] != null
          ? CompositionFeatureData.fromJson(
              json['composition'] as Map<String, dynamic>,
            )
          : null,
      texture: json['texture'] != null
          ? TextureFeatureData.fromJson(json['texture'] as Map<String, dynamic>)
          : null,
      dynamics: json['dynamics'] != null
          ? DynamicsFeatureData.fromJson(
              json['dynamics'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class LightingFeatureData {
  final String? quality;
  final String? direction;
  final String? contrastRatio;
  final String? note;

  LightingFeatureData({
    this.quality,
    this.direction,
    this.contrastRatio,
    this.note,
  });

  factory LightingFeatureData.fromJson(Map<String, dynamic> json) {
    return LightingFeatureData(
      quality: json['quality'] as String?,
      direction: json['direction'] as String?,
      contrastRatio: json['contrastRatio'] as String?,
      note: json['note'] as String?,
    );
  }
}

class ColorFeatureData {
  final String? dominantTone;
  final String? colorRelation;
  final String? saturation;
  final String? note;

  ColorFeatureData({
    this.dominantTone,
    this.colorRelation,
    this.saturation,
    this.note,
  });

  factory ColorFeatureData.fromJson(Map<String, dynamic> json) {
    return ColorFeatureData(
      dominantTone: json['dominantTone'] as String?,
      colorRelation: json['colorRelation'] as String?,
      saturation: json['saturation'] as String?,
      note: json['note'] as String?,
    );
  }
}

class CompositionFeatureData {
  final String? lineForm;
  final String? negativeSpace;
  final String? layering;
  final String? symmetry;
  final String? aspectRatio;
  final String? note;

  CompositionFeatureData({
    this.lineForm,
    this.negativeSpace,
    this.layering,
    this.symmetry,
    this.aspectRatio,
    this.note,
  });

  factory CompositionFeatureData.fromJson(Map<String, dynamic> json) {
    return CompositionFeatureData(
      lineForm: json['lineForm'] as String?,
      negativeSpace: json['negativeSpace'] as String?,
      layering: json['layering'] as String?,
      symmetry: json['symmetry'] as String?,
      aspectRatio: json['aspectRatio'] as String?,
      note: json['note'] as String?,
    );
  }
}

class TextureFeatureData {
  final String? surfaceQuality;
  final String? repetitionPattern;
  final String? note;

  TextureFeatureData({this.surfaceQuality, this.repetitionPattern, this.note});

  factory TextureFeatureData.fromJson(Map<String, dynamic> json) {
    return TextureFeatureData(
      surfaceQuality: json['surfaceQuality'] as String?,
      repetitionPattern: json['repetitionPattern'] as String?,
      note: json['note'] as String?,
    );
  }
}

class DynamicsFeatureData {
  final String? motionElements;
  final String? weather;
  final String? intervention;
  final String? note;

  DynamicsFeatureData({
    this.motionElements,
    this.weather,
    this.intervention,
    this.note,
  });

  factory DynamicsFeatureData.fromJson(Map<String, dynamic> json) {
    return DynamicsFeatureData(
      motionElements: json['motionElements'] as String?,
      weather: json['weather'] as String?,
      intervention: json['intervention'] as String?,
      note: json['note'] as String?,
    );
  }
}

class PoseItemData {
  final String? name;
  final String? description;

  PoseItemData({this.name, this.description});

  factory PoseItemData.fromJson(Map<String, dynamic> json) {
    return PoseItemData(
      name: json['name'] as String?,
      description: json['description'] as String?,
    );
  }
}

class FilterData {
  final String? style;
  final int? temperature;
  final int? saturation;
  final int? contrast;
  final int? brightness;

  FilterData({
    this.style,
    this.temperature,
    this.saturation,
    this.contrast,
    this.brightness,
  });

  factory FilterData.fromJson(Map<String, dynamic> json) {
    return FilterData(
      style: json['style'] as String?,
      temperature: json['temperature'] as int?,
      saturation: json['saturation'] as int?,
      contrast: json['contrast'] as int?,
      brightness: json['brightness'] as int?,
    );
  }
}

class AngleData {
  final String? direction;
  final String? height;
  final String? distance;

  AngleData({this.direction, this.height, this.distance});

  factory AngleData.fromJson(Map<String, dynamic> json) {
    return AngleData(
      direction: json['direction'] as String?,
      height: json['height'] as String?,
      distance: json['distance'] as String?,
    );
  }
}

// ==================== 拍照分析 API ====================

class AnalyzeApi {
  /// 上传图片进行分析（需登录态）
  static Future<ApiResponse<AnalyzeData>> analyze(File imageFile) async {
    final uri = Uri.parse('$_baseUrl/api/analyze');
    final request = http.MultipartRequest('POST', uri);

    final token = await AuthApi.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ApiResponse<AnalyzeData>.fromJson(
      json,
      (data) => AnalyzeData.fromJson(data as Map<String, dynamic>),
    );
  }
}

// ==================== 穿搭推荐数据模型 ====================

class SpotData {
  final int id;
  final String name;
  final String styleTags;
  final String colorTone;
  final String recommendedStyle;
  final String imageUrl;

  SpotData({
    required this.id,
    required this.name,
    required this.styleTags,
    required this.colorTone,
    required this.recommendedStyle,
    required this.imageUrl,
  });

  factory SpotData.fromJson(Map<String, dynamic> json) {
    return SpotData(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      styleTags: json['styleTags'] as String? ?? '',
      colorTone: json['colorTone'] as String? ?? '',
      recommendedStyle: json['recommendedStyle'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }
}

class OutfitRecommendData {
  final String spotName;
  final List<OutfitData> outfits;

  OutfitRecommendData({required this.spotName, required this.outfits});

  factory OutfitRecommendData.fromJson(Map<String, dynamic> json) {
    return OutfitRecommendData(
      spotName: json['spotName'] as String? ?? '',
      outfits: (json['outfits'] as List? ?? [])
          .map((e) => OutfitData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OutfitData {
  final int matchScore;
  final List<OutfitItemData> items;
  final String reason;
  final String photoTip;

  OutfitData({
    required this.matchScore,
    required this.items,
    required this.reason,
    required this.photoTip,
  });

  factory OutfitData.fromJson(Map<String, dynamic> json) {
    return OutfitData(
      matchScore: json['matchScore'] as int? ?? 0,
      items: (json['items'] as List? ?? [])
          .map((e) => OutfitItemData.fromJson(e as Map<String, dynamic>))
          .toList(),
      reason: json['reason'] as String? ?? '',
      photoTip: json['photoTip'] as String? ?? '',
    );
  }
}

class OutfitItemData {
  final String type;
  final String color;
  final String colorHex;

  OutfitItemData({
    required this.type,
    required this.color,
    required this.colorHex,
  });

  factory OutfitItemData.fromJson(Map<String, dynamic> json) {
    return OutfitItemData(
      type: json['type'] as String? ?? '',
      color: json['color'] as String? ?? '',
      colorHex: json['colorHex'] as String? ?? '#000000',
    );
  }
}

// ==================== 穿搭推荐 API ====================

class OutfitApi {
  /// 获取景点列表
  static Future<ApiResponse<List<SpotData>>> getSpots() async {
    final uri = Uri.parse('$_baseUrl/api/outfit/spots');
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = await AuthApi.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.get(uri, headers: headers);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return ApiResponse<List<SpotData>>.fromJson(
      json,
      (data) => (data as List)
          .map((e) => SpotData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// AI 穿搭推荐
  static Future<ApiResponse<OutfitRecommendData>> recommend({
    required int spotId,
    required List<Map<String, String>> wardrobe,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/outfit/recommend');
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = await AuthApi.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({'spotId': spotId, 'wardrobe': wardrobe}),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ApiResponse<OutfitRecommendData>.fromJson(
      json,
      (data) => OutfitRecommendData.fromJson(data as Map<String, dynamic>),
    );
  }
}
