import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unicalhub/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:unicalhub/screens/studente/voti_screen.dart';

class AppelliStudenteScreen extends StatefulWidget {
  final String? corsoId;
  final String? corsoNome;

  const AppelliStudenteScreen({Key? key, this.corsoId, this.corsoNome}) : super(key: key);

  @override
  State<AppelliStudenteScreen> createState() => _AppelliStudenteScreenState();
}

class _AppelliStudenteScreenState extends State<AppelliStudenteScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.redAccent[700],
        title: Text(
          widget.corsoNome != null
              ? 'Appelli: ${widget.corsoNome}'
              : 'I Miei Appelli',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,

          tabs: const [
            Tab(text: 'DISPONIBILI'),
            Tab(text: 'ISCRIZIONI'),

          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab Appelli Disponibili
          widget.corsoId != null
              ? _buildAppelliCorsoTab()
              : _buildCorsiConAppelliTab(),

          // Tab Iscrizioni
          _buildIscrizioniTab(),

        ],
      ),
    );
  }

  Widget _buildAppelliCorsoTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.getAppelliCorso(widget.corsoId!),
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

        // Filtra solo gli appelli aperti
        final appelliAperti = appelli.where((a) => a['stato'] == 'aperto').toList();

        if (appelliAperti.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'Nessun appello disponibile',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Al momento non ci sono appelli aperti per questo corso',
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appelliAperti.length,
          itemBuilder: (context, index) {
            final appello = appelliAperti[index];
            final data = (appello['data'] as dynamic).toDate();
            final dataFormattata = DateFormat('EEE d MMM, HH:mm').format(data);
            final iscritti = appello['iscritti'] as List<dynamic>;


            // Controlla se lo studente è già iscritto
            final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
            final isGiaIscritto = iscritti.any((iscritto) => iscritto['id'] == uid);



            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appello['titolo'] ?? 'Appello d\'esame',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

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

                    if (appello['descrizione'] != null && appello['descrizione'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          appello['descrizione'],
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people, size: 16, color: Colors.indigo),
                            const SizedBox(width: 6),
                          ],
                        ),

                        if (isGiaIscritto)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Cancella Iscrizione'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[700],
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Conferma'),
                                  content: const Text(
                                      'Sei sicuro di voler cancellare la tua iscrizione a questo appello?'
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('No'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _firebaseService.cancellaIscrizioneAppello(
                                          widget.corsoId!,
                                          appello['id'],
                                        ).then((_) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Iscrizione cancellata con successo'),
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
                                      child: const Text('Sì'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )

                        else
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check, color: Colors.white,),
                            label: const Text('Iscriviti'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.redAccent[700],
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Conferma Iscrizione'),
                                  content: const Text(
                                      'Sei sicuro di volerti iscrivere a questo appello d\'esame?'
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('No'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _firebaseService.iscrivitiAppello(
                                          widget.corsoId!,
                                          appello['id'],
                                        ).then((_) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Iscrizione effettuata con successo'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );

                                          // Passa alla tab delle iscrizioni
                                          _tabController.animateTo(1);
                                        }).catchError((error) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Errore: $error'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        });
                                      },
                                      child: const Text('Sì'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
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

  Widget _buildCorsiConAppelliTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<List<String>>(
      stream: _firebaseService.getCorsiIscritti(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Errore nel caricamento dei corsi: ${snapshot.error}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        final corsiIds = snapshot.data ?? [];

        if (corsiIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'Nessun corso trovato',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Iscriviti a dei corsi per visualizzare gli appelli',
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

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: Future.wait(corsiIds.map((corsoId) async {
            // Ottieni informazioni sul corso
            final corsoDoc = await FirebaseFirestore.instance.collection('corsi').doc(corsoId).get();
            final corsoNome = corsoDoc.data()?['nome'] ?? 'Corso';

            // Ottieni gli appelli aperti per questo corso
            final appelliSnapshot = await FirebaseFirestore.instance
                .collection('corsi')
                .doc(corsoId)
                .collection('appelli')
                .where('stato', isEqualTo: 'aperto')
                .get();

            return {
              'id': corsoId,
              'nome': corsoNome,
              'numAppelli': appelliSnapshot.docs.length,
            };
          })),
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

            final corsiConAppelli = snapshot.data ?? [];

            // Filtra solo i corsi con appelli aperti
            final corsiConAppelliAperti = corsiConAppelli.where((c) => c['numAppelli'] > 0).toList();

            if (corsiConAppelliAperti.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text(
                      'Nessun appello disponibile',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Al momento non ci sono appelli aperti nei tuoi corsi',
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

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: corsiConAppelliAperti.length,
              itemBuilder: (context, index) {
                final corso = corsiConAppelliAperti[index];

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
                          builder: (context) => AppelliStudenteScreen(
                            corsoId: corso['id'],
                            corsoNome: corso['nome'],
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                corso['nome'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${corso['numAppelli']} appelli disponibili',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.redAccent[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              color: Colors.redAccent[700],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildIscrizioniTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.getAppelliIscritto(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Errore nel caricamento delle iscrizioni: ${snapshot.error}',
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
                Icon(Icons.event_note, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'Nessuna iscrizione',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Non sei iscritto a nessun appello d\'esame',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent[700],
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        _tabController.animateTo(0); // Vai alla tab degli appelli disponibili
                      },
                      child: const Text('Vedi Appelli Disponibili'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.grading),
                      label: const Text('I miei voti'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent[700],
                        side: BorderSide(color: Colors.redAccent[700]!),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VotiStudentiScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Organizza gli appelli per stato e data
        final appelliPassati = appelli.where((a) =>
        (a['data'] as dynamic).toDate().isBefore(DateTime.now()) ||
            a['stato'] == 'valutato' ||
            a['stato'] == 'chiuso'
        ).toList();

        final appelliAttivi = appelli.where((a) =>
        (a['data'] as dynamic).toDate().isAfter(DateTime.now()) &&
            a['stato'] == 'aperto'
        ).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Pulsante per accedere ai voti nella parte superiore
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.grading, color: Colors.white),
                label: const Text('Visualizza tutti i voti'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent[700],
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VotiStudentiScreen(),
                    ),
                  );
                },
              ),
            ),

            if (appelliAttivi.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'APPELLI ATTIVI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
              ...appelliAttivi.map(_buildAppelloCard),
              const SizedBox(height: 24),
            ],

            if (appelliPassati.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'STORICO APPELLI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.grading, size: 16),
                    label: const Text('Vedi voti'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent[700],
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VotiStudentiScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...appelliPassati.map(_buildAppelloCard),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAppelloCard(Map<String, dynamic> appello) {
    final data = (appello['data'] as dynamic).toDate();
    final dataFormattata = DateFormat('EEE d MMM, HH:mm').format(data);
    final stato = appello['stato'] as String;
    final voto = appello['voto'];
    final statoStudente = appello['statoStudente'] as String;

    Color statoColor;
    IconData statoIcon;

    switch (stato) {
      case 'aperto':
        statoColor = Colors.green;
        statoIcon = Icons.event_available;
        break;
      case 'chiuso':
        statoColor = Colors.orange;
        statoIcon = Icons.event;
        break;
      case 'valutato':
        statoColor = Colors.blue;
        statoIcon = Icons.grading;
        break;
      default:
        statoColor = Colors.grey;
        statoIcon = Icons.event_note;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nome del corso
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statoIcon, size: 12, color: statoColor),
                      const SizedBox(width: 4),
                      Text(
                        stato.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: statoColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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

            if (appello['descrizione'] != null && appello['descrizione'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  appello['descrizione'],
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Stato studente e voto se disponibile
            if (stato == 'valutato') ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        statoStudente == 'presente' ? Icons.check_circle : Icons.cancel,
                        size: 18,
                        color: statoStudente == 'presente' ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statoStudente == 'presente' ? 'Presente' : 'Assente',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: statoStudente == 'presente' ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  if (voto != null && statoStudente == 'presente')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: voto >= 18 ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        voto.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: voto >= 18 ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                    ),
                ],
              ),
            ] else if (stato == 'aperto') ...[
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Cancella Iscrizione'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Conferma'),
                        content: const Text(
                            'Sei sicuro di voler cancellare la tua iscrizione a questo appello?'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('No'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _firebaseService.cancellaIscrizioneAppello(
                                appello['corsoId'],
                                appello['id'],
                              ).then((_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Iscrizione cancellata con successo'),
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
                            child: const Text('Sì'),
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