import 'package:flutter/material.dart';

import '../data/local_schedule_history_item.dart';
import '../data/local_schedule_history_store.dart';
import 'restored_schedule_page.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  late Future<List<LocalScheduleHistoryItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = LocalScheduleHistoryStore().findAll();
  }

  String _formatDateTime(DateTime dateTime) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');

    return '$y/$m/$d $hh:$mm';
  }

  void _openSchedule(LocalScheduleHistoryItem item) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RestoredSchedulePage(publicId: item.publicId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('対戦表一覧'),
      ),
      body: FutureBuilder<List<LocalScheduleHistoryItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '対戦表一覧を取得できませんでした。\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final items = snapshot.data ?? const [];

          if (items.isEmpty) {
            return const Center(
              child: Text('まだ開いた対戦表はありません'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(4),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text(
                    '面数: ${item.courtCount} / 人数: ${item.participantCount}\n'
                    '最終表示: ${_formatDateTime(item.lastOpenedAt)}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openSchedule(item),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
