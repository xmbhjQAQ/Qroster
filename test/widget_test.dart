import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qroster/src/app/qroster_app.dart';
import 'package:qroster/src/models/app_data.dart';
import 'package:qroster/src/models/app_settings.dart';
import 'package:qroster/src/models/parsed_roster_entry.dart';
import 'package:qroster/src/models/roster_models.dart';
import 'package:qroster/src/state/qroster_controller.dart';
import 'package:qroster/src/storage/qroster_store.dart';
import 'package:qroster/src/ui/result_screen.dart';

void main() {
  testWidgets('shows onboarding on first launch', (tester) async {
    final controller = QrosterController(store: MemoryQrosterStore());
    await controller.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const QrosterApp(),
      ),
    );

    expect(find.text('第一次使用 Q名册'), findsOneWidget);
    expect(find.text('跳过'), findsOneWidget);
  });

  testWidgets('shows empty home after onboarding', (tester) async {
    final controller = QrosterController(
      store: MemoryQrosterStore(
        AppData.empty().copyWith(
          settings: const AppSettings(onboardingCompleted: true),
        ),
      ),
    );
    await controller.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const QrosterApp(),
      ),
    );

    expect(find.text('Q名册'), findsWidgets);
    expect(find.text('还没有花名册'), findsOneWidget);
  });

  testWidgets('creates first roster from onboarding without route swap errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = QrosterController(store: MemoryQrosterStore());
    await controller.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const QrosterApp(),
      ),
    );

    await tester.ensureVisible(find.text('创建花名册'));
    await tester.tap(find.text('创建花名册'));
    await tester.pumpAndSettle();

    expect(find.text('格式示例'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '测试花名册');
    await tester.enterText(find.byType(TextField).at(1), '张三\n李四，1班');
    await tester.tap(find.text('按固定格式解析'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存花名册'));
    await tester.pumpAndSettle();

    expect(controller.settings.onboardingCompleted, isTrue);
    expect(find.text('测试花名册'), findsOneWidget);
  });

  test('pins and deletes rosters with scoped data cleanup', () async {
    final controller = QrosterController(store: MemoryQrosterStore());
    await controller.load();
    final first = await controller.createRoster(
      name: '第一组',
      type: RosterType.longTerm,
      statusOptions: defaultStatusOptions,
      parsedEntries: const [ParsedRosterEntry(displayName: '张三')],
    );
    final second = await controller.createRoster(
      name: '第二组',
      type: RosterType.temporary,
      statusOptions: defaultStatusOptions,
      parsedEntries: const [ParsedRosterEntry(displayName: '李四')],
    );
    final firstSession = await controller.createSession(first);
    await controller.setResult(
      sessionId: firstSession.id,
      entryId: controller.entriesFor(first.id).first.id,
      statusLabel: '没到',
    );

    await controller.pinRoster(second.id);
    expect(controller.rosters.first.id, second.id);

    await controller.deleteRoster(first.id);
    expect(controller.rosters.map((roster) => roster.id), [second.id]);
    expect(controller.entriesFor(first.id), isEmpty);
    expect(controller.sessionsFor(first.id), isEmpty);
    expect(controller.resultsFor(firstSession.id), isEmpty);
  });

  test('converts xlsx rows to readable text for LLM parsing', () async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow([
      TextCellValue('姓名'),
      TextCellValue('班级'),
    ]);
    sheet.appendRow([
      TextCellValue('张三'),
      TextCellValue('1班'),
    ]);
    final controller = QrosterController(store: MemoryQrosterStore());
    final text = controller.spreadsheetTextForLlm(
      Uint8List.fromList(excel.encode()!),
    );

    expect(text, contains('Sheet: Sheet1'));
    expect(text, contains('Row 1: 姓名 | 班级'));
    expect(text, contains('Row 2: 张三 | 1班'));
  });

  testWidgets('filters result page by status and shows filtered count', (
    tester,
  ) async {
    final controller = QrosterController(store: MemoryQrosterStore());
    await controller.load();
    final roster = await controller.createRoster(
      name: '考勤',
      type: RosterType.longTerm,
      statusOptions: defaultStatusOptions,
      parsedEntries: const [
        ParsedRosterEntry(displayName: '张三'),
        ParsedRosterEntry(displayName: '李四'),
      ],
    );
    final session = await controller.createSession(roster);
    final entries = controller.entriesFor(roster.id);
    await controller.setResult(
      sessionId: session.id,
      entryId: entries[0].id,
      statusLabel: '到了',
    );
    await controller.setResult(
      sessionId: session.id,
      entryId: entries[1].id,
      statusLabel: '没到',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(
          home: ResultScreen(
            rosterId: roster.id,
            sessionId: session.id,
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilterChip, '没到'));
    await tester.pumpAndSettle();

    expect(find.text('数量: 1'), findsOneWidget);
    expect(find.text('李四'), findsOneWidget);
    expect(find.text('张三'), findsNothing);

    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();

    expect(find.text('张三'), findsOneWidget);
    expect(find.text('李四'), findsOneWidget);
  });
}
