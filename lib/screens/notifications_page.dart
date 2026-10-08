import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../store.dart';
import '../widgets.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('اعلان‌ها', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          if (store.unreadCount > 0) TextButton(onPressed: store.markAllRead, child: const Text('خواندن همه')),
          if (store.notifications.isNotEmpty) TextButton(onPressed: store.clearNotifications, child: const Text('پاک کردن')),
        ],
      ),
      body: store.notifications.isEmpty
          ? const EmptyState(Icons.notifications_none, 'اعلانی وجود ندارد.')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: store.notifications.length,
              itemBuilder: (_, i) {
                final n = store.notifications[i];
                final color = n.type == 'warning' ? Colors.amber.shade800 : (n.type == 'success' ? Colors.green.shade700 : Colors.blueGrey);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: n.read ? Colors.white : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE7E5E4)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(n.type == 'warning' ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        const SizedBox(height: 3),
                        Text(n.message, style: const TextStyle(fontSize: 12, height: 1.7)),
                        const SizedBox(height: 4),
                        Text(n.time, style: const TextStyle(fontSize: 10, color: Color(0xFF78716C))),
                      ]),
                    ),
                  ]),
                );
              },
            ),
    );
  }
}
