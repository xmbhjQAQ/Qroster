import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../state/qroster_controller.dart';
import 'widgets/qroster_widgets.dart';

class LlmSettingsScreen extends StatefulWidget {
  const LlmSettingsScreen({super.key});

  @override
  State<LlmSettingsScreen> createState() => _LlmSettingsScreenState();
}

class _LlmSettingsScreenState extends State<LlmSettingsScreen> {
  late bool _enabled;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<QrosterController>().settings;
    _enabled = settings.llmEnabled;
    _baseUrlController = TextEditingController(text: settings.llmBaseUrl);
    _apiKeyController = TextEditingController(text: settings.llmApiKey);
    _modelController = TextEditingController(text: settings.llmModel);
  }

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
      appBar: AppBar(title: const Text('LLM 配置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
            title: const Text('开启 LLM 导入解析'),
            subtitle: const Text('仅支持 OpenAI-compatible 接口'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _baseUrlController,
            enabled: _enabled,
            decoration: const InputDecoration(
              labelText: 'Base URL',
              hintText: 'https://api.openai.com 或 https://api.openai.com/v1',
              helperText: '填到域名或 /v1 都可以，程序会自动请求 /chat/completions。',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            enabled: _enabled,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Key',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _modelController,
            enabled: _enabled,
            decoration: const InputDecoration(
              labelText: 'Model',
              hintText: 'gpt-4.1-mini',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('保存配置')),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final controller = context.read<QrosterController>();
    await controller.updateSettings(
      AppSettings(
        onboardingCompleted: controller.settings.onboardingCompleted,
        llmEnabled: _enabled,
        llmBaseUrl: _baseUrlController.text.trim(),
        llmApiKey: _apiKeyController.text.trim(),
        llmModel: _modelController.text.trim(),
      ),
    );
    await waitForUiSettle();
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
