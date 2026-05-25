import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:srp_lanske/l10n/l10n.dart';

class ScheduleShareDialog extends StatelessWidget {
  const ScheduleShareDialog({
    super.key,
    required this.shareUrl,
    required this.onCopyShareUrl,
  });

  final String shareUrl;
  final VoidCallback onCopyShareUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
      title: Row(
        children: [
          Expanded(child: Text(l10n.shareUrlButton)),
          IconButton(
            tooltip: l10n.closeButton,
            onPressed: () => Navigator.pop(context),
            iconSize: 36,
            constraints: const BoxConstraints.tightFor(
              width: 56,
              height: 56,
            ),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.cancel_presentation),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ScheduleShareQrCode(data: shareUrl),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCopyShareUrl,
              icon: const Icon(Icons.copy),
              label: Text(l10n.copyUrlButton),
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleShareQrCode extends StatefulWidget {
  const ScheduleShareQrCode({
    super.key,
    required this.data,
  });

  final String data;

  @override
  State<ScheduleShareQrCode> createState() => _ScheduleShareQrCodeState();
}

class _ScheduleShareQrCodeState extends State<ScheduleShareQrCode> {
  late QrImage _qrImage;

  @override
  void initState() {
    super.initState();
    _qrImage = _buildQrImage(widget.data);
  }

  @override
  void didUpdateWidget(ScheduleShareQrCode oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.data != widget.data) {
      _qrImage = _buildQrImage(widget.data);
    }
  }

  QrImage _buildQrImage(String data) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.H,
    );

    return QrImage(qrCode);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: PrettyQrView(
        qrImage: _qrImage,
        decoration: const PrettyQrDecoration(
          quietZone: PrettyQrQuietZone.standard,
        ),
      ),
    );
  }
}
