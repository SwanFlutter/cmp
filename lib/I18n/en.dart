import 'messages.dart';
import 'translations.dart';

class English implements AppTranslationsKeys {
  @override
  Map<String, String> get keys => {
    // App General
    Messages.title: 'Markdown ↔ PDF Converter',
    Messages.welcome: 'Welcome to Markdown PDF Converter!',
    Messages.buyPackage: 'Buy Package',
    Messages.features: 'Features',

    // Converter
    Messages.markdownToPdf: 'Markdown to PDF',
    Messages.pdfToMarkdown: 'PDF to Markdown',
    Messages.selectFile: 'Select File',
    Messages.convert: 'Convert',
    Messages.downloading: 'Downloading...',
    Messages.downloadComplete: 'Download Complete',
    Messages.downloadError: 'Download Error',
    Messages.fileConverted: 'File Converted Successfully',
    Messages.conversionError: 'Conversion Error',
    Messages.openFile: 'Open File',
    Messages.saveFile: 'Save File',
    Messages.fileSaved: 'File Saved Successfully',
    Messages.saveError: 'Save Error',
    Messages.selectOutputLocation: 'Select Output Location',
    Messages.converting: 'Converting...',
    Messages.pleaseWait: 'Please Wait...',
    Messages.success: 'Success',
    Messages.error: 'Error',
    Messages.warning: 'Warning',
    Messages.info: 'Info',
    Messages.close: 'Close',
    Messages.cancel: 'Cancel',
    Messages.ok: 'OK',
    Messages.yes: 'Yes',
    Messages.no: 'No',

    // Settings
    Messages.settings: 'Settings',
    Messages.theme: 'Theme',
    Messages.light: 'Light',
    Messages.dark: 'Dark',
    Messages.system: 'System',
    Messages.language: 'Language',
    Messages.english: 'English',
    Messages.persian: 'Persian (فارسی)',

    // File Operations
    Messages.fileNotSelected: 'No file selected',
    Messages.invalidFile: 'Invalid file format',
    Messages.fileTooLarge: 'File is too large',
    Messages.unsupportedFormat: 'Unsupported file format',

    // Help/About
    Messages.help: 'Help',
    Messages.about: 'About',
    Messages.appDescription:
        'A powerful tool to convert between Markdown and PDF formats',
    Messages.version: 'Version',

    // Converter UI
    'converter.title': 'Markdown ↔ PDF Converter',
    'converter.clearText': 'Clear Text',
    'converter.emptyTextError': 'Please enter some text',
    'converter.markdownInputLabel': 'Markdown Text',
    'converter.markdownInputHint': 'Enter your markdown text here...',
    'converter.pasteFromClipboard': 'Paste from Clipboard',
    'converter.convertToPdf': 'Convert to PDF',
    'converter.downloadPdf': 'Download PDF',
    'converter.extractPdfText': 'Extract Text from PDF',
    'converter.markdownPreview': 'Markdown Preview',
    'converter.fullscreenPreview': 'Fullscreen Preview',
    'converter.preview': 'Preview',
    'settings.language': 'Language',
    'settings.toggleTheme': 'Toggle Theme',
  };
}
