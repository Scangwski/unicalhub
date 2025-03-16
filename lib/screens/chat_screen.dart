import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const ChatScreen({
    Key? key,
    required this.recipientId,
    required this.recipientName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _currentUserId;
  late String _chatId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid ?? '';
    // Generate a unique chat ID based on both user IDs
    // Ensures the same chat ID regardless of who initiates
    List<String> ids = [_currentUserId, widget.recipientId];
    ids.sort(); // Sort to ensure consistent order
    _chatId = ids.join('_');
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final String messageText = _messageController.text.trim();
    _messageController.clear();

    // Get current user info
    final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
    final firstName = userDoc.data()?['firstName'] ?? '';
    final lastName = userDoc.data()?['lastName'] ?? '';
    final senderName = '${firstName} ${lastName}'.trim();
    final displayName = senderName.isEmpty ? 'Utente' : senderName;

    // Get recipient user info (per garantire il nome corretto)
    final recipientDoc = await _firestore.collection('users').doc(widget.recipientId).get();
    final recipientFirstName = recipientDoc.data()?['firstName'] ?? '';
    final recipientLastName = recipientDoc.data()?['lastName'] ?? '';
    final recipientFullName = '${recipientFirstName} ${recipientLastName}'.trim();
    final recipientDisplayName = recipientFullName.isEmpty ? widget.recipientName : recipientFullName;

    // Create message document
    await _firestore.collection('chats').doc(_chatId).collection('messages').add({
      'senderId': _currentUserId,
      'senderName': displayName,
      'recipientId': widget.recipientId,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    // Update chat metadata with Map structure for participantNames and unreadCount
    Map<String, dynamic> participantNames = {};
    participantNames[_currentUserId] = displayName;
    participantNames[widget.recipientId] = recipientDisplayName;

    Map<String, dynamic> unreadCount = {};
    unreadCount[_currentUserId] = 0;

    // Incrementa il contatore dei messaggi non letti per il destinatario
    // Se il documento esiste già, usa FieldValue.increment
    final chatDoc = await _firestore.collection('chats').doc(_chatId).get();
    if (chatDoc.exists) {
      final data = chatDoc.data()!;
      final currentUnreadCount = (data['unreadCount'] as Map<String, dynamic>?)?[widget.recipientId] ?? 0;
      unreadCount[widget.recipientId] = currentUnreadCount + 1;
    } else {
      unreadCount[widget.recipientId] = 1;
    }

    await _firestore.collection('chats').doc(_chatId).set({
      'participants': [_currentUserId, widget.recipientId],
      'participantNames': participantNames,
      'lastMessage': messageText,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'unreadCount': unreadCount,
    }, SetOptions(merge: true));

    print("Messaggio inviato e metadati chat aggiornati"); // Debug print
  }

  Future<void> _markMessagesAsRead() async {
    // Get unread messages sent by the other user
    final querySnapshot = await _firestore
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .where('senderId', isEqualTo: widget.recipientId)
        .where('read', isEqualTo: false)
        .get();

    // Batch update to mark all as read
    final batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }

    // Reset unread count for current user
    if (querySnapshot.docs.isNotEmpty) {
      batch.update(
          _firestore.collection('chats').doc(_chatId),
          {'unreadCount.${_currentUserId}': 0}
      );
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientName),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Nessun messaggio. Inizia a chattare!'),
                  );
                }

                // Mark messages as read when they appear
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markMessagesAsRead();
                });

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10.0),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = snapshot.data!.docs[index];
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == _currentUserId;

                    // Format timestamp
                    String formattedTime = '';
                    if (data['timestamp'] != null) {
                      DateTime dateTime = (data['timestamp'] as Timestamp).toDate();
                      formattedTime = DateFormat('HH:mm').format(dateTime);
                    }

                    return MessageBubble(
                      message: data['text'],
                      isMe: isMe,
                      time: formattedTime,
                      senderName: data['senderName'],
                      isRead: data['read'] ?? false,
                    );
                  },
                );
              },
            ),
          ),
          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Scrivi un messaggio...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String time;
  final String senderName;
  final bool isRead;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.time,
    required this.senderName,
    required this.isRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    if (isMe)
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}