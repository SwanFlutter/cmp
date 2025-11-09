import 'package:get_x_master/get_x_master.dart';


import 'en.dart';
import 'fa.dart';

abstract class AppTranslationsKeys {
  Map<String, String> get keys;
}

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': English().keys,
    'fa_IR': Farsi().keys,
  };
}
