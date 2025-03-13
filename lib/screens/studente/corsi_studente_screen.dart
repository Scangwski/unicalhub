import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unicalhub/screens/posts_screen.dart';
import 'dart:ui'; // Per effetto blur
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: Colors.grey[100], // Sfondo chiaro per contrasto
      appBar: AppBar(
        title: Text(
          _visualizzaCorsiDisponibili ? 'Corsi Disponibili' : 'I Miei Corsi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.redAccent[700],
        elevation: 10, // Ombra per profondità
        shadowColor: Colors.black45,
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
        backgroundColor: Colors.redAccent[700],
        label: Text(
          _visualizzaCorsiDisponibili
              ? 'I Miei Corsi'
              : 'Corsi Disponibili',
          style: TextStyle(color: Colors.white),
        ),
        icon: Icon(
          _visualizzaCorsiDisponibili ? Icons.school : Icons.search,
          color: Colors.white,
        ),
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
          return _emptyState("Non sei iscritto a nessun corso. Cerca corsi disponibili!");
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: corsi.length,
          itemBuilder: (context, index) {
            final corso = corsi[index];

            return _corsoCard(
              titolo: corso['nome'] ?? 'Corso senza nome',
              descrizione: corso['descrizione'] ?? 'Nessuna descrizione disponibile',
              icona: Icons.book,
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => CorsoPostsScreen(
                      corsoId: corso['id'],
                      corsoNome: corso['nome'] ?? 'Corso senza nome',
                    ),
                    transitionsBuilder: (_, animation, __, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              },
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
          return _emptyState("Nessun corso disponibile al momento.");
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

                return _corsoCard(
                  titolo: corso['nome'] ?? 'Corso senza nome',
                  descrizione: corso['descrizione'] ?? 'Nessuna descrizione disponibile',
                  icona: Icons.school,
                  bottone: ElevatedButton(
                    onPressed: iscritto ? null : () => _iscrivitiAlCorso(corso['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iscritto ? Colors.grey : Colors.redAccent[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(iscritto ? 'Già iscritto' : 'Iscriviti'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _corsoCard({required String titolo, required String descrizione, required IconData icona, VoidCallback? onTap, Widget? bottone}) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icona, color: Colors.redAccent[700], size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      titolo,
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                descrizione,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
              ),
              if (bottone != null) ...[
                const SizedBox(height: 16),
                Align(alignment: Alignment.centerRight, child: bottone),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54),
      ),
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
