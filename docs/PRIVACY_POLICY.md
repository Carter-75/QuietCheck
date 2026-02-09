# QuietCheck Privacy Policy

**Effective Date:** February 3, 2026  
**Last Updated:** February 3, 2026

## Introduction

QuietCheck ("we," "our," or "the app") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, store, and protect your personal information when you use our mental health and burnout detection application.

## Our Privacy Commitment

**QuietCheck is designed with privacy-first principles:**

- ✅ **No cloud storage** - All data is stored locally on your device
- ✅ **No user accounts required** - No email, phone number, or personal identifiers collected
- ✅ **No advertisements** - We do not use advertising SDKs or trackers
- ✅ **No third-party analytics** - We do not share data with analytics providers
- ✅ **Offline-first** - The app functions completely offline
- ✅ **Local-only processing** - All mental load analysis happens on your device
- ✅ **Encrypted storage** - All sensitive data is encrypted using AES-256 encryption
- ✅ **User-controlled deletion** - You can delete all your data at any time

## Information We Collect

### 1. Behavioral Data (Collected Locally)

**Android:**
- Device unlock frequency
- App switching velocity (how often you switch between apps)
- Session duration patterns
- Screen time statistics
- Activity recognition data (movement patterns)
- Accelerometer data (restlessness indicators)

**iOS:**
- Screen time patterns (via Screen Time framework)
- Movement activity data (via Core Motion)
- Device interaction patterns

**Purpose:** To detect behavioral changes that may indicate increased mental load or burnout risk.

**Storage:** All behavioral data is stored locally on your device in an encrypted database. It is never transmitted to external servers.

### 2. Health Data (Optional, User-Consented)

**Android (via Health Connect API):**
- Heart rate (HR)
- Heart rate variability (HRV)
- Sleep duration and quality
- Step count

**iOS (via HealthKit):**
- Heart rate (HR)
- Heart rate variability (HRV)
- Sleep analysis
- Step count

**Purpose:** To provide more accurate mental load assessments by correlating physiological stress indicators with behavioral patterns.

**Consent:** Health data collection is entirely optional. You must explicitly grant permission through your device's health settings. You can revoke this permission at any time.

**Storage:** Health data is stored locally on your device in an encrypted format. It is never transmitted to external servers.

### 3. Subscription Data

**What We Collect:**
- Subscription status (free or premium)
- Trial start date and remaining days
- Payment transaction records (processed by Google Play Store or Apple App Store)

**Purpose:** To manage your subscription and provide access to premium features.

**Storage:** Subscription data is stored locally on your device. Payment processing is handled entirely by Google Play Store or Apple App Store. We do not have access to your payment card information.

### 4. App Settings and Preferences

**What We Collect:**
- Notification preferences
- Quiet hours settings
- Sound pack selections
- Mental load sensitivity settings

**Purpose:** To personalize your app experience and respect your notification preferences.

**Storage:** Settings are stored locally on your device.

## What We DO NOT Collect

**QuietCheck does NOT collect, access, or store:**

- ❌ App contents (messages, emails, documents)
- ❌ Notification contents
- ❌ Browser history
- ❌ Typed text or keyboard input
- ❌ Location data
- ❌ Contact lists
- ❌ Photos or media files
- ❌ Phone calls or SMS messages
- ❌ Email addresses or phone numbers
- ❌ Social media accounts
- ❌ Biometric data (fingerprints, face scans)

## How We Use Your Information

**All data processing happens locally on your device:**

1. **Mental Load Scoring:** We analyze behavioral and health patterns to calculate a mental load score (0-100 scale).
2. **Burnout Prediction:** We use machine learning models (running locally) to predict burnout risk 48 hours in advance.
3. **Personalized Notifications:** We send proactive alerts when elevated mental load is detected.
4. **Trend Analysis:** We generate charts and insights showing your mental load patterns over time.
5. **Recovery Guidance:** We provide personalized recovery recommendations based on your patterns.

**No data is transmitted to external servers or third parties.**

## Data Storage and Security

### Encryption

- All sensitive data is encrypted using **AES-256-CBC encryption** with a device-specific encryption key.
- Encryption keys are stored securely using:
  - **Android:** Android Keystore
  - **iOS:** iOS Keychain

