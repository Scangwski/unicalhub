import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "package:timeago/timeago.dart" as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../firebase_service.dart';
import '../professore/pubblication__post_screen.dart';

class CorsoPostsScreen extends StatefulWidget {
  final String corsoId;
  final String corsoNome;

  const CorsoPostsScreen({
    Key? key,
    required this.corsoId,
    required this.corsoNome,
  }) : super(key: key);

  @override
  _CorsoPostsScreenState createState() => _CorsoPostsScreenState();
}

class _CorsoPostsScreenState extends State<CorsoPostsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _commentController = TextEditingController();
  String? _commentingPostId;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _showCommentField(String postId) {
    setState(() {
      _commentingPostId = postId;
    });
  }

  Future<void> _submitComment(String postId) async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await _firebaseService.aggiungiCommento(
        widget.corsoId,
        postId,
        _commentController.text.trim(),
      );

      _commentController.clear();
      setState(() {
        _commentingPostId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nel pubblicare il commento: $e')),
      );
    }
  }
  void _showDeletePostDialog(String postId, String autoreId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    // Mostra il dialogo solo se l'utente è l'autore del post
    if (uid != autoreId) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina post'),
        content: const Text('Sei sicuro di voler eliminare questo post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Eliminazione in corso...'))
                );

                await _firebaseService.eliminaPost(
                  widget.corsoId,
                  postId,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post eliminato con successo'))
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e'))
                );
              }
            },
            child: const Text('Elimina'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

// Aggiungi questo metodo alla classe _CorsoPostsScreenState
  void _showDeleteCommentDialog(String postId, Map<String, dynamic> commento) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final commentoAutoreId = commento['autoreId'] as String?;

    // Mostra il dialogo solo se l'utente è l'autore del commento
    if (uid != commentoAutoreId) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina commento'),
        content: const Text('Sei sicuro di voler eliminare questo commento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Eliminazione in corso...'))
                );

                await _firebaseService.eliminaCommento(
                  widget.corsoId,
                  postId,
                  commento,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Commento eliminato con successo'))
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e'))
                );
              }
            },
            child: const Text('Elimina'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.corsoNome),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firebaseService.getPostsCorso(widget.corsoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return const Center(
              child: Text(
                'Nessun post in questo corso.\nSii il primo a pubblicare qualcosa!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final postId = post['id'];
              final autoreNome = post['autoreNome'] ?? 'Utente';
              final contenuto = post['contenuto'] ?? '';
              final fileUrls = List<String>.from(post['fileUrls'] ?? []);
              final likes = List<String>.from(post['likes'] ?? []);
              final isLiked = likes.contains(uid);
              final commenti = List<Map<String, dynamic>>.from(
                  (post['commenti'] ?? []).map((c) => c as Map<String, dynamic>)
              );

              final createdAt = post['creato_il'] as Timestamp?;
              final timeAgo = createdAt != null
                  ? timeago.format(createdAt.toDate(), locale: 'it')
                  : '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Intestazione post
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text(autoreNome[0].toUpperCase()),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  autoreNome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  timeAgo,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (post['autoreId'] == uid)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _showDeletePostDialog(postId, post['autoreId']),
                              tooltip: 'Elimina post',
                            ),
                        ],
                      ),

                      // Contenuto
                      const SizedBox(height: 12),
                      Text(contenuto),

                      // File/Immagini allegati
                      if (fileUrls.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: fileUrls.length,
                            itemBuilder: (context, fileIndex) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: fileUrls[fileIndex],
                                    fit: BoxFit.cover,
                                    height: 200,
                                    width: 200,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      // Contatori
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '${likes.length} mi piace',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${commenti.length} commenti',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),

                      // Pulsanti azioni
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton.icon(
                            onPressed: () => _firebaseService.toggleLikePost(
                              widget.corsoId,
                              postId,
                            ),
                            icon: Icon(
                              isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                              color: isLiked ? Colors.blue : null,
                            ),
                            label: Text(
                              'Mi piace',
                              style: TextStyle(
                                color: isLiked ? Colors.blue : null,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showCommentField(postId),
                            icon: const Icon(Icons.comment_outlined),
                            label: const Text('Commenta'),
                          ),
                        ],
                      ),

                      // Commenti
                      if (commenti.isNotEmpty) ...[
                        const Divider(),
                        ...commenti.map((commento) {
                          final commentoAutore = commento['autoreNome'] ?? 'Utente';
                          final commentoTesto = commento['testo'] ?? '';
                          final commentoAutoreId = commento['autoreId'] as String?;

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  child: Text(
                                    commentoAutore[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                commentoAutore,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            // Aggiungi pulsante elimina se l'utente è l'autore del commento
                                            if (commentoAutoreId == uid)
                                              GestureDetector(
                                                onTap: () => _showDeleteCommentDialog(postId, commento),
                                                child: const Icon(Icons.close, size: 16, color: Colors.grey),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(commentoTesto),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],

                      // Campo per aggiungere commento
                      if (_commentingPostId == postId) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  hintText: 'Scrivi un commento...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                maxLines: 2,
                                minLines: 1,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () => _submitComment(postId),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostPublicationScreen(
                corsoId: widget.corsoId,
                corsoNome: widget.corsoNome,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Nuovo post',
      ),
    );
  }
}