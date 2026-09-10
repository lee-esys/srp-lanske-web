import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      _message = '連携申請を作成しました。確認コードをテニスベア個人チャットから送信してください。';
      _messageIsError = false;
    });
  }

  Future<void> _reissue() async {
    if (_busy) return;
    final confirmed = await _confirm(
      title: '確認コードを再発行しますか？',
      body: '現在の確認コードは無効になります。新しいコードを発行したあと、テニスベア個人チャットから送信してください。',
      actionLabel: '再発行する',
    );
    if (!confirmed || !mounted) return;

    await _runAction(() async {
      final issued = await ExternalIdentityLinkScope.of(context)
          .reissue(widget.lanskeUserId);
      _confirmationCode = issued.confirmationCode;
      _snapshot = await ExternalIdentityLinkScope.of(context)
          .load(widget.lanskeUserId);
      _message = '新しい確認コードを発行しました。旧コードは無効です。';
      _messageIsError = false;
    });
  }

  Future<void> _cancelRequest() async {
    if (_busy) return;
    final confirmed = await _confirm(
      title: '申請を取り消しますか？',
      body: '現在の連携申請と確認コードを無効にします。必要になった場合は、プロフィールURLの入力から改めて申請できます。',
      actionLabel: '申請を取り消す',
    );
    if (!confirmed || !mounted) return;

    await _runAction(() async {
      await ExternalIdentityLinkScope.of(context).cancel(widget.lanskeUserId);
      _confirmationCode = null;
      _snapshot = await ExternalIdentityLinkScope.of(context)
          .load(widget.lanskeUserId);
      _message = '連携申請を取り消しました。';
      _messageIsError = false;
    });
  }

  Future<void> _unlink() async {
    if (_busy) return;
    final mapping = _snapshot?.activeMapping;
    if (mapping == null) return;

    final confirmed = await _confirm(
      title: 'テニスベアプロフィール連携を解除しますか？',
      body: '${mapping.identity.profileUrl}\n\n連携を解除しても、過去のイベント・参加者・試合結果などの元データは削除されません。再連携する場合は、新しい確認コードによる確認が必要です。',
      actionLabel: '連携を解除する',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    await _runAction(() async {
      await ExternalIdentityLinkScope.of(context).unlink(widget.lanskeUserId);
      _confirmationCode = null;
      _profileUrlController.text = mapping.identity.profileUrl;
      _snapshot = await ExternalIdentityLinkScope.of(context)
          .load(widget.lanskeUserId);
      _message = 'テニスベアプロフィール連携を解除しました。必要な場合は改めて申請できます。';
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
      setState(() {
        _message = _messageForError(error);
        _messageIsError = true;
      });
      if (error is ExternalIdentityLinkException &&
          (error.code == ExternalIdentityLinkFailureCode.requestAlreadyExists ||
              error.code == ExternalIdentityLinkFailureCode.invalidState ||
              error.code == ExternalIdentityLinkFailureCode.requestNotFound)) {
        await _load();
      }
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
              child: const Text('キャンセル'),
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
      const SnackBar(content: Text('確認コードをコピーしました。')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                    'テニスベアプロフィール連携',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: '最新の状態に更新',
                  onPressed: _busy || _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Lanskeアカウントと、ご自身のテニスベア公開プロフィールを対応付ける補助機能です。',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusRow(
          icon: Icons.verified_outlined,
          label: '承認済み',
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
            label: const Text('テニスベアでプロフィールを開く'),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'プロフィール連携だけを理由に、イベントや対戦表全体の閲覧権が付与されることはありません。',
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _busy ? null : _unlink,
          icon: const Icon(Icons.link_off),
          label: const Text('プロフィール連携を解除'),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusRow(
          icon: expired ? Icons.schedule_outlined : Icons.hourglass_top,
          label: expired ? '確認コードの期限切れ' : '申請中',
          color: expired ? colorScheme.error : colorScheme.primary,
        ),
        const SizedBox(height: 12),
        SelectableText(request.identity.profileUrl),
        const SizedBox(height: 16),
        if (_confirmationCode != null) ...[
          Text(
            '確認コード',
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
                  tooltip: '確認コードをコピー',
                  onPressed: _copyCode,
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
          ),
        ] else if (!expired) ...[
          _InlineMessage(
            message: '確認コードは安全のため保存していません。この画面を再読み込みした場合、同じコードは再表示できません。必要なら新しいコードを再発行してください。',
            isError: false,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          expired
              ? '確認コードのシステム上の有効期限（7日間）が過ぎています。再発行すると新しいコードで確認をやり直せます。'
              : '発行後1時間以内を目安に、確認コードをテニスベア個人チャットからLanske管理者へ送信してください。システム上の有効期限は7日間です。送信後は2営業日以内を目安に確認します。',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _reissue,
          icon: const Icon(Icons.refresh),
          label: Text(expired ? '確認コードを再発行' : '新しい確認コードを再発行'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : _cancelRequest,
          child: const Text('申請を取り消す'),
        ),
      ],
    );
  }

  Widget _buildRequestForm(BuildContext context) {
    final latest = _snapshot?.latestRequest;
    final retryReason = _retryReason(latest);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusRow(
            icon: Icons.link_outlined,
            label: retryReason == null ? '未連携' : '再申請できます',
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
            decoration: const InputDecoration(
              labelText: 'テニスベア公開プロフィールURL',
              hintText: 'https://www.tennisbear.net/user/899212/info',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final raw = value?.trim() ?? '';
              if (raw.isEmpty) {
                return 'プロフィールURLを入力してください。';
              }
              try {
                _parser.parse(raw);
                return null;
              } on FormatException {
                return 'テニスベアの公開プロフィールURLを入力してください。';
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
            label: const Text('このプロフィールで連携を申請'),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskNotice(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const items = [
      'TennisBear公式のアカウント連携・本人確認機能ではなく、Lanske独自の補助機能です。',
      '誤ったプロフィールを連携すると、将来そのプロフィールに紐づく本人向け履歴・統計が自分の情報として表示される可能性があります。',
      'プロフィール連携だけでは、イベントや対戦表全体の閲覧権は付与されません。',
      '連携を解除しても、過去のイベント・試合結果などの元データは削除されません。',
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
            '申請前に確認してください',
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
                  const Text('・'),
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
    if (request.unlinkedAt != null) {
      return '以前のプロフィール連携は解除されています。再連携する場合は、新しい確認コードで改めて申請してください。';
    }
    return switch (request.state) {
      ExternalIdentityLinkRequestState.rejected =>
        '以前の申請は承認されませんでした。内容を確認して改めて申請できます。',
      ExternalIdentityLinkRequestState.canceled =>
        '以前の申請は取り消されています。改めて申請できます。',
      ExternalIdentityLinkRequestState.expired =>
        '以前の申請は期限切れです。改めて申請できます。',
      _ => null,
    };
  }

  String _messageForError(Object error) {
    if (error is FormatException) {
      return 'テニスベアの公開プロフィールURLの形式を確認してください。';
    }
    if (error is ExternalIdentityLinkException) {
      return switch (error.code) {
        ExternalIdentityLinkFailureCode.userNotFound =>
          'Lanskeアカウント情報を確認できませんでした。アカウント情報を再確認してからお試しください。',
        ExternalIdentityLinkFailureCode.requestAlreadyExists =>
          '申請状態が更新されています。最新の状態を確認してください。',
        ExternalIdentityLinkFailureCode.requestNotFound ||
        ExternalIdentityLinkFailureCode.invalidState =>
          '申請状態が変更されています。最新の状態を確認してからもう一度お試しください。',
        ExternalIdentityLinkFailureCode.confirmationCodeExpired =>
          '確認コードの有効期限が切れています。新しいコードを再発行してください。',
        ExternalIdentityLinkFailureCode.identityAlreadyLinked ||
        ExternalIdentityLinkFailureCode.sourceAlreadyLinked ||
        ExternalIdentityLinkFailureCode.conflict =>
          'このテニスベアプロフィールとは連携できません。不明点がある場合はお問い合わせください。',
        _ => 'プロフィール連携の処理に失敗しました。通信状態を確認して、もう一度お試しください。',
      };
    }
    return 'プロフィール連携の処理に失敗しました。通信状態を確認して、もう一度お試しください。';
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
