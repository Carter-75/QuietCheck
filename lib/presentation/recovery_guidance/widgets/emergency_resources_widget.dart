import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Emergency Resources Widget
/// Provides crisis hotline numbers and professional help guidance with one-tap calling
class EmergencyResourcesWidget extends StatelessWidget {
  const EmergencyResourcesWidget({super.key});

  final List<Map<String, dynamic>> _emergencyContacts = const [
    {
      "name": "National Suicide Prevention Lifeline",
      "number": "988",
      "description":
          "24/7 free and confidential support for people in distress",
      "icon": "phone_in_talk",
    },
    {
      "name": "Crisis Text Line",
      "number": "741741",
      "description": "Text HOME to connect with a crisis counselor",
      "icon": "message",
      "isTextLine": true,
    },
    {
      "name": "SAMHSA National Helpline",
      "number": "1-800-662-4357",
      "description": "Treatment referral and information service",
      "icon": "support_agent",
    },
  ];

  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
        HapticFeedback.mediumImpact();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not launch phone dialer. Please dial $phoneNumber manually.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: Unable to make call. Please dial $phoneNumber manually.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _sendTextMessage(
    String phoneNumber,
    BuildContext context,
  ) async {
    final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
        HapticFeedback.mediumImpact();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not launch messaging app. Please text $phoneNumber manually.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: Unable to send message. Please text $phoneNumber manually.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'emergency',
                color: theme.colorScheme.error,
                size: 28,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Emergency Resources',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 1.h),

          Text(
            'If you\'re experiencing a mental health crisis, please reach out for immediate help',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          SizedBox(height: 2.h),

          ..._emergencyContacts.map((contact) {
            final isTextLine = contact["isTextLine"] as bool? ?? false;
            return Container(
              margin: EdgeInsets.only(bottom: 2.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomIconWidget(
                          iconName: contact["icon"] as String,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          contact["name"] as String,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 1.h),

                  Text(
                    contact["description"] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  SizedBox(height: 1.5.h),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (isTextLine) {
                          _sendTextMessage(
                            contact["number"] as String,
                            context,
                          );
                        } else {
                          _makePhoneCall(contact["number"] as String, context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                      icon: CustomIconWidget(
                        iconName: isTextLine ? 'message' : 'phone',
                        color: theme.colorScheme.onError,
                        size: 20,
                      ),
                      label: Text(
                        isTextLine
                            ? 'Text ${contact["number"]}'
                            : 'Call ${contact["number"]}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onError,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          SizedBox(height: 1.h),

          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'These services are free, confidential, and available 24/7',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
