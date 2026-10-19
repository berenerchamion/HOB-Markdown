import 'package:flutter/foundation.dart';
import 'package:htmltopdfwidgets/htmltopdfwidgets.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/document_model.dart';

/// Service responsible for converting Markdown documents to clean, print-ready
/// HTML and sending them to the operating system's native print dialog.
class PrintService {
  const PrintService();

  /// Converts a [DocumentModel] into a complete HTML document with clean,
  /// print-optimized styling (GitHub-flavored Markdown, typography, tables,
  /// code blocks, and page-break rules).
  String generateHtml(DocumentModel document) {
    final bodyHtml = md.markdownToHtml(
      document.content,
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>${_escapeHtml(document.fileName)}</title>
  <style>
    @page {
      margin: 18mm 16mm;
      size: auto;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      color: #24292f;
      line-height: 1.6;
      font-size: 11pt;
      margin: 0;
      padding: 0;
    }
    h1, h2, h3, h4, h5, h6 {
      color: #1f2328;
      font-weight: 600;
      margin-top: 1.4em;
      margin-bottom: 0.6em;
      page-break-after: avoid;
      break-after: avoid;
    }
    h1 {
      font-size: 20pt;
      border-bottom: 1px solid #d0d7de;
      padding-bottom: 0.3em;
      margin-top: 0;
    }
    h2 {
      font-size: 15pt;
      border-bottom: 1px solid #d0d7de;
      padding-bottom: 0.25em;
    }
    h3 { font-size: 13pt; }
    h4 { font-size: 11.5pt; }
    h5 { font-size: 10pt; }
    h6 { font-size: 9.5pt; color: #57606a; }

    p, ul, ol, blockquote, table, pre {
      margin-top: 0;
      margin-bottom: 12px;
    }

    ul, ol {
      padding-left: 24px;
    }

    li {
      margin-bottom: 4px;
    }

    code {
      font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, Courier, monospace;
      font-size: 9.5pt;
      background-color: rgba(175, 184, 193, 0.2);
      padding: 0.2em 0.4em;
      border-radius: 4px;
    }

    pre {
      background-color: #f6f8fa;
      border: 1px solid #d0d7de;
      border-radius: 6px;
      padding: 12px;
      overflow-x: auto;
      page-break-inside: avoid;
      break-inside: avoid;
    }

    pre code {
      background-color: transparent;
      padding: 0;
      font-size: 9pt;
      border-radius: 0;
    }

    blockquote {
      padding: 0 1em;
      color: #57606a;
      border-left: 0.25em solid #d0d7de;
      margin: 0 0 12px 0;
    }

    table {
      border-collapse: collapse;
      width: 100%;
      margin-bottom: 16px;
      page-break-inside: avoid;
      break-inside: avoid;
    }

    th, td {
      border: 1px solid #d0d7de;
      padding: 6px 12px;
      text-align: left;
    }

    th {
      background-color: #f6f8fa;
      font-weight: 600;
    }

    tr:nth-child(even) td {
      background-color: #fcfcfc;
    }

    hr {
      height: 1px;
      background-color: #d0d7de;
      border: none;
      margin: 18px 0;
    }

    img {
      max-width: 100%;
      page-break-inside: avoid;
      break-inside: avoid;
    }

    a {
      color: #0969da;
      text-decoration: underline;
    }
  </style>
</head>
<body>
  $bodyHtml
</body>
</html>
''';
  }

  /// Sends the rendered HTML to the operating system's native print dialog.
  Future<bool> printDocument(DocumentModel document) async {
    final html = generateHtml(document);

    try {
      return await Printing.layoutPdf(
        name: document.fileName,
        onLayout: (PdfPageFormat format) async {
          final pdf = pw.Document();
          final widgets = await (HTMLToPdf().convert(html));
          pdf.addPage(pw.MultiPage(build: (context) => widgets));
          return await pdf.save();
        },
      );
    } catch (e) {
      debugPrint('Error invoking native print: $e');
      rethrow;
    }
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
