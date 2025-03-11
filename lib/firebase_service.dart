import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // 🔹 Ottiene tutti i corsi disponibili
  Stream<List<Map<String, dynamic>>> getCorsiDisponibili() {
    return _firestore.collection('corsi').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'nome': doc['nome'],
          'descrizione': doc['descrizione'],
        };
      }).toList();
    });
  }

  // 🔹 Ottiene i corsi a cui lo studente è iscritto
  Stream<List<String>> getCorsiIscritti() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || !doc.data()!.containsKey('corsi')) {
        return <String>[];
      }
      return List<String>.from(doc.data()!['corsi'] ?? []);
    });
  }

  // 🔹 Ottiene i dettagli completi dei corsi a cui lo studente è iscritto
  Stream<List<Map<String, dynamic>>> getDettagliCorsiIscritti() {
    return getCorsiIscritti().asyncMap((corsiIds) async {
      if (corsiIds.isEmpty) return [];

      List<Map<String, dynamic>> risultati = [];

      for (String corsoId in corsiIds) {
        final doc = await _firestore.collection('corsi').doc(corsoId).get();
        if (doc.exists) {
          risultati.add({
            'id': doc.id,
            ...doc.data()!
          });
        }
      }

      return risultati;
    });
  }

  // 🔹 Iscrive uno studente a un corso
  Future<void> iscrivitiAlCorso(String corsoId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print("Errore: utente non autenticato.");
      return;
    }

    DocumentReference userRef = _firestore.collection('users').doc(uid);
    await userRef.set({
      'corsi': FieldValue.arrayUnion([corsoId])
    }, SetOptions(merge: true));

    print("Iscritto con successo al corso: $corsoId");
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