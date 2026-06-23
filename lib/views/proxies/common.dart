import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/core.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Height for group header with subscription info (3 content rows)
double get listHeaderHeight {
  final measure = globalState.measure;
  // Row 1: subscription name (titleMedium)
  // Row 2: progress bar + icons — icon buttons are 28px (Icon 20 + Padding 4*2)
  // Row 3: date text (bodySmall)
  // Padding top=12 bottom=12 matches card's EdgeInsets.fromLTRB(16,12,12,12)
  return 12.0 + measure.titleMediumHeight + 6.0 + 28.0 + 4.0 + measure.bodySmallHeight + 12.0;
}

// Compact group header (no subscription info) = same height as proxy cards
double get listHeaderMinHeight => 52.0;

double getItemHeight(ProxyCardType proxyCardType) {
  return 52.0;
}

Future<void> delayTestAllGroups() async {
  final groups = getCurrentGroups();
  for (final group in groups) {
    delayTest(group.all, group.testUrl);
  }
}

List<Group> getCurrentGroups() {
  return globalState.container.read(currentGroupsStateProvider).value;
}

List<Group> getGroups() {
  return globalState.container.read(groupsProvider);
}

String? getCurrentGroupName() {
  return globalState.container.read(
    currentProfileProvider.select((state) => state?.currentGroupName),
  );
}

void updateCurrentGroupName(String groupName) {
  globalState.container
      .read(proxiesActionProvider.notifier)
      .updateCurrentGroupName(groupName);
}

void updateCurrentUnfoldSet(Set<String> value) {
  globalState.container
      .read(proxiesActionProvider.notifier)
      .updateCurrentUnfoldSet(value);
}

Future<void> proxyDelayTest(Proxy proxy, [String? testUrl]) async {
  // libclash.so panics when the Go runtime calls into VLESS protocol handler
  if (proxy.type.toLowerCase() == 'vless') return;

  final ref = globalState.container;
  final groups = getGroups();
  final selectedMap = ref.read(
    currentProfileProvider.select((state) => state?.selectedMap ?? {}),
  );
  final state = computeRealSelectedProxyState(
    proxy.name,
    groups: groups,
    selectedMap: selectedMap,
  );
  final currentTestUrl = state.testUrl.takeFirstValid([
    ref.read(realTestUrlProvider(testUrl)),
  ]);
  if (state.proxyName.isEmpty) {
    return;
  }
  ref
      .read(proxiesActionProvider.notifier)
      .setDelay(Delay(url: currentTestUrl, name: state.proxyName, value: 0));
  ref
      .read(proxiesActionProvider.notifier)
      .setDelay(await coreController.getDelay(currentTestUrl, state.proxyName));
}

Future<void> delayTest(List<Proxy> proxies, [String? testUrl]) async {
  final delayProxies = proxies.map<Future>((proxy) async {
    await proxyDelayTest(proxy, testUrl);
  }).toList();

  final batchesDelayProxies = delayProxies.batch(100);
  for (final batchDelayProxies in batchesDelayProxies) {
    await Future.wait(batchDelayProxies);
  }
  globalState.container.read(sortNumProvider.notifier).add();
  _autoSwitchTimedOutProxies();
}

void _autoSwitchTimedOutProxies() {
  final ref = globalState.container;
  final groups = getGroups();
  for (final group in groups) {
    if (group.type != GroupType.Selector) continue;
    final selectedName = ref.read(selectedProxyNameProvider(group.name));
    if (selectedName == null || selectedName.isEmpty) continue;
    final currentDelay = ref.read(
      delayProvider(proxyName: selectedName, testUrl: group.testUrl),
    );
    // < 0 = timeout; null = not tested; 0 = in progress; > 0 = ok
    if (currentDelay == null || currentDelay >= 0) continue;
    Proxy? best;
    int bestDelay = 999999;
    for (final proxy in group.all) {
      if (proxy.name == selectedName) continue;
      if (proxy.type.toLowerCase() == 'vless') continue;
      final d = ref.read(
        delayProvider(proxyName: proxy.name, testUrl: group.testUrl),
      );
      if (d != null && d > 0 && d < bestDelay) {
        bestDelay = d;
        best = proxy;
      }
    }
    if (best != null) {
      ref.read(profilesActionProvider.notifier)
          .updateCurrentSelectedMap(group.name, best.name);
      ref.read(proxiesActionProvider.notifier)
          .changeProxyDebounce(group.name, best.name);
    }
  }
}

double getScrollToSelectedOffset({
  required String groupName,
  required List<Proxy> proxies,
}) {
  final ref = globalState.container;
  final columns = ref.read(proxiesColumnsProvider);
  final proxyCardType = ref.read(
    proxiesStyleSettingProvider.select((state) => state.cardType),
  );
  final selectedProxyName = ref.read(selectedProxyNameProvider(groupName));
  final findSelectedIndex = proxies.indexWhere(
    (proxy) => proxy.name == selectedProxyName,
  );
  final selectedIndex = findSelectedIndex != -1 ? findSelectedIndex : 0;
  final rows = (selectedIndex / columns).floor();
  return rows * getItemHeight(proxyCardType) + (rows - 1) * 8;
}
