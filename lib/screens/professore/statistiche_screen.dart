import 'package:flutter/material.dart';
import 'package:unicalhub/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatisticheProfessoreScreen extends StatefulWidget {
  const StatisticheProfessoreScreen({Key? key}) : super(key: key);

  @override
  State<StatisticheProfessoreScreen> createState() => _StatisticheProfessoreScreenState();
}

class _StatisticheProfessoreScreenState extends State<StatisticheProfessoreScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String? _selectedCorsoId;
  String? _selectedCorsoNome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo[700],
        title: const Text(
          'Statistiche Corsi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _selectedCorsoId == null
          ? _buildSelezionaCorsoView()
          : _buildStatisticheCorsoView(),
    );
  }

  Widget _buildSelezionaCorsoView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _firebaseService.getCorsiDelProfessore().first,
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

        final corsi = snapshot.data ?? [];

        if (corsi.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Nessun corso trovato',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Non sei docente di nessun corso',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Seleziona un corso per visualizzarne le statistiche:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...corsi.map((corso) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCorsoId = corso['id'];
                      _selectedCorsoNome = corso['nome'];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.indigo[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.school,
                              color: Colors.indigo[700],
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
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
                                'Studenti iscritti: ${corso['numStudenti'] ?? 0}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[400],
                          size: 16,
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
  }

  Widget _buildStatisticheCorsoView() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _firebaseService.getStatisticheAppelli(_selectedCorsoId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Errore nel caricamento delle statistiche: ${snapshot.error}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        final stats = snapshot.data ?? {};
        // Add null safety check for totaleAppelli
        final hasData = (stats['totaleAppelli'] ?? 0) > 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con info corso
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.indigo[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.school,
                              color: Colors.indigo[700],
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedCorsoNome ?? 'Corso',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Statistiche e rendimento',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!hasData) ...[
                        const SizedBox(height: 20),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nessun dato disponibile',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Non ci sono ancora appelli valutati per questo corso',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (hasData) ...[
                const SizedBox(height: 24),

                // Statistiche principali
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Appelli',
                        '${stats['totaleAppelli'] ?? 0}',
                        Icons.event_note,
                        Colors.indigo,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Studenti',
                        '${stats['totaleIscritti'] ?? 0}',
                        Icons.people,
                        Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Media',
                        '${(stats['mediaVoti'] ?? 0.0).toStringAsFixed(1)}',
                        Icons.school,
                        Colors.amber,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Grafico distribuzione voti
                const Text(
                  'Distribuzione dei Voti',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ..._buildDistribuzioneVoti(stats),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Tassi di superamento e presenza
                const Text(
                  'Tassi di Superamento e Presenza',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildPercentageCard(
                        'Superamento',
                        // Added null safety
                        (stats['totaleIscritti'] ?? 0) > 0 && (stats['studentiPromossi'] ?? 0) > 0
                            ? ((stats['studentiPromossi'] ?? 0) / (stats['totaleIscritti'] ?? 1) * 100).round()
                            : 0,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPercentageCard(
                        'Presenza',
                        // Added null safety
                        (stats['totaleIscritti'] ?? 0) > 0 && (stats['totalePresenti'] ?? 0) > 0
                            ? ((stats['totalePresenti'] ?? 0) / (stats['totaleIscritti'] ?? 1) * 100).round()
                            : 0,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Pulsante per selezionare un altro corso
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Seleziona un altro corso'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedCorsoId = null;
                      _selectedCorsoNome = null;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, MaterialColor color) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color[700],
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDistribuzioneVoti(Map<String, dynamic> stats) {
    final List<Map<String, dynamic>> distribuzione = List<Map<String, dynamic>>.from(stats['distribuzione'] ?? []);

    if (distribuzione.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Nessun dato disponibile'),
          ),
        ),
      ];
    }

    // Trova il valore massimo per calcolare le percentuali
    int maxValue = 0;
    for (var fascia in distribuzione) {
      final numero = fascia['numero'] ?? 0;
      if (numero > maxValue) {
        maxValue = numero;
      }
    }

    return distribuzione.map((fascia) {
      // Assicurati che 'numero' non sia null
      final int numero = fascia['numero'] ?? 0;

      // Calcola percentuale in modo sicuro con null check migliorato
      final percentage = (maxValue > 0 && (stats['totalePresenti'] ?? 0) > 0)
          ? (numero / (stats['totalePresenti'] ?? 1) * 100).round()
          : 0;

      Color barColor;
      switch (fascia['fascia']) {
        case '< 18':
          barColor = Colors.red[400]!;
          break;
        case '18-20':
          barColor = Colors.orange[400]!;
          break;
        case '21-23':
          barColor = Colors.amber[400]!;
          break;
        case '24-26':
          barColor = Colors.lime[500]!;
          break;
        case '27-29':
          barColor = Colors.green[500]!;
          break;
        case '30/30L':
          barColor = Colors.indigo[500]!;
          break;
        default:
          barColor = Colors.grey[400]!;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                fascia['fascia'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calcola la larghezza della barra in modo sicuro
                  double barWidth = 0;
                  if (maxValue > 0) {
                    barWidth = constraints.maxWidth * (numero / maxValue);
                  }

                  return Stack(
                    children: [
                      Container(
                        height: 24,
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      Container(
                        height: 24,
                        width: barWidth, // Usa il valore calcolato in modo sicuro
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$numero',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildPercentageCard(String title, int percentage, MaterialColor color) {
    final safePercentage = percentage.clamp(0, 100);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color[800],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                children: [
                  Center(
                    child: SizedBox(
                      height: 100,
                      width: 100,
                      child: CircularProgressIndicator(
                        value: safePercentage / 100.0,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color[400]!),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}