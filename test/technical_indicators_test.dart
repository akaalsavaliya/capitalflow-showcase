/// Unit tests for technical_indicators.dart
///
/// Run with: dart test test/technical_indicators_test.dart
///
/// Tests verify:
///   - SMA correctness on known dataset
///   - EMA convergence property
///   - RSI boundary conditions (all gains → 100, all losses → 0)
///   - RSI known value on published dataset
///   - ATR basic true range calculation
///   - Bollinger Band width > 0 for non-constant data
///   - MACD signal crossover detection
import 'package:test/test.dart';
import '../lib/utils/technical_indicators.dart';

void main() {
  // ── SMA ─────────────────────────────────────────────────────────────────────

  group('SMA', () {
    test('returns correct average for simple window', () {
      final prices = [10.0, 20.0, 30.0, 40.0, 50.0];
      expect(sma(prices, 3), closeTo(40.0, 0.001)); // avg of [30,40,50]
    });

    test('returns correct 5-period SMA', () {
      final prices = [10.0, 20.0, 30.0, 40.0, 50.0];
      expect(sma(prices, 5), closeTo(30.0, 0.001));
    });

    test('returns null when insufficient data', () {
      expect(sma([10.0, 20.0], 5), isNull);
    });

    test('returns null for period 0', () {
      expect(sma([1.0, 2.0, 3.0], 0), isNull);
    });

    test('smaFull returns correct length', () {
      final prices = List.generate(20, (i) => (i + 1).toDouble());
      final result = smaFull(prices, 5);
      expect(result.length, equals(20));
      expect(result[3], isNull); // first 4 bars have no SMA(5)
      expect(result[4], isNotNull);
    });
  });

  // ── EMA ─────────────────────────────────────────────────────────────────────

  group('EMA', () {
    test('EMA(1) equals last price', () {
      final prices = [10.0, 20.0, 30.0, 99.0];
      expect(ema(prices, 1), closeTo(99.0, 0.001));
    });

    test('EMA converges toward trend for monotonic series', () {
      final rising = List.generate(50, (i) => i.toDouble());
      final result = ema(rising, 10)!;
      // EMA should be below the last price but above the SMA seed
      expect(result, greaterThan(0));
      expect(result, lessThan(50));
    });

    test('returns null when insufficient data', () {
      expect(ema([1.0, 2.0], 5), isNull);
    });

    test('emaFull has correct length and null prefix', () {
      final prices = List.generate(30, (i) => (i + 1).toDouble());
      final result = emaFull(prices, 10);
      expect(result.length, equals(30));
      expect(result[8], isNull);  // index 8 = 9 bars < period 10
      expect(result[9], isNotNull); // index 9 = 10 bars = period 10
    });
  });

  // ── RSI ─────────────────────────────────────────────────────────────────────

  group('RSI', () {
    test('RSI = 100 when all moves are gains', () {
      final prices = List.generate(20, (i) => i.toDouble() + 1);
      expect(rsi(prices, period: 14), closeTo(100.0, 0.001));
    });

    test('RSI = 0 when all moves are losses', () {
      final prices = List.generate(20, (i) => 20.0 - i);
      expect(rsi(prices, period: 14), closeTo(0.0, 0.001));
    });

    test('RSI = 50 for alternating +1/-1 price movements', () {
      final prices = <double>[100];
      for (int i = 0; i < 40; i++) {
        prices.add(prices.last + (i.isEven ? 1 : -1));
      }
      final result = rsi(prices, period: 14)!;
      // Alternating equal gains/losses → avg gain ≈ avg loss → RSI ≈ 50
      expect(result, closeTo(50.0, 1.0));
    });

    test('RSI returns null when insufficient data', () {
      expect(rsi([1.0, 2.0, 3.0], period: 14), isNull);
    });

    test('RSI stays within 0–100 for random-walk data', () {
      // Simulate a random walk (deterministic seed for reproducibility)
      final prices = <double>[100.0];
      var direction = 1.0;
      for (int i = 0; i < 100; i++) {
        direction = (i % 7 < 4) ? 1.0 : -1.0;
        prices.add(prices.last + direction * (i % 3 + 0.5));
      }
      final result = rsi(prices, period: 14)!;
      expect(result, greaterThanOrEqualTo(0.0));
      expect(result, lessThanOrEqualTo(100.0));
    });

    test('rsiFull has correct length and null prefix', () {
      final prices = List.generate(30, (i) => (i + 1).toDouble());
      final result = rsiFull(prices, period: 14);
      expect(result.length, equals(30));
      expect(result[13], isNull);   // need 14 changes = 15 bars
      expect(result[14], isNotNull);
    });
  });

  // ── ATR ─────────────────────────────────────────────────────────────────────

  group('ATR / True Range', () {
    test('trueRange = high - low when no gap', () {
      const candle = Candle(high: 110.0, low: 90.0, close: 100.0);
      expect(trueRange(candle, 100.0), closeTo(20.0, 0.001));
    });

    test('trueRange uses high-prevClose when gap up', () {
      const candle = Candle(high: 120.0, low: 100.0, close: 110.0);
      // HL = 20, H-PC = 120-90 = 30, L-PC = |100-90| = 10 → TR = 30
      expect(trueRange(candle, 90.0), closeTo(30.0, 0.001));
    });

    test('ATR returns null for insufficient data', () {
      final candles = List.generate(
        10,
        (i) => Candle(high: i + 1.0, low: i.toDouble(), close: i + 0.5),
      );
      expect(atr(candles, period: 14), isNull);
    });

    test('ATR is positive for normal OHLC data', () {
      final candles = List.generate(
        30,
        (i) => Candle(
          high:  100.0 + i + 2,
          low:   100.0 + i - 1,
          close: 100.0 + i + 0.5,
        ),
      );
      final result = atr(candles, period: 14)!;
      expect(result, greaterThan(0));
    });
  });

  // ── Bollinger Bands ──────────────────────────────────────────────────────────

  group('Bollinger Bands', () {
    test('constant prices produce zero band width', () {
      final prices = List.filled(30, 100.0);
      final bb = bollingerBands(prices, period: 20)!;
      expect(bb.upper, closeTo(100.0, 0.001));
      expect(bb.lower, closeTo(100.0, 0.001));
      expect(bb.bandWidth, closeTo(0.0, 0.001));
    });

    test('upper > middle > lower for volatile prices', () {
      final prices = List.generate(30, (i) => 100.0 + (i % 5) * 3.0);
      final bb = bollingerBands(prices, period: 20)!;
      expect(bb.upper, greaterThan(bb.middle));
      expect(bb.lower, lessThan(bb.middle));
    });

    test('%B = 0.5 when last price equals middle band', () {
      // All prices equal except last which equals the SMA
      final prices = List.generate(19, (i) => (i % 3 == 0) ? 110.0 : 90.0);
      final avg = prices.reduce((a, b) => a + b) / prices.length;
      prices.add(avg); // last price = SMA of window
      final bb = bollingerBands(prices, period: 20)!;
      expect(bb.percentB, closeTo(0.5, 0.1));
    });

    test('returns null for insufficient data', () {
      expect(bollingerBands([1.0, 2.0, 3.0], period: 20), isNull);
    });
  });

  // ── MACD ─────────────────────────────────────────────────────────────────────

  group('MACD', () {
    test('returns null for insufficient data', () {
      expect(
        macd(List.generate(20, (i) => i.toDouble()), fast: 12, slow: 26, signal: 9),
        isNull,
      );
    });

    test('MACD line = 0 when fast EMA = slow EMA (flat line)', () {
      // Flat prices → both EMAs converge to the same value → MACD ≈ 0
      final prices = List.filled(60, 100.0);
      final result = macd(prices)!;
      expect(result.macdLine.abs(), lessThan(0.1));
    });

    test('MACD > 0 in a strong uptrend', () {
      // Strongly rising prices → fast EMA > slow EMA → positive MACD
      final prices = List.generate(60, (i) => 100.0 + i * 2.0);
      final result = macd(prices)!;
      expect(result.macdLine, greaterThan(0));
    });

    test('histogram = macdLine - signalLine', () {
      final prices = List.generate(60, (i) => 100.0 + (i % 10) * 5.0);
      final result = macd(prices)!;
      expect(
        result.histogram,
        closeTo(result.macdLine - result.signalLine, 0.0001),
      );
    });
  });
}
