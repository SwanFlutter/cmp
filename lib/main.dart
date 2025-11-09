import 'package:cmp/I18n/translations.dart';
import 'package:cmp/controller/language_controller.dart';
import 'package:cmp/model/theme_manager.dart';
import 'package:cmp/screen/markdown_pdf_converter.dart';
import 'package:flutter/material.dart';
import 'package:get_x_master/get_x_master.dart';
import 'package:get_x_storage/get_x_storage.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetXStorage.init();

  // Initialize language controller
  Get.put(LanguageController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = ThemeManager();
    themeManager.init();
    final languageController = Get.find<LanguageController>();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeManager.themeNotifier,
      builder: (context, themeMode, child) {
        return Obx(() {
          // Get current locale from language controller
          Locale currentLocale;
          if (languageController.currentLanguage.value == 'en_US') {
            currentLocale = const Locale('en', 'US');
          } else {
            currentLocale = const Locale('fa', 'IR');
          }

          return GetMaterialApp(
            title: 'Markdown <-> PDF Converter',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.vazirmatnTextTheme(),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.vazirmatnTextTheme(
                ThemeData.dark().textTheme,
              ),
            ),
            themeMode: themeMode,
            translations: AppTranslations(),
            locale: currentLocale,
            fallbackLocale: const Locale('en', 'US'),
            home: const MarkdownPdfConverter(),
          );
        });
      },
    );
  }
}
