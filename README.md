![CarLog Banner](banner_CarLog_1.png)

# CarLog

An AI-powered vehicle management and expense tracking mobile application built with Flutter.

CarLog helps car owners and fleet managers track fuel, maintenance, recurring costs, and reminders with AI-assisted input, automated anomaly detection, and vehicle sharing. Designed with a clean mobile interface, offline-first reliability, and real-time cloud synchronization.

Current app version: 0.1.0 (Interactive Prototype / UI Demo).

> Note: CarLog is currently an interactive UI/UX prototype and concept demonstration. While all interfaces, forms, charts, navigation flows, and mock engines are fully functional for demonstration purposes, live AI/OCR cloud integrations and production backends will be connected in future releases. It operates in local mock mode by default for an instant out-of-the-box demo experience, with optional Firebase mode for cloud synchronization.

---

## Demo video

🎬 [Watch full mobile walkthrough video (MP4)](screenshots/demo_video_compressed.mp4)

---

## Screenshots

### Authentication & onboarding
| Welcome & options | Sign in | Create account & password strength |
|:---:|:---:|:---:|
| <img src="screenshots/auth_1.jpg" width="260" alt="Welcome & Authentication Options"/> | <img src="screenshots/auth_2.jpg" width="260" alt="Sign In Screen"/> | <img src="screenshots/auth_3.jpg" width="260" alt="Create Account with Password Strength"/> |

### Garage & AI Insights
| Add vehicle | Vehicle specs & AI Insights | Costs, maintenance & history |
|:---:|:---:|:---:|
| <img src="screenshots/vehicle_1.jpg" width="260" alt="Add Vehicle Screen"/> | <img src="screenshots/vehicle_2.jpg" width="260" alt="Vehicle Detail with AI Overview"/> | <img src="screenshots/vehicle_3.jpg" width="260" alt="Garage Fleet List"/> |

### Vehicle identification & special tags
| Set special tag | Fleet list with tags | Filter by tagged vehicle |
|:---:|:---:|:---:|
| <img src="screenshots/vehicle_special_tag_1.jpg" width="260" alt="Special Tag Input Field"/> | <img src="screenshots/vehicle_special_tag_2.jpg" width="260" alt="Vehicles List with License Plate Tags"/> | <img src="screenshots/vehicle_special_tag_3.jpg" width="260" alt="Filtering by Tagged Vehicle"/> |

### Vehicle sharing & collaboration
| Add with code | Shared vehicle attribution | Manage sharing & members |
|:---:|:---:|:---:|
| <img src="screenshots/vehicle_share_1.jpg" width="260" alt="Join Vehicle with Code"/> | <img src="screenshots/vehicle_share_2.jpg" width="260" alt="Shared Vehicle Badge"/> | <img src="screenshots/vehicle_share_3.jpg" width="260" alt="Manage Sharing & Members"/> |

### AI voice expense input
| Expense mode selection | Voice dictation & waveform | AI-parsed expense review |
|:---:|:---:|:---:|
| <img src="screenshots/expense_voice_1.jpg" width="260" alt="Choose Expense Mode"/> | <img src="screenshots/expense_voice_2.jpg" width="260" alt="Voice Dictation Recording"/> | <img src="screenshots/expense_voice_3.jpg" width="260" alt="AI-Parsed Expense Review"/> |

### AI receipt scanner & OCR
| Camera receipt capture | OCR parsed invoice | Auto-filled expense review |
|:---:|:---:|:---:|
| <img src="screenshots/expense_camera_1.jpg" width="260" alt="Receipt OCR Scanner"/> | <img src="screenshots/expense_camera_2.jpg" width="260" alt="OCR Parsed Invoice"/> | <img src="screenshots/expense_camera_3.jpg" width="260" alt="Auto-filled Expense Review"/> |

### Data import
| Prerequisite check | Multi-format file upload | Import review & confirmation |
|:---:|:---:|:---:|
| <img src="screenshots/import_1.jpg" width="260" alt="Import Prerequisites"/> | <img src="screenshots/import_2.jpg" width="260" alt="Multi-format File Upload"/> | <img src="screenshots/import_3.jpg" width="260" alt="Import Review and Complete"/> |

