import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';

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
        title: const Text('I miei Corsi'),
        backgroundColor: Colors.indigo[700],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firebaseService.getCorsiDelProfessore(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nessun corso trovato'));
          }

          final corsi = snapshot.data!;

          return ListView.builder(
            itemCount: corsi.length,
            itemBuilder: (context, index) {
              final corso = corsi[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(corso['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(corso['descrizione']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _eliminaCorso(corso['id']),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo[700],
        child: const Icon(Icons.add),
        onPressed: _mostraDialogAggiuntaCorso,
      ),
    );
  }

  void _mostraDialogAggiuntaCorso() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi un corso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome corso'),
            ),
            TextField(
              controller: _descrizioneController,
              decoration: const InputDecoration(labelText: 'Descrizione'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Annulla'),
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
