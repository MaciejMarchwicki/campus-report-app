// Shared language helpers for the public web app.
// Put this file in: lib/app_language.dart

enum AppLanguage {
  en,
  pl,
}

String tr(AppLanguage lang, String en, String pl) {
  return lang == AppLanguage.en ? en : pl;
}
