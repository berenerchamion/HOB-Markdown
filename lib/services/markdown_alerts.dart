import 'package:markdown/markdown.dart' as md;

/// Reads GitHub alerts (`> [!NOTE]`, `> [!TIP]`, `> [!WARNING]` and so on)
/// and turns them into a blockquote that starts with a bold title.
///
/// `ExtensionSet.gitHubFlavored` doesn't include alerts, so without this the
/// `[!TIP]` marker shows up as text. The package's own alert syntax builds a
/// `<div>`, which flutter_markdown_plus has no renderer for, so this keeps
/// its parsing and swaps the result for a blockquote, which both the
/// on-screen view and the print HTML already style.
class QuoteAlertSyntax extends md.AlertBlockSyntax {
  const QuoteAlertSyntax();

  @override
  md.Node parse(md.BlockParser parser) {
    final alert = super.parse(parser) as md.Element;
    final children = alert.children ?? const <md.Node>[];
    if (children.isEmpty) return alert;

    final title = children.first;
    final titleText = title is md.Element ? title.children : [title];
    final type = (alert.attributes['class'] ?? '')
        .split('markdown-alert-')
        .last;

    return md.Element('blockquote', [
      md.Element('p', [md.Element('strong', titleText)])
        ..attributes['class'] = 'alert-title',
      ...children.skip(1),
    ])..attributes['class'] = 'alert alert-$type';
  }
}

/// Block syntaxes to pass alongside `ExtensionSet.gitHubFlavored`.
const List<md.BlockSyntax> extraBlockSyntaxes = [QuoteAlertSyntax()];
