# Daily motivation

Today's motivation appears on the home screen. It uses 60 original messages bundled with the app, changes by the phone's local calendar date, and repeats after the full cycle. It needs neither an API key nor an internet connection.

Tap **Notify me daily** on the home card, or enable **Settings → Daily motivation notification**, and allow system notification permission. The default delivery time is **8:00 AM in the phone's local timezone**. Change it in Settings. The enable switch and time persist across launches. Enabling previews today's message immediately; subsequent reminders follow the chosen schedule. The in-app card refreshes at midnight and on resume.

The **Current reality notification** setting remains independent. Generating a Pessimistic, Cynical, Positive, Literal Negation or any other reality updates that notification only. Turning either notification off does not cancel the other. Clearing reality history also leaves daily motivation alone.

## Android

- Current reality uses notification ID `4107`; daily motivation uses `4108` and a separate channel.
- The native receiver updates ID `4108` each day, so daily messages replace one another rather than accumulating. After generating a reality and enabling daily motivation, the app has two independent notification items, subject to Android's display/grouping rules.
- One native inexact alarm schedules the next local delivery; Flutter and the AI backend do not need to be running.
- Boot, app-update and timezone/clock-change receivers restore the daily schedule. Existing current-reality delivery behavior is unchanged.
- Android may delay an inexact alarm for battery management. The app does not ask for exact-alarm privileges or try to bypass system restrictions. Force-stopping the app can stop delivery until it is reopened. Users and the OS can dismiss notifications; ongoing does not mean impossible to remove.

## iOS and macOS

- The app schedules the next 30 dated messages and renews this queue whenever it is opened/resumed. Open the app at least once every 30 days; reminders stop when the queue runs out.
- Daily messages use their own notification thread and reserved IDs `4200`–`4229`, plus `4108` for today's preview. `4107` is never cancelled by the daily service.
- The OS can retain earlier delivered messages in the daily group. Exactly two permanently pinned notifications is not guaranteed on Apple platforms. Opening the app refreshes the daily group and its queue.
- Reopen the app after changing timezone to recalculate the upcoming local delivery times.

On web, Windows and Linux, today's text remains visible, but the daily scheduling controls are disabled. Unsupported scheduling is never reported as enabled.

## Checks

Automated tests cover stable daily content, rotation, date boundaries, persisted settings, permission errors, Android method-channel requests and Apple queue isolation. An Android build checks the native receiver and manifest. Real-device delivery, battery restrictions, restart and overnight behavior still need device testing.

Manual Android test: generate a reality, enable daily motivation, confirm two entries, choose a time a few minutes ahead and leave the app. When the alarm fires, daily motivation should refresh without replacing current reality. Disable each feature in turn and verify the other remains. Test overnight content change and reboot recovery separately.

References: [Android alarm scheduling](https://developer.android.com/develop/background-work/services/alarms), [Apple local notification scheduling](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/SchedulingandHandlingLocalNotifications.html).
