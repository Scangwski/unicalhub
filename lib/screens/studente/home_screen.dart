import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unicalhub/firebase_service.dart';
import 'package:unicalhub/screens/chat_list_screen.dart';
import '../auth_screen.dart';
import '../voti_screen.dart';
import '../studente/corsi_studente_screen.dart';
import '../orario_screen.dart';
import '../chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FirebaseService _firebaseService = FirebaseService(); // Istanza del servizio


  // Funzione per gestire il cambio di indice nella bottom navigation bar
  void _onItemTapped(int index) {
    if (index == 0) {
      // Siamo già nella Home, quindi aggiorniamo solo l'indice
      setState(() {
        _selectedIndex = index;
      });
    } else if (index == 1) {
      // Naviga alla schermata dei corsi
      final currentUser = FirebaseAuth.instance.currentUser;
      final uid = currentUser?.uid ?? '';
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CorsiStudenteScreen(studenteId: uid)),
      );
    } else if (index == 2) {
      // Gestione della navigazione alle notifiche
      setState(() {
        _selectedIndex = index;
      });
      // Implementare qui la navigazione alla schermata delle notifiche
    } else if (index == 3) {
      // Gestione della navigazione al profilo
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
        backgroundColor: Colors.redAccent[700],
        title: const Text('UniCalHub', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con saluto personalizzato
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:Colors.redAccent[700],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Text(
                            username.isNotEmpty ? username[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Benvenuto, ${username.isNotEmpty ? username.toUpperCase() : "Studente"}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              email,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Dashboard Studente',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Sezione delle funzionalità principali
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Funzionalità',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Grid per le funzionalità
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                childAspectRatio: 1.3,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [

                  _buildFeatureCard(
                    context,
                    title: 'Corsi',
                    icon: Icons.my_library_books_outlined,
                    color: Colors.red[400]!,
                    onTap: () {
                      final uid = currentUser?.uid ?? '';
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CorsiStudenteScreen(studenteId: uid)),
                      );
                    },
                  ),

                  _buildFeatureCard(
                    context,
                    title: 'Chat',
                    icon: Icons.chat,
                    color: Colors.purple[400]!,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatListScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Sezione informazioni recenti
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attività Recenti',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Visualizza tutte le attività
                      },
                      child: Text(
                        'Vedi Tutto',
                        style: TextStyle(
                          color: Colors.indigo[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              // Lista attività recenti con StreamBuilder
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firebaseService.streamAttivitaRecenti(5), // Mostra le 5 attività più recenti
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Errore nel caricamento delle attività',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  }

                  final attivita = snapshot.data ?? [];

                  if (attivita.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'Nessuna attività recente',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: attivita.length,
                    itemBuilder: (context, index) {
                      final item = attivita[index];
                      return _buildActivityItem(
                        title: item['titolo'],
                        subtitle: item['subtitle'],
                        time: item['time'],
                        icon: IconData(item['icon'], fontFamily: 'MaterialIcons'),
                        color: Color(item['color']),
                        onTap: () {
                          // Naviga in base al tipo di attività
                          if (item['tipo'] == 'post') {
                            // Naviga al post specifico
                            // Implementare la navigazione al corso e al post
                          } else if (item['tipo'] == 'messaggio') {
                            // Naviga alla chat
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatListScreen(),
                              ),
                            );
                          } else if (item['tipo'] == 'lezione') {
                            // Naviga alla lezione/presenze
                            // Implementare la navigazione
                          }
                        },
                      );
                    },
                  );
                },
              ),


            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo[700],
        unselectedItemColor: Colors.grey[600],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Corsi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifiche',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profilo',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}