### Expense ledger & filters
| Expense feed | Multi-criteria filters | Expense details & actions |
|:---:|:---:|:---:|
| <img src="screenshots/expense_screen_1.jpg" width="260" alt="Expense Ledger"/> | <img src="screenshots/expense_screen_2.jpg" width="260" alt="Filter Expenses Modal"/> | <img src="screenshots/expense_screen_3.jpg" width="260" alt="Expense Details and Actions"/> |

### Dashboard & cost analytics
| Overview & projections | Category & trend charts | Fleet spend & activity |
|:---:|:---:|:---:|
| <img src="screenshots/dashboard_1.jpg" width="260" alt="Dashboard Overview & Fuel Trend"/> | <img src="screenshots/dashboard_2.jpg" width="260" alt="Category Donut & 6-Month Trend"/> | <img src="screenshots/dashboard_3.jpg" width="260" alt="Vehicle Breakdown & Activity"/> |

### Maintenance & system notifications
| Upcoming reminders | Add custom reminder | System notification tray |
|:---:|:---:|:---:|
| <img src="screenshots/reminder_1.jpg" width="260" alt="Upcoming Reminders List"/> | <img src="screenshots/reminder_2.jpg" width="260" alt="Add Reminder Modal"/> | <img src="screenshots/reminder_3.jpg" width="260" alt="Android Lockscreen Notifications"/> |

### AI anomaly & fraud detection
| Odometer rollback warning | EV / fuel mismatch | Tank capacity overflow |
|:---:|:---:|:---:|
| <img src="screenshots/anomaly_detection_1.jpg" width="260" alt="Odometer Anomaly Alert"/> | <img src="screenshots/anomaly_detection_2.jpg" width="260" alt="Powertrain Anomaly Alert"/> | <img src="screenshots/anomaly_detection_3.jpg" width="260" alt="Tank Overflow Anomaly Alert"/> |

### Profile & data export
| Account & preferences | Privacy & settings | Data export & filters |
|:---:|:---:|:---:|
| <img src="screenshots/profile_and_export_1.jpg" width="260" alt="Profile Settings Screen"/> | <img src="screenshots/profile_and_export_2.jpg" width="260" alt="Privacy & Settings"/> | <img src="screenshots/profile_and_export_3.jpg" width="260" alt="Data Export & Privacy"/> |

---

## Tech Stack

- Flutter & Dart – cross-platform mobile UI toolkit and application logic
- AI & Reasoning Engine – natural language voice dictation, receipt vision OCR, intelligent dashboard cost projections, proactive maintenance scheduling, vehicle reliability insights, and fraud/anomaly detection
- Firebase Auth – email/password authentication, Google Sign-In, and guest access
- Cloud Firestore – real-time cloud database with user-isolated security rules
- FL Chart – interactive expense donuts, spline area graphs, and cost projections
- Flutter Local Notifications – scheduled maintenance, inspection, and service alerts
- Shared Preferences – persistent offline configuration and cached user preferences

---

## Features

- Garage management with dedicated profiles across ICE, EV, and hybrid vehicles
- AI mechanic insights providing vehicle-specific maintenance advice and reliability recommendations
- AI smart expense input with real-time speech-to-text dictation and natural language parsing
- AI receipt scanner for automated merchant, date, and line item extraction
- AI anomaly detection to prevent impossible entries, fuel mismatches on EVs, or odometer rollbacks
- Interactive analytics dashboard with expense breakdown by category, monthly cost curves, and ANRE Moldova live fuel market pricing
- Proactive maintenance reminders for technical inspections, oil service, tire rotations, and battery checks by date or mileage
- Fleet sharing and collaboration using unique 6-digit vehicle invite codes
- Data import and export supporting CSV and JSON backups

---

## Project setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Run the app

For the best experience on a connected mobile device:

```bash
flutter run --release
```

To run in debug mode:

```bash
flutter run
```