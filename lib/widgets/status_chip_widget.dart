/// CapitalFlow — IPO Status Chip Widget
///
/// Standalone widget. Uses MOCK data only.
/// No imports from the full app's services, repositories, or models.
///
/// Shows a pill-shaped status badge with appropriate color and icon
/// for: Live · Upcoming · Closed · Listed · Archived
library capitalflow_status_chip;

import 'package:flutter/material.dart';
import 'theme_tokens.dart';

// ── Status Enum ───────────────────────────────────────────────────────────────

enum IpoStatus {
  live,
  upcoming,
  closed,
  listed,
  archived,
}

extension IpoStatusX on IpoStatus {
  String get label {
    switch (this) {
      case IpoStatus.live:     return 'Live';
      case IpoStatus.upcoming: return 'Upcoming';
      case IpoStatus.closed:   return 'Closed';
      case IpoStatus.listed:   return 'Listed';
      case IpoStatus.archived: return 'Archived';
    }
  }

  Color get color {
    switch (this) {
      case IpoStatus.live:     return CFColors.statusLive;
      case IpoStatus.upcoming: return CFColors.statusUpcoming;
      case IpoStatus.closed:   return CFColors.statusClosed;
      case IpoStatus.listed:   return CFColors.statusListed;
      case IpoStatus.archived: return CFColors.textDisabled;
    }
  }

  IconData get icon {
    switch (this) {
      case IpoStatus.live:     return Icons.radio_button_checked_rounded;
      case IpoStatus.upcoming: return Icons.schedule_rounded;
      case IpoStatus.closed:   return Icons.lock_outline_rounded;
      case IpoStatus.listed:   return Icons.trending_up_rounded;
      case IpoStatus.archived: return Icons.archive_outlined;
    }
  }

  bool get isPulsing => this == IpoStatus.live;
}

// ── Status Chip Widget ────────────────────────────────────────────────────────

class IpoStatusChip extends StatefulWidget {
  const IpoStatusChip({
    super.key,
    required this.status,
    this.size = ChipSize.medium,
    this.showIcon = true,
  });

  final IpoStatus status;
  final ChipSize size;
  final bool showIcon;

  @override
  State<IpoStatusChip> createState() => _IpoStatusChipState();
}

enum ChipSize { small, medium, large }

class _IpoStatusChipState extends State<IpoStatusChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.35).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    if (widget.status.isPulsing) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(IpoStatusChip old) {
    super.didUpdateWidget(old);
    if (widget.status.isPulsing && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.status.isPulsing && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color   = widget.status.color;
    final label   = widget.status.label;
    final icon    = widget.status.icon;

    final (double fontSize, double iconSize, double h, double hPad) =
        switch (widget.size) {
      ChipSize.small  => (10.0, 10.0, 20.0, 6.0),
      ChipSize.medium => (11.0, 12.0, 24.0, 8.0),
      ChipSize.large  => (13.0, 14.0, 28.0, 10.0),
    };

    Widget chip = Container(
      height: h,
      padding: EdgeInsets.symmetric(horizontal: hPad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(CFRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.75),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon) ...[
            Icon(icon, size: iconSize, color: color),
            SizedBox(width: hPad * 0.5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (widget.status.isPulsing) {
      chip = AnimatedBuilder(
        animation: _opacity,
        builder: (_, child) => Opacity(opacity: _opacity.value, child: child),
        child: chip,
      );
    }

    return chip;
  }
}

// ── Change Badge ──────────────────────────────────────────────────────────────

/// Shows a gain/loss percentage change badge. e.g. "+12.4%" in green or "-3.2%" in red.
class ChangeBadge extends StatelessWidget {
  const ChangeBadge({
    super.key,
    required this.change,
    this.suffix = '%',
    this.compact = false,
  });

  final double change;
  final String suffix;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isGain = change >= 0;
    final color  = isGain ? CFColors.gain : CFColors.loss;
    final sign   = isGain ? '+' : '';
    final label  = '$sign${change.toStringAsFixed(compact ? 1 : 2)}$suffix';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(CFRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Demo / Showcase Preview ───────────────────────────────────────────────────

/// Run this widget standalone to preview all chip states.
class StatusChipShowcase extends StatelessWidget {
  const StatusChipShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CFColors.background,
      body: Padding(
        padding: const EdgeInsets.all(CFSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IPO Status Chips', style: CFTextStyles.headingLarge),
            const SizedBox(height: CFSpacing.xl),
            Wrap(
              spacing: CFSpacing.md,
              runSpacing: CFSpacing.md,
              children: [
                for (final status in IpoStatus.values) ...[
                  IpoStatusChip(status: status, size: ChipSize.small),
                  IpoStatusChip(status: status, size: ChipSize.medium),
                  IpoStatusChip(status: status, size: ChipSize.large),
                ],
              ],
            ),
            const SizedBox(height: CFSpacing.xl),
            Text('Change Badges', style: CFTextStyles.headingLarge),
            const SizedBox(height: CFSpacing.lg),
            Wrap(
              spacing: CFSpacing.md,
              runSpacing: CFSpacing.md,
              children: const [
                ChangeBadge(change: 12.45),
                ChangeBadge(change: -3.20),
                ChangeBadge(change: 0.0),
                ChangeBadge(change: 66.62, suffix: 'x'),
                ChangeBadge(change: -0.85, compact: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
