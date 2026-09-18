import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/navigation.dart';
import 'outfit_views.dart';

/// 智能穿搭推荐 - 三阶段流程（MD3 风格）
/// 阶段一：选择景点  →  阶段二：衣橱录入  →  阶段三：推荐结果
class OutfitPage extends StatefulWidget {
  const OutfitPage({super.key});

  @override
  State<OutfitPage> createState() => _OutfitPageState();
}

class _OutfitPageState extends State<OutfitPage> {
  int _phase = 0;

  SpotData? _selectedSpot;
  final List<Map<String, String>> _wardrobe = [];

  OutfitRecommendData? _result;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSpots();
  }

  List<SpotData> _spots = [];

  Future<void> _loadSpots() async {
    try {
      final result = await OutfitApi.getSpots();
      if (mounted && result.isSuccess && result.data != null) {
        setState(() => _spots = result.data!);
      }
    } catch (_) {}
  }

  Future<void> _submitRecommend() async {
    if (_selectedSpot == null || _wardrobe.isEmpty) return;
    setState(() => _loading = true);

    try {
      final result = await OutfitApi.recommend(
        spotId: _selectedSpot!.id,
        wardrobe: _wardrobe,
      );

      if (!mounted) return;

      if (result.isSuccess && result.data != null) {
        setState(() {
          _result = result.data;
          _phase = 2;
        });
      } else {
        _showError(result.message);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('网络连接失败，请检查网络后重试');
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

  void _reset() => setState(() {
        _selectedSpot = null;
        _wardrobe.clear();
        _result = null;
        _phase = 0;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TitleAppBar(title: _phase == 2 ? '穿搭方案' : '智能穿搭',),
      body: switch (_phase) {
        0 => SpotSelectView(
            spots: _spots,
            selectedSpot: _selectedSpot,
            onSelect: (s) => setState(() => _selectedSpot = s),
            onNext: _selectedSpot != null
                ? () => setState(() => _phase = 1)
                : null,
          ),
        1 => WardrobeView(
            wardrobe: _wardrobe,
            loading: _loading,
            onSubmit: _submitRecommend,
            onBack: () => setState(() => _phase = 0),
          ),
        _ => OutfitResultView(
            result: _result,
            onBack: _reset,
          ),
      },
    );
  }
}