// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:cmp/I18n/messages.dart';
import 'package:cmp/controller/language_controller.dart';
import 'package:cmp/model/theme_manager.dart';
import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_x_master/get_x_master.dart';
import 'package:get_x_storage/get_x_storage.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_text/pdf_text.dart';
import 'package:printing/printing.dart';

class MarkdownPdfConverter extends StatefulWidget {
  const MarkdownPdfConverter({super.key});

  @override
  State<MarkdownPdfConverter> createState() => _MarkdownPdfConverterState();
}

class _MarkdownPdfConverterState extends State<MarkdownPdfConverter> {
  final TextEditingController _markdownController = TextEditingController();
  String pdfExtractedText = '';
  bool _isLoading = false;
  bool _isDarkMode = false;
  final ScrollController _scrollController = ScrollController();

  final storage = GetXStorage();
  Uint8List? _pdfBytes;
  String? _pdfFileName;

  final themeManager = ThemeManager();

  // Cache fonts to avoid reloading
  pw.Font? _cachedFont;
  pw.Font? _cachedBoldFont;
  List<pw.Font>? _cachedFallbacks;
  // کنترل نسخه‌ی کش فونت برای بی‌اثر کردن کش‌های قدیمی پس از hot-reload
  static const int _kFontCacheVersion = 2;
  int _fontCacheVersion = 0;

