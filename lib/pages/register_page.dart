import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../widgets/buttons.dart';
import '../widgets/navigation.dart';
import '../services/api_service.dart';

/// 注册页 - 账号密码注册（MD3 风格）
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  String? _confirmError;

  bool get _usernameValid =>
      RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(_usernameCtrl.text.trim());
  bool get _passwordValid =>
      RegExp(r'^[\S]{6,20}$').hasMatch(_passwordCtrl.text);
  bool get _nicknameValid => _nicknameCtrl.text.trim().isNotEmpty;

  bool get _canSubmit =>
      _usernameValid &&
      _passwordValid &&
      _confirmError == null &&
      _nicknameValid &&
      !_loading;

  void _validateConfirm() {
    final pwd = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;
    setState(() {
      _confirmError = confirm.isEmpty || pwd == confirm ? null : '两次输入的密码不一致';
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _loading = true);

    try {
      final result = await AuthApi.register(
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
        nickname: _nicknameCtrl.text.trim(),
      );

      if (!mounted) return;

      if (result.isSuccess) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      } else {
        _showError(result.message);
      }
    } on SocketException {
      if (!mounted) return;
      _showError('网络连接失败，请检查网络后重试');
    } on http.ClientException {
      if (!mounted) return;
      _showError('网络连接失败，请检查网络后重试');
    } on FormatException {
      if (!mounted) return;
      _showError('服务端响应异常，请稍后重试');
    } on ApiResponseFormatException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('注册处理失败，请重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const BackAppBar(title: '注册'),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '创建账号',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '开启你的口袋摄影之旅',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                _buildField(
                  controller: _usernameCtrl,
                  hint: '设置用户名',
                  icon: Icons.person_outline,
                  helper: '3-20 位字母/数字/下划线',
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _passwordCtrl,
                  hint: '设置密码',
                  icon: Icons.lock_outline,
                  obscure: _obscure1,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure1 ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                  ),
                  helper: '6-20 位字符',
                  onChanged: (_) => _validateConfirm(),
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _confirmCtrl,
                  hint: '确认密码',
                  icon: Icons.lock_outline,
                  obscure: _obscure2,
                  errorText: _confirmError,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure2 ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                  ),
                  onChanged: (_) => _validateConfirm(),
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _nicknameCtrl,
                  hint: '设置昵称',
                  icon: Icons.edit_outlined,
                ),
                const SizedBox(height: 32),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                        label: '注 册',
                        onPressed: _canSubmit ? _submit : null,
                        enabled: _canSubmit,
                      ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '已有账号？',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    TextLinkButton(
                      label: '去登录',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? helper,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        helperText: errorText == null ? helper : null,
        errorText: errorText,
      ),
    );
  }
}
