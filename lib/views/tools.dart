import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/about.dart';
import 'package:fl_clash/views/access.dart';
import 'package:fl_clash/views/application_setting.dart';
import 'package:fl_clash/views/backup_and_restore.dart';
import 'package:fl_clash/views/config/config.dart';
import 'package:fl_clash/views/hotkey.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' show dirname, join;

import 'config/advanced.dart';
import 'developer.dart';
import 'theme.dart';

class ToolsView extends ConsumerStatefulWidget {
  const ToolsView({super.key});

  @override
  ConsumerState<ToolsView> createState() => _ToolViewState();
}

class _ToolViewState extends ConsumerState<ToolsView> {
  Widget _buildNavigationMenuItem(NavigationItem navigationItem) {
    return ListItem.open(
      leading: navigationItem.icon,
      title: Text(Intl.message(navigationItem.label.name)),
      subtitle: navigationItem.description != null
          ? Text(Intl.message(navigationItem.description!))
          : null,
      delegate: OpenDelegate(widget: navigationItem.builder(context)),
    );
  }

  Widget _buildNavigationMenu(List<NavigationItem> navigationItems) {
    return Column(
      children: [
        for (final navigationItem in navigationItems) ...[
          _buildNavigationMenuItem(navigationItem),
          navigationItems.last != navigationItem
              ? const Divider(height: 0)
              : Container(),
        ],
      ],
    );
  }

  List<Widget> _getOtherList(bool enableDeveloperMode) {
    return generateSection(
      title: context.appLocalizations.other,
      items: [
        const _DisclaimerItem(),
        if (enableDeveloperMode) const _DeveloperItem(),
        const _InfoItem(),
      ],
    );
  }

