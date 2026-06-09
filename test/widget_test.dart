import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:qroster/src/app/qroster_app.dart';
import 'package:qroster/src/models/app_data.dart';
import 'package:qroster/src/models/app_settings.dart';
import 'package:qroster/src/models/parsed_roster_entry.dart';
import 'package:qroster/src/models/roster_models.dart';
import 'package:qroster/src/services/xlsx_export_service.dart';
import 'package:qroster/src/state/qroster_controller.dart';
import 'package:qroster/src/storage/qroster_store.dart';
import 'package:qroster/src/ui/marking_screen.dart';
import 'package:qroster/src/ui/result_screen.dart';
import 'package:qroster/src/ui/roster_detail_screen.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Q名册',
      packageName: 'qroster',
      version: '9.8.7',
      buildNumber: '654',
      buildSignature: '',
    );
  });

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

  testWidgets('opens about page from bottom drawer entry', (tester) async {
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

    await tester.tap(find.byTooltip('菜单'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('关于 Q名册'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, '关于 Q名册'), findsOneWidget);
    expect(find.text('qroster'), findsOneWidget);
    expect(find.text('版本 9.8.7 (654)'), findsOneWidget);
    expect(find.text('第三方许可证'), findsOneWidget);
  });

  testWidgets(
    'creates first roster from onboarding without route swap errors',
    (tester) async {
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
    },
  );

  test('pins and deletes rosters with scoped data cleanup', () async {
    final controller = QrosterController(store: MemoryQrosterStore());
    await controller.load();
    final first = await controller.createRoster(
      name: '第一组',
      statusOptions: defaultStatusOptions,
      parsedEntries: const [ParsedRosterEntry(displayName: '张三')],
    );
    final second = await controller.createRoster(
      name: '第二组',
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

  test(
    'deletes one history session without deleting members or other sessions',
    () async {
      final controller = QrosterController(store: MemoryQrosterStore());
      await controller.load();
      final roster = await controller.createRoster(
        name: '考勤',
        statusOptions: defaultStatusOptions,
        parsedEntries: const [ParsedRosterEntry(displayName: '张三')],
      );
      final entry = controller.entriesFor(roster.id).first;
      final firstSession = await controller.createSession(roster);
      final secondSession = await controller.createSession(roster);
      await controller.setResult(
        sessionId: firstSession.id,
        entryId: entry.id,
        statusLabel: '到了',
      );
      await controller.setResult(
        sessionId: secondSession.id,
        entryId: entry.id,
        statusLabel: '没到',
      );

      await controller.deleteSession(firstSession.id);

      expect(
        controller.entriesFor(roster.id).map((entry) => entry.displayName),
        ['张三'],
      );
      expect(controller.sessionsFor(roster.id).map((session) => session.id), [
        secondSession.id,
      ]);
      expect(controller.resultsFor(firstSession.id), isEmpty);
      expect(controller.resultsFor(secondSession.id), hasLength(1));
    },
  );

  test('renames sessions and supports custom session titles', () async {
    final controller = QrosterController(store: MemoryQrosterStore());
    await controller.load();
    final roster = await controller.createRoster(
      name: '考勤',
      statusOptions: defaultStatusOptions,
      parsedEntries: const [ParsedRosterEntry(displayName: '张三')],
    );
    final createdAt = DateTime(2026, 6, 9, 8, 30);
    final session = await controller.createSession(
      roster,
      recordedAt: createdAt,
      title: '周二早读',
    );

    expect(session.title, '周二早读');

    await controller.renameSession(sessionId: session.id, title: '第一次训练');
    final renamed = controller.sessionsFor(roster.id).single;

    expect(renamed.title, '第一次训练');
    expect(renamed.createdAt, createdAt);
    expect(renamed.updatedAt.isAfter(createdAt), isTrue);
  });

  testWidgets('cancels session rename dialog without route teardown errors', (
    tester,
  ) async {
    final controller = QrosterController(store: MemoryQrosterStore());
    await controller.load();
    final roster = await controller.createRoster(
      name: '考勤',
      statusOptions: defaultStatusOptions,
      parsedEntries: const [ParsedRosterEntry(displayName: '张三')],
    );
    await controller.createSession(roster, title: '周二早读');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(home: RosterDetailScreen(rosterId: roster.id)),
      ),
    );

    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();
    expect(find.text('重命名记录'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('周二早读'), findsOneWidget);
  });

  test('converts xlsx rows to readable text for LLM parsing', () async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow([TextCellValue('姓名'), TextCellValue('班级')]);
    sheet.appendRow([TextCellValue('张三'), TextCellValue('1班')]);
    final controller = QrosterController(store: MemoryQrosterStore());
    final text = controller.spreadsheetTextForLlm(
      Uint8List.fromList(excel.encode()!),
    );

    expect(text, contains('Sheet: Sheet1'));
    expect(text, contains('Row 1: 姓名 | 班级'));
    expect(text, contains('Row 2: 张三 | 1班'));
  });

  test(
    'builds editable xlsx exports with meaningful sheets and columns',
    () async {
      final controller = QrosterController(store: MemoryQrosterStore());
      await controller.load();
      final roster = await controller.createRoster(
        name: '考勤',
        statusOptions: defaultStatusOptions,
        parsedEntries: const [
          ParsedRosterEntry(displayName: '张三', note: '1班'),
          ParsedRosterEntry(displayName: '李四'),
        ],
      );
      final session = await controller.createSession(
        roster,
        recordedAt: DateTime(2026, 6, 9, 8, 30),
      );
      final entries = controller.entriesFor(roster.id);
      await controller.setResult(
        sessionId: session.id,
        entryId: entries[0].id,
        statusLabel: '到了',
      );
      final service = XlsxExportService();

      final single = Excel.decodeBytes(
        service.buildSingleSessionWorkbook(
          roster: roster,
          session: session,
          entries: entries,
          results: controller.resultsFor(session.id),
        ),
      );
      expect(single.tables.keys, containsAll(['记录', '统计']));
      final singleHeader = _findRow(single['记录'].rows, [
        '序号',
        '姓名',
        '备注',
        '状态',
        '记录时间',
      ]);
      expect(singleHeader, isNotNull);
      expect(_rowText(single['记录'].rows[singleHeader! + 1]), [
        '1',
        '张三',
        '1班',
        '到了',
        '2026-06-09 08:30',
      ]);
      expect(_rowText(single['记录'].rows[singleHeader + 2]), [
        '2',
        '李四',
        '',
        unrecordedStatusLabel,
        '2026-06-09 08:30',
      ]);
      expect(
        _findRow(single['统计'].rows, [
          '2026-06-09 08:30',
          unrecordedStatusLabel,
          '1',
        ]),
        isNotNull,
      );

      final history = Excel.decodeBytes(
        service.buildLongTermHistoryWorkbook(
          roster: roster,
          entries: entries,
          sessions: [session],
          results: controller.resultsFor(session.id),
        ),
      );
      expect(history.tables.keys, containsAll(['全部记录', '统计']));
      final historyHeader = _findRow(history['全部记录'].rows, [
        '序号',
        '姓名',
        '备注',
        '2026-06-09 08:30',
      ]);
      expect(historyHeader, isNotNull);
      expect(_rowText(history['全部记录'].rows[historyHeader! + 1]), [
        '1',
        '张三',
        '1班',
        '到了',
      ]);
      expect(_rowText(history['全部记录'].rows[historyHeader + 2]), [
        '2',
        '李四',
        '',
        unrecordedStatusLabel,
      ]);
    },
  );

  testWidgets(
    'confirms skipped marking and warns before finishing incomplete',
    (tester) async {
      final controller = QrosterController(store: MemoryQrosterStore());
      await controller.load();
      final roster = await controller.createRoster(
        name: '考勤',
        statusOptions: defaultStatusOptions,
        parsedEntries: const [
          ParsedRosterEntry(displayName: '张三'),
          ParsedRosterEntry(displayName: '李四'),
        ],
      );
      final session = await controller.createSession(roster);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: MaterialApp(
            home: MarkingScreen(rosterId: roster.id, sessionId: session.id),
          ),
        ),
      );

      expect(find.text('已记录 0 · 未记录 2'), findsOneWidget);
      expect(find.text('张三'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '跳过'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '跳过'));
      await tester.pumpAndSettle();

      expect(find.text('跳过未记录成员'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.text('张三'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '跳过'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '跳过').last);
      await tester.pumpAndSettle();

      expect(find.text('李四'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '到了'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();

      expect(find.text('还有 1 人未记录'), findsOneWidget);
      await tester.tap(find.text('返回补录'));
      await tester.pumpAndSettle();

      expect(find.text('张三'), findsOneWidget);
    },
  );

  testWidgets('filters result page by status and shows filtered count', (
    tester,
  ) async {
    final controller = QrosterController(store: MemoryQrosterStore());
    await controller.load();
    final roster = await controller.createRoster(
      name: '考勤',
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
          home: ResultScreen(rosterId: roster.id, sessionId: session.id),
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

  testWidgets('filters unrecorded result rows and allows filling status', (
    tester,
  ) async {
    final controller = QrosterController(store: MemoryQrosterStore());
    await controller.load();
    final roster = await controller.createRoster(
      name: '考勤',
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

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(
          home: ResultScreen(rosterId: roster.id, sessionId: session.id),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilterChip, '未记录 1'));
    await tester.pumpAndSettle();

    expect(find.text('数量: 1'), findsOneWidget);
    expect(find.text('李四'), findsOneWidget);
    expect(find.text('张三'), findsNothing);
    expect(find.text(unrecordedStatusLabel), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('请假').last);
    await tester.pumpAndSettle();

    expect(
      controller.statusFor(sessionId: session.id, entryId: entries[1].id),
      '请假',
    );
  });
}

List<String> _rowText(List<Data?> row) {
  return row.map((cell) => cell?.value.toString() ?? '').toList();
}

int? _findRow(List<List<Data?>> rows, List<String> expected) {
  for (final row in rows.indexed) {
    if (_rowText(row.$2).join('\u0000') == expected.join('\u0000')) {
      return row.$1;
    }
  }
  return null;
}
