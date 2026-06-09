import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'widgets/qroster_widgets.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const _appName = 'Q名册';
  static const _englishName = 'qroster';
  static const _repositoryUrl = 'https://github.com/xmbhjQAQ/Qroster';

  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于 Q名册')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SectionCard(
              child: FutureBuilder<PackageInfo>(
                future: _packageInfo,
                builder: (context, snapshot) => _IdentityHeader(
                  versionLabel: switch (snapshot) {
                    AsyncSnapshot(:final data?) => _versionLabel(data),
                    AsyncSnapshot(hasError: true) => '版本信息不可用',
                    _ => '正在读取版本信息',
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                children: const [
                  _InfoRow(
                    icon: Icons.fact_check_rounded,
                    title: '离线记录名单状态',
                    body: '导入名单后逐个记录成员状态，查看统计，并导出 .xlsx 结果。',
                  ),
                  _InfoRow(
                    icon: Icons.upload_file_rounded,
                    title: '导入与导出',
                    body: '支持名单导入、记录历史管理，以及围绕 .xlsx 的结果整理。',
                  ),
                  _InfoRow(
                    icon: Icons.insights_rounded,
                    title: '统计查看',
                    body: '按状态筛选结果，快速确认已记录、未记录和各状态数量。',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                children: const [
                  _InfoRow(
                    icon: Icons.phone_android_rounded,
                    title: '本地数据',
                    body: '花名册、记录历史和设置保存在当前设备，不做云端同步。',
                  ),
                  _InfoRow(
                    icon: Icons.auto_awesome_rounded,
                    title: 'LLM 请求',
                    body: '只有在你启用 LLM 解析并主动使用时，导入内容才会发送到你配置的接口。',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.code_rounded),
                    title: const Text('GitHub 仓库'),
                    subtitle: const Text(_repositoryUrl),
                    trailing: const Icon(Icons.copy_rounded),
                    onTap: () => _copyRepositoryUrl(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bug_report_rounded),
                    title: const Text('反馈问题'),
                    subtitle: const Text('复制仓库链接后提交 issue'),
                    trailing: const Icon(Icons.copy_rounded),
                    onTap: () => _copyRepositoryUrl(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.article_rounded),
                    title: const Text('第三方许可证'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showLicenses(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLicenses(BuildContext context) async {
    PackageInfo? packageInfo;
    try {
      packageInfo = await _packageInfo;
    } on Object {
      packageInfo = null;
    }
    if (!context.mounted) {
      return;
    }
    showLicensePage(
      context: context,
      applicationName: _appName,
      applicationVersion: packageInfo == null
          ? null
          : _versionText(packageInfo),
      applicationIcon: const Padding(
        padding: EdgeInsets.all(12),
        child: QAssetIcon('app_mark', size: 48),
      ),
    );
  }

  static Future<void> _copyRepositoryUrl(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _repositoryUrl));
    if (!context.mounted) {
      return;
    }
    showSnack(context, '已复制 GitHub 仓库链接');
  }

  static String _versionLabel(PackageInfo packageInfo) {
    return '版本 ${_versionText(packageInfo)}';
  }

  static String _versionText(PackageInfo packageInfo) {
    final buildNumber = packageInfo.buildNumber.trim();
    if (buildNumber.isEmpty) {
      return packageInfo.version;
    }
    return '${packageInfo.version} ($buildNumber)';
  }
}

class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({required this.versionLabel});

  final String versionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const QAssetIcon('app_mark', size: 64),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _AboutScreenState._appName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 2),
              Text(
                _AboutScreenState._englishName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(versionLabel, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
