import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/cards.dart';

/// 拍照分析结果视图 - MD3 TabBar 切换（构图/姿势/滤镜/角度）
class AnalyzeResultView extends StatefulWidget {
  const AnalyzeResultView({
    super.key,
    this.imageFile,
    this.analyzeData,
    required this.onBack,
  });

  final File? imageFile;
  final AnalyzeData? analyzeData;
  final VoidCallback onBack;

  @override
  State<AnalyzeResultView> createState() => _AnalyzeResultViewState();
}

class _AnalyzeResultViewState extends State<AnalyzeResultView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl = TabController(length: 4, vsync: this);
  static const _tabs = ['画面特征', '姿势', '滤镜', '角度'];

  String get _sceneName {
    switch (widget.analyzeData?.sceneType) {
      case 'mountain':
        return '山景';
      case 'sea':
        return '海边';
      case 'street':
        return '街景';
      case 'building':
        return '建筑';
      case 'park':
        return '公园';
      case 'indoor':
        return '室内';
      default:
        return widget.analyzeData?.sceneType ?? '未知场景';
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.analyzeData;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPhotoPreview(),
          const SizedBox(height: 16),
          _buildSceneTag(),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabCtrl,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _tabCtrl,
            builder: (_, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: AppCard(
                  key: ValueKey(_tabCtrl.index),
                  child: switch (_tabCtrl.index) {
                    0 => _buildVisualFeatures(data?.visualFeatures),
                    1 => _buildPose(data?.poses),
                    2 => _buildFilter(data?.filter),
                    _ => _buildAngle(data?.angle),
                  },
                ),
              );
            },
          ),
          if (data?.tip != null && data!.tip!.isNotEmpty) ...[
            const SizedBox(height: 16),
            TipBlock(title: '小贴士', text: data.tip!),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoPreview() {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        color: scheme.surfaceContainerHighest,
        child: widget.imageFile != null
            ? Image.file(
                widget.imageFile!,
                fit: BoxFit.cover,
                width: double.infinity,
              )
            : Center(child: Icon(Icons.image, color: scheme.outline, size: 40)),
      ),
    );
  }

  Widget _buildSceneTag() {
    return Row(
      children: [
        Icon(
          Icons.place,
          color: Theme.of(context).colorScheme.primary,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          '场景：$_sceneName',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        SceneTag(label: _sceneName, solid: true),
      ],
    );
  }

  Widget _buildVisualFeatures(VisualFeaturesData? vf) {
    if (vf == null) return _emptyTab('暂无画面特征数据');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FeatureSection(
          icon: Icons.wb_sunny_outlined,
          title: '光线',
          items: [
            ('光质', vf.lighting?.quality),
            ('光向', vf.lighting?.direction),
            ('光比', vf.lighting?.contrastRatio),
          ],
          note: vf.lighting?.note,
        ),
        _FeatureSection(
          icon: Icons.palette_outlined,
          title: '色彩',
          items: [
            ('主色调', vf.color?.dominantTone),
            ('色彩关系', vf.color?.colorRelation),
            ('饱和度', vf.color?.saturation),
          ],
          note: vf.color?.note,
        ),
        _FeatureSection(
          icon: Icons.grid_on_outlined,
          title: '构图',
          items: [
            ('线条', vf.composition?.lineForm),
            ('负空间', vf.composition?.negativeSpace),
            ('层次', vf.composition?.layering),
            ('对称性', vf.composition?.symmetry),
            ('画面比例', vf.composition?.aspectRatio),
          ],
          note: vf.composition?.note,
        ),
        _FeatureSection(
          icon: Icons.texture_outlined,
          title: '纹理',
          items: [
            ('质感', vf.texture?.surfaceQuality),
            ('重复图案', vf.texture?.repetitionPattern),
          ],
          note: vf.texture?.note,
        ),
        _FeatureSection(
          icon: Icons.air_outlined,
          title: '动态',
          items: [
            ('动态元素', vf.dynamics?.motionElements),
            ('天气', vf.dynamics?.weather),
            ('可干预性', vf.dynamics?.intervention),
          ],
          note: vf.dynamics?.note,
        ),
      ],
    );
  }

  Widget _buildPose(List<PoseItemData>? poses) {
    if (poses == null || poses.isEmpty) return _emptyTab('暂无姿势数据');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('推荐姿势'),
        const SizedBox(height: 12),
        ...poses.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (p.description != null)
                        Text(
                          p.description!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilter(FilterData? filter) {
    if (filter == null) return _emptyTab('暂无滤镜数据');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('滤镜风格：${filter.style ?? "自动"}'),
        const SizedBox(height: 12),
        _buildParam('色温', filter.temperature),
        _buildParam('饱和度', filter.saturation),
        _buildParam('对比度', filter.contrast),
        _buildParam('亮度', filter.brightness),
      ],
    );
  }

  Widget _buildAngle(AngleData? angle) {
    if (angle == null) return _emptyTab('暂无角度数据');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('拍摄方向：${angle.direction ?? "自动"}'),
        const SizedBox(height: 12),
        _buildParam('手机高度', angle.height),
        _buildParam('拍摄距离', angle.distance),
      ],
    );
  }

  Widget _buildParam(String key, dynamic value) {
    final valStr = value is int
        ? (value >= 0 ? '+$value' : '$value')
        : (value?.toString() ?? '--');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            valStr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyTab(String text) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

/// 画面特征分层展示组件
class _FeatureSection extends StatelessWidget {
  const _FeatureSection({
    required this.icon,
    required this.title,
    required this.items,
    this.note,
  });

  final IconData icon;
  final String title;
  final List<(String, String?)> items;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasAny = items.any((it) => it.$2 != null && it.$2!.isNotEmpty);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (hasAny) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: items
                  .where((it) => it.$2 != null && it.$2!.isNotEmpty)
                  .map((it) => _FeatureChip(label: it.$1, value: it.$2!))
                  .toList(),
            ),
          ],
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              note!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label：',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
