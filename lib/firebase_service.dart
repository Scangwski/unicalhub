import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ottiene i corsi a cui partecipa il professore attuale
  Stream<List<Map<String, dynamic>>> getCorsiDelProfessore() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore.collection('corsi')
        .where('docenti', arrayContains: uid)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  /// Aggiunge un nuovo corso
  Future<void> aggiungiCorso(String nome, String descrizione) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('corsi').add({
      'nome': nome,
      'descrizione': descrizione,
      'docenti': [uid], // Lista di professori che insegnano il corso
      'creato_il': FieldValue.serverTimestamp(),
    });
  }
}
