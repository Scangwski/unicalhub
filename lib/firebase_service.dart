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
  Future<void> pubblicaPost(
      String corsoId,
      String contenuto,
      List<String> fileUrls,
      ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Ottieni info dell'utente con i nomi di campo corretti
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final firstName = userDoc.data()?['firstName'] ?? '';
    final lastName = userDoc.data()?['lastName'] ?? '';
    final fullName = '${firstName} ${lastName}'.trim();
    final displayName = fullName.isEmpty ? 'Utente' : fullName;

    await _firestore.collection('corsi').doc(corsoId).collection('posts').add({
      'autoreId': uid,
      'autoreNome': displayName,
      'contenuto': contenuto,
      'fileUrls': fileUrls,
      'creato_il': FieldValue.serverTimestamp(),
      'likes': [],
      'commenti': []
    });
  }

// Ottieni i post di un corso
  Stream<List<Map<String, dynamic>>> getPostsCorso(String corsoId) {
    return _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('posts')
        .orderBy('creato_il', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

// Aggiungi un like a un post
  Future<void> toggleLikePost(String corsoId, String postId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final postRef = _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('posts')
        .doc(postId);

    final postDoc = await postRef.get();
    final likes = List<String>.from(postDoc.data()?['likes'] ?? []);

    if (likes.contains(uid)) {
      // Rimuovi il like
      await postRef.update({
        'likes': FieldValue.arrayRemove([uid])
      });
    } else {
      // Aggiungi il like
      await postRef.update({
        'likes': FieldValue.arrayUnion([uid])
      });
    }
  }

// Update the aggiungiCommento function in firebase_service.dart
  Future<void> aggiungiCommento(
      String corsoId,
      String postId,
      String testo
      ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Ottieni info dell'utente con i nomi di campo corretti
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final firstName = userDoc.data()?['firstName'] ?? '';
    final lastName = userDoc.data()?['lastName'] ?? '';
    final fullName = '${firstName} ${lastName}'.trim();
    final displayName = fullName.isEmpty ? 'Utente' : fullName;

    // Create a regular timestamp here instead of serverTimestamp()
    final timestamp = Timestamp.now();

    final commento = {
      'autoreId': uid,
      'autoreNome': displayName,
      'testo': testo,
      'creato_il': timestamp,
    };

    await _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('posts')
        .doc(postId)
        .update({
      'commenti': FieldValue.arrayUnion([commento])
    });
  }
  // Elimina un post
  Future<void> eliminaPost(String corsoId, String postId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Verifica che l'utente sia l'autore del post o un docente del corso
    final postDoc = await _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('posts')
        .doc(postId)
        .get();

    if (!postDoc.exists) return;

    final postData = postDoc.data()!;
    final autoreId = postData['autoreId'] as String?;

    // Controlla se l'utente è l'autore del post
    bool isAuthor = autoreId == uid;

    // Controlla se l'utente è un docente del corso
    bool isDocente = false;
    if (!isAuthor) {
      final corsoDoc = await _firestore.collection('corsi').doc(corsoId).get();
      if (corsoDoc.exists) {
        final docenti = List<String>.from(corsoDoc.data()?['docenti'] ?? []);
        isDocente = docenti.contains(uid);
      }
    }

    if (isAuthor || isDocente) {
      // Elimina il post
      await _firestore
          .collection('corsi')
          .doc(corsoId)
          .collection('posts')
          .doc(postId)
          .delete();
    } else {
      throw Exception('Non hai i permessi per eliminare questo post');
    }
  }

// Elimina un commento da un post
  Future<void> eliminaCommento(String corsoId, String postId, Map<String, dynamic> commento) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Verifica che l'utente sia l'autore del commento o un docente del corso o l'autore del post
    final commentoAutoreId = commento['autoreId'] as String?;
    bool isCommentAuthor = commentoAutoreId == uid;

    if (!isCommentAuthor) {
      // Controlla se l'utente è un docente o l'autore del post
      final postDoc = await _firestore
          .collection('corsi')
          .doc(corsoId)
          .collection('posts')
          .doc(postId)
          .get();

      if (!postDoc.exists) return;

      final postData = postDoc.data()!;
      final postAutoreId = postData['autoreId'] as String?;
      bool isPostAuthor = postAutoreId == uid;

      // Controlla se l'utente è un docente
      bool isDocente = false;
      if (!isPostAuthor) {
        final corsoDoc = await _firestore.collection('corsi').doc(corsoId).get();
        if (corsoDoc.exists) {
          final docenti = List<String>.from(corsoDoc.data()?['docenti'] ?? []);
          isDocente = docenti.contains(uid);
        }
      }

      if (!isPostAuthor && !isDocente) {
        throw Exception('Non hai i permessi per eliminare questo commento');
      }
    }

    // Rimuovi il commento dall'array
    await _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('posts')
        .doc(postId)
        .update({
      'commenti': FieldValue.arrayRemove([commento])
    });
  }
}