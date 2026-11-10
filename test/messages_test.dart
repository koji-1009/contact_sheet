import 'dart:convert';
import 'dart:io';

import 'package:contact_sheet/src/messages.g.dart';
import 'package:test/test.dart';

/// The ARB file of [locale], by key.
Map<String, Object?> _arb(String locale) =>
    jsonDecode(File('lib/src/l10n/messages_$locale.arb').readAsStringSync())
        as Map<String, Object?>;

/// The `{name}`s in [text].
Set<String> _names(String text) => {
  for (final m in RegExp(r'\{(\w+)\}').allMatches(text)) m[1]!,
};

void main() {
  final en = _arb('en');
  final keys = [
    for (final key in en.keys)
      if (!key.startsWith('@')) key,
  ];
  // Its parameters, as the English one declares them: what the generated
  // method takes, and what it replaces in each language's words.
  Set<String> params(String key) => switch (en['@$key']) {
    {'placeholders': final Map<String, Object?> placeholders} => {
      ...placeholders.keys,
    },
    _ => const {},
  };

  test('each language has the words of every message, and none else', () {
    expect(Messages.locales, ['en', 'ja']);
    for (final locale in Messages.locales) {
      final arb = _arb(locale);
      expect(
        {
          for (final key in arb.keys)
            if (!key.startsWith('@')) key,
        },
        keys.toSet(),
        reason: locale,
      );
    }
  });

  test('a message says each of its parameters, in every language, and no '
      'other: a name it does not take would be shown as written', () {
    for (final locale in Messages.locales) {
      final arb = _arb(locale);
      for (final key in keys) {
        expect(
          _names(arb[key]! as String),
          params(key),
          reason: 'messages_$locale.arb: $key',
        );
      }
    }
  });
}
