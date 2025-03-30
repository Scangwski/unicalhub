import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

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

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'Oggi';
    } else if (dateDay == yesterday) {
      return 'Ieri';
    } else {
      return DateFormat('d MMMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.redAccent.shade700,
        title: Text(
          widget.recipientName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 50, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Nessun messaggio',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Inizia a chattare con ${widget.recipientName}!',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Mark messages as read when they appear
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _markMessagesAsRead();
                  });

                  final docs = snapshot.data!.docs;
                  List<Widget> messageWidgets = [];
                  DateTime? lastMessageDay;

                  // Poiché stiamo usando reverse: true, dobbiamo invertire l'ordine per le date
                  // Questo è importante perché vogliamo che la data compaia prima del primo messaggio del giorno
                  for (int i = docs.length - 1; i >= 0; i--) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;

                    // Timestamp handling
                    DateTime? messageDate;
                    if (data['timestamp'] != null) {
                      messageDate = (data['timestamp'] as Timestamp).toDate();
                    }

                    // Add date separator if the day changes
                    if (messageDate != null) {
                      final messageDay = DateTime(messageDate.year, messageDate.month, messageDate.day);

                      if (lastMessageDay == null || lastMessageDay != messageDay) {
                        // Day changed, add a date separator
                        lastMessageDay = messageDay;

                        messageWidgets.add(
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _getDateLabel(messageDate),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    }

                    // Add the message bubble
                    bool isMe = data['senderId'] == _currentUserId;
                    String formattedTime = '';
                    if (messageDate != null) {
                      formattedTime = DateFormat('HH:mm').format(messageDate);
                    }

                    messageWidgets.add(
                      MessageBubble(
                        message: data['text'],
                        isMe: isMe,
                        time: formattedTime,
                        senderName: data['senderName'],
                        isRead: data['read'] ?? false,
                      ),
                    );
                  }

                  // Invertiamo di nuovo la lista per visualizzarla in ordine cronologico inverso
                  messageWidgets = messageWidgets.reversed.toList();

                  return ListView(
                    reverse: true,
                    padding: const EdgeInsets.all(16.0),
                    children: messageWidgets,
                  );
                },
              ),
            ),
          ),
          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Scrivi un messaggio...',
                        hintStyle: GoogleFonts.poppins(fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent.shade700,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
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
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: isMe ? Colors.redAccent.shade700 : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: isMe ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        color: isMe ? Colors.white70 : Colors.black54,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isMe)
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: isRead ? Colors.white : Colors.white70,
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