import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';

// ==================== 阶段一：景点选择 ====================

class SpotSelectView extends StatelessWidget {
  final List<SpotData> spots;
  final SpotData? selectedSpot;
  final ValueChanged<SpotData> onSelect;
  final VoidCallback? onNext;

  const SpotSelectView({
    super.key,
    required this.spots,
    required this.selectedSpot,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '选择你要去的景点',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'AI 将根据景点风格推荐穿搭',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          if (spots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ...List.generate(spots.length, (i) {
              final spot = spots[i];
              final selected = selectedSpot?.id == spot.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => onSelect(spot),
                  child: _SpotCard(
                    spot: spot,
                    selected: selected,
                  ),
                ),
              );
            }),
          const SizedBox(height: 16),
          PrimaryButton(
            label: '下一步：录入衣橱',
            icon: Icons.arrow_forward,
            onPressed: onNext,
            enabled: onNext != null,
          ),
        ],
      ),
    );
  }
}

class _SpotCard extends StatelessWidget {
  final SpotData spot;
  final bool selected;

  const _SpotCard({required this.spot, required this.selected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.5)
            : scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _getSpotColor(spot.name),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getSpotIcon(spot.name),
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                if (spot.styleTags.isNotEmpty)
                  Text(
                    spot.styleTags,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                if (spot.colorTone.isNotEmpty)
                  Text(
                    spot.colorTone,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                        ),
                  ),
              ],
            ),
          ),
          if (selected)
            Icon(Icons.check_circle, color: scheme.primary, size: 24),
        ],
      ),
    );
  }

  Color _getSpotColor(String name) {
    switch (name) {
      case '海边':
        return const Color(0xFF0288D1);
      case '公园':
        return const Color(0xFF43A047);
      case '古镇':
        return const Color(0xFF8D6E63);
      case '都市':
        return const Color(0xFF5C6BC0);
      case '山景':
        return const Color(0xFF6D4C41);
      default:
        return const Color(0xFF78909C);
    }
  }

  IconData _getSpotIcon(String name) {
    switch (name) {
      case '海边':
        return Icons.beach_access;
      case '公园':
        return Icons.park;
      case '古镇':
        return Icons.church;
      case '都市':
        return Icons.apartment;
      case '山景':
        return Icons.landscape;
      default:
        return Icons.place;
    }
  }
}

// ==================== 阶段二：衣橱录入 ====================

const _typeOptions = ['上衣', '下装', '外套', '配饰'];
const _colorOptions = {
  '黑': '0xFF000000',
  '白': '0xFFFFFFFF',
  '灰': '0xFF9E9E9E',
  '红': '0xFFE53935',
  '蓝': '0xFF1E88E5',
  '绿': '0xFF43A047',
  '黄': '0xFFFDD835',
  '紫': '0xFF8E24AA',
  '粉': '0xFFEC407A',
  '棕': '0xFF795548',
  '橙': '0xFFFB8C00',
  '牛仔蓝': '0xFF1565C0',
};

