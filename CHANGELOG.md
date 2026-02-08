# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2026-02-08

### Breaking Changes
- Live Activity operations now support multiple concurrent activities by targeting activity IDs.
- `startActivity(with:showing:)` now returns `Result<Activity<Attributes>.ID, LiveActivityError>`.
- `updateActivity` and `stopActivity` now require `withID activityID` instead of attributes.
- `endAll(dismissalPolicy:)` is now asynchronous.
- `LiveActivityAttributes` no longer requires `Equatable`.
- Error cases were updated:
  - Removed `alreadyInProgress`
  - Removed `notActive`
  - Added `activityNotFound`

### Internal
- iOS-only ActivityKit compilation guards were tightened to `#if canImport(ActivityKit) && os(iOS)` for SwiftPM host builds.
