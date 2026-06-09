import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../state/qroster_controller.dart';
import 'roster_editor_screen.dart';
import 'widgets/qroster_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _llmEnabled = false;
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController(text: 'gpt-4.1-mini');

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const QAssetIcon('app_mark', size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '第一次使用 Q名册',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                TextButton(onPressed: _skip, child: const Text('跳过')),
              ],
            ),
            const SizedBox(height: 20),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. LLM 导入解析',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('开启后可解析较乱的文本或表格；关闭后使用固定格式导入。'),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('开启'),
                        icon: Icon(Icons.auto_awesome_rounded),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('关闭'),
                        icon: Icon(Icons.block_rounded),
                      ),
                    ],
                    selected: {_llmEnabled},
                    onSelectionChanged: (values) =>
                        setState(() => _llmEnabled = values.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _baseUrlController,
                    enabled: _llmEnabled,
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      hintText:
                          'https://api.openai.com 或 https://api.openai.com/v1',
                      helperText: '填到域名或 /v1 都可以，程序会自动请求 /chat/completions。',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _apiKeyController,
                    enabled: _llmEnabled,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _modelController,
                    enabled: _llmEnabled,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saveLlmStep,
                    child: const Text('保存 LLM 选择'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2. 创建第一个花名册',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('设置名称、状态选项，然后导入名单。'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _createFirstRoster,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('创建花名册'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLlmStep() async {
    final controller = context.read<QrosterController>();
    await controller.updateSettings(
      controller.settings.copyWith(
        llmEnabled: _llmEnabled,
        llmBaseUrl: _baseUrlController.text.trim(),
        llmApiKey: _apiKeyController.text.trim(),
        llmModel: _modelController.text.trim(),
      ),
    );
    if (!mounted) return;
    showSnack(context, _llmEnabled ? 'LLM 配置已保存' : '已关闭 LLM');
  }

  Future<void> _createFirstRoster() async {
    await _saveLlmStep();
    if (!mounted) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            const RosterEditorScreen(completeOnboardingOnSave: true),
      ),
    );
    if (!mounted || created != true) return;
    await context.read<QrosterController>().completeOnboarding(completed: true);
  }

  Future<void> _skip() async {
    await context.read<QrosterController>().updateSettings(
      const AppSettings(onboardingCompleted: true),
    );
  }
}
