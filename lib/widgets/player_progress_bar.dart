import 'package:flutter/material.dart';
import '../config/theme.dart';

/// A visual progress bar showing "X / Y Players Joined".
/// Color transitions: red → amber → neon green as players fill up.
class PlayerProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const PlayerProgressBar({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text label
        Row(
          children: [
            Text(
              '$current / $total',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _progressColor(progress),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'players joined for Sunday',
              style: const TextStyle(
                fontSize: 13,
                color: HaaahTheme.textSecondary,
              ),
            ),
            const Spacer(),
            if (current < total)
              Text(
                '${total - current} spots left',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _progressColor(progress),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: HaaahTheme.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(_progressColor(progress)),
          ),
        ),
      ],
    );
  }

  Color _progressColor(double progress) {
    if (progress >= 1.0) return HaaahTheme.neonGreen;
    if (progress >= 0.5) return HaaahTheme.amber;
    return HaaahTheme.red;
  }
}
