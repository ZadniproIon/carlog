# CarLog

An AI-powered vehicle management and expense tracking mobile application built with Flutter.

CarLog helps car owners and fleet managers track fuel, maintenance, recurring costs, and reminders with AI-assisted input, automated anomaly detection, and vehicle sharing. Designed with a clean mobile interface, offline-first reliability, and real-time cloud synchronization.

Current app version: 1.0 (Demo).

> Note: CarLog is currently a prototype and demo showcasing the mobile user experience, architecture, and AI-driven workflows. The application will be finalized and expanded into full production in the future. It operates in localcal mock mode by default for an instant out-of-the-box demo experience, with optional Firebase Mode for cloud synchronization.

---

## Screenshots

### Dashboard & Cost Analytics
| Overview & Projections | Category & Trend Charts | Fleet Spend & Activity |
|:---:|:---:|:---:|
| <img src="screenshots/dashboard_1.jpg" width="260" alt="Dashboard Overview & Fuel Trend"/> | <img src="screenshots/dashboard_2.jpg" width="260" alt="Category Donut & 6-Month Trend"/> | <img src="screenshots/dashboard_3.jpg" width="260" alt="Vehicle Breakdown & Activity"/> |

### Garage & AI Mechanic Insights
| Add Vehicle | Vehicle Specs & AI Insights | Multi-Vehicle Garage |
|:---:|:---:|:---:|
| <img src="screenshots/vehicle_1.jpg" width="260" alt="Add Vehicle Screen"/> | <img src="screenshots/vehicle_2.jpg" width="260" alt="Vehicle Detail with AI Overview"/> | <img src="screenshots/vehicle_3.jpg" width="260" alt="Garage Fleet List"/> |

### Multi-Powertrain Support (ICE, EV, Hybrid)
| Diesel / TDI (Passat) | Electric / EV (Tesla Model 3) | Hybrid (Porsche Cayenne) |
|:---:|:---:|:---:|
| <img src="screenshots/vehicle_special_tag_1.jpg" width="260" alt="Diesel Vehicle Card"/> | <img src="screenshots/vehicle_special_tag_2.jpg" width="260" alt="EV Electric Vehicle Card"/> | <img src="screenshots/vehicle_special_tag_3.jpg" width="260" alt="Hybrid Vehicle Card"/> |

### Smart Expense Input (Voice, Camera & Manual)
| Voice Dictation | Camera Receipt Scanner | Filterable Ledger |
|:---:|:---:|:---:|
| <img src="screenshots/expense_voice_2.jpg" width="260" alt="Voice Dictation Recording"/> | <img src="screenshots/expense_camera_1.jpg" width="260" alt="Receipt OCR Scanner"/> | <img src="screenshots/expense_screen_1.jpg" width="260" alt="Expense Ledger"/> |

### AI Anomaly & Fraud Detection
| Odometer Rollback Warning | EV / Fuel Mismatch | Tank Capacity Overflow |
|:---:|:---:|:---:|
| <img src="screenshots/anomaly_detection_1.jpg" width="260" alt="Odometer Anomaly Alert"/> | <img src="screenshots/anomaly_detection_2.jpg" width="260" alt="Powertrain Anomaly Alert"/> | <img src="screenshots/anomaly_detection_3.jpg" width="260" alt="Tank Overflow Anomaly Alert"/> |

### Maintenance & System Notifications
| Upcoming Reminders | Add Custom Reminder | System Notification Tray |
|:---:|:---:|:---:|
| <img src="screenshots/reminder_1.jpg" width="260" alt="Upcoming Reminders List"/> | <img src="screenshots/reminder_2.jpg" width="260" alt="Add Reminder Modal"/> | <img src="screenshots/reminder_3.jpg" width="260" alt="Android Lockscreen Notifications"/> |

### Vehicle Sharing & Collaboration
| Generate Invite Code | Shared Vehicle Attribution | Join Shared Vehicle |
|:---:|:---:|:---:|
| <img src="screenshots/vehicle_share_1.jpg" width="260" alt="Share Vehicle Code"/> | <img src="screenshots/vehicle_share_2.jpg" width="260" alt="Shared Vehicle Badge"/> | <img src="screenshots/vehicle_share_3.jpg" width="260" alt="Join Vehicle Fleet"/> |

### Profile, Import & Data Export
| Account & Theme Settings | Universal File Import | Backup & Data Export |
|:---:|:---:|:---:|
| <img src="screenshots/profile_and_export_1.jpg" width="260" alt="Profile Settings Screen"/> | <img src="screenshots/import_2.jpg" width="260" alt="File Import Workflow"/> | <img src="screenshots/profile_and_export_2.jpg" width="260" alt="Data Export & Privacy"/> |

---

## Tech Stack

- Flutter & Dart – cross-platform mobile UI toolkit and application logic
- AI & Reasoning Engine – natural language expense processing, receipt vision OCR, and anomaly detection
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