### Local Storage

- **Android:** Room database with SQLCipher encryption
- **iOS:** CoreData with encrypted store

### Data Retention

- Data is retained locally on your device until you choose to delete it.
- You can delete specific data types (e.g., mental load scores, health data) or perform a complete data wipe at any time.

## Your Privacy Rights

### 1. Access Your Data

- View all collected data through the app's analytics and history screens.
- Export your data in CSV format (Premium feature).

### 2. Delete Your Data

- **Selective Deletion:** Delete specific data types (e.g., mental load scores, activity records).
- **Complete Data Wipe:** Permanently delete all data stored by the app.
- **Uninstall:** Uninstalling the app removes all locally stored data.

### 3. Control Data Collection

- Disable behavioral data collection at any time.
- Revoke health data permissions through your device settings.
- Adjust notification preferences and quiet hours.

### 4. Export Your Data

- Premium users can export all data in CSV format for personal records or analysis.

## Permissions Explained

### Android Permissions

| Permission | Purpose | Required? |
|------------|---------|----------|
| **Usage Access** | Monitor app switching and screen time patterns | Required for core functionality |
| **Activity Recognition** | Detect movement patterns (restlessness indicators) | Optional |
| **Health Connect** | Access heart rate, HRV, sleep, and step data | Optional |
| **Notifications** | Send burnout warning alerts | Required for notifications |
| **Battery Optimization Exclusion** | Ensure background data collection works reliably | Recommended |

### iOS Permissions

| Permission | Purpose | Required? |
|------------|---------|----------|
| **Screen Time** | Monitor device usage patterns | Required for core functionality |
| **HealthKit** | Access heart rate, HRV, sleep, and step data | Optional |
| **Motion & Fitness** | Detect movement patterns | Optional |
| **Notifications** | Send burnout warning alerts | Required for notifications |

**You can revoke any permission at any time through your device settings.**

## Children's Privacy

QuietCheck is not intended for use by individuals under the age of 18. We do not knowingly collect personal information from children. If you believe a child has provided us with personal information, please contact us immediately.

## Changes to This Privacy Policy

We may update this Privacy Policy from time to time to reflect changes in our practices or legal requirements. We will notify you of any material changes by:

- Displaying a notice in the app
- Updating the "Last Updated" date at the top of this policy

Your continued use of the app after changes are posted constitutes your acceptance of the updated Privacy Policy.

## Third-Party Services

### Payment Processing

- **Google Play Store (Android):** Subscription payments are processed by Google. See [Google Play Terms of Service](https://play.google.com/about/play-terms/) and [Google Privacy Policy](https://policies.google.com/privacy).
- **Apple App Store (iOS):** Subscription payments are processed by Apple. See [Apple Media Services Terms and Conditions](https://www.apple.com/legal/internet-services/itunes/) and [Apple Privacy Policy](https://www.apple.com/privacy/).

**We do not have access to your payment card information.**

### AI Processing (Local Only)

- QuietCheck uses Google Gemini AI SDK for behavioral pattern analysis and burnout prediction.
- **All AI processing happens locally on your device.**
- No data is sent to Google's servers.

## Data Breach Notification

Because all data is stored locally on your device and never transmitted to external servers, the risk of a data breach is minimal. However, if we become aware of any security vulnerability that could affect your data, we will:

1. Notify you through the app
2. Provide guidance on protecting your data
3. Release a security update as soon as possible

## Contact Us

If you have any questions, concerns, or requests regarding this Privacy Policy or your data, please contact us at:

**Email:** privacy@quietcheck.app  
**Support:** support@quietcheck.app

## Legal Compliance

QuietCheck complies with:

- **GDPR (General Data Protection Regulation)** - European Union
- **CCPA (California Consumer Privacy Act)** - California, USA
- **HIPAA (Health Insurance Portability and Accountability Act)** - USA (for health data handling)
- **Google Play Store Developer Policies**
- **Apple App Store Review Guidelines**

## Your Consent

By using QuietCheck, you consent to this Privacy Policy and our data practices as described herein.

---

**QuietCheck — Your personal burnout radar.**  
**Privacy-first. Local-only. Always encrypted.**
