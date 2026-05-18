# FocusGuard

# Mac Software Monitoring & Self-Control App

## Product Vision
FocusGuard is a native macOS application that monitors software usage and helps users improve focus.

## Core Features

### 1. Software Monitoring
- Uses NSWorkspace/Accessibility API to monitor foreground applications
- Tracks active application, window title, and usage duration

### 2. Data Storage
- Local SQLite storage for usage records
- Daily/weekly/monthly aggregation

### 3. Self-Control Mechanism
- Set daily software usage limits
- Notifications when limits are exceeded
- Optional app blocking functionality

### 4. Report Generation
- Visual charts for usage data
- Daily/weekly focus reports
- Personalized suggestions

## Technical Stack

- **Platform**: macOS
- **Language**: Swift
- **UI**: SwiftUI (status bar menu)
- **Data**: SQLite.swift
- **Architecture**: MVVM

## Version Roadmap

- **v0.1 (MVP)**: Basic monitoring + storage
- **v0.2**: Limits + notifications
- **v0.3**: Reports + visualization
