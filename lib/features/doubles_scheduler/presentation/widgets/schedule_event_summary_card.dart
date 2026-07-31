import 'package:flutter/material.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_progress_ui_store.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/presentation/app_message_type.dart';
import 'package:srp_lanske/shared/presentation/app_snack_bar.dart';
import 'package:srp_lanske/shared/repositories/app_repositories.dart';

import '../../domain/saved_event_models.dart';
import 'doubles_event_info_dialog.dart';

class ScheduleEventSummaryCard extends StatefulWidget {
  const ScheduleEventSummaryCard({
    super.key,
    this.aggregate,
    this.onShareUrl,
    this.onRefresh,
    this.onRefreshForEdit,
    this.canRefresh = true,
    this.isRefreshing = false,
    this.progressText,
  });

  final SavedEventAggregate? aggregate;
  final VoidCallback? onShareUrl;
  final Future<void> Function()? onRefresh;
  final Future<bool> Function()? onRefreshForEdit;
  final bool canRefresh;
  final bool isRefreshing;
  final String? progressText;

  @override
  State<ScheduleEventSummaryCard> createState() =>
      _ScheduleEventSummaryCardState();
}

class _ScheduleEventSummaryCardState extends State<ScheduleEventSummaryCard> {
  SavedEventAggregate? _loadedAggregate;
  bool _isEditingEventInfo = false;

  SavedEventAggregate? get _displayAggregate {
    return widget.aggregate ?? _loadedAggregate;
  }

  @override
  void initState() {
    super.initState();
    _loadedAggregate = widget.aggregate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadLatestAggregate();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ScheduleEventSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.aggregate != null && widget.aggregate != oldWidget.aggregate) {
      _loadedAggregate = widget.aggregate;
    }
  }

  String? _resolvePublicId() {
    final aggregatePublicId = _displayAggregate?.event.publicId.trim();
    if (aggregatePublicId != null && aggregatePublicId.isNotEmpty) {
      return aggregatePublicId;
    }

    final urlPublicId = Uri.base.queryParameters['sid']?.trim().toUpperCase();
    if (urlPublicId == null || urlPublicId.isEmpty) return null;
    return urlPublicId;
  }

  Future<SavedEventAggregate?> _loadLatestAggregate() async {
    final publicId = _resolvePublicId();
    if (publicId == null) return null;

    final latest = await appEventRepository.findByPublicId(publicId);
    if (!mounted) return latest;

    if (latest != null) {
      setState(() {
        _loadedAggregate = latest;
      });
    }
    return latest;
  }

  Future<bool> _refreshParentForEdit() async {
    final refreshForEdit = widget.onRefreshForEdit;
    if (refreshForEdit != null) {
      return refreshForEdit();
    }

    final refresh = widget.onRefresh;
    if (refresh != null) {
      await refresh();
    }
    return true;
  }

  Future<void> _editEventInfo() async {
    if (_isEditingEventInfo) return;

    final l10n = AppLocalizations.of(context);
    var dialogOpened = false;

    setState(() {
      _isEditingEventInfo = true;
    });

    try {
      final refreshed = await _refreshParentForEdit();
      if (!mounted || !refreshed) return;

      final latest = await _loadLatestAggregate();
      if (!mounted) return;

      if (latest == null) {
        AppSnackBar.show(
          context,
          message: l10n.doublesEventInfoLatestLoadFailedMessage,
          type: AppMessageType.error,
        );
        return;
      }

      dialogOpened = true;
      final updated = await showDialog<SavedEventAggregate>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return DoublesEventInfoDialog(
            initialAggregate: latest,
            repository: appEventRepository,
          );
        },
      );

      if (!mounted || updated == null) return;

      setState(() {
        _loadedAggregate = updated;
      });
      AppSnackBar.show(
        context,
        message: l10n.doublesEventInfoSavedMessage,
        type: AppMessageType.success,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: l10n.doublesEventInfoSaveFailedMessage(error.toString()),
        type: AppMessageType.error,
      );
    } finally {
      if (mounted && dialogOpened) {
        await _refreshParentForEdit();
        await _loadLatestAggregate();
      }
      if (mounted) {
        setState(() {
          _isEditingEventInfo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final event = _displayAggregate?.event;
    final canEdit = event != null &&
        !_isEditingEventInfo &&
        !widget.isRefreshing &&
        (widget.onRefreshForEdit != null || widget.onRefresh != null);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: canEdit ? _editEventInfo : null,
                    icon: _isEditingEventInfo
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.edit),
                    label: Text(l10n.editDoublesEventInfoButton),
                  ),
                ],
              ),
              if (event.memo.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  event.memo,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.onShareUrl != null)
                  OutlinedButton.icon(
                    onPressed: widget.onShareUrl,
                    icon: const Icon(Icons.share),
                    label: Text(l10n.shareUrlButton),
                  ),
                if (widget.onRefresh != null)
                  FilledButton.tonalIcon(
                    onPressed: widget.canRefresh &&
                            !widget.isRefreshing &&
                            !_isEditingEventInfo
                        ? widget.onRefresh
                        : null,
                    icon: widget.isRefreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: Text(l10n.refreshLatestButton),
                  ),
                ValueListenableBuilder<String?>(
                  valueListenable: DoublesProgressUiStore.progressText,
                  builder: (context, latestProgressText, child) {
                    final displayProgressText =
                        latestProgressText ?? widget.progressText;
                    if (displayProgressText == null) {
                      return const SizedBox.shrink();
                    }

                    return Chip(
                      avatar: const Icon(Icons.sports_score, size: 18),
                      label: Text(displayProgressText),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.shareUrlDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
