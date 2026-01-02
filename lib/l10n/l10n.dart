import 'package:flutter/material.dart';

class AppL10n {
  static const List<Locale> supportedLocales = [
    Locale('en'),
  ];

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  final String localeName;

  AppL10n(this.localeName);

  String get appTitle => 'Skillora Family';
  String get tabDiscover => 'Discover';
  String get tabAssignments => 'Assignments';
  String get tabHome => 'Home';
  String get tabMessages => 'Messages';
  String get tabProfile => 'Profile';
  String get emptyState => 'Nothing here yet';
  String get loading => 'Loading...';
  String get error => 'Something went wrong';
  String get discoverTitle => 'Find Classes';
  String get assignmentsTitle => 'Your Assignments';
  String get homeTitle => 'Overview';
  String get messagesTitle => 'Inbox';
  String get profileTitle => 'Profile';
  String get roleParent => 'Parent';
  String get roleStudent => 'Student';
  String get switchChild => 'Switch Child';
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en'].contains(locale.languageCode);
  }

  @override
  Future<AppL10n> load(Locale locale) async {
    return AppL10n(locale.languageCode);
  }

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}