  List<Widget> _getSettingList() {
    return generateSection(
      title: context.appLocalizations.settings,
      items: [
        const _LocaleItem(),
        const _ThemeItem(),
        const _BackupItem(),
        if (system.isDesktop) const _HotkeyItem(),
        if (system.isWindows) const _LoopbackItem(),
        if (system.isAndroid) const _AccessItem(),
        const _ConfigItem(),
        const _AdvancedConfigItem(),
        const _SettingItem(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm2 = ref.watch(
      appSettingProvider.select(
        (state) => VM2(state.locale, state.developerMode),
      ),
    );
    final items = [
      if (system.isAndroid) ...[
        ListHeader(title: 'Cập nhật'),
        const _UpdateAppItem(),
      ],
      Consumer(
        builder: (_, ref, _) {
          final state = ref.watch(moreToolsSelectorStateProvider);
          if (state.navigationItems.isEmpty) {
            return Container();
          }
          return Column(
            children: [
              ListHeader(title: context.appLocalizations.more),
              _buildNavigationMenu(state.navigationItems),
            ],
          );
        },
      ),
      ..._getSettingList(),
      ..._getOtherList(vm2.b),
    ];
    return CommonScaffold(
      title: context.appLocalizations.tools,
      body: ListView.builder(
        key: toolsStoreKey,
        itemCount: items.length,
        itemBuilder: (_, index) => items[index],
        padding: const EdgeInsets.only(bottom: 20),
      ),
    );
  }
}

// ─── Cập nhật app ngay trong ứng dụng: tải APK → bấm Cài đặt ─────────────────

class _UpdateAppItem extends StatefulWidget {
  const _UpdateAppItem();

  @override
  State<_UpdateAppItem> createState() => _UpdateAppItemState();
}

class _UpdateAppItemState extends State<_UpdateAppItem> {
  static const _apkUrl = 'https://client-user.jiangsuhk.com/apk/vpnstore.apk';
  static const _channel = MethodChannel('com.vpnstore.app/update');

  bool _downloading = false;
  double? _progress;
  String? _apkPath;
  String? _error;
  dio.CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _download() async {
    if (_downloading) return;
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
      _apkPath = null;
    });
    _cancelToken = dio.CancelToken();
    try {
      final dir = await _channel.invokeMethod<String>('getApkDir');
      final savePath = '$dir/vpnstore_update.apk';
      final old = File(savePath);
      if (await old.exists()) await old.delete();
      // ?t=... để Cloudflare không trả bản APK cũ đang cache (max-age 4h)
      final url = '$_apkUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      await dio.Dio().download(
        url,
        savePath,
        cancelToken: _cancelToken,
        options: dio.Options(
          receiveTimeout: const Duration(minutes: 10),
          headers: {'Cache-Control': 'no-cache'},
        ),
        onReceiveProgress: (received, total) {
          if (!mounted) return;
          setState(() => _progress = total > 0 ? received / total : null);
        },
      );
      if (!mounted) return;
      // Kiểm tra APK: hợp lệ? đúng app? có mới hơn bản đang cài?
      final check = Map<String, dynamic>.from(
        await _channel.invokeMethod<Map>('checkApk', {'path': savePath}) ?? {},
      );
      if (!mounted) return;
      if (check['valid'] != true || check['samePackage'] != true) {
        await File(savePath).delete().catchError((_) => File(savePath));
        setState(() {
          _downloading = false;
          _progress = null;
          _error = 'File tải về bị lỗi, vui lòng thử lại';
        });
        return;
      }
      final newVer = (check['newVersion'] as num?)?.toInt() ?? 0;
      final curVer = (check['currentVersion'] as num?)?.toInt() ?? 0;
      if (newVer <= curVer) {
        await File(savePath).delete().catchError((_) => File(savePath));
        setState(() {
          _downloading = false;
          _progress = null;
          _error = 'Bạn đang dùng phiên bản mới nhất';
        });
        globalState.showNotifier('Bạn đang dùng phiên bản mới nhất');
        return;
      }
      setState(() {
        _downloading = false;
        _apkPath = savePath;
      });
      _askInstall();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _progress = null;
        _error = (e is dio.DioException && dio.CancelToken.isCancel(e))
            ? 'Đã huỷ tải'
            : 'Tải thất bại, vui lòng thử lại';
      });
    }
  }

  Future<void> _askInstall() async {
    final res = await globalState.showMessage(
      title: 'Tải xong bản cập nhật',
      message: const TextSpan(
        text: 'Bản VPN Store mới đã tải xong. Bấm "Cài đặt" để cập nhật ngay.',
      ),
      confirmText: 'Cài đặt',
    );
    if (res == true) await _install();
  }

  Future<void> _install() async {
    final path = _apkPath;
    if (path == null) return;
    try {
      final canInstall = await _channel.invokeMethod<bool>('canInstall') ?? true;
      if (!canInstall) {
        globalState.showNotifier(
          'Hãy bật "Cho phép cài ứng dụng" cho VPN Store, rồi quay lại bấm Cài đặt',
        );
        await _channel.invokeMethod('openInstallPermission');
        return;
      }
      await _channel.invokeMethod('installApk', {'path': path});
    } catch (_) {
      globalState.showNotifier('Không mở được trình cài đặt, vui lòng thử lại');
    }
  }

  String get _subtitle {
    if (_downloading) {
      return _progress != null
          ? 'Đang tải... ${(_progress! * 100).toStringAsFixed(0)}%'
          : 'Đang tải...';
    }
    if (_apkPath != null) return 'Đã tải xong — bấm Cài đặt để cập nhật';
    if (_error != null) return _error!;
    return 'Tải và cài đặt phiên bản VPN Store mới nhất';
  }

  @override
  Widget build(BuildContext context) {
    final Widget trailing;
    if (_downloading) {
      trailing = TextButton(
        onPressed: () => _cancelToken?.cancel(),
        child: const Text('Huỷ'),
      );
    } else if (_apkPath != null) {
      trailing = FilledButton(
        style: FilledButton.styleFrom(backgroundColor: kHeaderColor),
        onPressed: _install,
        child: const Text('Cài đặt'),
      );
    } else {
      trailing = FilledButton(
        style: FilledButton.styleFrom(backgroundColor: kHeaderColor),
        onPressed: _download,
        child: const Text('Cập nhật'),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListItem(
          leading: const Icon(Icons.system_update, color: kHeaderColor),
          title: const Text('Cập nhật ứng dụng'),
          subtitle: Text(_subtitle),
          trailing: trailing,
          onTap: _downloading
              ? null
              : (_apkPath != null ? _install : _download),
        ),
        if (_downloading)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: LinearProgressIndicator(
              value: _progress,
              color: kHeaderColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _LocaleItem extends ConsumerWidget {
  const _LocaleItem();

  String _getLocaleString(BuildContext context, Locale? locale) {
    if (locale == null) return context.appLocalizations.defaultText;
    return Intl.message(locale.toString());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(
      appSettingProvider.select((state) => state.locale),
    );
    final subTitle = locale ?? context.appLocalizations.defaultText;
    final currentLocale = utils.getLocaleForString(locale);
    return ListItem<Locale?>.options(
      leading: const Icon(Icons.language_outlined),
      title: Text(context.appLocalizations.language),
      subtitle: Text(Intl.message(subTitle)),
      delegate: OptionsDelegate(
        title: context.appLocalizations.language,
        options: [null, ...AppLocalizations.delegate.supportedLocales],
        onChanged: (Locale? locale) {
          ref
              .read(appSettingProvider.notifier)
              .update((state) => state.copyWith(locale: locale?.toString()));
        },
        textBuilder: (locale) => _getLocaleString(context, locale),
        value: currentLocale,
      ),
    );
  }
}

class _ThemeItem extends StatelessWidget {
  const _ThemeItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.style),
      title: Text(context.appLocalizations.theme),
      subtitle: Text(context.appLocalizations.themeDesc),
      delegate: const OpenDelegate(widget: ThemeView()),
    );
  }
}

class _BackupItem extends StatelessWidget {
  const _BackupItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.cloud_sync),
      title: Text(context.appLocalizations.backupAndRestore),
      subtitle: Text(context.appLocalizations.backupAndRestoreDesc),
      delegate: const OpenDelegate(widget: BackupAndRestore()),
    );
  }
}

