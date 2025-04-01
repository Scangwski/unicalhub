import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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

  Future<void> _updateUserRole(String userId, String role, bool newValue) async {
    try {
      await _firestore.collection('users').doc(userId).update({role: newValue});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ruolo ${role.toUpperCase()} aggiornato con successo',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Errore nell\'aggiornamento del ruolo: $error',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.redAccent[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.redAccent[700],
        title: Text(
          'Gestione Utenti',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Aggiorna',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.redAccent[700],
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Cerca utenti...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: GoogleFonts.poppins(),
              ),
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Nessun utente trovato',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final users = snapshot.data!.docs;

                  // Filtra utenti in base alla ricerca
                  final filteredUsers = users.where((user) {
                    final userData = user.data() as Map<String, dynamic>;
                    final firstName = userData['firstName']?.toString().toLowerCase() ?? '';
                    final lastName = userData['lastName']?.toString().toLowerCase() ?? '';
                    final email = userData['email']?.toString().toLowerCase() ?? '';

                    return firstName.contains(_searchQuery) ||
                        lastName.contains(_searchQuery) ||
                        email.contains(_searchQuery);
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Text(
                        'Nessun risultato per "$_searchQuery"',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final userData = user.data() as Map<String, dynamic>;
                      final bool isAdmin = userData['admin'] ?? false;
                      final bool isProfessore = userData['professore'] ?? false;
                      final String firstName = userData['firstName'] ?? '';
                      final String lastName = userData['lastName'] ?? '';
                      final String email = userData['email'] ?? '';

                      return Card(
                        elevation: 2,
                        shadowColor: Colors.black.withAlpha(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.redAccent[700],
                                    radius: 24,
                                    child: Text(
                                      firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$firstName $lastName',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          email,
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildRoleToggle(
                                    label: 'Admin',
                                    value: isAdmin,
                                    onChanged: (value) => _updateUserRole(user.id, 'admin', value),
                                    activeColor: Colors.redAccent[700]!,
                                    icon: Icons.admin_panel_settings,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildRoleToggle(
                                    label: 'Professore',
                                    value: isProfessore,
                                    onChanged: (value) => _updateUserRole(user.id, 'professore', value),
                                    activeColor: Colors.blue[700]!,
                                    icon: Icons.school,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), // Ridotto il padding orizzontale
        decoration: BoxDecoration(
          color: value ? activeColor.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? activeColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Avvolto con Expanded per evitare overflow
            Expanded(
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16, // Ridotta la dimensione dell'icona
                    color: value ? activeColor : Colors.grey[600],
                  ),
                  const SizedBox(width: 4), // Ridotto lo spazio
                  // Testo ridimensionabile
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: value ? activeColor : Colors.grey[700],
                        fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 12, // Ridotta la dimensione del testo
                      ),
                      overflow: TextOverflow.ellipsis, // Gestisce eventuali testi troppo lunghi
                    ),
                  ),
                ],
              ),
            ),
            // Switch più compatto
            Transform.scale(
              scale: 0.8, // Riduce la dimensione dello switch
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: activeColor,
                activeTrackColor: activeColor.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}