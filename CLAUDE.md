# Android Best Practices

Follow these principles for all implementations in this project:

## Notifications
- Always use `setExactAndAllowWhileIdle()` (not `setExact()`) for exact alarms
- Check `canScheduleExactAlarms()` before scheduling on Android 12+ (API 31+)
- Persist all notification toggle states with `SharedPreferences`
- Handle all Android API version differences explicitly with `if (Build.VERSION.SDK_INT >= ...)` guards

## Permissions
- Handle all Android versions from API 21+ (Android 5.0 Lollipop)
- Never use APIs that only work on specific Android versions without fallbacks
- Always check runtime permissions for API 23+ (Marshmallow) while providing graceful degradation for lower APIs

## General
- Explicitly handle all Android API version differences — no assumptions about minimum SDK
- Provide fallbacks for every version-gated API
- Run `flutter analyze` before every push and fix all issues before proceeding
