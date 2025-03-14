import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../firebase_service.dart';

class PresenzeScreen extends StatefulWidget {
  final String corsoId;
  final String lezioneId;
  final String lezioneTitolo;
  final String data;

  const PresenzeScreen({
    Key? key,
    required this.corsoId,
    required this.lezioneId,
    required this.lezioneTitolo,
    required this.data,
  }) : super(key: key);

  @override
  _PresenzeScreenState createState() => _PresenzeScreenState();
}

class _PresenzeScreenState extends State<PresenzeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _studenti = [];
  Map<String, bool> _presenze = {};
  bool _isLoading = true;
  bool _isExporting = false;

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
      // Carica gli studenti iscritti al corso
      final studenti = await _firebaseService.getStudentiIscritti(widget.corsoId);

      // Carica le presenze già registrate
      final presenze = await _firebaseService.getPresenzeLezione(widget.corsoId, widget.lezioneId);

      // Inizializza le presenze per tutti gli studenti
      Map<String, bool> presenzeComplete = {};
      for (var studente in studenti) {
        String id = studente['id'];
        presenzeComplete[id] = presenze.containsKey(id) ? presenze[id]! : false;
      }

      setState(() {
        _studenti = studenti;
        _presenze = presenzeComplete;
        _isLoading = false;
      });
    } catch (e) {
      print('Errore durante il caricamento dei dati: $e');
      setState(() {
        _isLoading = false;
      });
      _mostraErrore('Errore durante il caricamento dei dati');
    }
  }

  Future<void> _togglePresenza(String studenteId) async {
    setState(() {
      _presenze[studenteId] = !(_presenze[studenteId] ?? false);
    });

    try {
      await _firebaseService.registraPresenza(
        widget.corsoId,
        widget.lezioneId,
        studenteId,
        _presenze[studenteId]!,
      );
    } catch (e) {
      print('Errore durante la registrazione della presenza: $e');
      // Ripristina lo stato precedente in caso di errore
      setState(() {
        _presenze[studenteId] = !(_presenze[studenteId] ?? false);
      });
      _mostraErrore('Errore durante la registrazione della presenza');
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

  void _mostraSuccesso(String messaggio) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messaggio),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _impostaTuttiPresenti() async {
    setState(() {
      for (var studente in _studenti) {
        _presenze[studente['id']] = true;
      }
    });

    try {
      for (var studente in _studenti) {
        await _firebaseService.registraPresenza(
          widget.corsoId,
          widget.lezioneId,
          studente['id'],
          true,
        );
      }
      _mostraSuccesso('Tutti gli studenti impostati come presenti');
    } catch (e) {
      _mostraErrore('Errore durante l\'aggiornamento delle presenze');
      _caricaDati(); // Ricarica i dati in caso di errore
    }
  }

  Future<void> _impostaTuttiAssenti() async {
    setState(() {
      for (var studente in _studenti) {
        _presenze[studente['id']] = false;
      }
    });

    try {
      for (var studente in _studenti) {
        await _firebaseService.registraPresenza(
          widget.corsoId,
          widget.lezioneId,
          studente['id'],
          false,
        );
      }
      _mostraSuccesso('Tutti gli studenti impostati come assenti');
    } catch (e) {
      _mostraErrore('Errore durante l\'aggiornamento delle presenze');
      _caricaDati(); // Ricarica i dati in caso di errore
    }
  }

  Future<void> _simulaEsportaPresenze() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Simula l'esportazione dei dati (in un'app reale potrebbe generare un PDF o CSV)
      await Future.delayed(const Duration(seconds: 2));
      _mostraSuccesso('Registro esportato con successo');
    } catch (e) {
      _mostraErrore('Errore durante l\'esportazione');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Presenze: ${widget.lezioneTitolo}',
          style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _caricaDati,
            tooltip: 'Aggiorna',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _studenti.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Nessuno studente iscritto a questo corso',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.indigo[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.indigo[700], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Data: ${widget.data}',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.indigo[700], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Studenti presenti: ${_presenze.values.where((presente) => presente).length}/${_studenti.length}',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _studenti.isEmpty ? 0 : _presenze.values.where((presente) => presente).length / _studenti.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _impostaTuttiPresenti,
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                    label: Text(
                      'Tutti presenti',
                      style: GoogleFonts.lato(color: Colors.green),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _impostaTuttiAssenti,
                    icon: const Icon(Icons.highlight_off, color: Colors.red),
                    label: Text(
                      'Tutti assenti',
                      style: GoogleFonts.lato(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _studenti.length,
              itemBuilder: (context, index) {
                final studente = _studenti[index];
                final studenteId = studente['id'];
                final nomeCognome = '${studente['firstName']} ${studente['lastName']}';
                final presente = _presenze[studenteId] ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: presente ? Colors.green : Colors.grey[300],
                      child: Icon(
                        presente ? Icons.check : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      nomeCognome,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(studente['email'] ?? ''),
                    trailing: Switch(
                      value: presente,
                      activeColor: Colors.green,
                      onChanged: (value) => _togglePresenza(studenteId),
                    ),
                    onTap: () => _togglePresenza(studenteId),
                  ),
                ).animate().fadeIn(duration: 300.ms);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.zero,
        height: 70,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text('Salva', style: GoogleFonts.lato(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[700],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () {
                  _mostraSuccesso('Presenze salvate con successo');
                },
              ),
              ElevatedButton.icon(
                icon: _isExporting
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.file_download, color: Colors.white),
                label: Text(
                  _isExporting ? 'Esportando...' : 'Esporta',
                  style: GoogleFonts.lato(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: _isExporting ? null : _simulaEsportaPresenze,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.visibility),
                label: Text('Riepilogo', style: GoogleFonts.lato()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () {
                  _mostraRiepilogoPresenze();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostraRiepilogoPresenze() {
    int presenti = _presenze.values.where((presente) => presente).length;
    int totale = _studenti.length;
    double percentuale = totale > 0 ? (presenti / totale) * 100 : 0;

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Riepilogo Presenze',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
          ListTile(
          leading: const Icon(Icons.calendar_today, color: Colors.indigo),
          title: Text('Data: ${widget.data}'),
        ),
        ListTile(
          leading: const Icon(Icons.book, color: Colors.indigo),
          title: Text('Lezione: ${widget.lezioneTitolo}'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.people, color: Colors.green),
          title: Text('Studenti Presenti: $presenti'),
        ),
                ListTile(
                  leading: const Icon(Icons.person_off, color: Colors.red),
                  title: Text('Studenti Assenti: ${totale - presenti}'),
                ),
                ListTile(
                  leading: const Icon(Icons.percent, color: Colors.blue),
                  title: Text('Percentuale Presenze: ${percentuale.toStringAsFixed(1)}%'),
                ),
              ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Chiudi', style: GoogleFonts.lato()),
            ),
          ],
        ),
    );
  }}