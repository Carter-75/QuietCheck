import 'package:flutter/foundation.dart';
import '../services/data_service.dart';
import '../services/gemini_service.dart';
import '../services/analytics_tracking_service.dart';
import '../models/burnout_prediction.dart';

/// Predictive burnout analysis service
/// Analyzes historical data to predict burnout 48 hours in advance
class BurnoutPredictionService {
  static BurnoutPredictionService? _instance;
  static BurnoutPredictionService get instance =>
      _instance ??= BurnoutPredictionService._();

  BurnoutPredictionService._();

  final DataService _dataService = DataService.instance;
  final GeminiService _geminiService = GeminiService.instance;
  final AnalyticsTrackingService _analyticsService =
      AnalyticsTrackingService.instance;

  /// Run predictive burnout analysis
  /// Returns prediction result if burnout is predicted within 48 hours, null otherwise
  Future<BurnoutPrediction?> runPredictiveAnalysis() async {
    try {
      debugPrint('🔮 Starting predictive burnout analysis...');

      // Fetch 14-30 days of historical data
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));

      final mentalLoadScores = await _dataService.getMentalLoadScores(
        startDate: startDate,
        endDate: now,
      );

      final activityRecords = await _dataService.getActivityTrackingRecords(
        startDate: startDate,
        endDate: now,
      );

      // Validate sufficient data
      if (mentalLoadScores.length < 7) {
        debugPrint(
          '⚠️ Insufficient historical data for prediction (${mentalLoadScores.length} days)',
        );
        return null;
      }

      // Run Gemini prediction
      final predictionResult = await _geminiService.predictBurnout(
        historicalScores: mentalLoadScores,
        activityRecords: activityRecords,
      );

      // Only proceed if burnout is predicted within 48 hours
      if (!predictionResult.willReachThreshold ||
          predictionResult.hoursUntilThreshold > 48) {
        debugPrint('✅ No burnout predicted within 48 hours');
        return null;
      }

      debugPrint(
        '⚠️ Burnout predicted in ${predictionResult.hoursUntilThreshold} hours',
      );

      // Calculate predicted threshold date
      final predictedThresholdDate = now.add(
        Duration(hours: predictionResult.hoursUntilThreshold),
      );

      // Save prediction to database
      await _dataService.saveBurnoutPrediction(
        predictedThresholdDate: predictedThresholdDate,
        currentMentalLoadScore: predictionResult.currentScore,
        predictedMentalLoadScore: predictionResult.predictedScore,
        hoursUntilThreshold: predictionResult.hoursUntilThreshold,
        confidenceLevel: predictionResult.confidence,
        identifiedTriggers: predictionResult.triggers,
        behavioralPatterns: predictionResult.patterns,
      );

      // Fetch the saved prediction
      final savedPrediction = await _dataService.getLatestBurnoutPrediction();
      if (savedPrediction == null) {
        throw Exception('Failed to retrieve saved prediction');
      }

      final prediction = BurnoutPrediction.fromJson(savedPrediction);

      // Log analytics event
      await _analyticsService.trackEvent(
        eventType: 'burnout_prediction',
        eventName: 'Burnout Predicted',
        properties: {
          'hours_until_threshold': predictionResult.hoursUntilThreshold,
          'confidence_level': predictionResult.confidence,
          'predicted_score': predictionResult.predictedScore,
          'current_score': predictionResult.currentScore,
        },
      );

      debugPrint('✅ Burnout prediction saved and logged');
      return prediction;
    } catch (e) {
      debugPrint('❌ Failed to run predictive analysis: $e');
      return null;
    }
  }

  /// Check if a warning should be sent for a prediction
  bool shouldSendWarning(BurnoutPrediction prediction) {
    // Don't send if already sent
    if (prediction.warningSent) return false;

    // Only send if within 48 hours
    if (prediction.hoursUntilThreshold > 48) return false;

    // Only send if prediction is recent (within last 6 hours)
    final hoursSincePrediction = DateTime.now()
        .difference(prediction.predictionTimestamp)
        .inHours;
    if (hoursSincePrediction > 6) return false;

    return true;
  }

  /// Mark prediction warning as sent
  Future<void> markWarningSent(String predictionId) async {
    try {
      await _dataService.markBurnoutWarningSent(predictionId);

      await _analyticsService.trackEvent(
        eventType: 'burnout_warning',
        eventName: 'Burnout Warning Sent',
        properties: {'prediction_id': predictionId},
      );
    } catch (e) {
      debugPrint('❌ Failed to mark warning as sent: $e');
    }
  }
}

/// Result of burnout prediction analysis
class BurnoutPredictionResult {
  final bool willReachThreshold;
  final int hoursUntilThreshold;
  final int currentScore;
  final int predictedScore;
  final String confidence;
  final List<String> triggers;
  final List<String> patterns;

  BurnoutPredictionResult({
    required this.willReachThreshold,
    required this.hoursUntilThreshold,
    required this.currentScore,
    required this.predictedScore,
    required this.confidence,
    required this.triggers,
    required this.patterns,
  });
}
