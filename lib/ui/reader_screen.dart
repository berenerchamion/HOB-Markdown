import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/toc_item.dart';
import '../state/reader_controller.dart';
import 'widgets/app_toolbar.dart';
import 'widgets/document_status_bar.dart';
import 'widgets/drop_target_zone.dart';
import 'widgets/empty_state_view.dart';
import 'widgets/markdown_view.dart';
import 'widgets/raw_markdown_view.dart';
import 'widgets/search_bar_overlay.dart';
import 'widgets/split_view.dart';
import 'widgets/toc_sidebar.dart';

class ReaderScreen extends StatefulWidget {
  final ReaderController controller;

  const ReaderScreen({super.key, required this.controller});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerStateChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerStateChanged);
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onControllerStateChanged() {
    final error = widget.controller.errorMessage;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.controller.clearError();
    }
  }

  void _toggleSidebar(bool isWideScreen) {
    if (isWideScreen) {
      widget.controller.toggleSidebar();
    } else {
      if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
        _scaffoldKey.currentState?.closeDrawer();
      } else {
        _scaffoldKey.currentState?.openDrawer();
      }
    }
  }

  void _scrollToHeading(TocItem item) {
    final doc = widget.controller.currentDocument;
    if (doc == null || !_scrollController.hasClients) return;

    final totalLines = doc.content.split('\n').length;
    if (totalLines <= 0) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final targetFraction = (item.lineNumber / totalLines).clamp(0.0, 1.0);
    final targetOffset = (maxScroll * targetFraction).clamp(0.0, maxScroll);

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  int _calculateSearchMatches(String content, String query) {
    if (query.trim().isEmpty) return 0;
    try {
      return RegExp(RegExp.escape(query), caseSensitive: false).allMatches(content).length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 840;
            final doc = widget.controller.currentDocument;

            return CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                // New File: Cmd+N / Ctrl+N
                const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
                    () => widget.controller.newDocument(),
                const SingleActivator(LogicalKeyboardKey.keyN, control: true):
                    () => widget.controller.newDocument(),

                // Open File: Cmd+O / Ctrl+O
                const SingleActivator(LogicalKeyboardKey.keyO, meta: true):
                    () => widget.controller.openFilePicker(),
                const SingleActivator(LogicalKeyboardKey.keyO, control: true):
                    () => widget.controller.openFilePicker(),

                // Save File: Cmd+S / Ctrl+S
                const SingleActivator(LogicalKeyboardKey.keyS, meta: true):
                    () => widget.controller.saveCurrentFile(),
                const SingleActivator(LogicalKeyboardKey.keyS, control: true):
                    () => widget.controller.saveCurrentFile(),

                // Reload: Cmd+R / Ctrl+R
                const SingleActivator(LogicalKeyboardKey.keyR, meta: true):
                    () => widget.controller.reloadCurrentFile(),
                const SingleActivator(LogicalKeyboardKey.keyR, control: true):
                    () => widget.controller.reloadCurrentFile(),

                // Toggle Sidebar: Cmd+B / Ctrl+B
                const SingleActivator(LogicalKeyboardKey.keyB, meta: true):
                    () => _toggleSidebar(isWideScreen),
                const SingleActivator(LogicalKeyboardKey.keyB, control: true):
                    () => _toggleSidebar(isWideScreen),

                // Search: Cmd+F / Ctrl+F
                const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
                    () => widget.controller.toggleSearching(),
                const SingleActivator(LogicalKeyboardKey.keyF, control: true):
                    () => widget.controller.toggleSearching(),

                // Zoom In: Cmd + / Cmd =
                const SingleActivator(LogicalKeyboardKey.equal, meta: true):
                    () => widget.controller.zoomIn(),
                const SingleActivator(LogicalKeyboardKey.equal, control: true):
                    () => widget.controller.zoomIn(),

                // Zoom Out: Cmd -
                const SingleActivator(LogicalKeyboardKey.minus, meta: true):
                    () => widget.controller.zoomOut(),
                const SingleActivator(LogicalKeyboardKey.minus, control: true):
                    () => widget.controller.zoomOut(),

                // Reset Zoom: Cmd 0
                const SingleActivator(LogicalKeyboardKey.digit0, meta: true):
                    () => widget.controller.resetZoom(),
                const SingleActivator(LogicalKeyboardKey.digit0, control: true):
                    () => widget.controller.resetZoom(),

                // Theme Toggle: Cmd + T / Ctrl + T
                const SingleActivator(LogicalKeyboardKey.keyT, meta: true):
                    () => widget.controller.toggleTheme(),
                const SingleActivator(LogicalKeyboardKey.keyT, control: true):
                    () => widget.controller.toggleTheme(),

                // View Modes: Cmd + 1/2/3
                const SingleActivator(LogicalKeyboardKey.digit1, meta: true):
                    () => widget.controller.setViewMode(ViewMode.rendered),
                const SingleActivator(LogicalKeyboardKey.digit2, meta: true):
                    () => widget.controller.setViewMode(ViewMode.split),
                const SingleActivator(LogicalKeyboardKey.digit3, meta: true):
                    () => widget.controller.setViewMode(ViewMode.source),
              },
              child: Focus(
                focusNode: _focusNode,
                autofocus: true,
                child: DropTargetZone(
                  onFileDropped: (path) => widget.controller.openFile(path),
                  onDraggingChanged: (isDragging) => widget.controller.setDragging(isDragging),
                  child: Scaffold(
                    key: _scaffoldKey,
                    appBar: AppToolbar(
                      controller: widget.controller,
                      isCompact: !isWideScreen,
                      onToggleSidebar: () => _toggleSidebar(isWideScreen),
                    ),
                    drawer: (!isWideScreen && doc != null)
                        ? Drawer(
                            child: SafeArea(
                              child: TocSidebar(
                                headings: doc.headings,
                                onHeadingSelected: (item) {
                                  Navigator.of(context).pop();
                                  _scrollToHeading(item);
                                },
                                onClose: () => Navigator.of(context).pop(),
                              ),
                            ),
                          )
                        : null,
                    body: Stack(
                      children: [
                        Column(
                          children: [
                            // Main Content Area (Sidebar + Document)
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Desktop Table of Contents Sidebar
                                  if (isWideScreen && widget.controller.isSidebarOpen && doc != null)
                                    TocSidebar(
                                      headings: doc.headings,
                                      onHeadingSelected: _scrollToHeading,
                                    ),

                                  // Document Area or Empty State
                                  Expanded(
                                    child: widget.controller.isLoading
                                        ? const Center(child: CircularProgressIndicator())
                                        : doc != null
                                            ? _buildDocumentView(doc)
                                            : EmptyStateView(controller: widget.controller),
                                  ),
                                ],
                              ),
                            ),

                            // Document Info Bottom Status Bar
                            if (doc != null)
                              DocumentStatusBar(
                                document: doc,
                                controller: widget.controller,
                              ),
                          ],
                        ),

                        // Search Bar Overlay
                        if (widget.controller.isSearching && doc != null)
                          Positioned(
                            top: 12,
                            right: 24,
                            child: SearchBarOverlay(
                              matchCount: _calculateSearchMatches(
                                doc.content,
                                widget.controller.searchQuery,
                              ),
                              onSearchChanged: (query) => widget.controller.setSearchQuery(query),
                              onClose: () => widget.controller.clearSearch(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentView(dynamic doc) {
    switch (widget.controller.viewMode) {
      case ViewMode.rendered:
        return MarkdownView(
          document: doc,
          scaleFactor: widget.controller.textScaleFactor,
          scrollController: _scrollController,
          onNavigateToHeading: _scrollToHeading,
        );
      case ViewMode.split:
        return SplitView(
          document: doc,
          scaleFactor: widget.controller.textScaleFactor,
          scrollController: _scrollController,
          onNavigateToHeading: _scrollToHeading,
          onContentChanged: (text) => widget.controller.updateContent(text),
        );
      case ViewMode.source:
        return RawMarkdownView(
          document: doc,
          scaleFactor: widget.controller.textScaleFactor,
          scrollController: _scrollController,
          onChanged: (text) => widget.controller.updateContent(text),
        );
    }
  }
}
