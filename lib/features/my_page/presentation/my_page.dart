import 'dart:async';

import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/utils/external_link.dart';

import '../../auth/application/account_service.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/domain/lanske_plan.dart';
import '../../auth/domain/lanske_user.dart';
import '../../auth/presentation/account_routes.dart';
import '../../auth/presentation/account_scope.dart';
import '../../auth/presentation/auth_scope.dart';
import 'my_page_navigation_drawer.dart';
import 'widgets/my_page_match_table_list_section.dart';
import 'widgets/my_page_section_card.dart';

class MyPage extends StatefulWidget {
  const MyPage({
    super.key,
    this.accountService,
    this.ownedEventsLoader,
    this.onOpenOwnedEvent,
  });

  final AccountService? accountService;
  final MyPageOwnedEventsLoader? ownedEventsLoader;
  final MyPageOwnedEventOpenCallback? onOpenOwnedEvent;

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String? _requestedUid;
  bool _loading = false;
  LanskeUser? _user;
  Object? _loadError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final session = AuthScope.of(context).session;
    final uid = session.uid;
    if (!session.isAccount || uid == null) {
      _requestedUid = null;
      _loading = false;
      _user = null;
      _loadError = null;
      return;
    }

    if (_requestedUid == uid) {
      return;
    }

    _requestedUid = uid;
    _loading = true;
    _user = null;
    _loadError = null;
    unawaited(_loadAccount(uid));
  }

  Future<void> _loadAccount(String uid) async {
    final service = widget.accountService ?? AccountScope.of(context);

    try {
      final user = await service.ensureCurrentUser();
      if (!mounted) return;

      final session = AuthScope.of(context).session;
      if (!session.isAccount || session.uid != uid) return;

      setState(() {
        _loading = false;
        _user = user;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;

      final session = AuthScope.of(context).session;
      if (!session.isAccount || session.uid != uid) return;

      setState(() {
        _loading = false;
        _user = null;
        _loadError = error;
      });
    }
  }

  void _retry() {
    final session = AuthScope.of(context).session;
    final uid = session.uid;
    if (!session.isAccount || uid == null || _loading) return;

    setState(() {
      _requestedUid = uid;
      _loading = true;
      _user = null;
      _loadError = null;
    });
    unawaited(_loadAccount(uid));
  }

  void _openAccount() {
    openUrlInCurrentTab(accountPagePath);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = AuthScope.of(context).session;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.myPageMenuLabel),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                key: const ValueKey('my-page-navigation-menu-button'),
                tooltip: l10n.navigationMenuTooltip,
                onPressed: Scaffold.of(context).openEndDrawer,
                icon: const Icon(Icons.menu),
              );
            },
          ),
        ],
      ),
      endDrawer: const MyPageNavigationDrawer(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (!session.isAccount)
                  _buildAccountRequired(context)
                else if (_loading)
                  _buildLoading(context)
                else if (_loadError != null)
                  _buildError(context)
                else if (_user != null)
                  _buildAccountSummary(context, session, _user!),
                if (session.isAccount && session.uid != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    l10n.myPageDoublesMatchTablesHeading,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  MyPageMatchTableListSection(
                    ownerUid: session.uid!,
                    loadOwnedEvents: widget.ownedEventsLoader,
                    onOpenEvent: widget.onOpenOwnedEvent,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountRequired(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return MyPageSectionCard(
      icon: Icons.person_off_outlined,
      title: l10n.myPageAccountRequiredTitle,
      subtitle: l10n.myPageAccountRequiredBody,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: _openAccount,
          icon: const Icon(Icons.login),
          label: Text(l10n.myPageOpenAccountButton),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return MyPageSectionCard(
      icon: Icons.person_outline,
      title: l10n.myPageAccountSectionTitle,
      subtitle: l10n.myPageAccountSectionSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Text(l10n.myPageLoadingAccountMessage),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return MyPageSectionCard(
      icon: Icons.person_outline,
      title: l10n.myPageAccountSectionTitle,
      subtitle: l10n.myPageAccountSectionSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.myPageLoadErrorTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.myPageLoadErrorBody),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.myPageRetryButton),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSummary(
    BuildContext context,
    AuthSession session,
    LanskeUser user,
  ) {
    final l10n = AppLocalizations.of(context);
    final email = session.email?.trim();
    final createdDate = MaterialLocalizations.of(context).formatMediumDate(
      user.createdAt.toLocal(),
    );
    final planLabel = switch (user.plan) {
      LanskePlan.free => l10n.myPagePlanFree,
      LanskePlan.premium => l10n.myPagePlanPremium,
    };

    return MyPageSectionCard(
      icon: Icons.person_outline,
      title: l10n.myPageAccountSectionTitle,
      subtitle: l10n.myPageAccountSectionSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (email != null && email.isNotEmpty) ...[
            _AccountInfoRow(
              icon: Icons.email_outlined,
              label: l10n.myPageEmailLabel,
              value: email,
            ),
            const SizedBox(height: 12),
          ],
          _AccountInfoRow(
            icon: Icons.workspace_premium_outlined,
            label: l10n.myPagePlanLabel,
            value: planLabel,
          ),
          const SizedBox(height: 12),
          _AccountInfoRow(
            icon: Icons.calendar_today_outlined,
            label: l10n.myPageStartedAtLabel(createdDate),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _openAccount,
              icon: const Icon(Icons.manage_accounts_outlined),
              label: Text(l10n.myPageAccountManagementButton),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountInfoRow extends StatelessWidget {
  const _AccountInfoRow({
    required this.icon,
    required this.label,
    this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: value == null
              ? Text(label)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(value!),
                  ],
                ),
        ),
      ],
    );
  }
}
