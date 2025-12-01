import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_screen.dart';
import 'create_group_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  void _showCreateChatDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
    );
  }

  Future<void> _joinGroup(String chatId, String chatName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('chats').doc(chatId).update({
        'participants': FieldValue.arrayUnion([user.uid])
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined $chatName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _auth.currentUser;

    if (user == null) {
      return const Center(child: Text('Please log in to view chats'));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'My Chats'),
              Tab(text: 'Discover'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreateChatDialog,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // My Chats Tab
            _buildChatList(user.uid, isMyChats: true),
            // Discover Tab
            _buildChatList(user.uid, isMyChats: false),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(String userId, {required bool isMyChats}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('chats').orderBy('lastMessageTime', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];
        
        // Filter docs based on tab
        final docs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final participants = List<String>.from(data['participants'] ?? []);
          if (isMyChats) {
            return participants.contains(userId);
          } else {
            // Discover tab: Show only public groups that user is NOT in
            final isPublic = data['isPublic'] ?? true; // Default to true for old groups
            return !participants.contains(userId) && isPublic;
          }
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isMyChats ? Icons.chat_bubble_outline : Icons.public,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isMyChats ? 'No chats yet' : 'No new groups to discover',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                if (isMyChats)
                  TextButton(
                    onPressed: _showCreateChatDialog,
                    child: const Text('Create a Group'),
                  ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final chatId = docs[index].id;
            final name = data['name'] ?? 'Unknown';
            final message = data['lastMessage'] ?? '';
            final initials = data['initials'] ?? '??';
            
            // Format time (simplified)
            String timeStr = '';
            if (data['lastMessageTime'] != null) {
              final Timestamp t = data['lastMessageTime'];
              final dt = t.toDate();
              final now = DateTime.now();
              final diff = now.difference(dt);
              if (diff.inMinutes < 60) {
                timeStr = '${diff.inMinutes}m';
              } else if (diff.inHours < 24) {
                timeStr = '${diff.inHours}h';
              } else {
                timeStr = '${dt.day}/${dt.month}';
              }
            }

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                radius: 24,
                child: Text(initials),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: isMyChats 
                ? Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '${(data['participants'] as List).length} members',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
              trailing: isMyChats 
                ? Text(
                    timeStr,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  )
                : ElevatedButton(
                    onPressed: () => _joinGroup(chatId, name),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(60, 32),
                    ),
                    child: const Text('Join'),
                  ),
              onTap: isMyChats 
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          chatId: chatId,
                          chatName: name,
                          initials: initials,
                        ),
                      ),
                    );
                  }
                : () => _joinGroup(chatId, name),
            );
          },
        );
      },
    );
  }
}
