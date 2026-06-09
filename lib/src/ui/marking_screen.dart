import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/qroster_controller.dart';
import 'result_screen.dart';
import 'widgets/qroster_widgets.dart';

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
    final recordedCount = controller.recordedCountFor(
      rosterId: widget.rosterId,
      sessionId: widget.sessionId,
    );
    final unrecordedCount = controller.unrecordedCountFor(
      rosterId: widget.rosterId,
      sessionId: widget.sessionId,
    );
    final hasCurrentStatus = currentStatus.isNotEmpty;
    final isLastEntry = _index >= entries.length - 1;

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
              const SizedBox(height: 8),
              Text(
                '已记录 $recordedCount · 未记录 $unrecordedCount',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: ActionChip(
                  avatar: const Icon(Icons.find_in_page_rounded),
                  label: Text('未记录 $unrecordedCount'),
                  onPressed: unrecordedCount == 0
                      ? null
                      : () => _jumpToNextUnrecorded(context),
                ),
              ),
              const Spacer(),
              Text(
                entry.displayName,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
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
                    child: hasCurrentStatus
                        ? FilledButton.icon(
                            onPressed: () => _moveForward(context),
                            icon: Icon(
                              isLastEntry
                                  ? Icons.check_rounded
                                  : Icons.chevron_right_rounded,
                            ),
                            label: Text(isLastEntry ? '完成' : '下一个'),
                          )
                        : FilledButton.tonalIcon(
                            onPressed: () => _moveForward(context),
                            icon: const Icon(Icons.warning_amber_rounded),
                            label: const Text('跳过'),
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

  Future<void> _moveForward(BuildContext context) async {
    final controller = context.read<QrosterController>();
    final entries = controller.entriesFor(widget.rosterId);
    final entry = entries[_index];
    final currentStatus = controller.statusFor(
      sessionId: widget.sessionId,
      entryId: entry.id,
    );
    if (currentStatus.isEmpty) {
      final confirmed = await _confirmSkip(context, entry.displayName);
      if (confirmed != true || !context.mounted) {
        return;
      }
    }
    if (_index >= entries.length - 1) {
      await _finish(context);
      return;
    }
    setState(() => _index += 1);
  }

  Future<bool?> _confirmSkip(BuildContext context, String displayName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('跳过未记录成员'),
        content: Text('$displayName 还没有选择状态，确定跳过吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('跳过'),
          ),
        ],
      ),
    );
  }

  Future<void> _finish(BuildContext context) async {
    final controller = context.read<QrosterController>();
    final unrecordedCount = controller.unrecordedCountFor(
      rosterId: widget.rosterId,
      sessionId: widget.sessionId,
    );
    if (unrecordedCount == 0) {
      await _openResult(context);
      return;
    }
    final viewResult = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('还有 $unrecordedCount 人未记录'),
        content: const Text('可以返回补录，也可以先查看结果。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('返回补录'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('查看结果'),
          ),
        ],
      ),
    );
    if (!context.mounted) {
      return;
    }
    if (viewResult == true) {
      await _openResult(context);
      return;
    }
    final nextIndex = controller.firstUnrecordedIndex(
      rosterId: widget.rosterId,
      sessionId: widget.sessionId,
    );
    if (nextIndex != null && mounted) {
      setState(() => _index = nextIndex);
    }
  }

  void _jumpToNextUnrecorded(BuildContext context) {
    final controller = context.read<QrosterController>();
    final nextIndex = controller.nextUnrecordedIndex(
      rosterId: widget.rosterId,
      sessionId: widget.sessionId,
      startIndex: _index,
    );
    if (nextIndex == null) {
      showSnack(context, '没有未记录成员');
      return;
    }
    setState(() => _index = nextIndex);
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
