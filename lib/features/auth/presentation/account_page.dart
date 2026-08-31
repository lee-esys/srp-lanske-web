import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/utils/external_link.dart';
import '../application/account_auth_repository.dart';
import '../application/account_service.dart';
import '../domain/auth_session.dart';
import 'account_scope.dart';
import 'auth_scope.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _registerMode = false;
  bool _busy = false;
  String? _statusMessage;
  bool _statusIsError = false;
  String? _ensuredUid;
  String? _ensuringUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = AuthScope.of(context).session;
    final uid = session.uid;

    if (session.isAccount &&
        uid != null &&
        _ensuredUid != uid &&
        _ensuringUid != uid) {
      _ensuringUid = uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_ensureCurrentUser(uid));
        }
      });
      return;
    }

    if (!session.isAccount) {
      _ensuredUid = null;
      _ensuringUid = null;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _ensureCurrentUser(String uid) async {
    final service = AccountScope.of(context);
    try {
      await service.ensureCurrentUser();
      if (!mounted) return;
      if (AuthScope.of(context).session.uid != uid) return;
      setState(() {
        _ensuredUid = uid;
        _ensuringUid = null;
      });
    } catch (_) {
      if (!mounted) return;
      if (AuthScope.of(context).session.uid != uid) return;
      setState(() {
        _ensuringUid = null;
        _statusMessage =
            'Lanske アカウント情報を準備できませんでした。通信状態を確認して、もう一度お試しください。';
        _statusIsError = true;
      });
    }
  }

  Future<bool> _runAction(Future<void> Function() action) async {
    if (_busy) return false;

    setState(() {
      _busy = true;
      _statusMessage = null;
      _statusIsError = false;
    });

    try {
      await action();
      return true;
    } catch (error) {
      if (mounted) {
        setState(() {
          _statusMessage = _messageForError(error);
          _statusIsError = true;
        });
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _submitEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final service = AccountScope.of(context);

    await _runAction(() async {
      if (_registerMode) {
        await service.createAccountWithEmailPassword(
          email: email,
          password: password,
        );
      } else {
        await service.signInWithEmailPassword(
          email: email,
          password: password,
        );
      }
    });
  }

  Future<void> _signInWithGoogle() async {
    final service = AccountScope.of(context);
    await _runAction(() async {
      await service.signInWithGoogle();
    });
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    if (!_looksLikeEmail(email)) {
      setState(() {
        _statusMessage = 'パスワード再設定メールを送るメールアドレスを入力してください。';
        _statusIsError = true;
      });
      return;
    }

    final service = AccountScope.of(context);
    final succeeded = await _runAction(() async {
      await service.sendPasswordResetEmail(email);
    });
    if (succeeded && mounted) {
      setState(() {
        _statusMessage = 'パスワード再設定メールを送信しました。';
        _statusIsError = false;
      });
    }
  }

  Future<void> _signOut() async {
    final auth = AuthScope.of(context);
    await _runAction(auth.signOut);
  }

  void _retryEnsureUser() {
    final session = AuthScope.of(context).session;
    final uid = session.uid;
    if (!session.isAccount || uid == null || _ensuringUid == uid) return;

    setState(() {
      _statusMessage = null;
      _statusIsError = false;
      _ensuringUid = uid;
    });
    unawaited(_ensureCurrentUser(uid));
  }

  void _toggleRegisterMode() {
    if (_busy) return;
    setState(() {
      _registerMode = !_registerMode;
      _statusMessage = null;
      _statusIsError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthScope.of(context).session;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'TOPへ',
          onPressed: () => openUrlInCurrentTab('/'),
          icon: const Icon(Icons.home_outlined),
        ),
        title: const Text('アカウント'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_statusMessage != null) ...[
                  _StatusMessage(
                    message: _statusMessage!,
                    isError: _statusIsError,
                  ),
                  const SizedBox(height: 16),
                ],
                if (session.kind == AuthSessionKind.signedOut)
                  _buildSignedOut(context)
                else if (session.kind == AuthSessionKind.anonymous)
                  _buildAnonymous(context)
                else
                  _buildAccount(context, session),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignedOut(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _registerMode ? 'Lanske アカウントを作成' : 'Lanske にログイン',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ログインしなくても対戦表は利用できます。アカウントを使うと、今後マイページや本人履歴などを利用できるようになります。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _signInWithGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text('Google でログイン'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'または',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'メールアドレス',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (!_looksLikeEmail(value?.trim() ?? '')) {
                      return '有効なメールアドレスを入力してください。';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  enabled: !_busy,
                  obscureText: true,
                  autofillHints: _registerMode
                      ? const [AutofillHints.newPassword]
                      : const [AutofillHints.password],
                  decoration: const InputDecoration(
                    labelText: 'パスワード',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final password = value ?? '';
                    if (password.isEmpty) {
                      return 'パスワードを入力してください。';
                    }
                    if (_registerMode && password.length < 6) {
                      return 'パスワードは6文字以上で入力してください。';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (!_busy) unawaited(_submitEmail());
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _submitEmail,
                  child: Text(_registerMode ? 'アカウントを作成' : 'ログイン'),
                ),
                if (!_registerMode)
                  TextButton(
                    onPressed: _busy ? null : _sendPasswordResetEmail,
                    child: const Text('パスワードを忘れた場合'),
                  ),
                const Divider(height: 32),
                TextButton(
                  onPressed: _busy ? null : _toggleRegisterMode,
                  child: Text(
                    _registerMode
                        ? 'すでにアカウントをお持ちの方はこちら'
                        : '新しくアカウントを作成する',
                  ),
                ),
                if (_busy) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnonymous(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.person_outline,
              size: 40,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'ログインなしで利用中',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            const Text(
              'この端末にはログインなしで利用している識別情報があります。'
              '作成済みデータを安全に保持したままアカウントへ移行する機能を準備しているため、'
              '現在はこの状態からの登録・ログインを停止しています。',
            ),
            const SizedBox(height: 12),
            Text(
              '通常の対戦表利用はそのまま継続できます。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccount(BuildContext context, AuthSession session) {
    final colorScheme = Theme.of(context).colorScheme;
    final uid = session.uid;
    final userReady = uid != null && _ensuredUid == uid;
    final userLoading = uid != null && _ensuringUid == uid;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.displayName?.trim().isNotEmpty == true
                            ? session.displayName!.trim()
                            : 'Lanske アカウント',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (session.email?.trim().isNotEmpty == true)
                        Text(
                          session.email!.trim(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (userLoading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Lanske アカウント情報を確認しています…'),
            ] else if (userReady)
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Lanske アカウント情報を確認済みです。')),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _retryEnsureUser,
                icon: const Icon(Icons.refresh),
                label: const Text('アカウント情報を再確認'),
              ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _busy ? null : _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('ログアウト'),
            ),
            if (_busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  bool _looksLikeEmail(String value) {
    final at = value.indexOf('@');
    return at > 0 && at < value.length - 1 && value.contains('.', at);
  }

  String _messageForError(Object error) {
    if (error is AccountTransitionRequiredException) {
      return 'ログインなしで作成したデータを保持したまま移行する必要があります。引継ぎ機能の対応後に操作してください。';
    }
    if (error is AccountAlreadySignedInException) {
      return 'すでにLanskeアカウントへログインしています。';
    }
    if (error is AccountAuthException) {
      return switch (error.code) {
        'weak-password' => 'より強いパスワードを設定してください。',
        'email-already-in-use' => 'このメールアドレスはすでに使用されています。',
        'invalid-email' => 'メールアドレスの形式を確認してください。',
        'user-disabled' => 'このアカウントは現在利用できません。',
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'メールアドレスまたはパスワードを確認してください。',
        'too-many-requests' => '試行回数が多すぎます。時間をおいてからもう一度お試しください。',
        'network-request-failed' => '通信に失敗しました。ネットワーク接続を確認してください。',
        'operation-not-allowed' => 'このログイン方法は現在利用できません。',
        'popup-closed-by-user' || 'cancelled-popup-request' =>
          'Googleログインをキャンセルしました。',
        'popup-blocked' => 'Googleログインのポップアップがブロックされました。ブラウザ設定を確認してください。',
        'account-exists-with-different-credential' =>
          '同じメールアドレスで別のログイン方法が登録されています。',
        'credential-already-in-use' => 'この認証情報は別のアカウントで使用されています。',
        _ => '認証処理に失敗しました。もう一度お試しください。',
      };
    }
    return '処理に失敗しました。通信状態を確認して、もう一度お試しください。';
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = isError
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
    final foreground = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

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
