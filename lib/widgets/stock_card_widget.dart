/// CapitalFlow — Scanner Stock Card Widget
///
/// Standalone widget. Uses MOCK data structs defined in this file.
/// No imports from the full app. No real service/API calls.
///
/// Demonstrates: glassmorphism card design, responsive layout,
/// micro-animations on tap, multi-condition match badges.
library capitalflow_stock_card;

import 'package:flutter/material.dart';
import 'theme_tokens.dart';
import 'status_chip_widget.dart';

// ── Mock Data Model ───────────────────────────────────────────────────────────

/// Self-contained mock model — NOT from the real app.
class MockScanResult {
  const MockScanResult({
    required this.symbol,
    required this.companyName,
    required this.exchange,
    required this.lastPrice,
    required this.changePercent,
    required this.volume,
    required this.avgVolume,
    required this.matchedConditions,
    this.rsi,
    this.sector,
  });

  final String symbol;
  final String companyName;
  final String exchange;
  final double lastPrice;
  final double changePercent;
  final int volume;
  final int avgVolume;
  final List<String> matchedConditions;
  final double? rsi;
  final String? sector;

  double get volumeMultiple => avgVolume > 0 ? volume / avgVolume : 0;
  bool get isGain => changePercent >= 0;
}

/// Mock dataset — realistic NSE stock data for showcase purposes.
const List<MockScanResult> kMockScanResults = [
  MockScanResult(
    symbol: 'RELIANCE',
    companyName: 'Reliance Industries Ltd',
    exchange: 'NSE',
    lastPrice: 2847.35,
    changePercent: 2.14,
    volume: 8_430_000,
    avgVolume: 3_200_000,
    matchedConditions: ['RSI Oversold Recovery', 'Volume Surge 2x+', 'EMA 20 Cross'],
    rsi: 34.2,
    sector: 'Energy',
  ),
  MockScanResult(
    symbol: 'HDFCBANK',
    companyName: 'HDFC Bank Limited',
    exchange: 'NSE',
    lastPrice: 1723.80,
    changePercent: -0.87,
    volume: 5_120_000,
    avgVolume: 4_800_000,
    matchedConditions: ['Near 52W High', 'Bullish Engulfing'],
    rsi: 61.8,
    sector: 'Banking',
  ),
  MockScanResult(
    symbol: 'INFY',
    companyName: 'Infosys Limited',
    exchange: 'NSE',
    lastPrice: 1894.15,
    changePercent: 3.62,
    volume: 12_800_000,
    avgVolume: 5_500_000,
    matchedConditions: ['Volume Surge 2x+', 'Breakout Above Resistance', 'MACD Crossover'],
    rsi: 72.4,
    sector: 'IT',
  ),
  MockScanResult(
    symbol: 'TATASTEEL',
    companyName: 'Tata Steel Ltd',
    exchange: 'NSE',
    lastPrice: 142.60,
    changePercent: -1.23,
    volume: 22_400_000,
    avgVolume: 18_000_000,
    matchedConditions: ['RSI Oversold Recovery'],
    rsi: 28.9,
    sector: 'Metals',
  ),
];

// ── Stock Card Widget ─────────────────────────────────────────────────────────

class ScannerStockCard extends StatefulWidget {
  const ScannerStockCard({
    super.key,
    required this.result,
    this.onTap,
    this.rank,
  });

  final MockScanResult result;
  final VoidCallback? onTap;
  final int? rank;

  @override
  State<ScannerStockCard> createState() => _ScannerStockCardState();
}

