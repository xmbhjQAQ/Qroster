import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/roster_models.dart';
import '../state/qroster_controller.dart';
import 'marking_screen.dart';
import 'result_screen.dart';
import 'widgets/qroster_widgets.dart';

class RosterDetailScreen extends StatelessWidget {
  const RosterDetailScreen({
    super.key,
    required this.rosterId,
  });

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
                    Chip(label: Text(roster.type.label)),
                    const SizedBox(width: 8),
                    Chip(label: Text('${entries.length} 人')),
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
                    if (roster.type == RosterType.longTerm)
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
                  ...sessions.map(
                    (session) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(session.title),
                      subtitle: Text('${controller.resultsFor(session.id).length} 个状态'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ResultScreen(
                            rosterId: roster.id,
                            sessionId: session.id,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSession(BuildContext context, Roster roster) async {
    final recordedAt = await _chooseSessionTime(context);
    if (recordedAt == null || !context.mounted) {
      return;
    }
    final controller = context.read<QrosterController>();
    final session = await controller.createSession(
      roster,
      recordedAt: recordedAt,
    );
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MarkingScreen(
          rosterId: roster.id,
          sessionId: session.id,
        ),
      ),
    );
  }

  Future<DateTime?> _chooseSessionTime(BuildContext context) {
    var selected = DateTime.now();
    return showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('记录时间'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('默认使用当前设备时间。'),
              const SizedBox(height: 12),
              Text(
                '${selected.year}-${_twoDigits(selected.month)}-${_twoDigits(selected.day)} '
                '${_twoDigits(selected.hour)}:${_twoDigits(selected.minute)}',
                style: Theme.of(context).textTheme.titleMedium,
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
              onPressed: () => Navigator.of(context).pop(selected),
              child: const Text('开始记录'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportHistory(BuildContext context, Roster roster) async {
    try {
      final path = await context.read<QrosterController>().exportLongTermHistory(
            roster,
          );
      if (!context.mounted) return;
      showSnack(context, '已导出：$path');
    } catch (error) {
      if (!context.mounted) return;
      showSnack(context, '导出失败：$error');
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
