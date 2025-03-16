import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../firebase_service.dart'; // Import your service class
import 'chat_screen.dart'; // Import the ChatScreen we just created

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  @override
  void initState() {
    super.initState();
    // Debug check per verificare se l'utente è autenticato
    final uid = FirebaseAuth.instance.currentUser?.uid;
    print('Current user ID: $uid');

    // Verifica se ci sono chat nel database per questo utente
    FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid ?? '')
        .get()
        .then((snapshot) {
      print('Chat trovate direttamente: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        print('Chat ID: ${doc.id}');
        print('Chat data: ${doc.data()}');
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Messaggi'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                _showNewChatDialog(context);
              },
            ),
          ],
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firebaseService.getChats(),
    builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data!.isEmpty) {
    return const Center(
    child: Text('Nessuna chat. Inizia a chattare con qualcuno!'),
    );
    }

    final chats = snapshot.data!;
    return ListView.builder(
    itemCount: chats.length,
    itemBuilder: (context, index) {
    final chat = chats[index];

    // Format timestamp
    String formattedTime = '';
    if (chat['timestamp'] != null) {
    DateTime dateTime = (chat['timestamp'] as Timestamp).toDate();
    formattedTime = DateFormat('HH:mm').format(dateTime);
    }

    return ListTile(
    leading: CircleAvatar(
    backgroundColor: Theme.of(context).primaryColor,
    child: Text(
    chat['otherUserName'].substring(0, 1).toUpperCase(),
    style: const TextStyle(color: Colors.white),),
    ),
      title: Text(chat['otherUserName']),
      subtitle: Text(
        chat['lastMessage'],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(formattedTime, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          if (chat['unreadCount'] > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat['unreadCount'].toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              recipientId: chat['otherUserId'],
              recipientName: chat['otherUserName'],
            ),
          ),
        );
      },
    );
    },
    );
    },
        ),
    );
  }

  Future<void> _showNewChatDialog(BuildContext context) async {
    // Get all users
    final users = await _firebaseService.getAllUsers();

    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun utente disponibile')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nuova chat'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      user['name'].substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(user['name']),
                  subtitle: Text(user['email']),
                  onTap: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          recipientId: user['id'],
                          recipientName: user['name'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}