class WardrobeView extends StatefulWidget {
  final List<Map<String, String>> wardrobe;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const WardrobeView({
    super.key,
    required this.wardrobe,
    required this.loading,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  State<WardrobeView> createState() => _WardrobeViewState();
}

class _WardrobeViewState extends State<WardrobeView> {
  String _selectedType = _typeOptions[0];
  String _selectedColor = _colorOptions.keys.first;

  bool get _canSubmit => widget.wardrobe.isNotEmpty && !widget.loading;

  void _addItem() {
    setState(() {
      widget.wardrobe.add({
        'type': _selectedType,
        'color': _selectedColor,
      });
    });
  }

  void _removeItem(int index) {
    setState(() => widget.wardrobe.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '录入你的衣橱',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '选择你今天可穿的衣服颜色',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          _buildTypeSelector(),
          const SizedBox(height: 16),
          _buildColorGrid(),
          const SizedBox(height: 16),
          PrimaryButton(
            label: '添加衣物',
            icon: Icons.add,
            onPressed: _addItem,
            enabled: true,
          ),
          const SizedBox(height: 20),
          if (widget.wardrobe.isNotEmpty) ...[
            const SectionHeader(title: '已添加'),
            const SizedBox(height: 8),
            ...List.generate(widget.wardrobe.length, (i) {
              final item = widget.wardrobe[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(
                                int.parse(_colorOptions[item['color']]!)),
                            borderRadius: BorderRadius.circular(8),
                            border: item['color'] == '白'
                                ? Border.all(
                                    color: scheme.outlineVariant, width: 1)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item['type'] ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          item['color'] ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _removeItem(i),
                          child: Icon(Icons.close,
                              color: scheme.outline, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
          if (widget.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else
            PrimaryButton(
              label: '开始推荐',
              icon: Icons.auto_awesome,
              onPressed: _canSubmit ? widget.onSubmit : null,
              enabled: _canSubmit,
            ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: '上一步',
            icon: Icons.arrow_back,
            onPressed: widget.onBack,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _typeOptions.map((type) {
        final selected = _selectedType == type;
        final scheme = Theme.of(context).colorScheme;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: selected
                  ? Border.all(color: scheme.primary, width: 1.5)
                  : null,
            ),
            child: Text(
              type,
              style: TextStyle(
                color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _colorOptions.entries.map((entry) {
        final selected = _selectedColor == entry.key;
        final color = Color(int.parse(entry.value));
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = entry.key),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: entry.key == '白' || entry.key == '黄'
                        ? Colors.grey.shade300
                        : (selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent),
                    width: selected ? 3 : 1,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.key,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ==================== 阶段三：推荐结果 ====================

class OutfitResultView extends StatelessWidget {
  final OutfitRecommendData? result;
  final VoidCallback onBack;

  const OutfitResultView({
    super.key,
    required this.result,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outfits = result?.outfits ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            result?.spotName ?? '穿搭方案',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'AI 为你推荐了 ${outfits.length} 套穿搭',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          ...List.generate(outfits.length, (i) {
            final outfit = outfits[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _OutfitResultCard(
                index: i,
                outfit: outfit,
              ),
            );
          }),
          const SizedBox(height: 16),
          PrimaryButton(
            label: '重新推荐',
            icon: Icons.refresh,
            onPressed: onBack,
          ),
        ],
      ),
    );
  }
}

class _OutfitResultCard extends StatelessWidget {
  final int index;
  final OutfitData outfit;

  const _OutfitResultCard({required this.index, required this.outfit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '方案 ${index + 1}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Spacer(),
                _MatchScore(score: outfit.matchScore),
              ],
            ),
            const SizedBox(height: 16),
            ...outfit.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _parseColor(item.colorHex),
                          borderRadius: BorderRadius.circular(8),
                          border: _isLightColor(item.colorHex)
                              ? Border.all(
                                  color: scheme.outlineVariant, width: 1)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.type,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.color,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                )),
            const Divider(height: 24),
            if (outfit.reason.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates,
                      color: scheme.tertiary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      outfit.reason,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (outfit.photoTip.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.camera_alt,
                      color: scheme.tertiary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      outfit.photoTip,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  bool _isLightColor(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      final r = int.parse(h.substring(0, 2), radix: 16);
      final g = int.parse(h.substring(2, 4), radix: 16);
      final b = int.parse(h.substring(4, 6), radix: 16);
      return (r * 0.299 + g * 0.587 + b * 0.114) > 200;
    } catch (_) {
      return false;
    }
  }
}

class _MatchScore extends StatelessWidget {
  final int score;
  const _MatchScore({required this.score});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = score >= 80
        ? const Color(0xFF4CAF50)
        : score >= 60
            ? Colors.orange
            : scheme.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$score',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          '分',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
              ),
        ),
      ],
    );
  }
}