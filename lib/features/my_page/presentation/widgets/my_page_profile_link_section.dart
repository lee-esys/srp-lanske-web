import 'dart:async';

import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import '../../../external_identity/application/tennisbear_profile_link_service.dart';
import '../../../external_identity/domain/external_identity_link_request.dart';
import 'my_page_section_card.dart';

typedef MyPageProfileLinkLoader = Future<TennisBearProfileLinkSnapshot> Function(
  String lanskeUserId,
);

class MyPageProfileLinkSection extends StatefulWidget {
  const MyPageProfileLinkSection({
    super.key,
    required this.lanskeUserId,
    required this.onOpenManagement,
    required this.loadProfileLink,
    this.now,
  });

  final String lanskeUserId;
  final VoidCallback onOpenManagement;
  final MyPageProfileLinkLoader loadProfileLink;
  final DateTime Function()? now;

  @override
  State<MyPageProfileLinkSection> createState() =>
      _MyPageProfileLinkSectionState();
}

class _MyPageProfileLinkSectionState extends State<MyPageProfileLinkSection> {
  bool _loading = true;
  Object? _loadError;
  TennisBearProfileLinkSnapshot? _snapshot;
  int _loadSequence = 0;
  bool _initialLoadStarted = false;

  DateTime get _now => (widget.now?.call() ?? DateTime.now()).toUtc();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialLoadStarted) return;
    _initialLoadStarted = true;
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant MyPageProfileLinkSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lanskeUserId != widget.lanskeUserId ||
        oldWidget.loadProfileLink != widget.loadProfileLink) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final sequence = ++_loadSequence;
    final requestedUid = widget.lanskeUserId;
    final loader = widget.loadProfileLink;

    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
      final snapshot = await loader(requestedUid);
      if (!mounted ||
          sequence != _loadSequence ||
          requestedUid != widget.lanskeUserId) {
        return;
      }

      setState(() {
        _snapshot = snapshot;
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted ||
          sequence != _loadSequence ||
          requestedUid != widget.lanskeUserId) {
        return;
      }

      setState(() {
        _snapshot = null;
        _loading = false;
        _loadError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return MyPageSectionCard(
      icon: Icons.link_outlined,
      title: l10n.myPageProfileLinkTitle,
      subtitle: l10n.tennisBearProfileLinkSubtitle,
      trailing: IconButton(
        tooltip: l10n.myPageProfileLinkRefreshTooltip,
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh),
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Text(l10n.myPageProfileLinkLoadingMessage),
        ],
      );
    }

    if (_loadError != null) {
      final colorScheme = Theme.of(context).colorScheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.myPageProfileLinkLoadErrorTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.myPageProfileLinkLoadErrorBody),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.myPageRetryButton),
              ),
              FilledButton.tonalIcon(
                onPressed: widget.onOpenManagement,
                icon: const Icon(Icons.manage_accounts_outlined),
                label: Text(l10n.myPageProfileLinkManageButton),
              ),
            ],
          ),
        ],
      );
    }

    final status = _statusOf(_snapshot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                l10n.tennisBearProfileLinkTitleSource,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Chip(
              avatar: Icon(status.icon, size: 18),
              label: Text(status.label(l10n)),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: widget.onOpenManagement,
            icon: const Icon(Icons.manage_accounts_outlined),
            label: Text(l10n.myPageProfileLinkManageButton),
          ),
        ),
      ],
    );
  }

  _MyPageProfileLinkStatus _statusOf(
    TennisBearProfileLinkSnapshot? snapshot,
  ) {
    if (snapshot?.activeMapping != null) {
      return _MyPageProfileLinkStatus.linked;
    }

    final activeRequest = snapshot?.activeRequest;
    if (activeRequest != null) {
      return activeRequest.isConfirmationCodeExpired(_now)
          ? _MyPageProfileLinkStatus.expired
          : _MyPageProfileLinkStatus.pending;
    }

    final latestRequest = snapshot?.latestRequest;
    if (latestRequest == null) {
      return _MyPageProfileLinkStatus.notLinked;
    }
    if (latestRequest.unlinkedAt != null) {
      return _MyPageProfileLinkStatus.retryable;
    }

    return switch (latestRequest.state) {
      ExternalIdentityLinkRequestState.rejected ||
      ExternalIdentityLinkRequestState.canceled ||
      ExternalIdentityLinkRequestState.expired ||
      ExternalIdentityLinkRequestState.superseded =>
        _MyPageProfileLinkStatus.retryable,
      ExternalIdentityLinkRequestState.pending =>
        latestRequest.isConfirmationCodeExpired(_now)
            ? _MyPageProfileLinkStatus.expired
            : _MyPageProfileLinkStatus.pending,
      ExternalIdentityLinkRequestState.approved =>
        _MyPageProfileLinkStatus.notLinked,
    };
  }
}

enum _MyPageProfileLinkStatus {
  notLinked(Icons.link_outlined),
  pending(Icons.hourglass_top),
  expired(Icons.schedule_outlined),
  retryable(Icons.refresh),
  linked(Icons.verified_outlined);

  const _MyPageProfileLinkStatus(this.icon);

  final IconData icon;

  String label(AppLocalizations l10n) {
    return switch (this) {
      _MyPageProfileLinkStatus.notLinked =>
        l10n.tennisBearProfileLinkNotLinkedStatus,
      _MyPageProfileLinkStatus.pending =>
        l10n.tennisBearProfileLinkPendingStatus,
      _MyPageProfileLinkStatus.expired =>
        l10n.tennisBearProfileLinkExpiredStatus,
      _MyPageProfileLinkStatus.retryable =>
        l10n.tennisBearProfileLinkRetryStatus,
      _MyPageProfileLinkStatus.linked =>
        l10n.tennisBearProfileLinkLinkedStatus,
    };
  }
}
