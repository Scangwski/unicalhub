import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../firebase_service.dart';

class ReportPresenzeStudentiScreen extends StatefulWidget {
  final String corsoId;
  final String corsoNome;

  const ReportPresenzeStudentiScreen({
    Key? key,
    required this.corsoId,
    required this.corsoNome,
  }) : super(key: key);

  @override
  _ReportPresenzeStudentiScreenState createState() =>
      _ReportPresenzeStudentiScreenState();
}

class _ReportPresenzeStudentiScreenState
    extends State<ReportPresenzeStudentiScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _datiPresenze = [];
  bool _isLoading = true;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _caricaDati();
  }

  Future<void> _caricaDati() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dati = await _firebaseService.getPresenzePerStudente(widget.corsoId);

      setState(() {
        _datiPresenze = dati;
        _isLoading = false;
      });
    } catch (e) {
      print('Errore durante il caricamento dei dati: $e');
      setState(() {
        _isLoading = false;
      });
      _mostraErrore('Errore durante il caricamento dei dati: $e');
    }
  }

  void _mostraErrore(String messaggio) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messaggio),
        backgroundColor: Colors.red,
      ),
    );
  }

  List<Map<String, dynamic>> get _studentiFiltrati {
    if (_filtro.isEmpty) return _datiPresenze;

    return _datiPresenze.where((studente) {
      final nome = studente['nome'].toString().toLowerCase();
      final email = studente['email'].toString().toLowerCase();
      final ricerca = _filtro.toLowerCase();

      return nome.contains(ricerca) || email.contains(ricerca);
    }).toList();
  }

  void _visualizzaDettaglioStudente(Map<String, dynamic> studente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final presenze = studente['presenze'] as List<dynamic>;
          final statistiche = studente['statistiche'] as Map<String, dynamic>;

          return Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(  // Aggiungi SingleChildScrollView per permettere lo scroll
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    studente['nome'],
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    studente['email'],
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Riepilogo statistiche
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _statTile(
                              'Lezioni totali',
                              '${statistiche['totaleLezioni']}',
                              Icons.book,
                              Colors.indigo,
                            ),
                            _statTile(
                              'Presenze',
                              '${statistiche['presenze']}',
                              Icons.check_circle,
                              Colors.green,
                            ),
                            _statTile(
                              'Assenze',
                              '${statistiche['assenze']}',
                              Icons.cancel,
                              Colors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            Text(
                              'Percentuale Presenze',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: statistiche['percentualePresenza'] / 100,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getPercentageColor(statistiche['percentualePresenza']),
                                      ),
                                      minHeight: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${statistiche['percentualePresenza'].toStringAsFixed(1)}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _getPercentageColor(statistiche['percentualePresenza']),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Dettaglio Presenze',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Aggiungi una dimensione fissa all'interno della lista
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: presenze.length,
                      itemBuilder: (context, index) {
                        final lezione = presenze[index];
                        final presente = lezione['presente'] as bool;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: presente ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: presente ? Colors.green : Colors.red,
                              child: Icon(
                                presente ? Icons.check : Icons.close,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              lezione['titolo'],
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text('Data: ${lezione['data']}'),
                            trailing: Text(
                              presente ? 'Presente' : 'Assente',
                              style: TextStyle(
                                color: presente ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statTile(String titolo, String valore, IconData icona, Color colore) {
    return Column(
      children: [
        Icon(icona, color: colore, size: 28),
        const SizedBox(height: 4),
        Text(
          valore,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colore,
          ),
        ),
        Text(
          titolo,
          style: GoogleFonts.lato(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Color _getPercentageColor(double percentuale) {
    if (percentuale >= 80) {
      return Colors.green;
    } else if (percentuale >= 50) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.corsoNome,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  _filtro = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Cerca Studente',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _studentiFiltrati.length,
                itemBuilder: (context, index) {
                  final studente = _studentiFiltrati[index];
                  return ListTile(
                    title: Text(studente['nome']),
                    subtitle: Text(studente['email']),
                    onTap: () => _visualizzaDettaglioStudente(studente),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
