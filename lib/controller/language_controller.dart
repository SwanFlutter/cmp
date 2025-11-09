import 'package:flutter/material.dart';
import 'package:get_x_master/get_x_master.dart';
import 'package:get_x_storage/get_x_storage.dart';

class LanguageController extends GetXController {
  static const String _languageKey = 'app_language';
  static const String _defaultLanguage = 'fa_IR';

  final RxString currentLanguage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  void _loadSavedLanguage() {
    final savedLanguage = GetXStorage().read(key: _languageKey);
    if (savedLanguage != null) {
      currentLanguage.value = savedLanguage;
      _updateAppLocale(savedLanguage);
    } else {
      currentLanguage.value = _defaultLanguage;
      _updateAppLocale(_defaultLanguage);
    }
  }

  void changeLanguage(String languageCode) {
    if (currentLanguage.value == languageCode) return;

    currentLanguage.value = languageCode;
    GetXStorage().write(key: _languageKey, value: languageCode);
    _updateAppLocale(languageCode);
  }

  void _updateAppLocale(String languageCode) {
    switch (languageCode) {
      case 'en_US':
        Get.updateLocale(const Locale('en', 'US'));
        break;
      case 'fa_IR':
        Get.updateLocale(const Locale('fa', 'IR'));
        break;
      default:
        Get.updateLocale(const Locale('fa', 'IR'));
    }
  }

  bool get isPersian => currentLanguage.value == 'fa_IR';
  bool get isEnglish => currentLanguage.value == 'en_US';

  void toggleLanguage() {
    if (isPersian) {
      changeLanguage('en_US');
    } else {
      changeLanguage('fa_IR');
    }
  }
}
