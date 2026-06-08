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
    final controller = context.read<QrosterController>();
    final session = await controller.createSession(roster);
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
