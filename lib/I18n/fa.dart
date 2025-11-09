import 'messages.dart';
import 'translations.dart';

class Farsi implements AppTranslationsKeys {
  @override
  Map<String, String> get keys => {
    // App General
    Messages.title: 'مبدل مارک‌دان به پی‌دی‌اف',
    Messages.welcome: 'به مبدل مارک‌دان به پی‌دی‌اف خوش آمدید!',
    Messages.buyPackage: 'خرید بسته',
    Messages.features: 'ویژگی‌ها',

    // Converter
    Messages.markdownToPdf: 'مارک‌دان به پی‌دی‌اف',
    Messages.pdfToMarkdown: 'پی‌دی‌اف به مارک‌دان',
    Messages.selectFile: 'انتخاب فایل',
    Messages.convert: 'تبدیل',
    Messages.downloading: 'در حال دانلود...',
    Messages.downloadComplete: 'دانلود کامل شد',
    Messages.downloadError: 'خطا در دانلود',
    Messages.fileConverted: 'فایل با موفقیت تبدیل شد',
    Messages.conversionError: 'خطا در تبدیل',
    Messages.openFile: 'باز کردن فایل',
    Messages.saveFile: 'ذخیره فایل',
    Messages.fileSaved: 'فایل با موفقیت ذخیره شد',
    Messages.saveError: 'خطا در ذخیره‌سازی',
    Messages.selectOutputLocation: 'انتخاب محل خروجی',
    Messages.converting: 'در حال تبدیل...',
    Messages.pleaseWait: 'لطفاً صبر کنید...',
    Messages.success: 'موفقیت',
    Messages.error: 'خطا',
    Messages.warning: 'هشدار',
    Messages.info: 'اطلاعات',
    Messages.close: 'بستن',
    Messages.cancel: 'لغو',
    Messages.ok: 'تأیید',
    Messages.yes: 'بله',
    Messages.no: 'خیر',

    // Settings
    Messages.settings: 'تنظیمات',
    Messages.theme: 'تم',
    Messages.light: 'روشن',
    Messages.dark: 'تاریک',
    Messages.system: 'سیستم',
    Messages.language: 'زبان',
    Messages.english: 'انگلیسی (English)',
    Messages.persian: 'فارسی',

    // File Operations
    Messages.fileNotSelected: 'هیچ فایلی انتخاب نشده است',
    Messages.invalidFile: 'فرمت فایل نامعتبر است',
    Messages.fileTooLarge: 'فایل خیلی بزرگ است',
    Messages.unsupportedFormat: 'فرمت فایل پشتیبانی نمی‌شود',

    // Help/About
    Messages.help: 'راهنما',
    Messages.about: 'درباره',
    Messages.appDescription:
        'ابزاری قدرتمند برای تبدیل بین فرمت‌های مارک‌دان و پی‌دی‌اف',
    Messages.version: 'نسخه',

    // Converter UI
    'converter.title': 'مبدل مارک‌دان ↔ پی‌دی‌اف',
    'converter.clearText': 'پاک کردن متن',
    'converter.emptyTextError': 'لطفاً متنی وارد کنید',
    'converter.markdownInputLabel': 'متن مارک‌دان',
    'converter.markdownInputHint': 'متن مارک‌دان خود را اینجا وارد کنید...',
    'converter.pasteFromClipboard': 'چسباندن از کلیپ‌بورد',
    'converter.convertToPdf': 'تبدیل به PDF',
    'converter.downloadPdf': 'دانلود PDF',
    'converter.extractPdfText': 'استخراج متن از PDF',
    'converter.markdownPreview': 'پیش‌نمایش مارک‌دان',
    'converter.fullscreenPreview': 'پیش‌نمایش تمام صفحه',
    'converter.preview': 'پیش‌نمایش',
    'settings.language': 'زبان',
    'settings.toggleTheme': 'تغییر تم',
  };
}
