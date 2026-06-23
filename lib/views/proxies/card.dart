import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/proxies/common.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProxyCard extends StatelessWidget {
  final String groupName;
  final Proxy proxy;
  final GroupType groupType;
  final ProxyCardType type;
  final String? testUrl;

  const ProxyCard({
    super.key,
    required this.groupName,
    required this.testUrl,
    required this.proxy,
    required this.groupType,
    required this.type,
  });

  void _handleTestCurrentDelay() {
    proxyDelayTest(proxy, testUrl);
  }

  Future<void> _changeProxy(WidgetRef ref) async {
    final isComputedSelected = groupType.isComputedSelected;
    final isSelector = groupType == GroupType.Selector;
    final container = globalState.container;
    if (isComputedSelected || isSelector) {
      final currentProxyName = container.read(proxyNameProvider(groupName));
      final nextProxyName = switch (isComputedSelected) {
        true => currentProxyName == proxy.name ? '' : proxy.name,
        false => proxy.name,
      };
      container
          .read(profilesActionProvider.notifier)
          .updateCurrentSelectedMap(groupName, nextProxyName);
      container
          .read(proxiesActionProvider.notifier)
          .changeProxyDebounce(groupName, nextProxyName);
      return;
    }
    globalState.showNotifier(currentAppLocalizations.notSelectedTip);
  }

  Widget _buildDelay(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final delay = ref.watch(
          delayProvider(proxyName: proxy.name, testUrl: testUrl),
        );
        if (delay == 0) {
          return const SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          );
        }
        if (delay == null) {
          return GestureDetector(
            onTap: _handleTestCurrentDelay,
            child: Icon(
              Icons.bolt,
              size: 16,
              color: context.textTheme.bodySmall?.color?.withOpacity(0.45),
            ),
          );
        }
        return GestureDetector(
          onTap: _handleTestCurrentDelay,
          child: Text(
            delay > 0 ? '$delay ms' : 'Timeout',
            maxLines: 1,
            textAlign: TextAlign.right,
            style: context.textTheme.labelSmall?.copyWith(
              color: utils.getDelayColor(delay),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, _) {
        final selectedProxyName = ref.watch(selectedProxyNameProvider(groupName));
        final isSelected = selectedProxyName == proxy.name;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _changeProxy(ref),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: isSelected
                  ? BoxDecoration(
                      color: context.colorScheme.primaryContainer.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: context.colorScheme.primary,
                        width: 1.5,
                      ),
                    )
                  : null,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: EmojiText(
                      proxy.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 76,
                    child: Text(
                      proxy.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.textTheme.bodySmall?.color?.withOpacity(0.55),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _buildDelay(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
