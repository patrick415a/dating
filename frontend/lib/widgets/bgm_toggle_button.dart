import 'package:flutter/material.dart';

import '../services/bgm_player.dart';
import '../theme/app_theme.dart';

class BgmToggleButton extends StatelessWidget {
  const BgmToggleButton({super.key});

  Future<void> _toggle(BuildContext context) async {
    try {
      await BgmPlayer().toggleBgm();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('음악을 제어할 수 없습니다. 다시 시도해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = BgmPlayer();
    return ListenableBuilder(
      listenable: player,
      builder: (context, child) => IconButton(
        tooltip: player.isPlaying ? '음악 일시정지' : '음악 재생',
        onPressed: player.isBusy ? null : () => _toggle(context),
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: AppColors.primarySoft,
          foregroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primarySoft,
          disabledForegroundColor: AppColors.muted,
        ),
        icon: Icon(
          player.isPlaying ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          size: 20,
        ),
      ),
    );
  }
}
