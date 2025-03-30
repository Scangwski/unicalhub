import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VotiStudentiScreen extends StatefulWidget {
  @override
  _VotiStudentiScreenState createState() => _VotiStudentiScreenState();
}

class _VotiStudentiScreenState extends State<VotiStudentiScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('I miei voti'),
      ),
      body: user == null
          ? Center(child: Text('Devi essere autenticato per vedere i voti'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('iscrizioni')
            .where('studenteId', isEqualTo: user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Nessun voto disponibile'));
          }

          var iscrizioni = snapshot.data!.docs;

          return ListView.builder(
            itemCount: iscrizioni.length,
            itemBuilder: (context, index) {
              var data = iscrizioni[index].data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('Materia: ${data['materia']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Data appello: ${data['dataAppello']}'),
                      Text('Voto: ${data['voto'] ?? 'Non assegnato'}'),
                      Text('Esito: ${data['esito'] ?? 'In attesa'}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
