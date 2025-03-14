import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:unicalhub/screens/professore/report_presenze_screen.dart';
import '../../firebase_service.dart';
import 'presenze_screen.dart';

class LezioniScreen extends StatefulWidget {
  final String corsoId;
  final String corsoNome;

  const LezioniScreen({
    Key? key,
    required this.corsoId,
    required this.corsoNome,
  }) : super(key: key);

  @override
  _LezioniScreenState createState() => _LezioniScreenState();
}

class _LezioniScreenState extends State<LezioniScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _titoloController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lezioni: ${widget.corsoNome}',
          style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: () {
              // Naviga alla schermata ReportPresenzeStudentiScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportPresenzeStudentiScreen(
                    corsoId: widget.corsoId, // Passa il corsoId
                    corsoNome: widget.corsoNome,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firebaseService.getLezioniCorso(widget.corsoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nessuna lezione disponibile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            );
          }

          final lezioni = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lezioni.length,
            itemBuilder: (context, index) {
              final lezione = lezioni[index];
              final data = lezione['data'] ?? 'Data sconosciuta';

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
                        builder: (context) => PresenzeScreen(
                          corsoId: widget.corsoId,
                          lezioneId: lezione['id'],
                          lezioneTitolo: lezione['titolo'],
                          data: data,
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
                          lezione['titolo'] ?? 'Lezione senza titolo',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data,
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
                                    builder: (context) => PresenzeScreen(
                                      corsoId: widget.corsoId,
                                      lezioneId: lezione['id'],
                                      lezioneTitolo: lezione['titolo'],
                                      data: data,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: const Text(
                                'Presenze',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confermaEliminazioneLezione(lezione['id']),
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
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Nuova Lezione', style: GoogleFonts.poppins(color: Colors.white)),
        onPressed: _mostraDialogAggiuntaLezione,
      ),
    );
  }

  void _mostraDialogAggiuntaLezione() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Aggiungi una lezione',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titoloController,
              decoration: const InputDecoration(
                labelText: 'Titolo lezione',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dataController,
              decoration: InputDecoration(
                labelText: 'Data',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _selectedDate = pickedDate;
                        _dataController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                      });
                    }
                  },
                ),
              ),
              readOnly: true,
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
              if (_titoloController.text.isNotEmpty && _dataController.text.isNotEmpty) {
                await _firebaseService.creaLezione(
                  widget.corsoId,
                  _titoloController.text,
                  _dataController.text,
                );
                _titoloController.clear();
                _dataController.clear();
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _confermaEliminazioneLezione(String lezioneId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: const Text('Sei sicuro di voler eliminare questa lezione?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _eliminaLezione(lezioneId);
              Navigator.pop(context);
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminaLezione(String lezioneId) async {
    await FirebaseFirestore.instance
        .collection('corsi')
        .doc(widget.corsoId)
        .collection('lezioni')
        .doc(lezioneId)
        .delete();
  }

  @override
  void dispose() {
    _titoloController.dispose();
    _dataController.dispose();
    super.dispose();
  }
}