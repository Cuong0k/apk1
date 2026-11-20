import 'package:collection/collection.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/common.dart';
import 'package:fl_clash/models/state.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/widgets/network_detection.dart' as nd;
import 'package:fl_clash/views/dashboard/widgets/traffic_usage.dart';
import 'package:fl_clash/views/profiles/add.dart';
import 'package:fl_clash/views/proxies/list.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common.dart';
import 'setting.dart';
import 'tab.dart';

class ProxiesView extends ConsumerStatefulWidget {
  const ProxiesView({super.key});

  @override
  ConsumerState<ProxiesView> createState() => _ProxiesViewState();
}

class _ProxiesViewState extends ConsumerState<ProxiesView> {
  final GlobalKey<CommonScaffoldState> _scaffoldKey = GlobalKey();
  final GlobalKey<ProxiesTabViewState> _proxiesTabKey = GlobalKey();
  bool _hasProviders = false;
  bool _isTab = false;

  List<Widget> _buildActions(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return [
      IconButton(
        onPressed: _handleShowAddProfile,
        icon: const Icon(Icons.add),
        tooltip: appLocalizations.addProfile,
      ),
      if (_isTab)
        IconButton(
          onPressed: () {
            _proxiesTabKey.currentState?.scrollToGroupSelected();
          },
          icon: const Icon(Icons.adjust, weight: 1),
        ),
      CommonPopupBox(
        targetBuilder: (open) {
          return IconButton(
            onPressed: () {
              final isMobile = ref.read(isMobileViewProvider);
              open(offset: Offset(0, isMobile ? 0 : 20));
            },
            icon: const Icon(Icons.more_vert),
          );
        },
        popup: CommonPopupMenu(
          items: [
            PopupMenuItemData(
              icon: Icons.tune,
              label: appLocalizations.settings,
              onPressed: () {
                showSheet(
                  context: context,
                  props: const SheetProps(isScrollControlled: true),
                  builder: (_) {
                    return AdaptiveSheetScaffold(
                      body: const ProxiesSetting(),
                      title: appLocalizations.settings,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    ];
  }

  void _handleShowAddProfile() {
    showExtend(
      context,
      builder: (_) {
        return AdaptiveSheetScaffold(
          body: AddProfileView(context: context),
          title: context.appLocalizations.addProfile,
        );
      },
    );
  }

  Widget _buildVpnRow() {
    return Consumer(
      builder: (context, ref, _) {
        final isStart = ref.watch(isStartProvider);
        final hasProfiles = ref.watch(
          profilesProvider.select((s) => s.isNotEmpty),
        );
        if (!hasProfiles) return const SizedBox.shrink();
        final mode = ref.watch(
          patchClashConfigProvider.select((s) => s.mode),
        );
        final currentGroups = ref.watch(
          currentGroupsStateProvider.select((s) => s.value),
        );
        final activeGroup = currentGroups.isNotEmpty ? currentGroups.first : null;
        final rawSelected = ref.watch(
          selectedProxyNameProvider(
            mode == Mode.global
                ? GroupName.GLOBAL.name
                : (activeGroup?.name ?? GroupName.GLOBAL.name),
          ),
        );
        // If the selected entry is itself an auto-select/fallback sub-group
        // (URLTest/Fallback), show the actual server it picked (its `now`)
        // instead of the group's own label like "Tự động chọn".
        String? selectedServer = rawSelected;
        if (mode != Mode.global && activeGroup != null && rawSelected != null) {
          final nested = activeGroup.all.firstWhereOrNull(
            (p) => p.name == rawSelected,
          );
          if (nested?.now != null && nested!.now!.isNotEmpty) {
            selectedServer = nested.now;
          }
        }
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.ap, vertical: 4),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isStart
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Icon(
                  Icons.power_settings_new_rounded,
                  size: 22,
                  color: isStart
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isStart ? 'Đã kết nối VPN' : 'Chưa kết nối VPN',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isStart
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isStart && selectedServer != null && selectedServer.isNotEmpty)
                      Text(
                        selectedServer,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Switch(
                value: isStart,
                onChanged: (value) {
                  ref.read(setupActionProvider.notifier).updateStatus(
                    value,
                    isInit: !ref.read(initProvider),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool _syncing = false;
  bool _testing = false;

  Future<void> _handleDelayTest() async {
    if (_testing) return;
    setState(() => _testing = true);
    try {
      await delayTestAllGroups();
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _handleSyncProfile() async {
    if (_syncing) return;
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;
    setState(() => _syncing = true);
    try {
      await globalState.container
          .read(profilesActionProvider.notifier)
          .updateProfile(profile, showLoading: true);
      globalState.showNotifier('Đồng bộ gói VPN thành công');
    } catch (_) {
      globalState.showNotifier('Đồng bộ thất bại, vui lòng thử lại');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Widget _buildActionTabs() {
    return Consumer(
      builder: (context, ref, _) {
        final hasProfiles = ref.watch(
          profilesProvider.select((s) => s.isNotEmpty),
        );
        if (!hasProfiles) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        Widget item({
          required IconData icon,
          required String label,
          required bool busy,
          required VoidCallback onTap,
        }) {
          return Expanded(
            child: InkWell(
              onTap: busy ? null : onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: busy
                          ? Padding(
                              padding: const EdgeInsets.all(3),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.primary,
                              ),
                            )
                          : Icon(icon, size: 24, color: scheme.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(16.ap, 6, 16.ap, 8),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant.withAlpha(120)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  item(
                    icon: Icons.schedule_outlined,
                    label: 'Kiểm tra máy chủ',
                    busy: _testing,
                    onTap: _handleDelayTest,
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: scheme.outlineVariant.withAlpha(120),
                  ),
                  item(
                    icon: Icons.sync,
                    label: 'Đồng Bộ Gói VPN',
                    busy: _syncing,
                    onTap: _handleSyncProfile,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomCards() {
    return Consumer(
      builder: (context, ref, _) {
        final hasProfiles = ref.watch(
          profilesProvider.select((s) => s.isNotEmpty),
        );
        if (!hasProfiles) return const SizedBox.shrink();
        return SizedBox(
          height: 76,
          child: Padding(
            padding: EdgeInsets.fromLTRB(8.ap, 4, 8.ap, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.topLeft,
                      heightFactor: 76 / getWidgetHeight(1).clamp(1, 999),
                      child: nd.NetworkDetection(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.topLeft,
                      heightFactor: 76 / getWidgetHeight(2).clamp(1, 999),
                      child: TrafficUsage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Bản cài cũ đã lưu allow-lan=false → bật TCP đồng thời + LAN đúng 1 lần
  Future<void> _applyDefaultsOnce() async {
    const key = 'vpnstore_defaults_v1';
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(key) == true) return;
      if (!mounted) return;
      ref
          .read(patchClashConfigProvider.notifier)
          .update((s) => s.copyWith(tcpConcurrent: true, allowLan: true));
      await prefs.setBool(key, true);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(providersProvider.select((state) => state.isNotEmpty), (
      prev,
      next,
    ) {
      if (prev != next) {
        setState(() {
          _hasProviders = next;
        });
      }
    }, fireImmediately: true);
    // Chế độ định tuyến cố định: Quy tắc (đã bỏ thanh chọn chế độ)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(patchClashConfigProvider).mode != Mode.rule) {
        ref.read(setupActionProvider.notifier).changeMode(Mode.rule);
      }
      _applyDefaultsOnce();
    });
    // Always list view — _isTab stays false
    ref.listenManual(
      currentPageLabelProvider.select((state) => state == PageLabel.proxies),
      (prev, next) {
        if (prev != next && next == false) {
          _scaffoldKey.currentState?.handleExitSearching();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const proxiesType = ProxiesType.list;
    final isLoading = ref.watch(loadingProvider(LoadingTag.proxies));
    return CommonScaffold(
      key: _scaffoldKey,
      isLoading: isLoading,
      resizeToAvoidBottomInset: false,
      actions: _buildActions(context),
      title: appName,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildVpnRow(),
          _buildActionTabs(),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80),
          ),
          Expanded(
            child: switch (proxiesType) {
              ProxiesType.tab => ProxiesTabView(key: _proxiesTabKey),
              ProxiesType.list => const ProxiesListView(),
            },
          ),
          _buildBottomCards(),
        ],
      ),
    );
  }
}
