import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/activity_tracking_record.dart';
import '../models/analytics_record.dart';
import '../models/app_usage_record.dart';
import '../models/mental_load_score.dart';
import './burnout_prediction_service.dart';

class GeminiService {
  static GeminiService? _instance;
  static GeminiService get instance => _instance ??= GeminiService._();

  GeminiService._();

  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');
  late final GenerativeModel _model;
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) {
      return; // Already initialized, skip
    }

    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY must be provided via --dart-define');
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
    );

    _isInitialized = true;
  }

  /// Predict burnout 48 hours in advance based on historical trends
  Future<BurnoutPredictionResult> predictBurnout({
    required List<MentalLoadScore> historicalScores,
    required List<ActivityTrackingRecord> activityRecords,
  }) async {
    try {
      if (historicalScores.length < 7) {
        throw Exception(
          'Insufficient historical data for prediction (minimum 7 days required)',
        );
      }

      final prompt = _buildPredictionPrompt(
        historicalScores: historicalScores,
        activityRecords: activityRecords,
      );

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      return _parsePredictionResponse(response.text!, historicalScores.last);
    } catch (e) {
      throw Exception('Failed to predict burnout: $e');
    }
  }

  String _buildPredictionPrompt({
    required List<MentalLoadScore> historicalScores,
    required List<ActivityTrackingRecord> activityRecords,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Analyze the following 14-30 day historical mental health data to predict if the user will reach critical burnout threshold (mental load score > 80) within the next 48 hours.',
    );
    buffer.writeln();

    // Mental load trend analysis
    buffer.writeln(
      'MENTAL LOAD SCORE HISTORY (Last ${historicalScores.length} days):',
    );
    for (int i = 0; i < historicalScores.length; i++) {
      final score = historicalScores[i];
      final daysAgo = historicalScores.length - i - 1;
      buffer.writeln('  Day -$daysAgo: Score ${score.score} (${score.zone})');
    }
    buffer.writeln();

    // Calculate trend metrics
    final recentScores = historicalScores.length >= 7
        ? historicalScores.sublist(historicalScores.length - 7)
        : historicalScores;
    final avgRecent =
        recentScores.map((s) => s.score).reduce((a, b) => a + b) /
        recentScores.length;
    final currentScore = historicalScores.last.score;

    buffer.writeln('TREND ANALYSIS:');
    buffer.writeln('  - Current Score: $currentScore');
    buffer.writeln('  - 7-Day Average: ${avgRecent.toStringAsFixed(1)}');
    buffer.writeln(
      '  - Trend Direction: ${currentScore > avgRecent ? "Increasing" : "Decreasing"}',
    );
    buffer.writeln();

    // Activity patterns
    if (activityRecords.isNotEmpty) {
      buffer.writeln(
        'RECENT ACTIVITY PATTERNS (Last ${activityRecords.length} days):',
      );
      for (final record in activityRecords.take(7)) {
        buffer.writeln('Date: ${record.trackingDate.toString().split(' ')[0]}');
        buffer.writeln('  - Screen Time: ${record.totalScreenTimeMinutes} min');
        buffer.writeln(
          '  - App Switches: ${record.appSwitchCount} (velocity: ${record.appSwitchVelocity.toStringAsFixed(2)}/min)',
        );
        buffer.writeln(
          '  - Focus Sessions: ${record.focusSessionsCount} (${record.focusDurationMinutes} min)',
        );
        buffer.writeln('  - Pattern: ${record.activityPattern.name}');
        buffer.writeln();
      }
    }

    buffer.writeln('PREDICTION TASK:');
    buffer.writeln(
      'Based on the historical trends, behavioral patterns, and current trajectory:',
    );
    buffer.writeln(
      '1. Will the user reach critical burnout threshold (score > 80) within 48 hours?',
    );
    buffer.writeln('2. If yes, how many hours until threshold is reached?');
    buffer.writeln(
      '3. What are the specific behavioral triggers contributing to this trajectory?',
    );
    buffer.writeln('4. What confidence level do you have in this prediction?');
    buffer.writeln();

    buffer.writeln('Provide your analysis in the following format:');
    buffer.writeln('WILL_REACH_THRESHOLD: [yes/no]');
    buffer.writeln('HOURS_UNTIL_THRESHOLD: [number between 0-48, or 0 if no]');
    buffer.writeln(
      'PREDICTED_SCORE: [predicted mental load score in 48 hours]',
    );
    buffer.writeln('CONFIDENCE: [low/medium/high]');
    buffer.writeln('TRIGGERS: [List 2-3 specific behavioral triggers]');
    buffer.writeln('PATTERNS: [List 2-3 key patterns observed]');

    return buffer.toString();
  }

  BurnoutPredictionResult _parsePredictionResponse(
    String responseText,
    MentalLoadScore currentScore,
  ) {
    bool willReachThreshold = false;
    int hoursUntilThreshold = 0;
    int predictedScore = currentScore.score;
    String confidence = 'medium';
    final triggers = <String>[];
    final patterns = <String>[];

    final lines = responseText.split('\n');
    String currentSection = '';

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('WILL_REACH_THRESHOLD:')) {
        final value = trimmed
            .substring('WILL_REACH_THRESHOLD:'.length)
            .trim()
            .toLowerCase();
        willReachThreshold = value.contains('yes');
      } else if (trimmed.startsWith('HOURS_UNTIL_THRESHOLD:')) {
        final value = trimmed.substring('HOURS_UNTIL_THRESHOLD:'.length).trim();
        hoursUntilThreshold =
            int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      } else if (trimmed.startsWith('PREDICTED_SCORE:')) {
        final value = trimmed.substring('PREDICTED_SCORE:'.length).trim();
        predictedScore =
            int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ??
            currentScore.score;
      } else if (trimmed.startsWith('CONFIDENCE:')) {
        confidence = trimmed
            .substring('CONFIDENCE:'.length)
            .trim()
            .toLowerCase();
      } else if (trimmed.startsWith('TRIGGERS:')) {
        currentSection = 'triggers';
        final content = trimmed.substring('TRIGGERS:'.length).trim();
        if (content.isNotEmpty) triggers.add(content);
      } else if (trimmed.startsWith('PATTERNS:')) {
        currentSection = 'patterns';
        final content = trimmed.substring('PATTERNS:'.length).trim();
        if (content.isNotEmpty) patterns.add(content);
      } else if (trimmed.startsWith('-') || trimmed.startsWith('•')) {
        final content = trimmed.substring(1).trim();
        if (currentSection == 'triggers') {
          triggers.add(content);
        } else if (currentSection == 'patterns') {
          patterns.add(content);
        }
      }
    }

    // Validation and fallbacks
    if (!willReachThreshold) {
      hoursUntilThreshold = 0;
    }
    if (hoursUntilThreshold > 48) {
      hoursUntilThreshold = 48;
    }
    if (triggers.isEmpty) {
      triggers.add('Elevated stress patterns detected in recent activity');
    }
    if (patterns.isEmpty) {
      patterns.add('Increasing mental load trend observed');
    }

    return BurnoutPredictionResult(
      willReachThreshold: willReachThreshold,
      hoursUntilThreshold: hoursUntilThreshold,
      currentScore: currentScore.score,
      predictedScore: predictedScore,
      confidence: confidence,
      triggers: triggers,
      patterns: patterns,
    );
  }

  /// Analyze behavioral patterns and identify burnout triggers
  Future<BehavioralAnalysis> analyzeBehavioralPatterns({
    required List<ActivityTrackingRecord> activityRecords,
    required List<AppUsageRecord> appUsageRecords,
    required List<MentalLoadScore> mentalLoadScores,
    required List<AnalyticsRecord> analyticsRecords,
  }) async {
    try {
      final prompt = _buildAnalysisPrompt(
        activityRecords: activityRecords,
        appUsageRecords: appUsageRecords,
        mentalLoadScores: mentalLoadScores,
        analyticsRecords: analyticsRecords,
      );

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      return _parseAnalysisResponse(response.text!);
    } catch (e) {
      throw Exception('Failed to analyze behavioral patterns: $e');
    }
  }

  /// Generate personalized recommendations based on analysis
  Future<List<String>> generateRecommendations({
    required BehavioralAnalysis analysis,
    required String currentMentalLoadZone,
  }) async {
    try {
      final prompt =
          '''
Based on the following behavioral analysis and current mental state, provide 3-5 specific, actionable recommendations to improve mental wellbeing and prevent burnout.

Current Mental Load Zone: $currentMentalLoadZone

Behavioral Patterns:
${analysis.patterns.map((p) => '- $p').join('\n')}

Burnout Triggers:
${analysis.burnoutTriggers.map((t) => '- $t').join('\n')}

Burnout Risk Level: ${analysis.burnoutRiskLevel}

Provide recommendations in the following format:
1. [Recommendation]
2. [Recommendation]
3. [Recommendation]

Focus on practical, immediately actionable steps. Keep each recommendation concise (1-2 sentences).''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      return _parseRecommendations(response.text!);
    } catch (e) {
      throw Exception('Failed to generate recommendations: $e');
    }
  }

  /// Generate personalized wellness goal recommendations based on burnout patterns
  Future<List<String>> generateGoalRecommendations({
    required List<MentalLoadScore> recentScores,
    required BehavioralAnalysis analysis,
    List<String>? existingGoalCategories,
  }) async {
    try {
      final prompt = _buildGoalRecommendationPrompt(
        recentScores: recentScores,
        analysis: analysis,
        existingGoalCategories: existingGoalCategories ?? [],
      );

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      return _parseRecommendations(response.text!);
    } catch (e) {
      throw Exception('Failed to generate goal recommendations: $e');
    }
  }

  String _buildGoalRecommendationPrompt({
    required List<MentalLoadScore> recentScores,
    required BehavioralAnalysis analysis,
    required List<String> existingGoalCategories,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Based on the user\'s mental health data and burnout patterns, suggest 3-5 personalized wellness goals that would be most effective for improving their mental wellbeing.',
    );
    buffer.writeln();

    // Recent mental load trend
    buffer.writeln('RECENT MENTAL LOAD SCORES (Last 7 days):');
    for (int i = 0; i < recentScores.length && i < 7; i++) {
      final score = recentScores[recentScores.length - 1 - i];
      buffer.writeln('  Day -$i: Score ${score.score} (${score.zone})');
    }
    buffer.writeln();

    // Behavioral patterns
    buffer.writeln('IDENTIFIED BEHAVIORAL PATTERNS:');
    for (final pattern in analysis.patterns) {
      buffer.writeln('  - $pattern');
    }
    buffer.writeln();

    // Burnout triggers
    buffer.writeln('BURNOUT TRIGGERS:');
    for (final trigger in analysis.burnoutTriggers) {
      buffer.writeln('  - $trigger');
    }
    buffer.writeln();

    buffer.writeln('Burnout Risk Level: ${analysis.burnoutRiskLevel}');
    buffer.writeln();

    if (existingGoalCategories.isNotEmpty) {
      buffer.writeln('EXISTING GOAL CATEGORIES (avoid duplicates):');
      for (final category in existingGoalCategories) {
        buffer.writeln('  - $category');
      }
      buffer.writeln();
    }

    buffer.writeln('Available goal categories:');
    buffer.writeln('  - stress_reduction: Techniques to lower stress levels');
    buffer.writeln('  - sleep_improvement: Better sleep quality and duration');
    buffer.writeln(
      '  - mindfulness_practice: Meditation and awareness exercises',
    );
    buffer.writeln(
      '  - work_life_balance: Boundary setting and time management',
    );
    buffer.writeln('  - physical_activity: Exercise and movement goals');
    buffer.writeln('  - social_connection: Building supportive relationships');
    buffer.writeln();

    buffer.writeln(
      'Provide recommendations in the following format (one per line):',
    );
    buffer.writeln(
      '1. [Category]: [Specific goal title] - [Brief reasoning based on patterns]',
    );
    buffer.writeln(
      '2. [Category]: [Specific goal title] - [Brief reasoning based on patterns]',
    );
    buffer.writeln();
    buffer.writeln(
      'Focus on goals that directly address the identified triggers and patterns. Make goals specific, measurable, and achievable within 2-4 weeks.',
    );

    return buffer.toString();
  }

  String _buildAnalysisPrompt({
    required List<ActivityTrackingRecord> activityRecords,
    required List<AppUsageRecord> appUsageRecords,
    required List<MentalLoadScore> mentalLoadScores,
    required List<AnalyticsRecord> analyticsRecords,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Analyze the following behavioral data to identify patterns, burnout triggers, and risk level:',
    );
    buffer.writeln();

    // Activity tracking summary
    buffer.writeln(
      'ACTIVITY TRACKING DATA (Last ${activityRecords.length} days):',
    );
    for (final record in activityRecords) {
      buffer.writeln('Date: ${record.trackingDate.toString().split(' ')[0]}');
      buffer.writeln(
        '  - Screen Time: ${record.totalScreenTimeMinutes} minutes',
      );
      buffer.writeln(
        '  - App Switches: ${record.appSwitchCount} (velocity: ${record.appSwitchVelocity.toStringAsFixed(2)}/min)',
      );
      buffer.writeln(
        '  - Focus Sessions: ${record.focusSessionsCount} (${record.focusDurationMinutes} minutes total)',
      );
      buffer.writeln('  - Activity Pattern: ${record.activityPattern.name}');
      buffer.writeln();
    }

    // App usage summary
    if (appUsageRecords.isNotEmpty) {
      buffer.writeln('TOP APP USAGE:');
      final sortedApps = List<AppUsageRecord>.from(appUsageRecords)
        ..sort(
          (a, b) => b.usageDurationMinutes.compareTo(a.usageDurationMinutes),
        );
      for (final app in sortedApps.take(5)) {
        buffer.writeln(
          '  - ${app.appName ?? app.appPackageName}: ${app.usageDurationMinutes} minutes (opened ${app.openCount} times)',
        );
      }
      buffer.writeln();
    }

    // Mental load trends
    buffer.writeln('MENTAL LOAD TRENDS:');
    for (final score in mentalLoadScores) {
      buffer.writeln(
        '  - ${score.recordedAt.toString().split(' ')[0]}: Score ${score.score} (${score.zone})',
      );
    }
    buffer.writeln();

    // Analytics summary
    if (analyticsRecords.isNotEmpty) {
      buffer.writeln('ANALYTICS SUMMARY:');
      for (final record in analyticsRecords) {
        buffer.writeln('Date: ${record.date.toString().split(' ')[0]}');
        buffer.writeln(
          '  - Avg Mental Load: ${record.avgMentalLoad.toStringAsFixed(1)}',
        );
        buffer.writeln('  - Peak Mental Load: ${record.peakMentalLoad}');
        if (record.baselineComparison != null) {
          buffer.writeln(
            '  - Baseline Comparison: ${record.baselineComparison!.toStringAsFixed(1)}',
          );
        }
        buffer.writeln();
      }
    }

    buffer.writeln('Provide analysis in the following format:');
    buffer.writeln('PATTERNS: [List 2-3 key behavioral patterns observed]');
    buffer.writeln(
      'BURNOUT_TRIGGERS: [List 2-3 specific burnout triggers identified]',
    );
    buffer.writeln('RISK_LEVEL: [low/moderate/high/critical]');
    buffer.writeln(
      'SUMMARY: [Brief 2-3 sentence summary of overall mental health state]',
    );

    return buffer.toString();
  }

  BehavioralAnalysis _parseAnalysisResponse(String responseText) {
    final patterns = <String>[];
    final burnoutTriggers = <String>[];
    String riskLevel = 'moderate';
    String summary = '';

    final lines = responseText.split('\n');
    String currentSection = '';

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('PATTERNS:')) {
        currentSection = 'patterns';
        final content = trimmed.substring('PATTERNS:'.length).trim();
        if (content.isNotEmpty) patterns.add(content);
      } else if (trimmed.startsWith('BURNOUT_TRIGGERS:')) {
        currentSection = 'triggers';
        final content = trimmed.substring('BURNOUT_TRIGGERS:'.length).trim();
        if (content.isNotEmpty) burnoutTriggers.add(content);
      } else if (trimmed.startsWith('RISK_LEVEL:')) {
        currentSection = 'risk';
        riskLevel = trimmed
            .substring('RISK_LEVEL:'.length)
            .trim()
            .toLowerCase();
      } else if (trimmed.startsWith('SUMMARY:')) {
        currentSection = 'summary';
        summary = trimmed.substring('SUMMARY:'.length).trim();
      } else if (trimmed.startsWith('-') || trimmed.startsWith('•')) {
        final content = trimmed.substring(1).trim();
        if (currentSection == 'patterns') {
          patterns.add(content);
        } else if (currentSection == 'triggers') {
          burnoutTriggers.add(content);
        }
      } else if (currentSection == 'summary' && summary.isNotEmpty) {
        summary += ' $trimmed';
      }
    }

    // Fallback parsing if structured format not found
    if (patterns.isEmpty && burnoutTriggers.isEmpty) {
      patterns.add(
        'Behavioral patterns detected in screen time and app usage data',
      );
      burnoutTriggers.add(
        'Potential stress indicators identified in activity patterns',
      );
      summary = responseText.length > 200
          ? '${responseText.substring(0, 200)}...'
          : responseText;
    }

    return BehavioralAnalysis(
      patterns: patterns,
      burnoutTriggers: burnoutTriggers,
      burnoutRiskLevel: riskLevel,
      summary: summary.isEmpty ? 'Analysis completed successfully' : summary,
    );
  }

  List<String> _parseRecommendations(String responseText) {
    final recommendations = <String>[];
    final lines = responseText.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Match numbered recommendations (1. 2. 3. etc.)
      final numberMatch = RegExp(r'^\d+\.\s*(.+)').firstMatch(trimmed);
      if (numberMatch != null) {
        recommendations.add(numberMatch.group(1)!.trim());
        continue;
      }

      // Match bullet points
      if (trimmed.startsWith('-') || trimmed.startsWith('•')) {
        recommendations.add(trimmed.substring(1).trim());
      }
    }

    // Fallback if no structured recommendations found
    if (recommendations.isEmpty) {
      recommendations.add('Take regular breaks from screen time');
      recommendations.add(
        'Practice mindfulness exercises during high-stress periods',
      );
      recommendations.add(
        'Monitor app switching patterns and reduce multitasking',
      );
    }

    return recommendations.take(5).toList();
  }
}

class BehavioralAnalysis {
  final List<String> patterns;
  final List<String> burnoutTriggers;
  final String burnoutRiskLevel;
  final String summary;

  BehavioralAnalysis({
    required this.patterns,
    required this.burnoutTriggers,
    required this.burnoutRiskLevel,
    required this.summary,
  });

  String getRiskLevelLabel() {
    switch (burnoutRiskLevel.toLowerCase()) {
      case 'low':
        return 'Low Risk';
      case 'moderate':
        return 'Moderate Risk';
      case 'high':
        return 'High Risk';
      case 'critical':
        return 'Critical Risk';
      default:
        return 'Moderate Risk';
    }
  }

  String getRiskLevelColor() {
    switch (burnoutRiskLevel.toLowerCase()) {
      case 'low':
        return '#4CAF50';
      case 'moderate':
        return '#FF9800';
      case 'high':
        return '#FF5722';
      case 'critical':
        return '#D32F2F';
      default:
        return '#FF9800';
    }
  }
}
