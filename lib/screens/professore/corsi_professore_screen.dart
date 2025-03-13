import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unicalhub/screens/posts_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../firebase_service.dart';

class CorsiScreen extends StatefulWidget {
  const CorsiScreen({Key? key}) : super(key: key);

  @override
  _CorsiScreenState createState() => _CorsiScreenState();
}

class _CorsiScreenState extends State<CorsiScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descrizioneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'I miei Corsi',
          style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo[700],
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firebaseService.getCorsiDelProfessore(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nessun corso trovato',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            );
          }

          final corsi = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: corsi.length,
            itemBuilder: (context, index) {
              final corso = corsi[index];

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CorsoPostsScreen(
                          corsoId: corso['id'],
                          corsoNome: corso['nome'] ?? 'Corso',
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          corso['nome'] ?? 'Corso senza nome',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          corso['descrizione'] ?? 'Nessuna descrizione disponibile',
                          style: GoogleFonts.lato(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CorsoPostsScreen(
                                      corsoId: corso['id'],
                                      corsoNome: corso['nome'] ?? 'Corso',
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.forum, color: Colors.white),
                              label: const Text(
                                'Visualizza Post',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confermaEliminazioneCorso(corso['id']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fade(duration: 500.ms).moveY(begin: 10);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo[700],
        icon: const Icon(Icons.add, color: Colors.white,),
        label: Text('Aggiungi Corso', style: GoogleFonts.poppins(color: Colors.white),),
        onPressed: _mostraDialogAggiuntaCorso,
      ),
    );
  }

  void _mostraDialogAggiuntaCorso() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Aggiungi un corso',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),

        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome corso',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descrizioneController,
              decoration: const InputDecoration(
                labelText: 'Descrizione',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Annulla', style: TextStyle(color: Colors.redAccent)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Aggiungi'),
            onPressed: () async {
              if (_nomeController.text.isNotEmpty && _descrizioneController.text.isNotEmpty) {
                await _firebaseService.aggiungiCorso(
                  _nomeController.text,
                  _descrizioneController.text,
                );
                _nomeController.clear();
                _descrizioneController.clear();
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _confermaEliminazioneCorso(String corsoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: const Text('Sei sicuro di voler eliminare questo corso?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _eliminaCorso(corsoId);
              Navigator.pop(context);
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminaCorso(String corsoId) async {
    await FirebaseFirestore.instance.collection('corsi').doc(corsoId).delete();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descrizioneController.dispose();
    super.dispose();
  }
}
