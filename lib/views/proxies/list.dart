import 'dart:math';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fl_clash/views/profiles/add.dart';
import 'package:fl_clash/views/profiles/edit.dart';
import 'card.dart';
import 'common.dart';

typedef GroupNameProxiesMap = Map<String, List<Proxy>>;

class ProxiesListView extends StatefulWidget {
  const ProxiesListView({super.key});

  @override
  State<ProxiesListView> createState() => _ProxiesListViewState();
}

class _ProxiesListViewState extends State<ProxiesListView> {
  final _controller = ScrollController();
  final _headerStateNotifier = ValueNotifier<ProxiesListHeaderSelectorState?>(
    null,
  );
  List<double> _headerOffset = [];
  double containerHeight = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_adjustHeader);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adjustHeader();
    });
  }

  ProxiesListHeaderSelectorState _getProxiesListHeaderSelectorState(
    double initOffset,
  ) {
    final index = _headerOffset.findInterval(initOffset);
    final currentIndex = index;
    double headerOffset = 0.0;
    if (index + 1 <= _headerOffset.length - 1) {
      final endOffset = _headerOffset[index + 1];
      final startOffset = endOffset - _currentHeaderHeight(index) - 8;
      if (initOffset > startOffset && initOffset < endOffset) {
        headerOffset = initOffset - startOffset;
      }
    }
    return ProxiesListHeaderSelectorState(
      offset: max(headerOffset, 0),
      currentIndex: currentIndex,
    );
  }

  double _currentHeaderHeight(int groupIndex) {
    // approximate — use listHeaderHeight as max
    return listHeaderHeight;
  }

  void _adjustHeader() {
    _headerStateNotifier.value = _getProxiesListHeaderSelectorState(
      !_controller.hasClients ? 0 : _controller.offset,
    );
  }

  double _getListItemHeight(Widget item, ProxyCardType proxyCardType) {
    if (item is ListHeader) return item.heightHint;
    if (item is SizedBox) return 8;
    return getItemHeight(proxyCardType);
  }

  @override
  void dispose() {
    _headerStateNotifier.dispose();
    _controller.removeListener(_adjustHeader);
    _controller.dispose();
    super.dispose();
  }

  void _handleChange(Set<String> currentUnfoldSet, String groupName) {
    _autoScrollToGroup(groupName);
    final tempUnfoldSet = Set<String>.from(currentUnfoldSet);
    if (tempUnfoldSet.contains(groupName)) {
      tempUnfoldSet.remove(groupName);
    } else {
      tempUnfoldSet.add(groupName);
    }
    updateCurrentUnfoldSet(tempUnfoldSet);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adjustHeader();
    });
  }

  List<double> _getItemHeightList(
    List<Widget> items,
    ProxyCardType proxyCardType,
  ) {
    final itemHeightList = <double>[];
    final List<double> headerOffset = [];
    double currentHeight = 0;
    for (final item in items) {
      if (item is ListHeader) {
        headerOffset.add(currentHeight);
      }
      final itemHeight = _getListItemHeight(item, proxyCardType);
      itemHeightList.add(itemHeight);
      currentHeight = currentHeight + itemHeight;
    }
    _headerOffset = headerOffset;
    return itemHeightList;
  }

  List<Widget> _buildItems(
    WidgetRef ref, {
    required List<Group> groups,
    required int columns,
    required Set<String> currentUnfoldSet,
    required ProxyCardType cardType,
  }) {
    final profile = ref.watch(currentProfileProvider);
    final items = <Widget>[];
    for (final group in groups) {
      final groupName = group.name;
      final isExpand = currentUnfoldSet.contains(groupName);

      // Since we only show top-level groups now, the first group always
      // corresponds to the current profile — show sub info for any visible group
      final hasSubInfo = profile != null &&
          profile.subscriptionInfo != null &&
          (profile.subscriptionInfo!.total > 0);

      final headerHeight =
          hasSubInfo ? listHeaderHeight : listHeaderMinHeight;

      items.addAll([
        ListHeader(
          heightHint: headerHeight,
          onScrollToSelected: _scrollToGroupSelected,
          isExpand: isExpand,
          group: group,
          subscriptionInfo: hasSubInfo ? profile.subscriptionInfo : null,
          lastUpdateDate: hasSubInfo ? profile.lastUpdateDate : null,
          profile: hasSubInfo ? profile : null,
          onChange: (String groupName) {
            _handleChange(currentUnfoldSet, groupName);
          },
        ),
        const SizedBox(height: 8),
      ]);
      if (isExpand) {
        final proxies = group.all;
        for (final proxy in proxies) {
          items.add(
            ProxyCard(
              testUrl: group.testUrl,
              type: cardType,
              groupType: group.type,
              key: ValueKey('$groupName.${proxy.name}'),
              proxy: proxy,
              groupName: groupName,
            ),
          );
        }
        items.add(const SizedBox(height: 8));
      }
    }
    return items;
  }

  Widget _buildHeader(
    WidgetRef ref, {
    required Group group,
    required Set<String> currentUnfoldSet,
    required double headerHeight,
    SubscriptionInfo? subscriptionInfo,
    DateTime? lastUpdateDate,
    Profile? profile,
  }) {
    final groupName = group.name;
    final isExpand = currentUnfoldSet.contains(groupName);
    return SizedBox(
      height: headerHeight,
      child: ListHeader(
        heightHint: headerHeight,
        enterAnimated: false,
        onScrollToSelected: _scrollToGroupSelected,
        key: Key(groupName),
        isExpand: isExpand,
        group: group,
        subscriptionInfo: subscriptionInfo,
        lastUpdateDate: lastUpdateDate,
        profile: profile,
        onChange: (String groupName) {
          _handleChange(currentUnfoldSet, groupName);
        },
      ),
    );
  }

  double _getGroupOffset(String groupName) {
    if (_controller.position.maxScrollExtent == 0) {
      return 0;
    }
    final currentGroups = getCurrentGroups();
    final findIndex = currentGroups.indexWhere(
      (item) => item.name == groupName,
    );
    final index = findIndex != -1 ? findIndex : 0;
    if (index >= _headerOffset.length) return 0;
    return _headerOffset[index];
  }

  void _scrollToMakeVisibleWithPadding({
    required double containerHeight,
    required double pixels,
    required double start,
    required double end,
    double padding = 24,
  }) {
    final visibleStart = pixels;
    final visibleEnd = pixels + containerHeight;

    final isElementVisible = start >= visibleStart && end <= visibleEnd;
    if (isElementVisible) {
      return;
    }

    double targetScrollOffset;

    if (end <= visibleStart) {
      targetScrollOffset = start;
    } else if (start >= visibleEnd) {
      targetScrollOffset = end - containerHeight + padding;
    } else {
      final visibleTopPart = end - visibleStart;
      final visibleBottomPart = visibleEnd - start;
      if (visibleTopPart.abs() >= visibleBottomPart.abs()) {
        targetScrollOffset = end - containerHeight + padding;
      } else {
        targetScrollOffset = start;
      }
    }

    targetScrollOffset = targetScrollOffset.clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );

    _controller.jumpTo(targetScrollOffset);
  }

  void _autoScrollToGroup(String groupName) {
    final pixels = _controller.position.pixels;
    final offset = _getGroupOffset(groupName);
    _scrollToMakeVisibleWithPadding(
      containerHeight: containerHeight,
      pixels: pixels,
      start: offset,
      end: offset + listHeaderHeight,
    );
  }

  void _scrollToGroupSelected(String groupName) {
    final currentInitOffset = _getGroupOffset(groupName);
    final currentGroups = getCurrentGroups();
    final proxies = currentGroups.getGroup(groupName)?.all;
    _jumpTo(
      currentInitOffset +
          8 +
          getScrollToSelectedOffset(
            groupName: groupName,
            proxies: proxies ?? [],
          ),
    );
  }

  void _jumpTo(double offset) {
    if (mounted && _controller.hasClients) {
      _controller.animateTo(
        offset.clamp(
          _controller.position.minScrollExtent,
          _controller.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return Consumer(
      builder: (_, ref, _) {
        final state = ref.watch(proxiesListStateProvider);
        ref.watch(themeSettingProvider.select((state) => state.textScale));
        if (state.groups.isEmpty) {
          return NullStatus(
            illustration: const ProxyEmptyIllustration(),
            label: appLocalizations.nullTip(appLocalizations.proxies),
          );
        }
        final profile = ref.watch(currentProfileProvider);
        final items = _buildItems(
          ref,
          groups: state.groups,
          currentUnfoldSet: state.currentUnfoldSet,
          columns: state.columns,
          cardType: state.proxyCardType,
        );
        final itemsOffset = _getItemHeightList(items, state.proxyCardType);
        return CommonScrollBar(
          controller: _controller,
          thumbVisibility: true,
          trackVisibility: true,
          child: Stack(
            children: [
              Positioned.fill(
                child: ScrollConfiguration(
                  behavior: HiddenBarScrollBehavior(),
                  child: ListView.builder(
                    key: proxiesListStoreKey,
                    padding: const EdgeInsets.all(16),
                    controller: _controller,
                    itemExtentBuilder: (index, _) {
                      return itemsOffset[index];
                    },
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      return items[index];
                    },
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (_, container) {
                  containerHeight = container.maxHeight;
                  return ValueListenableBuilder(
                    valueListenable: _headerStateNotifier,
                    builder: (_, headerState, _) {
                      if (headerState == null) {
                        return const SizedBox();
                      }
                      final index =
                          headerState.currentIndex > state.groups.length - 1
                          ? 0
                          : headerState.currentIndex;
                      if (index < 0 || state.groups.isEmpty) {
                        return Container();
                      }
                      final group = state.groups[index];
                      final hasSubInfo = profile != null &&
                          profile.subscriptionInfo != null &&
                          (profile.subscriptionInfo!.total > 0);
                      final headerHeight = hasSubInfo
                          ? listHeaderHeight
                          : listHeaderMinHeight;
                      return Stack(
                        children: [
                          Positioned(
                            top: -headerState.offset,
                            child: Container(
                              width: container.maxWidth,
                              color: context.colorScheme.surface,
                              padding: EdgeInsets.only(
                                top: hasSubInfo ? 16 : 0,
                                left: hasSubInfo ? 16 : 0,
                                right: hasSubInfo ? 16 : 0,
                                bottom: hasSubInfo ? 8 : 0,
                              ),
                              child: _buildHeader(
                                ref,
                                group: group,
                                currentUnfoldSet: state.currentUnfoldSet,
                                headerHeight: headerHeight,
                                subscriptionInfo: hasSubInfo
                                    ? profile!.subscriptionInfo
                                    : null,
                                lastUpdateDate: hasSubInfo
                                    ? profile!.lastUpdateDate
                                    : null,
                                profile: hasSubInfo ? profile : null,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class ListHeader extends StatefulWidget {
  final Group group;
  final Function(String groupName) onChange;
  final Function(String groupName) onScrollToSelected;
  final bool isExpand;
  final bool enterAnimated;
  final double heightHint;
  final SubscriptionInfo? subscriptionInfo;
  final DateTime? lastUpdateDate;
  final Profile? profile;

  const ListHeader({
    super.key,
    this.enterAnimated = true,
    required this.group,
    required this.onChange,
    required this.onScrollToSelected,
    required this.isExpand,
    required this.heightHint,
    this.subscriptionInfo,
    this.lastUpdateDate,
    this.profile,
  });

  @override
  State<ListHeader> createState() => _ListHeaderState();
}

class _ListHeaderState extends State<ListHeader> {
  var isLock = false;

  String get icon => widget.group.icon;
  // Show profile label (subscription name) when available, else group name
  String get groupName => (widget.profile?.label.isNotEmpty == true)
      ? widget.profile!.label
      : widget.group.name;
  String get groupType => widget.group.type.name;
  bool get isExpand => widget.isExpand;

  Future<void> _delayTest() async {
    if (isLock) return;
    isLock = true;
    await delayTest(widget.group.all, widget.group.testUrl);
    isLock = false;
  }

  void _handleChange(String groupName) {
    widget.onChange(groupName);
  }

  Future<void> _updateProfile() async {
    final profile = widget.profile;
    if (profile == null) return;
    globalState.container
        .read(profilesActionProvider.notifier)
        .updateProfile(profile, showLoading: true);
  }

  void _editProfile(BuildContext context) {
    final profile = widget.profile;
    if (profile == null) return;
    showExtend(
      context,
      builder: (_) => AdaptiveSheetScaffold(
        body: EditProfileView(context: context, profile: profile),
        title: context.appLocalizations.edit,
      ),
    );
  }

  void _addProfile(BuildContext context) {
    showExtend(
      context,
      builder: (_) => AdaptiveSheetScaffold(
        body: AddProfileView(context: context),
        title: context.appLocalizations.addProfile,
      ),
    );
  }

  Future<void> _deleteProfile(BuildContext context) async {
    final profile = widget.profile;
    if (profile == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.appLocalizations.delete),
        content: Text(profile.label.isNotEmpty ? profile.label : profile.id.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.appLocalizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.appLocalizations.confirm,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      globalState.container
          .read(profilesActionProvider.notifier)
          .deleteProfile(profile.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Groups without subscription info → compact flat row (same height/style as proxy cards)
    if (widget.subscriptionInfo == null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _handleChange(groupName),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: EmojiText(
                    groupName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  groupType,
                  maxLines: 1,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpand ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Groups with subscription info → ShadowClash-style card
    final info = widget.subscriptionInfo!;
    final lastUpdate = widget.lastUpdateDate;
    final used = info.upload + info.download;
    final total = info.total;
    final progress = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
    final usedStr = used.traffic.show;
    final totalStr = total.traffic.show;

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: group name (bold, no icons)
          EmojiText(
            groupName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          // Row 2: [progress bar] [usage text] [⊙] [⋮] [^]
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: context.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$usedStr / $totalStr',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              if (isExpand)
                GestureDetector(
                  onTap: () => widget.onScrollToSelected(groupName),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.adjust, size: 18,
                        color: context.colorScheme.onSurfaceVariant),
                  ),
                ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18,
                    color: context.colorScheme.onSurfaceVariant),
                padding: EdgeInsets.zero,
                iconSize: 18,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: (value) {
                  if (value == 'edit') _editProfile(context);
                  if (value == 'update') _updateProfile();
                  if (value == 'add') _addProfile(context);
                  if (value == 'delete') _deleteProfile(context);
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18,
                            color: context.colorScheme.onSurface),
                        const SizedBox(width: 8),
                        Text(context.appLocalizations.edit,
                            style: context.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'update',
                    child: Row(
                      children: [
                        Icon(Icons.sync, size: 18,
                            color: context.colorScheme.onSurface),
                        const SizedBox(width: 8),
                        Text(context.appLocalizations.update,
                            style: context.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'add',
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 18,
                            color: context.colorScheme.onSurface),
                        const SizedBox(width: 8),
                        Text(context.appLocalizations.addProfile,
                            style: context.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18,
                            color: context.colorScheme.error),
                        const SizedBox(width: 8),
                        Text(context.appLocalizations.delete,
                            style: context.textTheme.bodyMedium?.copyWith(
                                color: context.colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _handleChange(groupName),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isExpand ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          // Row 3: date · time ago
          if (lastUpdate != null) ...[
            const SizedBox(height: 4),
            Text(
              '${lastUpdate.year}-${lastUpdate.month.toString().padLeft(2, '0')}-${lastUpdate.day.toString().padLeft(2, '0')} · ${lastUpdate.getLastUpdateTimeDesc(context)}',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