class _HotkeyItem extends StatelessWidget {
  const _HotkeyItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.keyboard),
      title: Text(context.appLocalizations.hotkeyManagement),
      subtitle: Text(context.appLocalizations.hotkeyManagementDesc),
      delegate: const OpenDelegate(widget: HotKeyView()),
    );
  }
}

class _LoopbackItem extends StatelessWidget {
  const _LoopbackItem();

  @override
  Widget build(BuildContext context) {
    return ListItem(
      leading: const Icon(Icons.lock),
      title: Text(context.appLocalizations.loopback),
      subtitle: Text(context.appLocalizations.loopbackDesc),
      onTap: () {
        windows?.runas(
          '"${join(dirname(Platform.resolvedExecutable), "EnableLoopback.exe")}"',
          '',
        );
      },
    );
  }
}

class _AccessItem extends StatelessWidget {
  const _AccessItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.view_list),
      title: Text(context.appLocalizations.accessControl),
      subtitle: Text(context.appLocalizations.accessControlDesc),
      delegate: const OpenDelegate(widget: AccessView()),
    );
  }
}

class _ConfigItem extends StatelessWidget {
  const _ConfigItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.edit),
      title: Text(context.appLocalizations.basicConfig),
      subtitle: Text(context.appLocalizations.basicConfigDesc),
      delegate: const OpenDelegate(widget: ConfigView()),
    );
  }
}

class _AdvancedConfigItem extends StatelessWidget {
  const _AdvancedConfigItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.build),
      title: Text(context.appLocalizations.advancedConfig),
      subtitle: Text(context.appLocalizations.advancedConfigDesc),
      delegate: const OpenDelegate(widget: AdvancedConfigView()),
    );
  }
}

class _SettingItem extends StatelessWidget {
  const _SettingItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.settings),
      title: Text(context.appLocalizations.application),
      subtitle: Text(context.appLocalizations.applicationDesc),
      delegate: const OpenDelegate(widget: ApplicationSettingView()),
    );
  }
}

class _DisclaimerItem extends ConsumerWidget {
  const _DisclaimerItem();

  @override
  Widget build(BuildContext context, ref) {
    return ListItem(
      leading: const Icon(Icons.gavel),
      title: Text(context.appLocalizations.disclaimer),
      onTap: () async {
        final isDisclaimerAccepted = await globalState.showDisclaimer();
        if (!isDisclaimerAccepted) {
          await ref.read(systemActionProvider.notifier).handleExit();
        }
      },
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.info),
      title: Text(context.appLocalizations.about),
      delegate: const OpenDelegate(widget: AboutView()),
    );
  }
}

class _DeveloperItem extends StatelessWidget {
  const _DeveloperItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.developer_board),
      title: Text(context.appLocalizations.developerMode),
      delegate: const OpenDelegate(widget: DeveloperView()),
    );
  }
}
