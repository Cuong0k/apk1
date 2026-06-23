import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/pages/scan.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';

class AddProfileView extends StatelessWidget {
  final BuildContext context;

  const AddProfileView({super.key, required this.context});

  Future<void> _handleAddProfileFormURL(String raw) async {
    globalState.container
        .read(profilesActionProvider.notifier)
        .addProfileFormURL(raw);
  }

  Future<void> _toScan() async {
    if (system.isDesktop) {
      globalState.container
          .read(profilesActionProvider.notifier)
          .addProfileFormQrCode();
      return;
    }
    final url = await BaseNavigator.push(context, const ScanPage());
    if (url != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAddProfileFormURL(url);
      });
    }
  }

  Future<void> _toAdd() async {
    final value = await globalState.showCommonDialog<String>(
      child: InputDialog(
        autovalidateMode: AutovalidateMode.onUnfocus,
        title: 'Nhập token hoặc link sub',
        labelText: 'Token hoặc Link Sub',
        value: '',
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Vui lòng nhập token hoặc link sub';
          }
          return null;
        },
      ),
    );
    if (value != null) {
      _handleAddProfileFormURL(value);
    }
  }

  @override
  Widget build(context) {
    return ListView(
      children: [
        ListItem(
          leading: const Icon(Icons.qr_code_sharp),
          title: const Text('Quét mã QR'),
          subtitle: const Text('Quét mã QR từ hệ thống'),
          onTap: _toScan,
        ),
        ListItem(
          leading: const Icon(Icons.cloud_download_sharp),
          title: const Text('Token hoặc Link Sub'),
          subtitle: const Text('Nhập token hoặc link sub từ hệ thống'),
          onTap: _toAdd,
        ),
      ],
    );
  }
}

class URLFormDialog extends StatefulWidget {
  const URLFormDialog({super.key});

  @override
  State<URLFormDialog> createState() => _URLFormDialogState();
}

class _URLFormDialogState extends State<URLFormDialog> {
  final _urlController = TextEditingController();

  Future<void> _handleAddProfileFormURL() async {
    final url = _urlController.value.text;
    if (url.isEmpty) return;
    Navigator.of(context).pop<String>(url);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: 'Nhập token hoặc link sub',
      actions: [
        TextButton(
          onPressed: _handleAddProfileFormURL,
          child: const Text('Xác nhận'),
        ),
      ],
      child: const SizedBox(
        width: 300,
        child: Wrap(
          runSpacing: 16,
          children: [],
        ),
      ),
    );
  }
}
