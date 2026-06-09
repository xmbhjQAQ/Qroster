import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/parsed_roster_entry.dart';
import '../models/roster_models.dart';
import '../state/qroster_controller.dart';
import 'widgets/qroster_widgets.dart';

class RosterEditorScreen extends StatefulWidget {
  const RosterEditorScreen({super.key, this.completeOnboardingOnSave = false});

  final bool completeOnboardingOnSave;

  @override
  State<RosterEditorScreen> createState() => _RosterEditorScreenState();
}

class _RosterEditorScreenState extends State<RosterEditorScreen> {
  final _nameController = TextEditingController();
  final _textImportController = TextEditingController();
  final List<String> _statuses = List<String>.from(defaultStatusOptions);
  final List<ParsedRosterEntry> _previewEntries = [];
  String _spreadsheetLlmText = '';
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _textImportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<QrosterController>().settings;
    return Scaffold(
      appBar: AppBar(title: const Text('新建花名册')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '花名册名称',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('状态选项', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in _statuses)
                      InputChip(
                        label: Text(status),
                        onDeleted: _statuses.length <= 1
                            ? null
                            : () => setState(() => _statuses.remove(status)),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add_rounded),
                      label: const Text('添加'),
                      onPressed: _addStatus,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '导入名单',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _showImportHelp,
                      icon: const Icon(Icons.help_outline_rounded),
                      label: const Text('格式示例'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _textImportController,
                  minLines: 5,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: '纯文本',
                    hintText: '一行一个名字；也可用逗号/制表符追加备注',
                    helperText: '点右上角 ? 查看固定格式示例。',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _parseText,
                      icon: const Icon(Icons.text_fields_rounded),
                      label: const Text('按固定格式解析'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _pickSpreadsheet,
                      icon: const Icon(Icons.table_chart_rounded),
                      label: const Text('导入 .xlsx'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: settings.hasLlmConfig && !_busy
                          ? _parseWithLlm
                          : null,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('LLM 解析'),
                    ),
                  ],
                ),
                if (!settings.hasLlmConfig)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      settings.llmEnabled
                          ? 'LLM 配置不完整，暂不可用。'
                          : 'LLM 已关闭，请使用固定格式导入。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (_spreadsheetLlmText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '已读取 .xlsx 内容，可点击 LLM 解析重新适配表格格式。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '导入预览',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text('${_previewEntries.length} 项'),
                  ],
                ),
                const SizedBox(height: 8),
                if (_previewEntries.isEmpty)
                  const Text('解析后会在这里确认和修改。')
                else
                  ..._previewEntries.asMap().entries.map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.value.displayName),
                      subtitle: entry.value.note.isEmpty
                          ? null
                          : Text(entry.value.note),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: '编辑',
                            icon: const Icon(Icons.edit_rounded),
                            onPressed: () => _editPreviewEntry(entry.key),
                          ),
                          IconButton(
                            tooltip: '删除',
                            icon: Icon(
                              Icons.delete_rounded,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () => setState(
                              () => _previewEntries.removeAt(entry.key),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? '处理中...' : '保存花名册'),
          ),
        ],
      ),
    );
  }

  void _parseText() {
    final entries = context.read<QrosterController>().parseText(
      _textImportController.text,
    );
    setState(() {
      _previewEntries
        ..clear()
        ..addAll(entries);
    });
  }

  Future<void> _pickSpreadsheet() async {
    final controller = context.read<QrosterController>();
    const typeGroup = XTypeGroup(
      label: 'Excel',
      extensions: ['xlsx'],
      mimeTypes: [
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      ],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) {
      return;
    }
    final bytes = await file.readAsBytes();
    _spreadsheetLlmText = controller.spreadsheetTextForLlm(bytes);
    _replacePreview(controller.parseSpreadsheet(bytes));
  }

  Future<void> _parseWithLlm() async {
    setState(() => _busy = true);
    try {
      final sourceText = _textImportController.text.trim().isNotEmpty
          ? _textImportController.text
          : _spreadsheetLlmText;
      if (sourceText.trim().isEmpty) {
        showSnack(context, '请先输入文本或导入 .xlsx');
        return;
      }
      final entries = await context.read<QrosterController>().parseWithLlm(
        sourceText,
      );
      _replacePreview(entries);
      if (!mounted) return;
      showSnack(context, 'LLM 已生成 ${entries.length} 个条目');
    } catch (error) {
      if (!mounted) return;
      showSnack(context, 'LLM 解析失败：$error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _replacePreview(List<ParsedRosterEntry> entries) {
    setState(() {
      _previewEntries
        ..clear()
        ..addAll(entries);
    });
  }

  Future<void> _addStatus() async {
    var draft = '';
    final status = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加状态'),
        content: TextFormField(
          autofocus: true,
          onChanged: (value) => draft = value,
          decoration: const InputDecoration(labelText: '状态名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(draft),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    if (status == null || status.trim().isEmpty) {
      return;
    }
    setState(() => _statuses.add(status.trim()));
  }

  Future<void> _showImportHelp() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('固定格式示例'),
        content: const SingleChildScrollView(
          child: Text(
            '纯文本：\n'
            '张三\n'
            '李四\n'
            '王五，1班 3号\n\n'
            '规则：\n'
            '1. 每行一个人。\n'
            '2. 行首第一段是显示名。\n'
            '3. 后面的内容会合并为备注。\n'
            '4. 可用逗号、中文逗号、分号、竖线或 Tab 分隔。\n\n'
            '表格：\n'
            '优先识别“姓名 / 名字 / name”列；其他非空列会合并到备注。',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _editPreviewEntry(int index) async {
    final entry = _previewEntries[index];
    var displayName = entry.displayName;
    var note = entry.note;
    var nameError = '';
    final updated = await showDialog<ParsedRosterEntry>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('编辑条目'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: displayName,
                onChanged: (value) {
                  displayName = value;
                  if (nameError.isNotEmpty && value.trim().isNotEmpty) {
                    setDialogState(() => nameError = '');
                  }
                },
                decoration: InputDecoration(
                  labelText: '显示名',
                  errorText: nameError.isEmpty ? null : nameError,
                ),
              ),
              TextFormField(
                initialValue: note,
                onChanged: (value) => note = value,
                decoration: const InputDecoration(labelText: '备注'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (displayName.trim().isEmpty) {
                  setDialogState(() => nameError = '显示名不能为空');
                  return;
                }
                Navigator.of(context).pop(
                  ParsedRosterEntry(
                    displayName: displayName.trim(),
                    note: note.trim(),
                  ),
                );
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (updated == null || !updated.isValid) {
      return;
    }
    setState(() => _previewEntries[index] = updated);
  }

  Future<void> _save() async {
    final validEntries = _previewEntries
        .where((entry) => entry.isValid)
        .toList();
    if (validEntries.isEmpty) {
      showSnack(context, '请先导入或保留至少一个有效名单条目');
      return;
    }
    setState(() => _busy = true);
    try {
      final controller = context.read<QrosterController>();
      await controller.createRoster(
        name: _nameController.text,
        statusOptions: _statuses,
        parsedEntries: validEntries,
      );
      await waitForUiSettle();
      if (!mounted) return;
      Navigator.of(context).pop(widget.completeOnboardingOnSave);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
