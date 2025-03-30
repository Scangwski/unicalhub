import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unicalhub/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:unicalhub/screens/professore/dettagli_appello_screen.dart';

class AppelliProfessoreScreen extends StatefulWidget {
  final String? corsoId;
  final String? corsoNome;

  const AppelliProfessoreScreen({Key? key, this.corsoId, this.corsoNome}) : super(key: key);

  @override
  State<AppelliProfessoreScreen> createState() => _AppelliProfessoreScreenState();
}

class _AppelliProfessoreScreenState extends State<AppelliProfessoreScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo[700],
        title: Text(
          widget.corsoNome != null
              ? 'Appelli: ${widget.corsoNome}'
              : 'Tutti gli Appelli',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              _showCreaAppelloDialog(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: widget.corsoId != null
              ? _firebaseService.getAppelliCorso(widget.corsoId!)
              : _firebaseService.getAppelliProfessore(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Errore nel caricamento degli appelli: ${snapshot.error}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              );
            }

            final appelli = snapshot.data ?? [];

            if (appelli.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text(
                      'Nessun appello programmato',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Premi il pulsante + per aggiungere un nuovo appello',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            // Organizza gli appelli per mese
            Map<String, List<Map<String, dynamic>>> appelliPerMese = {};
            for (var appello in appelli) {
              final data = (appello['data'] as dynamic).toDate();
              final meseAnno = DateFormat('MMMM yyyy').format(data);

              if (!appelliPerMese.containsKey(meseAnno)) {
                appelliPerMese[meseAnno] = [];
              }
              appelliPerMese[meseAnno]!.add(appello);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appelliPerMese.length,
              itemBuilder: (context, index) {
                final meseAnno = appelliPerMese.keys.toList()[index];
                final appelliMese = appelliPerMese[meseAnno]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        meseAnno.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.indigo[700],
                        ),
                      ),
                    ),
                    ...appelliMese.map((appello) {
                      final data = (appello['data'] as dynamic).toDate();
                      final dataFormattata = DateFormat('EEE d MMM, HH:mm').format(data);
                      final iscritti = appello['iscritti'] as List<dynamic>;
                      final stato = appello['stato'] as String;


                      Color statoColor;
                      switch (stato) {
                        case 'aperto':
                          statoColor = Colors.green;
                          break;
                        case 'chiuso':
                          statoColor = Colors.orange;
                          break;
                        case 'valutato':
                          statoColor = Colors.blue;
                          break;
                        default:
                          statoColor = Colors.grey;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DettaglioAppelloScreen(
                                  corsoId: appello['corsoId'] ?? widget.corsoId!,
                                  appelloId: appello['id'],
                                  appelloData: appello,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Nome del corso se siamo nella vista generale
                                    if (widget.corsoId == null)
                                      Text(
                                        appello['nomeCorso'] ?? 'Corso',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey,
                                        ),
                                      ),

                                    // Stato dell'appello
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statoColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        stato.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: statoColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  appello['titolo'] ?? 'Appello d\'esame',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 6),
                                    Text(
                                      dataFormattata,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.people, size: 16, color: Colors.indigo),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${iscritti.length} iscritti',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (stato == 'aperto')
                                      OutlinedButton(
                                        onPressed: () {
                                          _firebaseService.chiudiAppello(
                                            appello['corsoId'] ?? widget.corsoId!,
                                            appello['id'],
                                          ).then((_) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Iscrizioni chiuse con successo'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }).catchError((error) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Errore: $error'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          });
                                        },
                                        child: const Text('Chiudi'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showCreaAppelloDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descrizioneController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 14));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);

    // Se non c'è corsoId, chiediamo all'utente di selezionare un corso
    String? selectedCorsoId = widget.corsoId;
    String? selectedCorsoNome = widget.corsoNome;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nuovo Appello d\'Esame'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedCorsoId == null)
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _firebaseService.getCorsiDelProfessore().first,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          if (snapshot.hasError) {
                            return Text('Errore: ${snapshot.error}');
                          }

                          final corsi = snapshot.data ?? [];
                          if (corsi.isEmpty) {
                            return const Text('Nessun corso disponibile');
                          }

                          return DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Corso',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedCorsoId,
                            items: corsi.map((corso) {
                              return DropdownMenuItem<String>(
                                value: corso['id'],
                                child: Text(corso['nome']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCorsoId = value;
                                selectedCorsoNome = corsi
                                    .firstWhere((c) => c['id'] == value)['nome'];
                              });
                            },
                          );
                        },
                      ),

                    if (selectedCorsoId == null)
                      const SizedBox(height: 16),

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titolo dell\'appello',
                        hintText: 'Es. Primo appello sessione invernale',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );

                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(selectedDate),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );

                        if (time != null) {
                          setState(() {
                            selectedTime = time;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Orario',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          selectedTime.format(context),
                        ),
                      ),
                    ),





                    const SizedBox(height: 16),

                    TextField(
                      controller: descrizioneController,
                      decoration: const InputDecoration(
                        labelText: 'Descrizione (opzionale)',
                        hintText: 'Es. Portare documento d\'identità',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Annulla'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedCorsoId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Seleziona un corso'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Inserisci un titolo'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Combina data e ora
                    final dataAppello = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    // Crea l'appello
                    _firebaseService.creaAppello(
                      selectedCorsoId!,
                      titleController.text,
                      dataAppello,
                      descrizioneController.text,

                    ).then((docId) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Appello creato con successo'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Errore: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    });
                  },
                  child: const Text('Crea'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}