import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:unicalhub/firebase_service.dart';

class VotiStudentiScreen extends StatefulWidget {
  const VotiStudentiScreen({Key? key}) : super(key: key);

  @override
  _VotiStudentiScreenState createState() => _VotiStudentiScreenState();
}

class _VotiStudentiScreenState extends State<VotiStudentiScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _voti = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _caricaVoti();
  }

  Future<void> _caricaVoti() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Utilizziamo direttamente il metodo esistente per ottenere gli appelli a cui lo studente è iscritto
      final appelli = await _firebaseService.getAppelliIscritto().first;

      // Filtriamo solo quelli che hanno un voto
      final appelliValutati = appelli.where((appello) =>
      appello.containsKey('voto') && appello['voto'] != null &&
          appello['stato'] == 'valutato'
      ).toList();

      setState(() {
        _voti = appelliValutati;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore nel caricamento dei voti: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'I miei voti',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _caricaVoti,
            tooltip: 'Aggiorna',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Si è verificato un errore',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : _voti.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Nessun voto disponibile',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Non hai ancora sostenuto esami o i voti non sono stati ancora registrati',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      )
          : _buildVotiList(),
    );
  }

  Widget _buildVotiList() {
    // Organizza i voti per corso
    Map<String, List<Map<String, dynamic>>> votiPerCorso = {};
    for (var voto in _voti) {
      final nomeCorso = voto['nomeCorso'] ?? 'Corso senza nome';
      if (!votiPerCorso.containsKey(nomeCorso)) {
        votiPerCorso[nomeCorso] = [];
      }
      votiPerCorso[nomeCorso]!.add(voto);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: votiPerCorso.length,
      itemBuilder: (context, index) {
        final corso = votiPerCorso.keys.elementAt(index);
        final votiCorso = votiPerCorso[corso]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent[700],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.school, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        corso,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: votiCorso.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final voto = votiCorso[index];
                  final titolo = voto['titolo'] ?? 'Appello senza titolo';
                  final data = voto['data'] != null
                      ? DateFormat('dd/MM/yyyy').format((voto['data'] as Timestamp).toDate())
                      : 'Data non disponibile';
                  final valutazione = voto['voto'];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      titolo,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              data,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        if (voto['statoStudente'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  voto['statoStudente'] == 'presente' ? Icons.check_circle : Icons.cancel,
                                  size: 14,
                                  color: voto['statoStudente'] == 'presente' ? Colors.green[700] : Colors.red[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  voto['statoStudente'] == 'presente' ? 'Presente' : 'Assente',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: voto['statoStudente'] == 'presente' ? Colors.green[700] : Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: valutazione == null
                            ? Colors.grey[200]
                            : (valutazione >= 18 ? Colors.green[100] : Colors.red[100]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        valutazione != null ? valutazione.toString() : 'N/A',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: valutazione == null
                              ? Colors.grey[700]
                              : (valutazione >= 18 ? Colors.green[800] : Colors.red[800]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}