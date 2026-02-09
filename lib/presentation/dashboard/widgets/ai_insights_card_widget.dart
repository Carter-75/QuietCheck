import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/gemini_service.dart';
import '../../../models/burnout_prediction.dart';

class AiInsightsCardWidget extends StatelessWidget {
  final BehavioralAnalysis? analysis;
  final List<String>? recommendations;
  final BurnoutPrediction? burnoutPrediction;
  final bool isLoading;
  final VoidCallback onRefresh;

  const AiInsightsCardWidget({
    super.key,
    this.analysis,
    this.recommendations,
    this.burnoutPrediction,
    this.isLoading = false,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'AI Insights',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    size: 18.sp,
                  ),
                  onPressed: isLoading ? null : onRefresh,
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Burnout Prediction Warning (if present)
            if (burnoutPrediction != null && !burnoutPrediction!.warningSent) ...[
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: _getSeverityColor(burnoutPrediction!.getSeverityLevel()).withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: _getSeverityColor(burnoutPrediction!.getSeverityLevel()),
                    width: 2.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: _getSeverityColor(burnoutPrediction!.getSeverityLevel()),
                          size: 20.sp,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            'Burnout Predicted in ${burnoutPrediction!.hoursUntilThreshold}h',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: _getSeverityColor(burnoutPrediction!.getSeverityLevel()),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Predicted Score: ${burnoutPrediction!.predictedMentalLoadScore}/100',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Key Triggers:',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    ...burnoutPrediction!.identifiedTriggers.take(2).map(
                      (trigger) => Padding(
                        padding: EdgeInsets.only(left: 2.w, top: 0.5.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(fontSize: 12.sp)),
                            Expanded(
                              child: Text(
                                trigger,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
            ],

            if (isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 1.h),
                      Text(
                        'Analyzing behavioral patterns...',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (analysis == null)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Column(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 32.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'No analysis available yet',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      TextButton(
                        onPressed: onRefresh,
                        child: Text('Generate Analysis'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Burnout Risk Level
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: Color(int.parse(
                        analysis!.getRiskLevelColor().replaceFirst('#', '0xFF'),
                      )).withAlpha(26),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Color(int.parse(
                          analysis!.getRiskLevelColor().replaceFirst('#', '0xFF'),
                        )),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Color(int.parse(
                            analysis!.getRiskLevelColor().replaceFirst('#', '0xFF'),
                          )),
                          size: 16.sp,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Burnout Risk: ${analysis!.getRiskLevelLabel()}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Color(int.parse(
                              analysis!.getRiskLevelColor().replaceFirst('#', '0xFF'),
                            )),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Summary
                  if (analysis!.summary.isNotEmpty) ...[
                    Text(
                      analysis!.summary,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[700],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                  ],

                  // Behavioral Patterns
                  if (analysis!.patterns.isNotEmpty) ...[
                    Text(
                      'Behavioral Patterns',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    ...analysis!.patterns.take(2).map((pattern) => Padding(
                      padding: EdgeInsets.only(bottom: 0.5.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 6.sp,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              pattern,
                              style: TextStyle(fontSize: 12.sp),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                    SizedBox(height: 2.h),
                  ],

                  // Burnout Triggers
                  if (analysis!.burnoutTriggers.isNotEmpty) ...[
                    Text(
                      'Burnout Triggers',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    ...analysis!.burnoutTriggers.take(2).map((trigger) => Padding(
                      padding: EdgeInsets.only(bottom: 0.5.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_outlined,
                            size: 12.sp,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              trigger,
                              style: TextStyle(fontSize: 12.sp),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                    SizedBox(height: 2.h),
                  ],

                  // Recommendations
                  if (recommendations != null && recommendations!.isNotEmpty) ...[
                    Text(
                      'Recommendations',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    ...recommendations!.take(3).map((rec) => Padding(
                      padding: EdgeInsets.only(bottom: 0.5.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 12.sp,
                            color: Colors.green,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              rec,
                              style: TextStyle(fontSize: 12.sp),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Add this method
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }
}