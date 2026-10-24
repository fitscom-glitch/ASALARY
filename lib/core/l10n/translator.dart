import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/l10n/en_translations.dart';

String tr(String s) {
  if (currentLang != 'en') return s;
  final exact = enExactTranslations[s];
  if (exact != null) return exact;
  for (final (re, build) in enPatternTranslations) {
    final match = re.firstMatch(s);
    if (match != null) return build(match);
  }
  return s;
}
