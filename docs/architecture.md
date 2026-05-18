# FocusGuard Technical Architecture

## Overview
FocusGuard monitors macOS application usage and helps users maintain focus.

## Core Monitoring Module

### Technology
- **NSWorkspace.runningApplications** - Get list of active apps
- **NSWorkspace.frontmostApplication** - Get currently focused app
- **AXUIElement** - Accessibility API for deeper introspection
- **Poll interval**: 60 seconds

### Data Flow
```
App Launch → MonitoringService.start() 
  → Timer (60s interval) 
  → Fetch active app info 
  → StoreUsageRecord() 
  → SQLite DB
```

## Module Architecture (MVVM)

### Models
- `UsageRecord` - timestamp, app_bundle_id, app_name, duration
- `AppLimit` - app_bundle_id, daily_limit_seconds
- `DailySummary` - date, total_usage, app_breakdown

### ViewModels
- `MonitorViewModel` - ObservableObject for UI binding
- `SettingsViewModel` - Limit configuration
- `ReportViewModel` - Usage analytics

### Views (SwiftUI)
- `StatusBarMenu` - Main entry point (menu bar app)
- `UsageListView` - Daily app usage list
- `LimitsSettingsView` - Configure limits
- `ReportView` - Charts and analytics

## Database Schema (SQLite)

```sql
CREATE TABLE usage_records (
    id INTEGER PRIMARY KEY,
    app_bundle_id TEXT NOT NULL,
    app_name TEXT,
    start_time INTEGER NOT NULL,
    duration_seconds INTEGER DEFAULT 0
);

CREATE TABLE app_limits (
    id INTEGER PRIMARY KEY,
    app_bundle_id TEXT UNIQUE NOT NULL,
    daily_limit_seconds INTEGER NOT NULL
);
```

## Technical Constraints
- Requires Accessibility permission (for AXUIElement)
- No App Store distribution (uses private APIs)
- Minimum macOS version: 12.0 (Monterey)
