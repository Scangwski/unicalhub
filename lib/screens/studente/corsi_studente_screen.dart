import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_service.dart';

class CorsiStudenteScreen extends StatefulWidget {
  final String studenteId;
  const CorsiStudenteScreen({Key? key, required this.studenteId}) : super(key: key);

  @override
  _CorsiStudenteScreenState createState() => _CorsiStudenteScreenState();
}

class _CorsiStudenteScreenState extends State<CorsiStudenteScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _visualizzaCorsiDisponibili = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_visualizzaCorsiDisponibili ? 'Corsi Disponibili' : 'I Miei Corsi'),
      ),
      body: _visualizzaCorsiDisponibili
          ? _buildCorsiDisponibili()
          : _buildCorsiIscritti(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _visualizzaCorsiDisponibili = !_visualizzaCorsiDisponibili;
          });
        },
        label: Text(_visualizzaCorsiDisponibili
            ? 'Visualizza i miei corsi'
            : 'Visualizza corsi disponibili'),
        icon: Icon(_visualizzaCorsiDisponibili ? Icons.school : Icons.add),
      ),
    );
  }

  Widget _buildCorsiIscritti() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.getDettagliCorsiIscritti(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Errore: ${snapshot.error}'));
        }

        final corsi = snapshot.data ?? [];

        if (corsi.isEmpty) {
          return const Center(
            child: Text(
              'Non sei iscritto a nessun corso. Visualizza i corsi disponibili per iscriverti.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: corsi.length,
          itemBuilder: (context, index) {
            final corso = corsi[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      corso['nome'] ?? 'Corso senza nome',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      corso['descrizione'] ?? 'Nessuna descrizione disponibile',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCorsiDisponibili() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.getCorsiDisponibili(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Errore: ${snapshot.error}'));
        }

        final corsi = snapshot.data ?? [];

        if (corsi.isEmpty) {
          return const Center(
            child: Text(
              'Non ci sono corsi disponibili al momento.',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return StreamBuilder<List<String>>(
          stream: _firebaseService.getCorsiIscritti(),
          builder: (context, iscrittiSnapshot) {
            final corsiIscritti = iscrittiSnapshot.data ?? [];

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: corsi.length,
              itemBuilder: (context, index) {
                final corso = corsi[index];
                final bool iscritto = corsiIscritti.contains(corso['id']);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          corso['nome'] ?? 'Corso senza nome',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          corso['descrizione'] ?? 'Nessuna descrizione disponibile',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: iscritto
                              ? null  // Disabilita il pulsante se già iscritto
                              : () => _iscrivitiAlCorso(corso['id']),
                          child: Text(iscritto ? 'Già iscritto' : 'Iscriviti'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _iscrivitiAlCorso(String corsoId) async {
    try {
      await _firebaseService.iscrivitiAlCorso(corsoId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iscrizione effettuata con successo!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'iscrizione: $e')),
      );
    }
  }
}
