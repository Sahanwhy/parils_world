# Voice Alarm — Android Test Plan

Test on a physical Android phone, not only an emulator.

For each test, record Android version, device model, permissions granted and result:
- [ ] App foreground at alarm time.
- [ ] Screen locked.
- [ ] App in background.
- [ ] App swiped away from recents.
- [ ] Device rebooted after alarm was scheduled.
- [ ] Battery saver enabled.
- [ ] Battery optimization enabled for app.
- [ ] Do Not Disturb enabled.
- [ ] Notification permission denied.
- [ ] Exact alarm permission denied (if applicable).
- [ ] Voice file missing or deleted.
- [ ] Alarm disabled/deleted before its scheduled time.
- [ ] Repeating alarm across day boundaries and timezone changes.
- [ ] Long recording vs short recording.

Document OS restrictions honestly. Do not claim reliable full voice playback in every state unless verified.
