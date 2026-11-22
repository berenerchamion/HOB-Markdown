import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/services/window_service.dart';
import 'package:hob_markdown_reader/state/reader_controller.dart';
import 'package:hob_markdown_reader/ui/widgets/app_toolbar.dart';

const _channel = MethodChannel('com.hob.markdown/window');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    WindowService.resetForTesting();
    messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      return call.method == 'isFullScreen' ? false : null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(_channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  group('off macOS', () {
    test('every call is a no-op', () async {
      await WindowService.init();
      await WindowService.startDrag();
      await WindowService.setDocument(title: 'a', edited: true);
      expect(calls, isEmpty);
    });
  });

  group('on macOS', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.macOS);

    test(
      'setDocument sends title, path and edited, skipping repeats',
      () async {
        await WindowService.setDocument(
          title: 'a.md — HOB Markdown',
          path: '/x/a.md',
          edited: false,
        );
        await WindowService.setDocument(
          title: 'a.md — HOB Markdown',
          path: '/x/a.md',
          edited: false,
        );
        await WindowService.setDocument(
          title: 'a.md — HOB Markdown',
          path: '/x/a.md',
          edited: true,
        );
        expect(calls.map((c) => c.method), ['setDocument', 'setDocument']);
        expect(calls.last.arguments, {
          'title': 'a.md — HOB Markdown',
          'path': '/x/a.md',
          'edited': true,
        });
      },
    );

    test('drag and double-click go to the native window', () async {
      await WindowService.startDrag();
      await WindowService.titleBarDoubleClicked();
      expect(calls.map((c) => c.method), [
        'startDrag',
        'titleBarDoubleClicked',
      ]);
    });

    test('full screen changes from native update isFullScreen', () async {
      await WindowService.init();
      expect(WindowService.isFullScreen.value, isFalse);
      await messenger.handlePlatformMessage(
        _channel.name,
        _channel.codec.encodeMethodCall(
          const MethodCall('fullScreenChanged', true),
        ),
        (_) {},
      );
      expect(WindowService.isFullScreen.value, isTrue);
    });

    test('a missing native side is ignored', () async {
      messenger.setMockMethodCallHandler(_channel, null);
      await WindowService.startDrag();
      await WindowService.setDocument(title: 'a', edited: false);
    });

    testWidgets(
      'toolbar leaves room for the traffic lights until full screen',
      (tester) async {
        // The narrowest width that still shows the full toolbar.
        tester.view.physicalSize = const Size(840, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final controller = ReaderController();
        addTearDown(controller.dispose);
        controller.newDocument();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppToolbar(
                controller: controller,
                isCompact: false,
                onToggleSidebar: () {},
              ),
            ),
          ),
        );

        final menuButton = find.byTooltip('Toggle Table of Contents (⌘B)');
        expect(
          tester.getSize(find.byType(AppBar)).height,
          WindowService.titleBarHeight,
        );
        expect(
          tester.getTopLeft(menuButton).dx,
          greaterThanOrEqualTo(WindowService.trafficLightInset),
        );

        WindowService.isFullScreen.value = true;
        await tester.pump();
        expect(
          tester.getTopLeft(menuButton).dx,
          lessThan(WindowService.trafficLightInset),
        );

        // Dragging empty toolbar space moves the window.
        await tester.dragFrom(const Offset(420, 4), const Offset(40, 0));
        expect(calls.map((c) => c.method), contains('startDrag'));
        await tester.pump(const Duration(seconds: 2)); // let gesture timers end
        debugDefaultTargetPlatformOverride = null;
      },
    );
  });
}
