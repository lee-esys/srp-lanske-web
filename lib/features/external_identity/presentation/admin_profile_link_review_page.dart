import 'dart:async';

import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import '../../../shared/utils/external_link.dart';
import '../application/external_identity_link_exception.dart';
import '../application/tennisbear_admin_profile_link_review_service.dart';
import '../domain/external_identity_link_request.dart';
import 'external_identity_admin_review_scope.dart';

class AdminProfileLinkReviewPage extends StatefulWidget {
  const AdminProfileLinkReviewPage({super.key});

  @override
  State<AdminProfileLinkReviewPage> createState() =>
      _AdminProfileLinkReviewPageState();
}

class _AdminProfileLinkReviewPageState
    extends State<AdminProfileLinkReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _confirmationCodeController = TextEditingController();

  bool _checkingAccess = true;
  bool _canReview = false;
  bool _busy = false;
  ExternalIdentityLinkRequest? _request;
  String? _message;
  bool _messageIsError = false;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_checkAccess());
      }
    });
  }

  @override
  void dispose() {
    _confirmationCodeController.dispose();
    super.dispose();
  }

  Future<void> _checkAccess() async {
    try {
      final canReview =
          await ExternalIdentityAdminReviewScope.of(context).canReview();
      if (!mounted) return;
      setState(() {
        _checkingAccess = false;
        _canReview = canReview;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checkingAccess = false;
        _canReview = false;
      });
    }
  }

  Future<void> _search() async {
    if (!(_formKey.currentState?.validate() ?? false) || _busy) return;

    setState(() {
      _busy = true;
      _request = null;
      _message = null;
      _messageIsError = false;
    });

    try {
      final request = await ExternalIdentityAdminReviewScope.of(context)
          .findReviewableRequest(_confirmationCodeController.text);
      if (!mounted) return;
      setState(() {
        _request = request;
        if (request == null) {
          _message = _l10n.adminProfileLinkReviewNotFoundMessage;
          _messageIsError = true;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _request = null;
        _message = _messageForError(error);
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

  Future<void> _approve() async {
    final request = _request;
    if (request == null ||
        _busy ||
        !ExternalIdentityAdminReviewScope.of(context).canDecide(request)) {
      return;
    }
    final confirmed = await _confirm(
      title: _l10n.adminProfileLinkReviewApproveDialogTitle,
      body: _l10n.adminProfileLinkReviewApproveDialogBody,
      actionLabel: _l10n.adminProfileLinkReviewApproveDialogAction,
    );
    if (!confirmed || !mounted) return;

    await _runDecision(
      action: () async {
        await ExternalIdentityAdminReviewScope.of(context)
            .approve(_confirmationCodeController.text);
      },
      successMessage: _l10n.adminProfileLinkReviewApproveSuccess,
    );
  }

  Future<void> _reject() async {
    final request = _request;
    if (request == null ||
        _busy ||
        !ExternalIdentityAdminReviewScope.of(context).canDecide(request)) {
      return;
    }
    final confirmed = await _confirm(
      title: _l10n.adminProfileLinkReviewRejectDialogTitle,
      body: _l10n.adminProfileLinkReviewRejectDialogBody,
      actionLabel: _l10n.adminProfileLinkReviewRejectDialogAction,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    await _runDecision(
      action: () => ExternalIdentityAdminReviewScope.of(context)
          .reject(_confirmationCodeController.text),
      successMessage: _l10n.adminProfileLinkReviewRejectSuccess,
    );
  }

  Future<void> _runDecision({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    setState(() {
      _busy = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      await action();
      if (!mounted) return;
      setState(() {
        _request = null;
        _confirmationCodeController.clear();
        _message = successMessage;
        _messageIsError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _request = null;
        _message = _messageForError(error);
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
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(_l10n.cancelButton),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    )
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  String _messageForError(Object error) {
    if (error is TennisBearAdminProfileLinkReviewException) {
      return _l10n.adminProfileLinkReviewAccessDeniedMessage;
    }
    if (error is ExternalIdentityLinkException) {
      return switch (error.code) {
        ExternalIdentityLinkFailureCode.requestNotFound ||
        ExternalIdentityLinkFailureCode.confirmationCodeNotFound ||
        ExternalIdentityLinkFailureCode.confirmationCodeExpired ||
        ExternalIdentityLinkFailureCode.invalidState ||
        ExternalIdentityLinkFailureCode.userNotFound ||
        ExternalIdentityLinkFailureCode.identityAlreadyLinked ||
        ExternalIdentityLinkFailureCode.sourceAlreadyLinked ||
        ExternalIdentityLinkFailureCode.conflict =>
          _l10n.adminProfileLinkReviewRequestChangedMessage,
        _ => _l10n.adminProfileLinkReviewGenericFailureMessage,
      };
    }
    return _l10n.adminProfileLinkReviewGenericFailureMessage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: _l10n.topPageMenu,
          onPressed: () => openUrlInCurrentTab('/'),
          icon: const Icon(Icons.home_outlined),
        ),
        title: Text(_l10n.adminProfileLinkReviewTitle),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_checkingAccess)
                  const LinearProgressIndicator()
                else if (!_canReview)
                  _buildAccessDenied(context)
                else
                  _buildReview(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, color: colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_l10n.adminProfileLinkReviewAccessDeniedMessage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview(BuildContext context) {
    final request = _request;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _l10n.adminProfileLinkReviewTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(_l10n.adminProfileLinkReviewSubtitle),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _confirmationCodeController,
                    enabled: !_busy,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: _l10n.adminProfileLinkReviewCodeLabel,
                      hintText: _l10n.adminProfileLinkReviewCodeHint,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return _l10n.adminProfileLinkReviewCodeRequiredMessage;
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      if (!_busy) unawaited(_search());
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : _search,
                    icon: const Icon(Icons.search),
                    label: Text(_l10n.adminProfileLinkReviewSearchButton),
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: 16),
          _InlineMessage(
            message: _message!,
            isError: _messageIsError,
          ),
        ],
        if (request != null) ...[
          const SizedBox(height: 16),
          _buildRequestCard(context, request),
        ],
      ],
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    ExternalIdentityLinkRequest request,
  ) {
    final reviewService = ExternalIdentityAdminReviewScope.of(context);
    final status = reviewService.statusOf(request);
    final canDecide = reviewService.canDecide(request);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailRow(
              label: _l10n.adminProfileLinkReviewSourceLabel,
              value: 'TennisBear',
            ),
            _DetailRow(
              label: _l10n.adminProfileLinkReviewSourceUserIdLabel,
              value: request.identity.sourceUserId,
            ),
            _DetailRow(
              label: _l10n.adminProfileLinkReviewStateLabel,
              value: _statusLabel(status),
            ),
            _DetailRow(
              label: _l10n.adminProfileLinkReviewCreatedAtLabel,
              value: _formatDateTime(request.createdAt),
            ),
            _DetailRow(
              label: _l10n.adminProfileLinkReviewExpiresAtLabel,
              value: _formatDateTime(request.confirmationCodeExpiresAt),
            ),
            const SizedBox(height: 8),
            Text(
              _l10n.adminProfileLinkReviewProfileUrlLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            SelectableText(request.identity.profileUrl),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => openExternalUrl(request.identity.profileUrl),
                icon: const Icon(Icons.open_in_new),
                label: Text(_l10n.adminProfileLinkReviewOpenProfileButton),
              ),
            ),
            const SizedBox(height: 12),
            if (canDecide) ...[
              Text(_l10n.adminProfileLinkReviewVerifyInstruction),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _busy ? null : _approve,
                icon: const Icon(Icons.check),
                label: Text(_l10n.adminProfileLinkReviewApproveButton),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: _busy ? null : _reject,
                icon: const Icon(Icons.close),
                label: Text(_l10n.adminProfileLinkReviewRejectButton),
              ),
            ] else
              Text(_statusNote(status)),
          ],
        ),
      ),
    );
  }

  String _statusLabel(TennisBearAdminProfileLinkReviewStatus status) {
    return switch (status) {
      TennisBearAdminProfileLinkReviewStatus.pending =>
        _l10n.adminProfileLinkReviewPendingState,
      TennisBearAdminProfileLinkReviewStatus.expired =>
        _l10n.adminProfileLinkReviewExpiredState,
      TennisBearAdminProfileLinkReviewStatus.approved =>
        _l10n.adminProfileLinkReviewApprovedState,
      TennisBearAdminProfileLinkReviewStatus.approvedUnlinked =>
        _l10n.adminProfileLinkReviewApprovedUnlinkedState,
      TennisBearAdminProfileLinkReviewStatus.rejected =>
        _l10n.adminProfileLinkReviewRejectedState,
      TennisBearAdminProfileLinkReviewStatus.canceled =>
        _l10n.adminProfileLinkReviewCanceledState,
      TennisBearAdminProfileLinkReviewStatus.superseded =>
        _l10n.adminProfileLinkReviewSupersededState,
    };
  }

  String _statusNote(TennisBearAdminProfileLinkReviewStatus status) {
    return switch (status) {
      TennisBearAdminProfileLinkReviewStatus.pending => '',
      TennisBearAdminProfileLinkReviewStatus.expired =>
        _l10n.adminProfileLinkReviewExpiredNote,
      TennisBearAdminProfileLinkReviewStatus.approved =>
        _l10n.adminProfileLinkReviewApprovedNote,
      TennisBearAdminProfileLinkReviewStatus.approvedUnlinked =>
        _l10n.adminProfileLinkReviewApprovedUnlinkedNote,
      TennisBearAdminProfileLinkReviewStatus.rejected =>
        _l10n.adminProfileLinkReviewRejectedNote,
      TennisBearAdminProfileLinkReviewStatus.canceled =>
        _l10n.adminProfileLinkReviewCanceledNote,
      TennisBearAdminProfileLinkReviewStatus.superseded =>
        _l10n.adminProfileLinkReviewSupersededNote,
    };
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${local.year}/${twoDigits(local.month)}/${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
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
