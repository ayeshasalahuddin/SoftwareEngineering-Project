import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Map<String, dynamic>> chats = [
      {
        'name': 'CS101 Study Group',
        'message': 'Anyone up for review session?',
        'time': '2m',
        'initials': 'CS',
      },
      {
        'name': 'Campus Carpool',
        'message': 'Heading downtown at 3pm',
        'time': '15m',
        'initials': 'CC',
      },
      {
        'name': 'MATH201 Help',
        'message': 'Thanks for the notes!',
        'time': '1h',
        'initials': 'MH',
      },
      {
        'name': 'Engineering Club',
        'message': 'Meeting tomorrow at 5pm',
        'time': '3h',
        'initials': 'EC',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Add new chat action
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: chats.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              radius: 24,
              child: Text(chat['initials']),
            ),
            title: Text(
              chat['name'],
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                chat['message'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            trailing: Text(
              chat['time'],
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(
                    chatName: chat['name'],
                    initials: chat['initials'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
