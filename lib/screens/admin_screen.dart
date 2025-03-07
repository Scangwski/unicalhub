import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _updateUserRole(String userId, String role, bool newValue) async {
    try {
      await _firestore.collection('users').doc(userId).update({role: newValue});
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nell\'aggiornamento del ruolo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestione Utenti')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nessun utente trovato.'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userData = user.data() as Map<String, dynamic>;
              final bool isAdmin = userData['admin'] ?? false;
              final bool isProfessore = userData['professore'] ?? false;

              return ListTile(
                title: Text('${userData['firstName']} ${userData['lastName']}'),
                subtitle: Text(userData['email']),
                trailing: Wrap(  // 🔥 Wrap evita l'overflow!
                  spacing: 20, // Distanza tra gli switch
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Admin'),
                        Switch(
                          value: isAdmin,
                          onChanged: (value) => _updateUserRole(user.id, 'admin', value),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Professore'),
                        Switch(
                          value: isProfessore,
                          onChanged: (value) => _updateUserRole(user.id, 'professore', value),
                        ),
                      ],
                    ),
                  ],
                ),
              );

            },
          );
        },
      ),
    );
  }
}
