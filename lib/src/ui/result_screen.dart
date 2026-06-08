import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/roster_models.dart';
import '../state/qroster_controller.dart';
import 'widgets/qroster_widgets.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.rosterId,
    required this.sessionId,
  });

  final String rosterId;
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<QrosterController>();
    final roster = controller.rosters
        .where((item) => item.id == rosterId)
        .firstOrNull;
    final session = controller
        .sessionsFor(rosterId)
        .where((item) => item.id == sessionId)
        .firstOrNull;
    if (roster == null || session == null) {
      return const Scaffold(body: Center(child: Text('记录不存在')));
    }
    final entries = controller.entriesFor(roster.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(session.title),
        actions: [
          IconButton(
            tooltip: '导出 .xlsx',
            onPressed: () => _export(context, roster, session),
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final entry = entries[index];
          final selected = controller.statusFor(
            sessionId: session.id,
            entryId: entry.id,
          );
          return SectionCard(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _editEntry(context, entry),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (entry.note.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(entry.note),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selected.isEmpty ? null : selected,
                  hint: const Text('状态'),
                  items: roster.statusOptions
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (status) {
                    if (status == null) return;
                    context.read<QrosterController>().setResult(
                          sessionId: session.id,
                          entryId: entry.id,
                          statusLabel: status,
                        );
                  },
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemCount: entries.length,
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    Roster roster,
    RosterSession session,
  ) async {
    try {
      final path = await context.read<QrosterController>().exportSingleSession(
            roster: roster,
            session: session,
          );
      if (!context.mounted) return;
      showSnack(context, '已导出：$path');
    } catch (error) {
      if (!context.mounted) return;
      showSnack(context, '导出失败：$error');
    }
  }

  Future<void> _editEntry(BuildContext context, RosterEntry entry) async {
    var displayName = entry.displayName;
    var note = entry.note;
    final updated = await showDialog<RosterEntry>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑成员'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: displayName,
              onChanged: (value) => displayName = value,
              decoration: const InputDecoration(labelText: '显示名'),
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
            onPressed: () => Navigator.of(context).pop(
              entry.copyWith(
                displayName: displayName.trim(),
                note: note.trim(),
              ),
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (updated == null || updated.displayName.trim().isEmpty) {
      return;
    }
    if (!context.mounted) return;
    await context.read<QrosterController>().updateEntry(updated);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
