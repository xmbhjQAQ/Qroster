import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/qroster_controller.dart';
import 'result_screen.dart';

class MarkingScreen extends StatefulWidget {
  const MarkingScreen({
    super.key,
    required this.rosterId,
    required this.sessionId,
  });

  final String rosterId;
  final String sessionId;

  @override
  State<MarkingScreen> createState() => _MarkingScreenState();
}

class _MarkingScreenState extends State<MarkingScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<QrosterController>();
    final roster = controller.rosters
        .where((item) => item.id == widget.rosterId)
        .firstOrNull;
    final entries = controller.entriesFor(widget.rosterId);
    if (roster == null || entries.isEmpty) {
      return const Scaffold(body: Center(child: Text('没有可记录的成员')));
    }
    final entry = entries[_index.clamp(0, entries.length - 1)];
    final currentStatus = controller.statusFor(
      sessionId: widget.sessionId,
      entryId: entry.id,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(roster.name),
        actions: [
          TextButton(
            onPressed: () => _openResult(context),
            child: const Text('结果'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: (_index + 1) / entries.length),
              const SizedBox(height: 20),
              Text(
                '${_index + 1} / ${entries.length}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                entry.displayName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (entry.note.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  entry.note,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const Spacer(),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: roster.statusOptions.map((status) {
                  final selected = status == currentStatus;
                  return SizedBox(
                    height: 52,
                    child: selected
                        ? FilledButton(
                            onPressed: () => _chooseStatus(status),
                            child: Text(status),
                          )
                        : FilledButton.tonal(
                            onPressed: () => _chooseStatus(status),
                            child: Text(status),
                          ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _index == 0
                          ? null
                          : () => setState(() => _index -= 1),
                      icon: const Icon(Icons.chevron_left_rounded),
                      label: const Text('上一个'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _index >= entries.length - 1
                          ? () => _openResult(context)
                          : () => setState(() => _index += 1),
                      icon: Icon(
                        _index >= entries.length - 1
                            ? Icons.check_rounded
                            : Icons.chevron_right_rounded,
                      ),
                      label: Text(_index >= entries.length - 1 ? '完成' : '下一个'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseStatus(String status) async {
    final controller = context.read<QrosterController>();
    final entry = controller.entriesFor(widget.rosterId)[_index];
    await controller.setResult(
      sessionId: widget.sessionId,
      entryId: entry.id,
      statusLabel: status,
    );
  }

  Future<void> _openResult(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          rosterId: widget.rosterId,
          sessionId: widget.sessionId,
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
