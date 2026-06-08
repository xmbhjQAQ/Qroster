import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/roster_models.dart';
import '../state/qroster_controller.dart';
import 'llm_settings_screen.dart';
import 'roster_detail_screen.dart';
import 'roster_editor_screen.dart';
import 'widgets/qroster_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _drawerOpen = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<QrosterController>();
    final rosters = controller.rosters;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: '菜单',
                        icon: const Icon(Icons.menu_rounded),
                        onPressed: () => setState(() => _drawerOpen = true),
                      ),
                      const SizedBox(width: 8),
                      const QAssetIcon('app_mark', size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Q名册',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              '共 ${rosters.length} 个花名册',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: rosters.isEmpty
                      ? const EmptyState(
                          title: '还没有花名册',
                          message: '点左下角新建一个，或从菜单里先配置 LLM。',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemBuilder: (context, index) => _RosterCard(
                            roster: rosters[index],
                          ),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemCount: rosters.length,
                        ),
                ),
              ],
            ),
            Positioned(
              left: 16,
              bottom: 20,
              child: FloatingActionButton.small(
                tooltip: '新建花名册',
                onPressed: () => _openRosterEditor(context),
                child: const Icon(Icons.add_rounded),
              ),
            ),
            if (_drawerOpen)
              GestureDetector(
                onTap: () => setState(() => _drawerOpen = false),
                child: Container(color: Colors.black.withValues(alpha: 0.22)),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              left: _drawerOpen ? 0 : -MediaQuery.sizeOf(context).width * 0.58,
              top: 0,
              bottom: 0,
              width: MediaQuery.sizeOf(context).width * 0.58,
              child: _HomeDrawer(
                onClose: () => setState(() => _drawerOpen = false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRosterEditor(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RosterEditorScreen()),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const QAssetIcon('app_mark'),
                  const SizedBox(width: 8),
                  Text('Q名册', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.auto_awesome_rounded),
                title: const Text('LLM 配置'),
                subtitle: const Text('OpenAI-compatible'),
                onTap: () {
                  onClose();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LlmSettingsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('长期配置'),
                subtitle: const Text('后续放全局默认项'),
                onTap: () => showSnack(context, '长期配置将在后续版本扩展'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RosterCard extends StatefulWidget {
  const _RosterCard({required this.roster});

  final Roster roster;

  @override
  State<_RosterCard> createState() => _RosterCardState();
}

class _RosterCardState extends State<_RosterCard> {
  static const _actionWidth = 144.0;

  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<QrosterController>();
    final roster = widget.roster;
    final entryCount = controller.entriesFor(roster.id).length;
    final sessionCount = controller.sessionCountFor(roster.id);
    final offset = _dragOffset.clamp(0.0, _actionWidth);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              children: [
                SizedBox(
                  width: _actionWidth / 2,
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: InkWell(
                      onTap: () => _pinRoster(context),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.vertical_align_top_rounded),
                          SizedBox(height: 4),
                          Text('置顶'),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: _actionWidth / 2,
                  child: Material(
                    color: Theme.of(context).colorScheme.error,
                    child: InkWell(
                      onTap: () => _confirmDelete(context),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_rounded,
                            color: Theme.of(context).colorScheme.onError,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '删除',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onError,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragOffset = (_dragOffset + details.delta.dx).clamp(
                  0.0,
                  _actionWidth,
                );
              });
            },
            onHorizontalDragEnd: (_) {
              setState(() {
                _dragOffset = _dragOffset > _actionWidth / 2 ? _actionWidth : 0;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(offset, 0, 0),
              child: SectionCard(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    if (_dragOffset > 0) {
                      setState(() => _dragOffset = 0);
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RosterDetailScreen(rosterId: roster.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.fact_check_rounded),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                roster.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _metadataLabel(
                                  controller: controller,
                                  roster: roster,
                                  entryCount: entryCount,
                                  sessionCount: sessionCount,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _metadataLabel({
    required QrosterController controller,
    required Roster roster,
    required int entryCount,
    required int sessionCount,
  }) {
    final parts = [
      roster.type.label,
      '$entryCount 人',
      if (roster.type == RosterType.longTerm) '已记录 $sessionCount 次',
      controller.latestRecordLabel(roster.id),
    ];
    return parts.join(' · ');
  }

  Future<void> _pinRoster(BuildContext context) async {
    await context.read<QrosterController>().pinRoster(widget.roster.id);
    if (!mounted || !context.mounted) return;
    setState(() => _dragOffset = 0);
    showSnack(context, '已置顶：${widget.roster.name}');
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除花名册'),
        content: Text('确定删除“${widget.roster.name}”吗？相关成员、记录和结果都会删除。'),
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
    await context.read<QrosterController>().deleteRoster(widget.roster.id);
    if (!mounted) return;
    setState(() => _dragOffset = 0);
    if (context.mounted) {
      showSnack(context, '已删除：${widget.roster.name}');
    }
  }
}
