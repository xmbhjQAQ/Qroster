import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/roster_models.dart';
import '../state/qroster_controller.dart';
import 'marking_screen.dart';
import 'result_screen.dart';
import 'widgets/qroster_widgets.dart';

class RosterDetailScreen extends StatelessWidget {
  const RosterDetailScreen({super.key, required this.rosterId});

  final String rosterId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<QrosterController>();
    final roster = controller.rosters
        .where((item) => item.id == rosterId)
        .firstOrNull;
    if (roster == null) {
      return const Scaffold(body: Center(child: Text('花名册不存在')));
    }
    final entries = controller.entriesFor(roster.id);
    final sessions = controller.sessionsFor(roster.id);

    return Scaffold(
      appBar: AppBar(title: Text(roster.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(label: Text('${entries.length} 人')),
                    const SizedBox(width: 8),
                    Chip(label: Text('已记录 ${sessions.length} 次')),
                  ],
                ),
                const SizedBox(height: 12),
                Text('状态选项', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: roster.statusOptions
                      .map((status) => Chip(label: Text(status)))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: entries.isEmpty
                            ? null
                            : () => _startSession(context, roster),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('开始记录'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: '导出全部历史',
                      onPressed: sessions.isEmpty
                          ? null
                          : () => _exportHistory(context, roster),
                      icon: const Icon(Icons.download_rounded),
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
                Text('成员', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (entries.isEmpty)
                  const Text('这个花名册还没有成员。')
                else
                  ...entries.map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.displayName),
                      subtitle: entry.note.isEmpty ? null : Text(entry.note),
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
                Text('记录历史', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (sessions.isEmpty)
                  const Text('尚未记录。')
                else
                  ...sessions.map((session) {
                    final recordedCount = controller.recordedCountFor(
                      rosterId: roster.id,
                      sessionId: session.id,
                    );
                    final unrecordedCount = controller.unrecordedCountFor(
                      rosterId: roster.id,
                      sessionId: session.id,
                    );
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(session.title),
                      subtitle: Text(
                        '已记录 $recordedCount · 未记录 $unrecordedCount · ${_formatSessionTime(session.createdAt)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: '重命名记录',
                            icon: const Icon(Icons.edit_rounded),
                            onPressed: () => _renameSession(context, session),
                          ),
                          IconButton(
                            tooltip: '删除记录',
                            icon: Icon(
                              Icons.delete_rounded,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () =>
                                _confirmDeleteSession(context, session),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ResultScreen(
                            rosterId: roster.id,
                            sessionId: session.id,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSession(BuildContext context, Roster roster) async {
    final draft = await _chooseSessionDraft(context);
    if (draft == null || !context.mounted) {
      return;
    }
    final controller = context.read<QrosterController>();
    final session = await controller.createSession(
      roster,
      recordedAt: draft.recordedAt,
      title: draft.title,
    );
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MarkingScreen(rosterId: roster.id, sessionId: session.id),
      ),
    );
  }

  Future<_SessionDraft?> _chooseSessionDraft(BuildContext context) async {
    var selected = DateTime.now();
    final titleController = TextEditingController();
    try {
      return await showDialog<_SessionDraft>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('记录时间'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('默认使用当前设备时间。'),
                const SizedBox(height: 12),
                Text(
                  _formatSessionTime(selected),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '记录名称',
                    hintText: '默认使用所选时间',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selected,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked == null) return;
                          setDialogState(() {
                            selected = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              selected.hour,
                              selected.minute,
                            );
                          });
                        },
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: const Text('日期'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selected),
                          );
                          if (picked == null) return;
                          setDialogState(() {
                            selected = DateTime(
                              selected.year,
                              selected.month,
                              selected.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        },
                        icon: const Icon(Icons.schedule_rounded),
                        label: const Text('时间'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  _SessionDraft(
                    recordedAt: selected,
                    title: titleController.text.trim(),
                  ),
                ),
                child: const Text('开始记录'),
              ),
            ],
          ),
        ),
      );
    } finally {
      titleController.dispose();
    }
  }

  Future<void> _exportHistory(BuildContext context, Roster roster) async {
    try {
      final path = await context.read<QrosterController>().exportHistory(
        roster,
      );
      if (!context.mounted) return;
      showSnack(context, '已导出：$path');
    } catch (error) {
      if (!context.mounted) return;
      showSnack(context, '导出失败：$error');
    }
  }

  Future<void> _confirmDeleteSession(
    BuildContext context,
    RosterSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: Text('确定删除“${session.title}”这条记录吗？成员和其他记录不会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await context.read<QrosterController>().deleteSession(session.id);
    if (context.mounted) {
      showSnack(context, '已删除记录：${session.title}');
    }
  }

  Future<void> _renameSession(
    BuildContext context,
    RosterSession session,
  ) async {
    final titleController = TextEditingController(text: session.title);
    var titleError = '';
    try {
      final title = await showDialog<String>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('重命名记录'),
            content: TextField(
              controller: titleController,
              autofocus: true,
              onChanged: (value) {
                if (titleError.isNotEmpty && value.trim().isNotEmpty) {
                  setDialogState(() => titleError = '');
                }
              },
              decoration: InputDecoration(
                labelText: '记录名称',
                errorText: titleError.isEmpty ? null : titleError,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  final trimmed = titleController.text.trim();
                  if (trimmed.isEmpty) {
                    setDialogState(() => titleError = '记录名称不能为空');
                    return;
                  }
                  Navigator.of(context).pop(trimmed);
                },
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      );
      if (title == null || !context.mounted) {
        return;
      }
      await context.read<QrosterController>().renameSession(
        sessionId: session.id,
        title: title,
      );
      if (context.mounted) {
        showSnack(context, '已重命名记录');
      }
    } finally {
      titleController.dispose();
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _formatSessionTime(DateTime value) {
  return '${value.year}-${_twoDigits(value.month)}-${_twoDigits(value.day)} '
      '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
}

class _SessionDraft {
  const _SessionDraft({required this.recordedAt, required this.title});

  final DateTime recordedAt;
  final String title;
}
