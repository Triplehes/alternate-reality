# Data handling for version 2.0 preview

- **Thoughts and perspectives:** the latest 500 entries are stored locally using app preferences. Clear History removes these local records and the current-reality notification. New entries replace the oldest when the limit is reached. Uninstalling the Android Preview removes its local history. The Android app disables system app-data backup.
- **AI:** only when you request a perspective, the text and selected mode are sent over HTTPS to the backend and to OpenAI. The backend does not log thought text or generated responses. Requests set `store: false`; this does not override the provider's other retention policies. Avoid sensitive personal information.
- **Voice:** microphone access is optional. Recognition uses the device/browser speech service, which may process audio remotely under that platform's policies. You can always type instead.
- **Notifications:** optional daily motivation and current-reality notifications have separate controls. Notification text may appear on the lock screen. Adjust the device's lock-screen notification privacy if needed.
- **Invitations:** Android stores a personal preview bearer code with platform-backed secure storage. The web app keeps it only in memory for the current page session. Remove Invitation clears the locally saved invitation; ask the app owner to revoke the code if it has been shared. Removing an invitation does not erase history.
- **Server usage records:** the backend keeps invitation hashes and current UTC-day request counts on a persistent disk for quota enforcement. It does not store thought text in this ledger. Hosting/proxy infrastructure may retain ordinary connection/access logs; configure that hosting before launch.
- **Analytics:** no analytics or advertising SDK was added.

This is an invitation-only test release. Contact the person who invited you for feedback, access removal or privacy questions. A public launch must add the operator's identity/contact details and review hosting/provider retention arrangements before publishing a final privacy policy.
