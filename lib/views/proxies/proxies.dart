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
import 'package:fl_clash/views/proxies/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
            if (_hasProviders)
              PopupMenuItemData(
                icon: Icons.poll_outlined,
                label: appLocalizations.providers,
                onPressed: () {
                  showExtend(
                    context,
                    builder: (_) {
                      return const ProvidersView();
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

  void _onSearch(String value) {
    ref.read(queryProvider(QueryTag.proxies).notifier).value = value;
  }

  Widget _buildVpnRow() {
    return Consumer(
      builder: (context, ref, _) {
        final isStart = ref.watch(isStartProvider);
        final hasProfiles = ref.watch(
          profilesProvider.select((s) => s.isNotEmpty),
        );
        if (!hasProfiles) return const SizedBox.shrink();
        final profileLabel = ref.watch(
          currentProfileProvider.select(
            (s) => s?.label.isNotEmpty == true ? s!.label : s?.id.toString() ?? '',
          ),
        );
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.ap, vertical: 4),
          child: Row(
            children: [
              Icon(
                isStart ? Icons.lock : Icons.lock_open,
                size: 22,
                color: isStart
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isStart
                      ? (profileLabel.isNotEmpty
                          ? profileLabel
                          : context.appLocalizations.connected)
                      : context.appLocalizations.disconnected,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isStart
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  Widget _buildLatencyRow() {
    return Consumer(
      builder: (context, ref, _) {
        final hasProfiles = ref.watch(
          profilesProvider.select((s) => s.isNotEmpty),
        );
        if (!hasProfiles) return const SizedBox.shrink();
        return InkWell(
          onTap: () async {
            await delayTestAllGroups();
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.ap, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.appLocalizations.delayTest,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.play_circle_outline,
                  size: 22,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeRow() {
    return Consumer(
      builder: (context, ref, _) {
        final hasProfiles = ref.watch(
          profilesProvider.select((s) => s.isNotEmpty),
        );
        if (!hasProfiles) return const SizedBox.shrink();
        final mode = ref.watch(
          patchClashConfigProvider.select((s) => s.mode),
        );
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.ap, vertical: 2),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 4.ap),
                child: Icon(
                  Icons.alt_route_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              ...Mode.values.map((m) {
                final isSelected = m == mode;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      globalState.container
                          .read(setupActionProvider.notifier)
                          .changeMode(m);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      margin: EdgeInsets.symmetric(horizontal: 3.ap),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withAlpha(100),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        Intl.message(m.name),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              Padding(
                padding: EdgeInsets.only(left: 4.ap),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () async {
                        await delayTestAllGroups();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.refresh,
                          size: 17,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        showSheet(
                          context: context,
                          props: const SheetProps(isScrollControlled: true),
                          builder: (_) {
                            return AdaptiveSheetScaffold(
                              body: const ProxiesSetting(),
                              title: context.appLocalizations.settings,
                            );
                          },
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.filter_list,
                          size: 17,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      searchState: AppBarSearchState(onSearch: _onSearch),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildVpnRow(),
          _buildLatencyRow(),
          _buildModeRow(),
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
