import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/buttons.dart';
import '../widgets/navigation.dart';
import '../services/api_service.dart';
import 'analyze_result_page.dart';

/// 拍照分析页 - 上传 / 分析中 / 分析结果 三态（MD3 风格）
class AnalyzePage extends StatefulWidget {
  const AnalyzePage({super.key});

  @override
  State<AnalyzePage> createState() => AnalyzePageState();
}

enum _Phase { upload, loading, result }

class AnalyzePageState extends State<AnalyzePage> {
  _Phase _phase = _Phase.upload;
  File? _imageFile;
  AnalyzeData? _analyzeData;

  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      setState(() {
        _imageFile = File(picked.path);
        _phase = _Phase.loading;
      });

      // 调用后端 API
      final result = await AnalyzeApi.analyze(_imageFile!);

      if (!mounted) return;

      if (result.isSuccess && result.data != null) {
        setState(() {
          _analyzeData = result.data;
          _phase = _Phase.result;
        });
      } else {
        setState(() {
          _phase = _Phase.upload;
        });
        _showError(result.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.upload;
      });
      _showError('网络连接失败，请检查网络后重试');
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

  void _reset() => setState(() {
    _imageFile = null;
    _analyzeData = null;
    _phase = _Phase.upload;
  });

  /// 重置到上传阶段（供 MainShell 切换标签时调用）
  void resetPhase() => _reset();

  @visibleForTesting
  void enterResultPhaseForTest({File? imageFile, AnalyzeData? analyzeData}) {
    setState(() {
      _imageFile = imageFile;
      _analyzeData = analyzeData;
      _phase = _Phase.result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase != _Phase.result,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _reset();
      },
      child: Scaffold(
        appBar: switch (_phase) {
          _Phase.result => AppBar(
            leading: IconButton(
              onPressed: _reset,
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
            title: const Text('分析结果'),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          _ => const TitleAppBar(title: '拍照分析'),
        },
        body: switch (_phase) {
          _Phase.upload => _UploadView(
            onPickGallery: () => _pickImage(ImageSource.gallery),
            onPickCamera: () => _pickImage(ImageSource.camera),
          ),
          _Phase.loading => _LoadingView(imageFile: _imageFile),
          _Phase.result => AnalyzeResultView(
            imageFile: _imageFile,
            analyzeData: _analyzeData,
            onBack: _reset,
          ),
        },
      ),
    );
  }
}

/// 上传视图
class _UploadView extends StatelessWidget {
  const _UploadView({required this.onPickGallery, required this.onPickCamera});
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UploadZone(onTap: onPickGallery),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: '相册',
                  icon: Icons.photo_outlined,
                  onPressed: onPickGallery,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SecondaryButton(
                  label: '拍摄',
                  icon: Icons.camera_alt_outlined,
                  onPressed: onPickCamera,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadZone extends StatelessWidget {
  const _UploadZone({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                color: scheme.onPrimaryContainer,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '上传照片',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'AI 将分析最佳构图',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// 分析中视图
///
/// 2 分钟匀速进度条 + 阶段提示。AI 实际响应可能比 2 分钟快或慢:
///   - 快于 2 分钟:_LoadingView 被 unmount,进度条自然消失
///   - 慢于 2 分钟:进度条停在 100%,继续显示"AI 仍在处理中..."文案
class _LoadingView extends StatefulWidget {
  const _LoadingView({this.imageFile});
  final File? imageFile;

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _step = 0;
  static const _steps = ['场景识别', '构图分析', '姿势匹配', '滤镜推荐'];
  static const _totalDuration = Duration(seconds: 120);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _totalDuration,
    )..forward();
    _advance();
  }

  Future<void> _advance() async {
    // 4 个阶段,每个 30 秒,与进度条同步
    for (var i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return;
      setState(() => _step = i + 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: widget.imageFile != null
                  ? Image.file(widget.imageFile!, fit: BoxFit.cover)
                  : Container(color: scheme.surfaceContainerHighest),
            ),
          ),
          const SizedBox(height: 24),
          // 2 分钟线性进度条
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = _controller.value;
              final elapsed = (progress * 120).round();
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          progress >= 1.0
                              ? 'AI 仍在处理中，请稍候...'
                              : 'AI 正在分析中... 由于 demo 阶段，资金有限，模型较小，耗时较长',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                      Text(
                        '${elapsed}s / 120s',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.outline,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          ...List.generate(_steps.length, (i) {
            final done = i < _step;
            final current = i == _step;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _StepDot(done: done, current: current),
                  const SizedBox(width: 12),
                  Text(
                    _steps[i],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: done || current
                          ? scheme.onSurface
                          : scheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.done, required this.current});
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (done) {
      return Icon(Icons.check_circle, color: scheme.primary, size: 22);
    }
    if (current) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: scheme.primary, width: 2),
        ),
        child: Center(
          child: SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(
              color: scheme.primary,
              strokeWidth: 1.5,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outline, width: 1.5),
      ),
    );
  }
}
