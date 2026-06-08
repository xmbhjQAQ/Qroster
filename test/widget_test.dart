import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qroster/src/app/qroster_app.dart';
import 'package:qroster/src/models/app_data.dart';
import 'package:qroster/src/models/app_settings.dart';
import 'package:qroster/src/state/qroster_controller.dart';
import 'package:qroster/src/storage/qroster_store.dart';

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
}
