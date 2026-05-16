import 'package:flutter/material.dart';

import '../data/mock_log_store.dart';
import 'schedule_page.dart';

class EventListPage extends StatelessWidget {
  const EventListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = MockLogStore.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('対戦表一覧'),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text('まだ保存された対戦表はありません'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(4),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final draft = item.draft;

                return Card(
                  child: ListTile(
                    title: Text(draft.eventName),
                    subtitle: Text(
                      '面数: ${draft.courts} / 人数: ${draft.players}\n'
                      '保存日時: ${item.savedAt.year}/'
                      '${item.savedAt.month.toString().padLeft(2, '0')}/'
                      '${item.savedAt.day.toString().padLeft(2, '0')} '
                      '${item.savedAt.hour.toString().padLeft(2, '0')}:'
                      '${item.savedAt.minute.toString().padLeft(2, '0')}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SchedulePage(draft: draft),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
