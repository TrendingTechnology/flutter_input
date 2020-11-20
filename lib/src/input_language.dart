// Copyright 2020 Hajo.Lemcke@gmail.com
// Please see the LICENSE file for details.

import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_widget.dart';

import 'input_form.dart';
import 'input_language.i18n.dart';

/// Provides a text with the current language and a trailing icon.
///
/// Tapping on the widget opens a list to select another language (`Locale`).
/// The required parameter [supportedLocales] specifies the languages
/// which your app supports.
/// To change the language of the app see file `example/lib/main.dart`.
///
/// To select a country see [InputCountry].
class InputLanguage extends InputField<Locale> {
  /// Locales available in this app
  final List<Locale> supportedLocales;
  final bool withDeviceLocale;

  InputLanguage({
    Key key,
    InputDecoration decoration,
    bool enabled,
    Locale initialValue,
    Map<String, dynamic> map,
    ValueChanged<Locale> onChanged,
    ValueSetter<Locale> onSaved,
    String path,
    @required this.supportedLocales,
    bool wantKeepAlive = false,
    this.withDeviceLocale = false,
  }) : super(
          key: key,
          decoration: decoration,
          enabled: enabled,
          initialValue: initialValue,
          map: map,
          onChanged: onChanged ?? (Locale loc) {},
          onSaved: onSaved,
          path: path,
          wantKeepAlive: wantKeepAlive,
        );

  @override
  _InputLanguageState createState() => _InputLanguageState();
}

class _InputLanguageState extends InputFieldState<Locale> {
  List<DropdownMenuItem<Locale>> _languageList;

  @override
  InputLanguage get widget => super.widget;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _languageList ??= _buildLanguageList(widget.withDeviceLocale);
    value ??= I18n.of(context).locale;
    return super.buildInputField(
      context,
      DropdownButton(
        icon: Icon(Icons.language),
        items: _languageList,
        onChanged: isEnabled() ? (v) => super.didChange(v) : null,
        value: value,
      ),
    );
  }

  List<DropdownMenuItem<Locale>> _buildLanguageList(bool withDeviceLocale) {
    final String _imagePath = 'lib/assets/flags/';
    List<DropdownMenuItem<Locale>> _languages = widget.supportedLocales
        .map((item) => DropdownMenuItem(
              value: item,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Image.asset(
                    _imagePath + item.countryCode + '.png',
                    package: 'flutter_input',
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Text(_languageNames[item.languageCode].i18n),
                ],
              ),
            ))
        .toList();
    if (withDeviceLocale) {
      _languages.insert(
          0,
          DropdownMenuItem(
            child: Text('From device'.i18n),
            value: null,
          ));
    }
    return _languages;
  }

  final Map<String, String> _languageNames = {
    'de': 'german',
    'en': 'english',
    'es': 'spain',
    'fr': 'french',
    'jp': 'japanese',
  };
}