  @override
  void dispose() {
    _markdownController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleTheme() async {
    await themeManager.toggleTheme();
    setState(() {
      _isDarkMode = themeManager.isDarkMode;
    });
  }

  Future<void> _convertMarkdownToPdf() async {
    if (_markdownController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('converter.emptyTextError'.tr)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pdf = pw.Document();

      // بی‌اعتبارسازی کش‌های قدیمی پس از تغییرات مربوط به فونت‌ها
      if (_fontCacheVersion != _kFontCacheVersion) {
        _cachedFont = null;
        _cachedBoldFont = null;
        _cachedFallbacks = null;
        _fontCacheVersion = _kFontCacheVersion;
      }

      // Load fonts with caching for better performance
      pw.Font font;
      pw.Font? boldFont;
      List<pw.Font> fontFallbacks = [];

      if (_cachedFont != null &&
          _cachedBoldFont != null &&
          _cachedFallbacks != null) {
        // Use cached fonts
        font = _cachedFont!;
        boldFont = _cachedBoldFont;
        fontFallbacks = _cachedFallbacks!;
        debugPrint('✓ استفاده از فونت‌های کش شده');
      } else {
        // Load fonts for the first time
        try {
          // Primary font: Amiri (best Arabic shaping support)
          font = await PdfGoogleFonts.amiriRegular();
          boldFont = await PdfGoogleFonts.amiriBold();

          // Add Noto Sans as fallback for better Latin character support
          try {
            final latinFont = await PdfGoogleFonts.notoSansRegular();
            fontFallbacks.add(latinFont);
            debugPrint('✓ اضافه شد: Noto Sans (Latin)');
          } catch (e) {
            debugPrint('⚠ خطا در Noto Sans: $e');
          }

          // نکته: فونت‌های ایموجی رنگی (مانند Noto Color Emoji) توسط
          // کتابخانه pdf به‌درستی پشتیبانی نمی‌شوند و باعث کرش می‌شوند.
          // بنابراین از افزودن fallback ایموجی خودداری می‌کنیم تا پایداری حفظ شود.

          debugPrint('✓ بارگذاری: Amiri (بهترین برای فارسی)');
        } catch (e) {
          debugPrint('✗ خطا در بارگذاری Amiri: $e');
          try {
            // Fallback: Use Noto Sans Arabic
            font = await PdfGoogleFonts.notoSansArabicRegular();
            boldFont = await PdfGoogleFonts.notoSansArabicBold();

            // Add Latin font fallback
            try {
              final latinFont = await PdfGoogleFonts.notoSansRegular();
              fontFallbacks.add(latinFont);
            } catch (e2) {
              debugPrint('⚠ خطا در Noto Sans: $e2');
            }

            // از افزودن فونت ایموجی اجتناب می‌شود (عدم پشتیبانی پایدار)

            debugPrint('✓ بارگذاری: Noto Sans Arabic');
          } catch (e2) {
            debugPrint('✗ خطا در بارگذاری Noto Sans Arabic: $e2');
            try {
              // Last resort: Vazirmatn from assets
              final fontData = await rootBundle.load(
                'assets/fonts/Vazirmatn-Regular.ttf',
              );
              font = pw.Font.ttf(fontData);
              boldFont = font;

              // از افزودن فونت ایموجی اجتناب می‌شود (عدم پشتیبانی پایدار)

              debugPrint('✓ بارگذاری: Vazirmatn از assets');
            } catch (e3) {
              debugPrint('✗ خطا در همه فونت‌ها: $e3');
              throw Exception('نمی‌توان فونت بارگذاری کرد');
            }
          }
        }

        // Cache the fonts for next time
        _cachedFont = font;
        _cachedBoldFont = boldFont;
        _cachedFallbacks = fontFallbacks;
      }

      final markdownText = _markdownController.text;

      debugPrint('📏 طول متن ورودی: ${markdownText.length} کاراکتر');
      debugPrint('📝 تعداد خطوط: ${markdownText.split('\n').length}');

      // Convert Markdown to PDF widgets (line by line)
      final widgets = _markdownLinesToPdfWidgets(markdownText, font);
      debugPrint('🎨 تعداد widget های تولید شده: ${widgets.length}');

      // Detect if text is primarily RTL
      final isRtl = _isPersian(markdownText);

      // تقسیم محتوا به صفحات دستی برای جلوگیری از حلقه بی‌نهایت
      const itemsPerPage = 20; // افزایش تعداد آیتم‌ها در هر صفحه
      int pageCount = 0;

      for (int i = 0; i < widgets.length; i += itemsPerPage) {
        final end = (i + itemsPerPage < widgets.length)
            ? i + itemsPerPage
            : widgets.length;
        final pageWidgets = widgets.sublist(i, end);
        pageCount++;

        debugPrint(
          '📄 صفحه $pageCount: ${pageWidgets.length} widget (از $i تا $end)',
        );

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            theme: pw.ThemeData.withFont(
              base: font,
              bold: boldFont ?? font,
              italic: font,
              boldItalic: boldFont ?? font,
              fontFallback: fontFallbacks,
            ),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: isRtl
                    ? pw.CrossAxisAlignment.end
                    : pw.CrossAxisAlignment.start,
                mainAxisSize: pw.MainAxisSize.min,
                children: pageWidgets,
              );
            },
          ),
        );
      }

      debugPrint('✅ تعداد کل صفحات تولید شده: $pageCount');

      // اگر محتوا خالی بود، یک صفحه خالی اضافه کن
      if (widgets.isEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              return pw.Text('بدون محتوا');
            },
          ),
        );
      }

      final pdfBytes = await pdf.save();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'markdown_$timestamp.pdf';

      // Store PDF bytes in get_x_storage
      await storage.write(key: fileName, value: pdfBytes);

      setState(() {
        _pdfBytes = pdfBytes;
        _pdfFileName = fileName;
        _isLoading = false;
      });

      // Show PDF preview
      await _showPdfPreview();
    } catch (e, stackTrace) {
      debugPrint('❌ خطا در ایجاد PDF: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ایجاد PDF: ${e.toString()}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: 'بستن', onPressed: () {}),
          ),
        );
      }
    }
  }

  List<pw.Widget> _markdownLinesToPdfWidgets(
    String markdownText,
    pw.Font font,
  ) {
    final widgets = <pw.Widget>[];
    final lines = markdownText.split('\n');

    bool inTable = false;
    List<List<String>> tableRows = [];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      // Skip empty lines
      if (line.trim().isEmpty) {
        continue;
      }

      final isRtl = _isPersian(line);
      final textDirection = isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
      final textAlign = isRtl ? pw.TextAlign.right : pw.TextAlign.left;

      // Headings
      if (line.startsWith('# ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              _processPersianText(line.substring(2)),
              style: pw.TextStyle(
                font: font,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
              textDirection: textDirection,
              textAlign: textAlign,
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              _processPersianText(line.substring(3)),
              style: pw.TextStyle(
                font: font,
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
              textDirection: textDirection,
              textAlign: textAlign,
            ),
          ),
        );
      } else if (line.startsWith('### ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              _processPersianText(line.substring(4)),
              style: pw.TextStyle(
                font: font,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
              textDirection: textDirection,
              textAlign: textAlign,
            ),
          ),
        );
      }
      // List items
      else if (line.startsWith('- ') || line.startsWith('* ')) {
        final itemText = line.substring(2);
        widgets.add(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('• ', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.Expanded(
                child: pw.Text(
                  _processPersianText(itemText),
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 14,
                    lineSpacing: 1.5,
                  ),
                  textDirection: textDirection,
                  textAlign: textAlign,
                ),
              ),
            ],
          ),
        );
      }
      // Table separator
      else if (line.contains('|') && line.contains('-')) {
        // Skip table separator line
        continue;
      }
      // Table row
      else if (line.contains('|')) {
        final cells = line
            .split('|')
            .where((c) => c.trim().isNotEmpty)
            .toList();
        tableRows.add(cells);
        inTable = true;
      }
      // Regular paragraph
      else {
        // If we were in a table, render it
        if (inTable && tableRows.isNotEmpty) {
          _addTableWidget(widgets, tableRows, font);
          tableRows.clear();
          inTable = false;
        }

        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              _processPersianText(line),
              style: pw.TextStyle(font: font, fontSize: 14, lineSpacing: 1.5),
              textDirection: textDirection,
              textAlign: textAlign,
            ),
          ),
        );
      }
    }

    // Render remaining table if any
    if (inTable && tableRows.isNotEmpty) {
      _addTableWidget(widgets, tableRows, font);
    }

    return widgets;
  }

  void _addTableWidget(
    List<pw.Widget> widgets,
    List<List<String>> tableRows,
    pw.Font font,
  ) {
    if (tableRows.isEmpty) return;

    final headers = tableRows.first;
    final dataRows = tableRows.length > 1
        ? tableRows.sublist(1)
        : <List<String>>[];

    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
        children: [
          // Header row
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: headers.map((cell) {
              final isRtl = _isPersian(cell);
              return pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  _processPersianText(cell.trim()),
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textDirection: isRtl
                      ? pw.TextDirection.rtl
                      : pw.TextDirection.ltr,
                  textAlign: isRtl ? pw.TextAlign.right : pw.TextAlign.left,
                ),
              );
            }).toList(),
          ),
          // Data rows
          ...dataRows.map((row) {
            return pw.TableRow(
              children: row.map((cell) {
                final isRtl = _isPersian(cell);
                return pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    _processPersianText(cell.trim()),
                    style: pw.TextStyle(font: font, fontSize: 12),
                    textDirection: isRtl
                        ? pw.TextDirection.rtl
                        : pw.TextDirection.ltr,
                    textAlign: isRtl ? pw.TextAlign.right : pw.TextAlign.left,
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  List<pw.Widget> markdownToPdfWidgets(List<md.Node> document, pw.Font font) {
    final widgets = <pw.Widget>[];
    int widgetCount = 0;
    const maxWidgets = 10000; // جلوگیری از تولید بی‌نهایت widget

    debugPrint('🔍 شروع پردازش ${document.length} نود');

    for (final node in document) {
      if (widgetCount >= maxWidgets) {
        debugPrint('⚠ تعداد widget ها از حد مجاز گذشت');
        break;
      }
      if (node is md.Element) {
        final nodeText = node.textContent;

        debugPrint(
          '  📌 پردازش نود: ${node.tag} - طول متن: ${nodeText.length}',
        );

        // Skip empty nodes
        if (nodeText.trim().isEmpty) {
          debugPrint('    ⏭ رد شد (خالی)');
          continue;
        }

        final isRtl = _isPersian(nodeText);
        final textDirection = isRtl
            ? pw.TextDirection.rtl
            : pw.TextDirection.ltr;
        final textAlign = isRtl ? pw.TextAlign.right : pw.TextAlign.left;

        // Handle ul/ol lists
        if (node.tag == 'ul' || node.tag == 'ol') {
          debugPrint('    📋 لیست با ${node.children?.length ?? 0} آیتم');
          for (final child in node.children ?? []) {
            if (child is md.Element && child.tag == 'li') {
              final liText = child.textContent;
              debugPrint(
                '      • آیتم لیست: ${liText.substring(0, liText.length > 30 ? 30 : liText.length)}...',
              );
              if (liText.trim().isNotEmpty) {
                final liIsRtl = _isPersian(liText);
                final liTextDirection = liIsRtl
                    ? pw.TextDirection.rtl
                    : pw.TextDirection.ltr;
                final liTextAlign = liIsRtl
                    ? pw.TextAlign.right
                    : pw.TextAlign.left;

                widgets.add(
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '• ',
                        style: pw.TextStyle(font: font, fontSize: 14),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          _processPersianText(liText),
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 14,
                            lineSpacing: 1.5,
                          ),
                          textDirection: liTextDirection,
                          textAlign: liTextAlign,
                        ),
                      ),
                    ],
                  ),
                );
                widgetCount++;
              }
            }
          }
          continue;
        }

        switch (node.tag) {
          case 'h1':
          case 'h2':
          case 'h3':
            // فقط متن مستقیم heading را بگیر، نه تمام children
            String headingText = '';
            for (final child in node.children ?? []) {
              if (child is md.Text) {
                headingText += child.text;
              }
            }

            if (headingText.trim().isEmpty) {
              headingText = nodeText.split('\n').first; // فقط خط اول
            }

            final fontSize = node.tag == 'h1'
                ? 24.0
                : node.tag == 'h2'
                ? 20.0
                : 18.0;
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  _processPersianText(headingText),
                  style: pw.TextStyle(
                    font: font,
                    fontSize: fontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textDirection: textDirection,
                  textAlign: textAlign,
                ),
              ),
            );
            break;
          case 'p':
            final processedText = _processPersianText(nodeText);
            if (processedText.trim().isNotEmpty) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Text(
                    processedText,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      lineSpacing: 1.5,
                    ),
                    textDirection: textDirection,
                    textAlign: textAlign,
                  ),
                ),
              );
            }
            break;
          case 'strong':
          case 'em':
            // این‌ها معمولاً inline هستند و نباید به عنوان widget جداگانه اضافه شوند
            // آنها باید درون پاراگراف parent خود پردازش شوند
            debugPrint('    ⏭ رد شد (inline element: ${node.tag})');
            break;
          case 'code':
            widgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  nodeText,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.normal,
                  ),
                  textDirection: pw.TextDirection.ltr,
                  textAlign: pw.TextAlign.left,
                ),
              ),
            );
            break;
          case 'table':
            final headers = <pw.Widget>[];
            final rows = <List<pw.Widget>>[];
            bool isFirstRow = true;

            // Handle both direct tr and nested thead/tbody
            final tableChildren = node.children ?? [];
            for (final child in tableChildren) {
              if (child is md.Element &&
                  (child.tag == 'thead' || child.tag == 'tbody')) {
                // Process rows inside thead/tbody
                for (final tr in child.children ?? []) {
                  if (tr is md.Element && tr.tag == 'tr') {
                    final row = <pw.Widget>[];
                    for (final cell in tr.children ?? []) {
                      if (cell is md.Element &&
                          (cell.tag == 'td' || cell.tag == 'th')) {
                        final cellText = cell.textContent.trim();
                        final cellIsRtl = _isPersian(cellText);
                        final cellTextDirection = cellIsRtl
                            ? pw.TextDirection.rtl
                            : pw.TextDirection.ltr;
                        final cellTextAlign = cellIsRtl
                            ? pw.TextAlign.right
                            : pw.TextAlign.left;

                        final cellWidget = pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            _processPersianText(cellText.replaceAll('`', '')),
                            style: pw.TextStyle(
                              font: font,
                              fontSize: cell.tag == 'th' ? 14 : 12,
                              fontWeight: cell.tag == 'th'
                                  ? pw.FontWeight.bold
                                  : pw.FontWeight.normal,
                            ),
                            textDirection: cellTextDirection,
                            textAlign: cellTextAlign,
                          ),
                        );
                        row.add(cellWidget);
                        if (isFirstRow && cell.tag == 'th') {
                          headers.add(cellWidget);
                        }
                      }
                    }
                    if (!isFirstRow || headers.isEmpty) {
                      rows.add(row);
                    }
                    isFirstRow = false;
                  }
                }
              } else if (child is md.Element && child.tag == 'tr') {
                // Direct tr (fallback)
                final row = <pw.Widget>[];
                for (final cell in child.children ?? []) {
                  if (cell is md.Element &&
                      (cell.tag == 'td' || cell.tag == 'th')) {
                    final cellText = cell.textContent.trim();
                    final cellIsRtl = _isPersian(cellText);
                    final cellTextDirection = cellIsRtl
                        ? pw.TextDirection.rtl
                        : pw.TextDirection.ltr;
                    final cellTextAlign = cellIsRtl
                        ? pw.TextAlign.right
                        : pw.TextAlign.left;

                    final cellWidget = pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        _processPersianText(cellText.replaceAll('`', '')),
                        style: pw.TextStyle(
                          font: font,
                          fontSize: cell.tag == 'th' ? 14 : 12,
                          fontWeight: cell.tag == 'th'
                              ? pw.FontWeight.bold
                              : pw.FontWeight.normal,
                        ),
                        textDirection: cellTextDirection,
                        textAlign: cellTextAlign,
                      ),
                    );
                    row.add(cellWidget);
                    if (isFirstRow && cell.tag == 'th') {
                      headers.add(cellWidget);
                    }
                  }
                }
                if (!isFirstRow || headers.isEmpty) {
                  rows.add(row);
                }
                isFirstRow = false;
              }
            }

            if (headers.isNotEmpty || rows.isNotEmpty) {
              widgets.add(
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey600,
                    width: 0.5,
                  ),
                  defaultColumnWidth: const pw.FlexColumnWidth(),
                  children: [
                    if (headers.isNotEmpty)
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey300,
                        ),
                        children: headers,
                      ),
                    ...rows.map((row) => pw.TableRow(children: row)),
                  ],
                ),
              );
            }
            break;
          default:
            widgets.add(
              pw.Text(
                _processPersianText(nodeText),
                style: pw.TextStyle(font: font, fontSize: 14, lineSpacing: 1.5),
                textDirection: textDirection,
                textAlign: textAlign,
              ),
            );
        }
        widgetCount++;
      }
    }
    return widgets;
  }

  Future<void> _showPdfPreview() async {
    if (_pdfBytes == null || _pdfFileName == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('پیش‌نمایش PDF'),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _downloadPdf,
                tooltip: 'دانلود PDF',
              ),
            ],
          ),
          body: PdfPreview(
            build: (format) => _pdfBytes!,
            pdfFileName: _pdfFileName,
            canDebug: false,
            canChangeOrientation: false,
            canChangePageFormat: false,
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    if (_pdfBytes == null || _pdfFileName == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_pdfFileName');
      await file.writeAsBytes(_pdfBytes!);

      // Open file for sharing/download
      await OpenFile.open(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF در مسیر ${file.path} ذخیره شد')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره PDF: ${e.toString()}')),
        );
      }
    }
  }

  String _processPersianText(String text) {
    try {
      // Normalize Arabic characters to Persian equivalents
      String normalized = text
          .replaceAll('ي', 'ی') // Arabic Yeh to Persian Yeh
          .replaceAll('ك', 'ک') // Arabic Kaf to Persian Kaf
          .replaceAll('ى', 'ی') // Alef Maksura to Persian Yeh
          .replaceAll('ة', 'ه') // Teh Marbuta to Heh
          .replaceAll('→', '-'); // Replace arrow with dash

      // حذف کامل تمام کاراکترهای خاص و ایموجی‌ها
      // فقط کاراکترهای امن را نگه می‌داریم
      normalized = _removeUnsupportedCharacters(normalized);

      // Only apply reshaping if text contains Persian/Arabic characters
      // Skip reshaping for pure English or special characters
      if (_isPersian(normalized) && _hasArabicLetters(normalized)) {
        return _reshapeArabicText(normalized);
      }

      return normalized;
    } catch (e) {
      debugPrint('⚠ خطا در پردازش متن فارسی: $e');
      // Return original text if reshaping fails
      return text;
    }
  }

  String _removeUnsupportedCharacters(String text) {
    // فقط کاراکترهای امن را نگه می‌داریم:
    // - حروف لاتین (A-Z, a-z)
    // - اعداد (0-9)
    // - فاصله و علائم نگارشی پایه
    // - Latin-1 Supplement (شامل «, », €, و غیره)
    // - حروف فارسی/عربی (U+0600-U+06FF, U+FB50-U+FDFF, U+FE70-U+FEFF)
    // - کاراکترهای RTL/LTR marks
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);

      // حروف لاتین و اعداد و علائم پایه
      if ((code >= 0x0020 && code <= 0x007E) || // ASCII printable
          (code >= 0x0080 &&
              code <= 0x00FF) || // Latin-1 Supplement (شامل « و »)
          (code >= 0x0600 && code <= 0x06FF) || // Arabic
          (code >= 0x0750 && code <= 0x077F) || // Arabic Supplement
          (code >= 0x08A0 && code <= 0x08FF) || // Arabic Extended-A
          (code >= 0xFB50 && code <= 0xFDFF) || // Arabic Presentation Forms-A
          (code >= 0xFE70 && code <= 0xFEFF) || // Arabic Presentation Forms-B
          code == 0x200C || // Zero width non-joiner
          code == 0x200D || // Zero width joiner
          code == 0x200E || // Left-to-right mark
          code == 0x200F || // Right-to-left mark
          code == 0x000A || // Line feed
          code == 0x000D) {
        // Carriage return
        buffer.writeCharCode(code);
      } else {
        // ایموجی و کاراکترهای غیرقابل پشتیبانی - حذف بی‌صدا
        // فقط در حالت debug لاگ می‌کنیم تا خروجی شلوغ نشود
        if (code >= 0x1F000) {
          // ایموجی - بدون لاگ
        } else {
          debugPrint(
            '⚠ حذف: U+${code.toRadixString(16).toUpperCase().padLeft(4, '0')}',
          );
        }
      }
    }

    return buffer.toString();
  }

  bool _hasArabicLetters(String text) {
    // Check if text has actual Arabic/Persian letters (not just numbers or punctuation)
    final arabicLetterRegex = RegExp(
      r'[\u0621-\u064A\u0660-\u0669\u06A9\u06AF\u06CC\u067E\u0686\u0698]',
    );
    return arabicLetterRegex.hasMatch(text);
  }

  String _reshapeArabicText(String text) {
    // Map of Arabic/Persian characters to their contextual forms
    // Format: isolated, final, initial, medial
    final Map<String, List<String>> arabicForms = {
      'ه': ['\u0647', '\uFEEA', '\uFEEB', '\uFEEC'], // Heh
      'ب': ['\u0628', '\uFE90', '\uFE91', '\uFE92'], // Beh
      'ت': ['\u062A', '\uFE96', '\uFE97', '\uFE98'], // Teh
      'ث': ['\u062B', '\uFE9A', '\uFE9B', '\uFE9C'], // Theh
      'ج': ['\u062C', '\uFE9E', '\uFE9F', '\uFEA0'], // Jeem
      'ح': ['\u062D', '\uFEA2', '\uFEA3', '\uFEA4'], // Hah
      'خ': ['\u062E', '\uFEA6', '\uFEA7', '\uFEA8'], // Khah
      'س': ['\u0633', '\uFEB2', '\uFEB3', '\uFEB4'], // Seen
      'ش': ['\u0634', '\uFEB6', '\uFEB7', '\uFEB8'], // Sheen
      'ص': ['\u0635', '\uFEBA', '\uFEBB', '\uFEBC'], // Sad
      'ض': ['\u0636', '\uFEBE', '\uFEBF', '\uFEC0'], // Dad
      'ط': ['\u0637', '\uFEC2', '\uFEC3', '\uFEC4'], // Tah
      'ظ': ['\u0638', '\uFEC6', '\uFEC7', '\uFEC8'], // Zah
      'ع': ['\u0639', '\uFECA', '\uFECB', '\uFECC'], // Ain
      'غ': ['\u063A', '\uFECE', '\uFECF', '\uFED0'], // Ghain
      'ف': ['\u0641', '\uFED2', '\uFED3', '\uFED4'], // Feh
      'ق': ['\u0642', '\uFED6', '\uFED7', '\uFED8'], // Qaf
      'ک': ['\u06A9', '\uFB8F', '\uFB90', '\uFB91'], // Kaf (Persian)
      'ك': ['\u0643', '\uFEDA', '\uFEDB', '\uFEDC'], // Kaf (Arabic)
      'گ': ['\u06AF', '\uFB93', '\uFB94', '\uFB95'], // Gaf
      'ل': ['\u0644', '\uFEDE', '\uFEDF', '\uFEE0'], // Lam
      'م': ['\u0645', '\uFEE2', '\uFEE3', '\uFEE4'], // Meem
      'ن': ['\u0646', '\uFEE6', '\uFEE7', '\uFEE8'], // Noon
      'ی': ['\u06CC', '\uFBFD', '\uFBFE', '\uFBFF'], // Yeh (Persian)
      'ي': ['\u064A', '\uFEF2', '\uFEF3', '\uFEF4'], // Yeh (Arabic)
      'پ': ['\u067E', '\uFB57', '\uFB58', '\uFB59'], // Peh
      'چ': ['\u0686', '\uFB7B', '\uFB7C', '\uFB7D'], // Tcheh
      'ژ': ['\u0698', '\uFB8B', '\uFB8B', '\uFB8B'], // Jeh
    };

    // Characters that don't connect to the left
    final Set<String> nonConnectors = {
      'ا',
      'د',
      'ذ',
      'ر',
      'ز',
      'ژ',
      'و',
      'ء',
      'آ',
      'أ',
      'إ',
      'ؤ',
    };

    final chars = text.runes.map((r) => String.fromCharCode(r)).toList();
    final result = <String>[];

    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];
      final forms = arabicForms[char];

      if (forms == null) {
        // Not an Arabic character, keep as is
        result.add(char);
        continue;
      }

      // Determine the form based on context
      final bool hasBefore =
          i > 0 &&
          !nonConnectors.contains(chars[i - 1]) &&
          arabicForms.containsKey(chars[i - 1]);
      final bool hasAfter =
          i < chars.length - 1 &&
          !nonConnectors.contains(chars[i + 1]) &&
          arabicForms.containsKey(chars[i + 1]);

      if (hasBefore && hasAfter) {
        // Medial form
        result.add(forms[3]);
      } else if (hasBefore) {
        // Final form
        result.add(forms[1]);
      } else if (hasAfter) {
        // Initial form
        result.add(forms[2]);
      } else {
        // Isolated form
        result.add(forms[0]);
      }
    }

    return result.join();
  }

  bool _isPersian(String text) {
    final persianRegex = RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    );
    return persianRegex.hasMatch(text);
  }

  // Ensure you have this package for PDF text extraction

  Future<void> _pickPdfAndExtractText() async {
    setState(() => _isLoading = true);

    try {
      final filePicker = OpenFilePicker()
        ..filterSpecification = {'All Files': '*.*'}
        ..defaultFilterIndex = 0
        ..defaultExtension = 'pdf'
        ..title = 'Select a PDF document';

      final result = filePicker.getFile();

      if (result != null) {
        final doc = await PDFDoc.fromPath(result.path);
        final text = await doc.text;

        setState(() {
          pdfExtractedText = text;
          _markdownController.text = text;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('متن PDF با موفقیت استخراج شد.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در استخراج متن PDF: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearText() {
    _markdownController.clear();
    setState(() {
      pdfExtractedText = '';
      _pdfBytes = null;
      _pdfFileName = null;
      // Clear font cache to reload fonts
      _cachedFont = null;
      _cachedBoldFont = null;
      _cachedFallbacks = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = themeManager.isDarkMode;
    return Scaffold(
      appBar: AppBar(
        title: Text('converter.title'.tr),
        actions: [
          // Language switcher
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            tooltip: Messages.language.tr,
            onSelected: (String value) {
              final languageController = Get.find<LanguageController>();
              if (value == 'en') {
                languageController.changeLanguage('en_US');
              } else if (value == 'fa') {
                languageController.changeLanguage('fa_IR');
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'en',
                child: Row(
                  children: [
                    const Icon(Icons.language, size: 20),
                    const SizedBox(width: 8),
                    Text(Messages.english.tr),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'fa',
                child: Row(
                  children: [
                    const Icon(Icons.language, size: 20),
                    const SizedBox(width: 8),
                    Text(Messages.persian.tr),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'converter.clearText'.tr,
            onPressed: _clearText,
          ),
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'settings.toggleTheme'.tr,
            onPressed: _toggleTheme,
          ),
        ],
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4.0),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: TextField(
                              controller: _markdownController,
                              maxLines: 8,
                              decoration: InputDecoration(
                                labelText: 'converter.markdownInputLabel'.tr,
                                border: const OutlineInputBorder(),
                                hintText: 'converter.markdownInputHint'.tr,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.paste),
                                  tooltip: 'converter.pasteFromClipboard'.tr,
                                  onPressed: () async {
                                    final data = await Clipboard.getData(
                                      'text/plain',
                                    );
                                    if (data?.text != null) {
                                      _markdownController.text = data!.text!;
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _convertMarkdownToPdf,
                              icon: const Icon(Icons.picture_as_pdf),
                              label: Text('converter.convertToPdf'.tr),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(150, 45),
                              ),
                            ),
                            if (_pdfBytes != null)
                              ElevatedButton.icon(
                                onPressed: _downloadPdf,
                                icon: const Icon(Icons.download),
                                label: Text('converter.downloadPdf'.tr),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(150, 45),
                                ),
                              ),
                            ElevatedButton.icon(
                              onPressed: _pickPdfAndExtractText,
                              icon: const Icon(Icons.file_upload),
                              label: Text('converter.extractPdfText'.tr),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(150, 45),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Card(
                            elevation: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.preview, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'converter.markdownPreview'.tr,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.fullscreen),
                                        tooltip:
                                            'converter.fullscreenPreview'.tr,
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => Scaffold(
                                                appBar: AppBar(
                                                  title: Text(
                                                    'converter.preview'.tr,
                                                  ),
                                                ),
                                                body: Markdown(
                                                  data:
                                                      _markdownController.text,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                Expanded(
                                  child: Markdown(
                                    data: _markdownController.text,
                                    controller: _scrollController,
                                    selectable: true,
                                    styleSheet:
                                        MarkdownStyleSheet.fromTheme(
                                          Theme.of(context),
                                        ).copyWith(
                                          p: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                          h1: Theme.of(
                                            context,
                                          ).textTheme.headlineSmall,
                                          h2: Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                          h3: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                          code: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontFamily: 'monospace',
                                                backgroundColor: Colors.grey
                                                    .withValues(alpha: 0.2),
                                              ),
                                          codeblockDecoration: BoxDecoration(
                                            color: Colors.grey.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
