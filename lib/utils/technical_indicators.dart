/// CapitalFlow — Standard Technical Indicator Utilities
///
/// Pure Dart math. No external dependencies.
/// All formulas are standard textbook implementations.
///
/// Indicators:
///   - SMA   Simple Moving Average
///   - EMA   Exponential Moving Average
///   - RSI   Relative Strength Index (Wilder smoothing)
///   - ATR   Average True Range (Wilder smoothing)
///   - MACD  Moving Average Convergence Divergence
///   - BB    Bollinger Bands
///
/// All functions are stateless and take a List<double> as input.
/// Returns null (or empty list) when there is insufficient data.
library capitalflow_indicators;

// ── Simple Moving Average ─────────────────────────────────────────────────────

/// Returns the SMA of [prices] over [period] bars.
/// Returns null if [prices].length < [period].
double? sma(List<double> prices, int period) {
  if (prices.length < period || period <= 0) return null;
  final window = prices.sublist(prices.length - period);
  return window.reduce((a, b) => a + b) / period;
}

/// Returns a full list of SMA values (one per bar, null where insufficient data).
List<double?> smaFull(List<double> prices, int period) {
  return List.generate(prices.length, (i) {
    if (i + 1 < period) return null;
    return sma(prices.sublist(0, i + 1), period);
  });
}

// ── Exponential Moving Average ────────────────────────────────────────────────

/// Returns the latest EMA value of [prices] over [period] bars.
/// Seeded with SMA for the first value (standard approach).
/// Returns null if [prices].length < [period].
double? ema(List<double> prices, int period) {
  if (prices.length < period || period <= 0) return null;
  final k = 2.0 / (period + 1);
  // Seed: SMA of first [period] bars
  double result = prices.sublist(0, period).reduce((a, b) => a + b) / period;
  for (int i = period; i < prices.length; i++) {
    result = prices[i] * k + result * (1 - k);
  }
  return result;
}

/// Returns a full list of EMA values.
List<double?> emaFull(List<double> prices, int period) {
  if (prices.length < period || period <= 0) {
    return List.filled(prices.length, null);
  }
  final k = 2.0 / (period + 1);
  final result = List<double?>.filled(prices.length, null);

  // Seed
  double prev = prices.sublist(0, period).reduce((a, b) => a + b) / period;
  result[period - 1] = prev;

  for (int i = period; i < prices.length; i++) {
    final curr = prices[i] * k + prev * (1 - k);
    result[i] = curr;
    prev = curr;
  }
  return result;
}

// ── RSI (Wilder Smoothing) ────────────────────────────────────────────────────

/// Calculates the RSI of [prices] with [period] (typically 14).
/// Uses Wilder's smoothing method (standard for RSI).
/// Returns null if insufficient data.
///
/// Interpretation:
///   < 30 → Oversold
///   > 70 → Overbought
///   30–70 → Neutral
double? rsi(List<double> prices, {int period = 14}) {
  if (prices.length <= period || period <= 0) return null;

  // Step 1: compute price changes
  final changes = <double>[];
  for (int i = 1; i < prices.length; i++) {
    changes.add(prices[i] - prices[i - 1]);
  }

  // Step 2: first avg gain / avg loss over initial [period] bars
  double avgGain = 0, avgLoss = 0;
  for (int i = 0; i < period; i++) {
    if (changes[i] > 0) {
      avgGain += changes[i];
    } else {
      avgLoss += -changes[i];
    }
  }
  avgGain /= period;
  avgLoss /= period;

  // Step 3: Wilder smooth the rest
  for (int i = period; i < changes.length; i++) {
    final gain = changes[i] > 0 ? changes[i] : 0.0;
    final loss = changes[i] < 0 ? -changes[i] : 0.0;
    avgGain = (avgGain * (period - 1) + gain) / period;
    avgLoss = (avgLoss * (period - 1) + loss) / period;
  }

  if (avgLoss == 0) return 100.0;
  final rs = avgGain / avgLoss;
  return 100 - (100 / (1 + rs));
}

/// Returns a full list of RSI values (one per bar).
List<double?> rsiFull(List<double> prices, {int period = 14}) {
  final result = List<double?>.filled(prices.length, null);
  for (int i = period; i < prices.length; i++) {
    result[i] = rsi(prices.sublist(0, i + 1), period: period);
  }
  return result;
}

// ── ATR (Wilder Smoothing) ────────────────────────────────────────────────────

/// Represents a single OHLC candle for ATR calculation.
class Candle {
  const Candle({
    required this.high,
    required this.low,
    required this.close,
  });
  final double high;
  final double low;
  final double close;
}

