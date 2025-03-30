import 'package:flutter/material.dart';
import 'package:unicalhub/firebase_service.dart';
import 'package:intl/intl.dart';

class DettaglioAppelloScreen extends StatefulWidget {
  final String corsoId;
  final String appelloId;
  final Map<String, dynamic> appelloData;

  const DettaglioAppelloScreen({
    Key? key,
    required this.corsoId,
    required this.appelloId,
    required this.appelloData,
  }) : super(key: key);

  @override
  State<DettaglioAppelloScreen> createState() => _DettaglioAppelloScreenState();
}

class _DettaglioAppelloScreenState extends State<DettaglioAppelloScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final iscritti = List<Map<String, dynamic>>.from(widget.appelloData['iscritti'] ?? []);
    final data = (widget.appelloData['data'] as dynamic).toDate();
    final dataFormattata = DateFormat('EEEE d MMMM yyyy, HH:mm').format(data);
    final stato = widget.appelloData['stato'] as String;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.indigo[700],
          title: Text(
            widget.appelloData['titolo'] ?? 'Dettaglio Appello',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'ISCRITTI'),
              Tab(text: 'DETTAGLI'),
            ],
            indicatorColor: Colors.white,
            indicatorWeight: 3,
          ),
        ),
        body: TabBarView(
          children: [
            // Tab Iscritti
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                iscritti.length.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              const Text('Iscritti'),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                iscritti.where((i) => i['stato'] == 'presente').length.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Text('Presenti'),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                iscritti.where((i) => i['stato'] == 'assente').length.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const Text('Assenti'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: iscritti.isEmpty
                        ? Center(
                      child: Text(
                        'Nessuno studente iscritto',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    )
                        : ListView.builder(
                      itemCount: iscritti.length,
                      itemBuilder: (context, index) {
                        final iscritto = iscritti[index];
                        final nome = iscritto['nome'] ?? 'Studente';
                        final statoStudente = iscritto['stato'] ?? 'iscritto';
                        final voto = iscritto['voto'];

                        Color statusColor;
                        IconData statusIcon;

                        switch (statoStudente) {
                          case 'presente':
                            statusColor = Colors.green;
                            statusIcon = Icons.check_circle;
                            break;
                          case 'assente':
                            statusColor = Colors.red;
                            statusIcon = Icons.cancel;
                            break;
                          default:
                            statusColor = Colors.grey;
                            statusIcon = Icons.person;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: statusColor.withOpacity(0.1),
                              child: Icon(statusIcon, color: statusColor),
                            ),
                            title: Text(nome),
                            subtitle: Text(iscritto['email'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (stato == 'chiuso' || stato == 'valutato')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: voto != null
                                          ? (voto >= 18 ? Colors.green[100] : Colors.red[100])
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      voto?.toString() ?? '-',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: voto != null
                                            ? (voto >= 18 ? Colors.green[800] : Colors.red[800])
                                            : Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                if (stato == 'chiuso')
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) {
                                      if (value == 'presente' || value == 'assente') {
                                        _firebaseService.registraPresenzaAppello(
                                          widget.corsoId,
                                          widget.appelloId,
                                          iscritto['id'],
                                          value == 'presente',
                                        ).then((_) {
                                          setState(() {
                                            // Aggiornamento UI gestito dal widget StreamBuilder
                                          });
                                        });
                                      } else if (value == 'voto') {
                                        _showInsertVotoDialog(
                                          context,
                                          iscritto['id'],
                                          nome,
                                          voto,
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem<String>(
                                        value: 'presente',
                                        child: Text('Segna come presente'),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'assente',
                                        child: Text('Segna come assente'),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'voto',
                                        child: Text('Inserisci voto'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  if (stato == 'chiuso' && iscritti.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            // Verifica se tutti gli studenti hanno un voto
                            bool tuttiValutati = true;
                            for (var iscritto in iscritti) {
                              if (iscritto['stato'] == 'presente' && iscritto['voto'] == null) {
                                tuttiValutati = false;
                                break;
                              }
                            }

                            if (!tuttiValutati) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Attenzione'),
                                  content: const Text(
                                      'Non tutti gli studenti presenti hanno un voto assegnato. '
                                          'Vuoi procedere comunque?'
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('No'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _completaAppello();
                                      },
                                      child: const Text('Sì, procedi'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              _completaAppello();
                            }
                          },
                          child: const Text(
                            'COMPLETA VALUTAZIONE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Tab Dettagli
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.appelloData['titolo'] ?? 'Appello d\'esame',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.indigo[700]),
                              const SizedBox(width: 8),
                              Text(
                                dataFormattata,
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Icon(Icons.people, color: Colors.indigo[700]),
                              const SizedBox(width: 8),
                              Text(
                                '${iscritti.length} iscritti',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.indigo[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Stato: ${stato.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),

                          if (widget.appelloData['descrizione'] != null &&
                              widget.appelloData['descrizione'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Descrizione:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.appelloData['descrizione'],
                                    style: const TextStyle(
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bottoni di azione in base allo stato
                  if (stato == 'aperto')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.lock),
                        label: const Text(
                          'CHIUDI ISCRIZIONI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Conferma'),
                              content: const Text(
                                'Sei sicuro di voler chiudere le iscrizioni? '
                                    'Questa azione non può essere annullata.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Annulla'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _firebaseService.chiudiAppello(
                                      widget.corsoId,
                                      widget.appelloId,
                                    ).then((_) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Iscrizioni chiuse con successo'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      Navigator.pop(context); // Torna alla lista appelli
                                    }).catchError((error) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Errore: $error'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    });
                                  },
                                  child: const Text('Conferma'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  // Solo se lo stato è valutato, mostra le statistiche
                  if (stato == 'valutato')
                    FutureBuilder<Map<String, dynamic>>(
                      future: _firebaseService.getStatisticheAppelli(widget.corsoId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Errore nel caricamento delle statistiche',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          );
                        }

                        final stats = snapshot.data ?? {};
                        final distribuzione = List<Map<String, dynamic>>.from(stats['distribuzione'] ?? []);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Statistiche Esame',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildStatCard('Media', '${stats['mediaVoti']?.toStringAsFixed(1) ?? "-"}'),
                                        _buildStatCard('Presenti', '${stats['totalePresenti'] ?? 0}'),
                                        _buildStatCard('Iscritti', '${stats['totaleIscritti'] ?? 0}'),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    const Text(
                                      'Distribuzione Voti',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    ...distribuzione.map((fascia) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 60,
                                              child: Text(
                                                fascia['fascia'],
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                            Expanded(
                                              child: LinearProgressIndicator(
                                                // Aggiungere un controllo per evitare divisione per zero
                                                value: stats['totalePresenti'] > 0
                                                    ? (fascia['numero'] / stats['totalePresenti'])
                                                    : 0,
                                                backgroundColor: Colors.grey[200],
                                                color: _getColorForVotoFascia(fascia['fascia']),
                                                minHeight: 8,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(fascia['numero'].toString()),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo[700],
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.indigo[400],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForVotoFascia(String fascia) {
    switch (fascia) {
      case '< 18':
        return Colors.red[400]!;
      case '18-20':
        return Colors.orange[400]!;
      case '21-23':
        return Colors.amber[400]!;
      case '24-26':
        return Colors.lime[600]!;
      case '27-29':
        return Colors.green[400]!;
      case '30/30L':
        return Colors.indigo[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  void _showInsertVotoDialog(BuildContext context, String studenteId, String nome, dynamic votoAttuale) {
    final votoController = TextEditingController(text: votoAttuale?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Voto per $nome'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: votoController,
              decoration: const InputDecoration(
                labelText: 'Voto',
                hintText: 'Inserisci un valore da 0 a 30 o 30L',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (var quickVoto in ['18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '30L'])
                  ElevatedButton(
                    onPressed: () {
                      votoController.text = quickVoto;
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: const Size(40, 24),
                    ),
                    child: Text(quickVoto),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final voto = votoController.text;
              if (voto.isEmpty) {
                return;
              }

              // Gestisci il caso speciale "30L"
              dynamic valoreDaSalvare;
              if (voto == '30L') {
                valoreDaSalvare = 30; // oppure un altro valore/flag per indicare la lode
              } else {
                valoreDaSalvare = int.tryParse(voto);
                if (valoreDaSalvare == null || valoreDaSalvare < 0 || valoreDaSalvare > 30) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Inserisci un voto valido (0-30 o 30L)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              }

              Navigator.pop(context);
              _firebaseService.registraVotoAppello(
                widget.corsoId,
                widget.appelloId,
                studenteId,
                valoreDaSalvare,
              ).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Voto registrato con successo'),
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
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  void _completaAppello() {
    _firebaseService.completaValutazioneAppello(
      widget.corsoId,
      widget.appelloId,
    ).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Valutazione completata con successo'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Torna alla lista appelli
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
}