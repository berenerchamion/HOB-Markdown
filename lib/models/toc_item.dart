class TocItem {
  final int level; // 1 to 6
  final String title;
  final int lineNumber;
  final String anchor;

  const TocItem({
    required this.level,
    required this.title,
    required this.lineNumber,
    required this.anchor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TocItem &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          title == other.title &&
          lineNumber == other.lineNumber;

  @override
  int get hashCode => Object.hash(level, title, lineNumber);

  @override
  String toString() => 'TocItem(H$level: "$title" at L$lineNumber)';
}
