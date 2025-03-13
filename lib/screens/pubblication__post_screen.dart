import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../firebase_service.dart';


class PostPublicationScreen extends StatefulWidget {
  final String corsoId;
  final String corsoNome;

  const PostPublicationScreen({
    Key? key,
    required this.corsoId,
    required this.corsoNome,
  }) : super(key: key);

  @override
  _PostPublicationScreenState createState() => _PostPublicationScreenState();
}

class _PostPublicationScreenState extends State<PostPublicationScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _contentController = TextEditingController();
  final List<File> _selectedFiles = [];
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedFiles.add(File(image.path));
      });
    }
  }

  Future<void> _publishPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci del contenuto per il post')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      List<String> fileUrls = [];

      // Carica i file selezionati su Firebase Storage
      if (_selectedFiles.isNotEmpty) {
        for (var file in _selectedFiles) {
          String fileName = DateTime.now().millisecondsSinceEpoch.toString() +
              '_' + file.path.split('/').last;

          final ref = FirebaseStorage.instance
              .ref()
              .child('posts/${widget.corsoId}/$fileName');

          await ref.putFile(file);
          String downloadUrl = await ref.getDownloadURL();
          fileUrls.add(downloadUrl);
        }
      }

      // Aggiungi il post a Firestore
      await _firebaseService.pubblicaPost(
        widget.corsoId,
        _contentController.text.trim(),
        fileUrls,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post pubblicato con successo')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante la pubblicazione: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pubblica post in ${widget.corsoNome}'),
        actions: [
          _isSubmitting
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.send),
            onPressed: _publishPost,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Scrivi qualcosa...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImage,
                  tooltip: 'Allega immagine',
                ),
                // Qui puoi aggiungere altri pulsanti per altre tipologie di allegati
                IconButton(
                  icon: const Icon(Icons.format_bold),
                  onPressed: () {
                    // Implementazione per formattazione del testo in grassetto
                  },
                  tooltip: 'Grassetto',
                ),
                IconButton(
                  icon: const Icon(Icons.format_italic),
                  onPressed: () {
                    // Implementazione per formattazione del testo in corsivo
                  },
                  tooltip: 'Corsivo',
                ),
                IconButton(
                  icon: const Icon(Icons.format_list_bulleted),
                  onPressed: () {
                    // Implementazione per elenco puntato
                  },
                  tooltip: 'Elenco puntato',
                ),
              ],
            ),
            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'File allegati:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedFiles[index],
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedFiles.removeAt(index);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}