/// True Range for a single candle (requires previous close).
double trueRange(Candle candle, double prevClose) {
  final hl  = candle.high - candle.low;
  final hpc = (candle.high - prevClose).abs();
  final lpc = (candle.low - prevClose).abs();
  return [hl, hpc, lpc].reduce((a, b) => a > b ? a : b);
}

/// Calculates ATR of [candles] over [period] bars using Wilder smoothing.
/// Returns null if insufficient data.
double? atr(List<Candle> candles, {int period = 14}) {
  if (candles.length <= period || period <= 0) return null;

  // Step 1: compute all true ranges
  final trs = <double>[];
  for (int i = 1; i < candles.length; i++) {
    trs.add(trueRange(candles[i], candles[i - 1].close));
  }

  // Step 2: seed = SMA of first [period] TRs
  double result = trs.sublist(0, period).reduce((a, b) => a + b) / period;

  // Step 3: Wilder smooth
  for (int i = period; i < trs.length; i++) {
    result = (result * (period - 1) + trs[i]) / period;
  }
  return result;
}

/// Returns a full list of ATR values (null for bars without enough history).
List<double?> atrFull(List<Candle> candles, {int period = 14}) {
  final result = List<double?>.filled(candles.length, null);
  for (int i = period; i < candles.length; i++) {
    result[i] = atr(candles.sublist(0, i + 1), period: period);
  }
  return result;
}

// ── MACD ──────────────────────────────────────────────────────────────────────

class MacdResult {
  const MacdResult({
    required this.macdLine,
    required this.signalLine,
    required this.histogram,
  });
  final double macdLine;    // EMA(fast) - EMA(slow)
  final double signalLine;  // EMA(macdLine, signal)
  final double histogram;   // macdLine - signalLine
}

/// Calculates MACD with [fast], [slow], [signal] periods.
/// Returns null if insufficient data.
MacdResult? macd(
  List<double> prices, {
  int fast = 12,
  int slow = 26,
  int signal = 9,
}) {
  if (prices.length < slow + signal) return null;

  final fastValues = emaFull(prices, fast).whereType<double>().toList();
  final slowValues = emaFull(prices, slow).whereType<double>().toList();

  // Align lengths (slow EMA starts later)
  final minLen = fastValues.length < slowValues.length
      ? fastValues.length
      : slowValues.length;

  final macdValues = <double>[];
  for (int i = 0; i < minLen; i++) {
    macdValues.add(fastValues[fastValues.length - minLen + i] -
                   slowValues[slowValues.length - minLen + i]);
  }

  final signalEma = ema(macdValues, signal);
  if (signalEma == null) return null;

  final macdLine = macdValues.last;
  return MacdResult(
    macdLine:   macdLine,
    signalLine: signalEma,
    histogram:  macdLine - signalEma,
  );
}

// ── Bollinger Bands ───────────────────────────────────────────────────────────

class BollingerBands {
  const BollingerBands({
    required this.upper,
    required this.middle,
    required this.lower,
    required this.bandWidth,
    required this.percentB,
  });

  final double upper;      // middle + (k × stdDev)
  final double middle;     // SMA(period)
  final double lower;      // middle - (k × stdDev)
  final double bandWidth;  // (upper - lower) / middle  — squeeze indicator
  final double percentB;   // (price - lower) / (upper - lower)
}

/// Calculates Bollinger Bands for the latest price in [prices].
/// [period] = 20, [k] = 2.0 are the standard defaults.
BollingerBands? bollingerBands(
  List<double> prices, {
  int period = 20,
  double k = 2.0,
}) {
  if (prices.length < period || period <= 0) return null;

  final window = prices.sublist(prices.length - period);
  final middle = window.reduce((a, b) => a + b) / period;

  // Population standard deviation
  final variance =
      window.map((p) => (p - middle) * (p - middle)).reduce((a, b) => a + b) /
      period;
  final stdDev = variance > 0 ? _sqrt(variance) : 0.0;

  final upper = middle + k * stdDev;
  final lower = middle - k * stdDev;
  final price = prices.last;

  return BollingerBands(
    upper:     upper,
    middle:    middle,
    lower:     lower,
    bandWidth: upper != lower ? (upper - lower) / middle : 0,
    percentB:  upper != lower ? (price - lower) / (upper - lower) : 0.5,
  );
}

// ── Internal helpers ──────────────────────────────────────────────────────────

/// Newton-Raphson square root (avoids dart:math dependency).
double _sqrt(double x) {
  if (x <= 0) return 0;
  double r = x;
  for (int i = 0; i < 20; i++) {
    r = (r + x / r) / 2;
  }
  return r;
}
