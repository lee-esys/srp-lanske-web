import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/utils/external_link.dart';
import '../application/external_identity_link_exception.dart';
import '../application/external_identity_link_service.dart';
import '../application/tennisbear_profile_link_service.dart';
import '../domain/external_identity_link_request.dart';
import '../domain/tennisbear_profile_url_parser.dart';
import 'external_identity_link_scope.dart';

class TennisBearProfileLinkCard extends StatefulWidget {
  const TennisBearProfileLinkCard({
    super.key,
    required this.lanskeUserId,
  });

  final String lanskeUserId;

  @override
  State<TennisBearProfileLinkCard> createState() =>
      _TennisBearProfileLinkCardState();
}

class _TennisBearProfileLinkCardState extends State<TennisBearProfileLinkCard> {
  static const _parser = TennisBearProfileUrlParser();

  final _formKey = GlobalKey<FormState>();
  final _profileUrlController = TextEditingController();

  TennisBearProfileLinkSnapshot? _snapshot;
  String? _confirmationCode;
  bool _loading = true;
  bool _busy = false;
  String? _message;
  bool _messageIsError = false;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_load());
      }
    });
  }

  @override
  void didUpdateWidget(TennisBearProfileLinkCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lanskeUserId != widget.lanskeUserId) {
      _confirmationCode = null;
      _profileUrlController.clear();
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _profileUrlController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      final snapshot = await ExternalIdentityLinkScope.of(context)
          .load(widget.lanskeUserId);
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = _messageForError(error);
        _messageIsError = true;
      });
    }
  }

  Future<void> _createRequest() async {
    if (!(_formKey.currentState?.validate() ?? false) || _busy) return;

    await _runAction(() async {
      final issued = await ExternalIdentityLinkScope.of(context).createRequest(
        lanskeUserId: widget.lanskeUserId,
        profileUrl: _profileUrlController.text.trim(),
      );
      _confirmationCode = issued.confirmationCode;
      _profileUrlController.text = issued.request.identity.profileUrl;
      _snapshot = await ExternalIdentityLinkScope.of(context)
          .load(widget.lanskeUserId);
      _message = _l10n.tennisBearProfileLinkCreateSuccess;
      _messageIsError = false;
    });
  }

  Future<void> _reissue() async {
    if (_busy) return;
    final l10n = _l10n;
    final confirmed = await _confirm(
      title: l10n.tennisBearProfileLinkReissueDialogTitle,
      body: l10n.tennisBearProfileLinkReissueDialogBody,
      actionLabel: l10n.tennisBearProfileLinkReissueDialogAction,
    );
    if (!confirmed || !mounted) return;

    await _runAction(() async {
      final issued = await ExternalIdentityLinkScope.of(context)
          .reissue(widget.lanskeUserId);
      _confirmationCode = issued.confirmationCode;
      _snapshot = await ExternalIdentityLinkScope.of(context)
          .load(widget.lanskeUserId);
      _message = _l10n.tennisBearProfileLinkReissueSuccess;
      _messageIsError = false;
    });
  }

  Future<void> _cancelRequest() async {
    if (_busy) return;
    final l10n = _l10n;
    final confirmed = await _confirm(
      title: l10n.tennisBearProfileLinkCancelDialogTitle,
      body: l10n.tennisBearProfileLinkCancelDialogBody,
      actionLabel: l10n.tennisBearProfileLinkCancelDialogAction,
    );
    if (!confirmed || !mounted) return;

    await _runAction(() async {
      await ExternalIdentityLinkScope.of(context).cancel(widget.lanskeUserId);
      _confirmationCode = null;
      _snapshot = await ExternalIdentityLinkScope.of(context)
          .load(widget.lanskeUserId);
      _message = _l10n.tennisBearProfileLinkCancelSuccess;
      _messageIsError = false;
    });
  }

  Future<void> _unlink() async {
    if (_busy) return;
    final mapping = _snapshot?.activeMapping;
    if (mapping == null) return;

    final l10n = _l10n;
    final confirmed = await _confirm(
      title: l10n.tennisBearProfileLinkUnlinkDialogTitle,
      body:
          '${mapping.identity.profileUrl}\n\n${l10n.tennisBearProfileLinkUnlinkDialogBody}',
      actionLabel: l10n.tennisBearProfileLinkUnlinkDialogAction,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    await _runAction(() async {
      await ExternalIdentityLinkScope.of(context).unlink(widget.lanskeUserId);
      _confirmationCode = null;
      _profileUrlController.text = mapping.identity.profileUrl;
      _snapshot = await ExternalIdentityLinkScope.of(context)
          .load(widget.lanskeUserId);
      _message = _l10n.tennisBearProfileLinkUnlinkSuccess;
      _messageIsError = false;
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      final message = _messageForError(error);
      TennisBearProfileLinkSnapshot? refreshedSnapshot;
      if (error is ExternalIdentityLinkException &&
          (error.code == ExternalIdentityLinkFailureCode.requestAlreadyExists ||
              error.code == ExternalIdentityLinkFailureCode.invalidState ||
              error.code == ExternalIdentityLinkFailureCode.requestNotFound)) {
        try {
          refreshedSnapshot = await ExternalIdentityLinkScope.of(context)
              .load(widget.lanskeUserId);
        } catch (_) {
          // Keep the original action error. Refresh is best effort only.
        }
      }
      if (!mounted) return;
      setState(() {
        if (refreshedSnapshot != null) {
          _snapshot = refreshedSnapshot;
        }
        _message = message;
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String actionLabel,
    bool destructive = false,
  }) async {
    final l10n = _l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelButton),
            ),
            destructive
                ? FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(actionLabel),
                  )
                : FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(actionLabel),
                  ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _copyCode() async {
    final code = _confirmationCode;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_l10n.tennisBearProfileLinkCodeCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = _l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.sports_tennis, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.tennisBearProfileLinkTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.tennisBearProfileLinkRefreshTooltip,
                  onPressed: _busy || _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tennisBearProfileLinkSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              _InlineMessage(
                message: _message!,
                isError: _messageIsError,
              ),
            ],
            const SizedBox(height: 20),
            if (_loading)
              const LinearProgressIndicator()
            else if (_snapshot?.activeMapping != null)
              _buildLinked(context)
            else if (_snapshot?.activeRequest != null)
              _buildPending(context, _snapshot!.activeRequest!)
            else
              _buildRequestForm(context),
            if (_busy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLinked(BuildContext context) {
    final mapping = _snapshot!.activeMapping!;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = _l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusRow(
          icon: Icons.verified_outlined,
          label: l10n.tennisBearProfileLinkLinkedStatus,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 12),
        SelectableText(mapping.identity.profileUrl),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => openExternalUrl(mapping.identity.profileUrl),
            icon: const Icon(Icons.open_in_new),
            label: Text(l10n.tennisBearProfileLinkOpenProfileButton),
          ),
        ),
        const SizedBox(height: 12),
        Text(l10n.tennisBearProfileLinkPermissionNotice),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _busy ? null : _unlink,
          icon: const Icon(Icons.link_off),
          label: Text(l10n.tennisBearProfileLinkUnlinkButton),
        ),
      ],
    );
  }

  Widget _buildPending(
    BuildContext context,
    ExternalIdentityLinkRequest request,
  ) {
    final expired = request.isConfirmationCodeExpired(DateTime.now().toUtc());
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = _l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusRow(
          icon: expired ? Icons.schedule_outlined : Icons.hourglass_top,
          label: expired
              ? l10n.tennisBearProfileLinkExpiredStatus
              : l10n.tennisBearProfileLinkPendingStatus,
          color: expired ? colorScheme.error : colorScheme.primary,
        ),
        const SizedBox(height: 12),
        SelectableText(request.identity.profileUrl),
        const SizedBox(height: 16),
        if (_confirmationCode != null) ...[
          Text(
            l10n.tennisBearProfileLinkConfirmationCodeLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    _confirmationCode!,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.tennisBearProfileLinkCopyCodeTooltip,
                  onPressed: _copyCode,
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
          ),
        ] else if (!expired) ...[
          _InlineMessage(
            message: l10n.tennisBearProfileLinkCodeNotRestoredMessage,
            isError: false,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          expired
              ? l10n.tennisBearProfileLinkExpiredMessage
              : l10n.tennisBearProfileLinkPendingInstruction,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _reissue,
          icon: const Icon(Icons.refresh),
          label: Text(
            expired
                ? l10n.tennisBearProfileLinkReissueExpiredButton
                : l10n.tennisBearProfileLinkReissueButton,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : _cancelRequest,
          child: Text(l10n.tennisBearProfileLinkCancelRequestButton),
        ),
      ],
    );
  }

  Widget _buildRequestForm(BuildContext context) {
    final latest = _snapshot?.latestRequest;
    final retryReason = _retryReason(latest);
    final l10n = _l10n;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusRow(
            icon: Icons.link_outlined,
            label: retryReason == null
                ? l10n.tennisBearProfileLinkNotLinkedStatus
                : l10n.tennisBearProfileLinkRetryStatus,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          if (retryReason != null) ...[
            const SizedBox(height: 8),
            Text(retryReason),
          ],
          const SizedBox(height: 20),
          TextFormField(
            controller: _profileUrlController,
            enabled: !_busy,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: l10n.tennisBearProfileLinkProfileUrlLabel,
              hintText: 'https://www.tennisbear.net/user/899212/info',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              final raw = value?.trim() ?? '';
              if (raw.isEmpty) {
                return l10n.tennisBearProfileLinkProfileUrlEmptyError;
              }
              try {
                _parser.parse(raw);
                return null;
              } on FormatException {
                return l10n.tennisBearProfileLinkProfileUrlInvalidError;
              }
            },
            onFieldSubmitted: (_) {
              if (!_busy) unawaited(_createRequest());
            },
          ),
          const SizedBox(height: 16),
          _buildRiskNotice(context),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _createRequest,
            icon: const Icon(Icons.link),
            label: Text(l10n.tennisBearProfileLinkSubmitButton),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskNotice(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = _l10n;
    final items = [
      l10n.tennisBearProfileLinkRiskOfficial,
      l10n.tennisBearProfileLinkRiskWrongProfile,
      l10n.tennisBearProfileLinkRiskPermission,
      l10n.tennisBearProfileLinkRiskUnlinkData,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tennisBearProfileLinkRiskTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String? _retryReason(ExternalIdentityLinkRequest? request) {
    if (request == null) return null;
    final l10n = _l10n;
    if (request.unlinkedAt != null) {
      return l10n.tennisBearProfileLinkRetryUnlinked;
    }
    return switch (request.state) {
      ExternalIdentityLinkRequestState.rejected =>
        l10n.tennisBearProfileLinkRetryRejected,
      ExternalIdentityLinkRequestState.canceled =>
        l10n.tennisBearProfileLinkRetryCanceled,
      ExternalIdentityLinkRequestState.expired =>
        l10n.tennisBearProfileLinkRetryExpired,
      _ => null,
    };
  }

  String _messageForError(Object error) {
    final l10n = _l10n;
    if (error is FormatException) {
      return l10n.tennisBearProfileLinkInvalidUrlMessage;
    }
    if (error is ExternalIdentityLinkException) {
      return switch (error.code) {
        ExternalIdentityLinkFailureCode.userNotFound =>
          l10n.tennisBearProfileLinkUserNotFoundMessage,
        ExternalIdentityLinkFailureCode.requestAlreadyExists =>
          l10n.tennisBearProfileLinkRequestUpdatedMessage,
        ExternalIdentityLinkFailureCode.requestNotFound ||
        ExternalIdentityLinkFailureCode.invalidState =>
          l10n.tennisBearProfileLinkRequestChangedMessage,
        ExternalIdentityLinkFailureCode.confirmationCodeExpired =>
          l10n.tennisBearProfileLinkCodeExpiredMessage,
        ExternalIdentityLinkFailureCode.identityAlreadyLinked ||
        ExternalIdentityLinkFailureCode.sourceAlreadyLinked ||
        ExternalIdentityLinkFailureCode.conflict =>
          l10n.tennisBearProfileLinkGenericConflictMessage,
        _ => l10n.tennisBearProfileLinkGenericFailureMessage,
      };
    }
    return l10n.tennisBearProfileLinkGenericFailureMessage;
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background =
        isError ? colorScheme.errorContainer : colorScheme.primaryContainer;
    final foreground =
        isError ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: foreground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
