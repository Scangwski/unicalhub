import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unicalhub/firebase_service.dart';
import 'package:unicalhub/screens/chat/chat_list_screen.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unicalhub/screens/professore/appelli_professore_screen.dart';
import 'package:unicalhub/screens/professore/statistiche_screen.dart';
import '../auth_screen.dart';
import '../studente/voti_screen.dart';
import 'corsi_professore_screen.dart';
import '../orario_screen.dart';
import '../chat/chat_screen.dart';

class ProfessoreScreen extends StatefulWidget {
  const ProfessoreScreen({Key? key}) : super(key: key);

  @override
  State<ProfessoreScreen> createState() => _ProfessoreScreenState();
}

class _ProfessoreScreenState extends State<ProfessoreScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final FirebaseService _firebaseService = FirebaseService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Funzione per gestire il cambio di indice nella bottom navigation bar
  void _onItemTapped(int index) {
    if (index == 0) {
      setState(() {
        _selectedIndex = index;
      });
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CorsiScreen()),
      );
    } else if (index == 2) {
      setState(() {
        _selectedIndex = index;
      });
      // Implementare qui la navigazione alla schermata delle notifiche
    } else if (index == 3) {
      setState(() {
        _selectedIndex = index;
      });
      // Implementare qui la navigazione alla schermata del profilo
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final email = currentUser?.email ?? '';
    final username = email.split('@')[0]; // Estrae lo username dall'email

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo.shade700,
        title: Text(
            'UnicalHub',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 22
            )
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'Notifiche',
            onPressed: () {
              // Azione per le notifiche
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              // Mostra un dialogo di conferma prima del logout
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'Conferma Logout',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'Sei sicuro di voler uscire dall\'applicazione?',
                      style: GoogleFonts.poppins(),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text(
                          'Annulla',
                          style: GoogleFonts.poppins(color: Colors.grey[700]),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Logout',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const AuthScreen()),
                                (Route<dynamic> route) => false,
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            color: Colors.indigo[700],
            onRefresh: () async {
              // Implementa il refresh dei dati
              await Future.delayed(const Duration(seconds: 1));
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con saluto personalizzato
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.indigo.shade700,
                          Colors.blue.shade500,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(26),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white,
                                child: Text(
                                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo[700],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Benvenuto,',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withAlpha(230),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    username.isNotEmpty ? username.toUpperCase() : "Professore",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    email,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withAlpha(204),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Dashboard Professore',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sezione delle funzionalità principali
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Funzionalità',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.indigo[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Professore',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Grid per le funzionalità
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildFeatureCard(
                        context,
                        title: 'Corsi',
                        subtitle: 'I tuoi corsi attuali',
                        icon: Icons.my_library_books_outlined,
                        color: Colors.red[400]!,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CorsiScreen()),
                        ),
                      ),

                      _buildFeatureCard(
                        context,
                        title: 'Chat',
                        subtitle: 'Messaggi e discussioni',
                        icon: Icons.chat_bubble_outline,
                        color: Colors.purple[700]!,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChatListScreen()),
                        ),
                      ),

                      _buildFeatureCard(
                        context,
                        title: 'Appelli',
                        subtitle: 'Gestione esami',
                        icon: Icons.event_note,
                        color: Colors.green[700]!,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AppelliProfessoreScreen()),
                        ),
                      ),

                      _buildFeatureCard(
                        context,
                        title: 'Statistiche',
                        subtitle: 'Analisi e dati',
                        icon: Icons.bar_chart,
                        color: Colors.amber[700]!,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const StatisticheProfessoreScreen()),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Sezione informazioni recenti
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Attività Recenti',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            // Visualizza tutte le attività
                          },
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: Text(
                            'Vedi Tutto',
                            style: GoogleFonts.poppins(
                              color: Colors.indigo[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lista attività recenti con StreamBuilder
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _firebaseService.streamAttivitaRecenti(5),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Icon(Icons.error_outline, size: 50, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'Errore nel caricamento delle attività',
                                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {});
                                  },
                                  child: Text(
                                    'Riprova',
                                    style: GoogleFonts.poppins(
                                      color: Colors.indigo[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final attivita = snapshot.data ?? [];

                      if (attivita.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Column(
                              children: [
                                Icon(Icons.inbox, size: 50, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'Nessuna attività recente',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(13),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: attivita.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Colors.grey[200],
                            height: 1,
                            indent: 70,
                            endIndent: 20,
                          ),
                          itemBuilder: (context, index) {
                            final item = attivita[index];
                            return _buildActivityItem(
                              title: item['titolo'],
                              subtitle: item['subtitle'],
                              time: item['time'],
                              icon: IconData(
                                  (item['icon'] is int) ? item['icon'] : item['icon'].toInt(),
                                  fontFamily: 'MaterialIcons'
                              ),
                              color: Color(item['color']),
                              onTap: () {
                                // Naviga in base al tipo di attività
                                if (item['tipo'] == 'post') {
                                  // Naviga al post specifico
                                } else if (item['tipo'] == 'messaggio') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatListScreen(),
                                    ),
                                  );
                                } else if (item['tipo'] == 'lezione') {
                                  // Naviga alla lezione/presenze
                                }
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          elevation: 10,
          selectedItemColor: Colors.indigo[700],
          selectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
          ),
          unselectedItemColor: Colors.grey[600],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Corsi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Notifiche',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profilo',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withAlpha(26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                time,
                style: GoogleFonts.poppins(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}