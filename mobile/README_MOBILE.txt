Create the Flutter project inside this folder if it does not already exist:
  flutter create .

Then add dependencies only when needed and verify their current APIs:
  flutter pub add go_router
  flutter pub add shared_preferences
  flutter pub add flame
  flutter pub add just_audio
  flutter pub add flutter_local_notifications
  flutter pub add timezone

Choose a local database package (for example Drift/SQLite or Isar) after checking current compatibility. Do not add every package at once without implementation/tests.