class _ScannerStockCardState extends State<ScannerStockCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scale;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.975).animate(
      CurvedAnimation(parent: _scale, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _scale.forward();
  void _onTapUp(_)   { _scale.reverse(); widget.onTap?.call(); }
  void _onTapCancel() => _scale.reverse();

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final changeColor = r.isGain ? CFColors.gain : CFColors.loss;
    final changeSign  = r.isGain ? '+' : '';

    return GestureDetector(
      onTapDown:   _onTapDown,
      onTapUp:     _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: CFSpacing.xs),
          decoration: BoxDecoration(
            color: CFColors.surface,
            borderRadius: CFRadius.lgAll,
            border: Border.all(color: CFColors.outline, width: 0.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(r, changeColor, changeSign),
              const Divider(height: 1, color: CFColors.outline, thickness: 0.5),
              _buildConditionBadges(r.matchedConditions),
              _buildFooter(r),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MockScanResult r, Color changeColor, String sign) {
    return Padding(
      padding: const EdgeInsets.all(CFSpacing.lg),
      child: Row(
        children: [
          // Rank badge
          if (widget.rank != null) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: CFColors.brandBlue.withValues(alpha: 0.15),
                borderRadius: CFRadius.smAll,
              ),
              alignment: Alignment.center,
              child: Text(
                '#${widget.rank}',
                style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: CFColors.brandBlueLight,
                ),
              ),
            ),
            const SizedBox(width: CFSpacing.md),
          ],

          // Symbol avatar
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: CFColors.brandBlue.withValues(alpha: 0.1),
              borderRadius: CFRadius.smAll,
            ),
            alignment: Alignment.center,
            child: Text(
              r.symbol.substring(0, r.symbol.length.clamp(0, 3)),
              style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: CFColors.brandBlueLight,
              ),
            ),
          ),
          const SizedBox(width: CFSpacing.md),

          // Company name + exchange
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.symbol, style: CFTextStyles.headingSmall),
                const SizedBox(height: 2),
                Text(
                  r.companyName,
                  style: CFTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Price + change
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${r.lastPrice.toStringAsFixed(2)}',
                style: CFTextStyles.monoPrimary,
              ),
              const SizedBox(height: 3),
              ChangeBadge(change: r.changePercent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionBadges(List<String> conditions) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CFSpacing.lg, vertical: CFSpacing.sm,
      ),
      child: Wrap(
        spacing: CFSpacing.xs,
        runSpacing: CFSpacing.xs,
        children: conditions
            .map((c) => _ConditionBadge(label: c))
            .toList(),
      ),
    );
  }

  Widget _buildFooter(MockScanResult r) {
    final volMultiple = r.volumeMultiple;
    final volColor = volMultiple >= 2
        ? CFColors.gain
        : volMultiple >= 1.5
            ? CFColors.warning
            : CFColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CFSpacing.lg, 0, CFSpacing.lg, CFSpacing.md,
      ),
      child: Row(
        children: [
          // Volume
          _FooterStat(
            icon: Icons.bar_chart_rounded,
            label: 'Vol',
            value: _formatVolume(r.volume),
            valueColor: volColor,
          ),
          const SizedBox(width: CFSpacing.xl),

          // Volume multiple
          _FooterStat(
            icon: Icons.trending_up_rounded,
            label: 'Vol ×',
            value: '${volMultiple.toStringAsFixed(1)}x',
            valueColor: volColor,
          ),
          const SizedBox(width: CFSpacing.xl),

          // RSI
          if (r.rsi != null)
            _FooterStat(
              icon: Icons.speed_rounded,
              label: 'RSI',
              value: r.rsi!.toStringAsFixed(1),
              valueColor: r.rsi! < 30
                  ? CFColors.gain
                  : r.rsi! > 70
                      ? CFColors.loss
                      : CFColors.textSecondary,
            ),

          const Spacer(),

          // Exchange tag
          if (r.sector != null)
            Text(r.sector!, style: CFTextStyles.labelSmall),
        ],
      ),
    );
  }

  String _formatVolume(int v) {
    if (v >= 10_000_000) return '${(v / 10_000_000).toStringAsFixed(1)}Cr';
    if (v >= 100_000)    return '${(v / 100_000).toStringAsFixed(1)}L';
    if (v >= 1_000)      return '${(v / 1_000).toStringAsFixed(1)}K';
    return v.toString();
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ConditionBadge extends StatelessWidget {
  const _ConditionBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: CFColors.brandBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(CFRadius.sm),
        border: Border.all(
          color: CFColors.brandBlue.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w500,
          color: CFColors.brandBlueLight,
        ),
      ),
    );
  }
}

class _FooterStat extends StatelessWidget {
  const _FooterStat({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: CFColors.textDisabled),
        const SizedBox(width: 3),
        Text(
          '$label ',
          style: CFTextStyles.labelSmall,
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: valueColor ?? CFColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Showcase Preview ──────────────────────────────────────────────────────────

/// Standalone preview screen — run this to see all mock cards.
class ScannerCardShowcase extends StatelessWidget {
  const ScannerCardShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CFColors.background,
      appBar: AppBar(
        backgroundColor: CFColors.surface,
        title: const Text(
          'Scanner Results',
          style: CFTextStyles.headingMedium,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: CFSpacing.lg),
            child: IpoStatusChip(
              status: IpoStatus.live,
              size: ChipSize.small,
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(CFSpacing.lg),
        itemCount: kMockScanResults.length,
        itemBuilder: (context, i) => ScannerStockCard(
          result: kMockScanResults[i],
          rank: i + 1,
          onTap: () {},
        ),
      ),
    );
  }
}
