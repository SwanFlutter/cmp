# CMP - Markdown ↔ PDF Converter

**CMP** stands for **C**onvert **M**arkdown to **P**DF

A powerful Flutter desktop application for converting between Markdown and PDF formats with full Persian/Farsi language support.

## English Description

### Features

- **Markdown to PDF Conversion**: Convert your Markdown documents to beautifully formatted PDF files
- **PDF to Markdown Extraction**: Extract text content from PDF files back to Markdown format
- **Bilingual Support**: Full support for both English and Persian (Farsi) languages
- **Live Preview**: Real-time Markdown preview as you type
- **Dark/Light Theme**: Toggle between dark and light modes for comfortable viewing
- **Persian Text Support**: Proper handling of Persian/Arabic text with correct text shaping and RTL (Right-to-Left) direction
- **Rich Markdown Features**: Support for headings, lists, tables, code blocks, and more
- **Font Optimization**: Uses Amiri and Vazirmatn fonts for optimal Persian text rendering
- **Cross-Platform**: Built with Flutter for Windows desktop (can be extended to other platforms)

### How to Use

1. **Write or Paste Markdown**: Enter your Markdown text in the input field
2. **Preview**: See live preview of your formatted Markdown
3. **Convert to PDF**: Click "Convert to PDF" button to generate a PDF file
4. **Download**: Save the generated PDF to your desired location
5. **Extract from PDF**: Upload a PDF file to extract its text content
6. **Change Language**: Use the language switcher in the app bar to toggle between English and Persian

### Technology Stack

- **Flutter**: Cross-platform UI framework
- **Get_X_Master**: State management and dependency injection
- **PDF Package**: PDF generation and manipulation
- **Google Fonts**: Beautiful typography with Vazirmatn and Amiri fonts
- **Markdown Package**: Markdown parsing and rendering

---

## توضیحات فارسی

### ویژگی‌ها

- **تبدیل مارک‌دان به PDF**: تبدیل اسناد مارک‌دان به فایل‌های PDF با قالب‌بندی زیبا
- **استخراج متن از PDF**: استخراج محتوای متنی از فایل‌های PDF به فرمت مارک‌دان
- **پشتیبانی دو زبانه**: پشتیبانی کامل از زبان‌های انگلیسی و فارسی
- **پیش‌نمایش زنده**: نمایش لحظه‌ای مارک‌دان در حین تایپ
- **تم تاریک/روشن**: امکان تغییر بین حالت تاریک و روشن برای مشاهده راحت‌تر
- **پشتیبانی از متن فارسی**: مدیریت صحیح متن فارسی/عربی با شکل‌دهی درست و جهت راست به چپ
- **امکانات غنی مارک‌دان**: پشتیبانی از سرفصل‌ها، لیست‌ها، جداول، بلوک‌های کد و موارد دیگر
- **بهینه‌سازی فونت**: استفاده از فونت‌های امیری و وزیرمتن برای نمایش بهینه متن فارسی
- **چند پلتفرمی**: ساخته شده با Flutter برای دسکتاپ ویندوز (قابل توسعه به سایر پلتفرم‌ها)

### نحوه استفاده

1. **نوشتن یا چسباندن مارک‌دان**: متن مارک‌دان خود را در فیلد ورودی وارد کنید
2. **پیش‌نمایش**: پیش‌نمایش زنده از مارک‌دان قالب‌بندی شده خود را مشاهده کنید
3. **تبدیل به PDF**: روی دکمه "تبدیل به PDF" کلیک کنید تا فایل PDF تولید شود
4. **دانلود**: فایل PDF تولید شده را در مکان دلخواه ذخیره کنید
5. **استخراج از PDF**: یک فایل PDF آپلود کنید تا محتوای متنی آن استخراج شود
6. **تغییر زبان**: از تغییر دهنده زبان در نوار برنامه برای جابجایی بین انگلیسی و فارسی استفاده کنید

### فناوری‌های استفاده شده

- **Flutter**: فریم‌ورک رابط کاربری چند پلتفرمی
- **Get_X_Master**: مدیریت وضعیت و تزریق وابستگی
- **PDF Package**: تولید و دستکاری PDF
- **Google Fonts**: تایپوگرافی زیبا با فونت‌های وزیرمتن و امیری
- **Markdown Package**: تجزیه و رندر مارک‌دان

---

## Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK
- Windows OS (for desktop build)

### Installation

```bash
# Clone the repository
git clone <repository-url>

# Navigate to project directory
cd cmp

# Install dependencies
flutter pub get

# Run the application
flutter run -d windows
```

### Build for Production

```bash
# Build Windows executable
flutter build windows --release
```

---

## License

This project is open source and available under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
