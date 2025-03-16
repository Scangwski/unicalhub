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
  // Ottiene gli studenti iscritti a un corso specifico
  Future<List<Map<String, dynamic>>> getStudentiIscritti(String corsoId) async {
    final querySnapshot = await _firestore.collection('users').where('corsi', arrayContains: corsoId).get();

    return querySnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'firstName': doc.data()['firstName'] ?? '',
        'lastName': doc.data()['lastName'] ?? '',
        'email': doc.data()['email'] ?? '',
      };
    }).toList();
  }

// Registra la presenza di uno studente per una lezione specifica
  Future<void> registraPresenza(String corsoId, String lezioneId, String studenteId, bool presente) async {
    await _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('lezioni')
        .doc(lezioneId)
        .collection('presenze')
        .doc(studenteId)
        .set({
      'presente': presente,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

// Crea una nuova lezione per un corso
  Future<String> creaLezione(String corsoId, String titolo, String data) async {
    final docRef = await _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('lezioni')
        .add({
      'titolo': titolo,
      'data': data,
      'creato_il': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

// Ottiene tutte le lezioni di un corso
  Stream<List<Map<String, dynamic>>> getLezioniCorso(String corsoId) {
    return _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('lezioni')
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

// Ottiene le presenze di una lezione specifica
  Future<Map<String, bool>> getPresenzeLezione(String corsoId, String lezioneId) async {
    final querySnapshot = await _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('lezioni')
        .doc(lezioneId)
        .collection('presenze')
        .get();

    Map<String, bool> presenze = {};
    for (var doc in querySnapshot.docs) {
      presenze[doc.id] = doc.data()['presente'] ?? false;
    }

    return presenze;
  }
  // Ottiene le presenze di tutti gli studenti per un corso specifico
  Future<List<Map<String, dynamic>>> getPresenzePerStudente(String corsoId) async {
    // Ottieni tutti gli studenti iscritti al corso
    final studenti = await getStudentiIscritti(corsoId);

    // Ottieni tutte le lezioni del corso
    final lezioniSnapshot = await _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('lezioni')
        .orderBy('data')
        .get();

    List<Map<String, dynamic>> risultato = [];

    // Per ogni studente, recupera le presenze per ogni lezione
    for (var studente in studenti) {
      final studenteId = studente['id'];
      final studenteNome = '${studente['firstName']} ${studente['lastName']}';

      Map<String, dynamic> presenzeStudente = {
        'id': studenteId,
        'nome': studenteNome,
        'email': studente['email'],
        'presenze': <Map<String, dynamic>>[],
        'statistiche': {
          'totaleLezioni': lezioniSnapshot.docs.length,
          'presenze': 0,
          'assenze': 0,
          'percentualePresenza': 0.0
        }
      };

      // Per ogni lezione, verifica se lo studente era presente
      for (var lezioneDoc in lezioniSnapshot.docs) {
        final lezioneId = lezioneDoc.id;
        final lezioneData = lezioneDoc.data();

        // Cerca la presenza dello studente per questa lezione
        final presenzaDoc = await _firestore
            .collection('corsi')
            .doc(corsoId)
            .collection('lezioni')
            .doc(lezioneId)
            .collection('presenze')
            .doc(studenteId)
            .get();

        final presente = presenzaDoc.exists && presenzaDoc.data()?['presente'] == true;

        // Aggiungi all'elenco delle presenze dello studente
        presenzeStudente['presenze'].add({
          'lezioneId': lezioneId,
          'titolo': lezioneData['titolo'],
          'data': lezioneData['data'],
          'presente': presente
        });

        // Aggiorna le statistiche
        if (presente) {
          presenzeStudente['statistiche']['presenze'] += 1;
        } else {
          presenzeStudente['statistiche']['assenze'] += 1;
        }
      }

      // Calcola la percentuale di presenza
      final totaleLezioni = presenzeStudente['statistiche']['totaleLezioni'];
      final presenze = presenzeStudente['statistiche']['presenze'];

      if (totaleLezioni > 0) {
        presenzeStudente['statistiche']['percentualePresenza'] =
            (presenze / totaleLezioni * 100).toDouble();
      }

      risultato.add(presenzeStudente);
    }

    // Ordina per percentuale di presenza decrescente
    risultato.sort((a, b) {
      final percA = a['statistiche']['percentualePresenza'] as double;
      final percB = b['statistiche']['percentualePresenza'] as double;
      return percB.compareTo(percA);
    });

    return risultato;
  }
  /// Ottiene la lista di chat dell'utente corrente
  Stream<List<Map<String, dynamic>>> getChats() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    // Versione senza orderBy che non richiede un indice composito
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return [];

      // Ottieni tutti i documenti e ordina lato client
      final chats = snapshot.docs.map((doc) {
        final data = doc.data();

        final participants = List<String>.from(data['participants'] ?? []);
        String otherUserId = '';

        if (participants.isNotEmpty) {
          otherUserId = participants.firstWhere(
                  (id) => id != uid,
              orElse: () => ''
          );
        }

        final participantNames = data['participantNames'] as Map<String, dynamic>? ?? {};
        final unreadCounts = data['unreadCount'] as Map<String, dynamic>? ?? {};

        return {
          'id': doc.id,
          'otherUserId': otherUserId,
          'otherUserName': participantNames[otherUserId] ?? 'Utente',
          'lastMessage': data['lastMessage'] ?? '',
          'timestamp': data['lastMessageTimestamp'],
          'unreadCount': unreadCounts[uid] ?? 0,
        };
      }).toList();

      // Ordina i documenti manualmente per timestamp decrescente
      chats.sort((a, b) {
        final timestampA = a['timestamp'] as Timestamp?;
        final timestampB = b['timestamp'] as Timestamp?;

        if (timestampA == null && timestampB == null) return 0;
        if (timestampA == null) return 1;
        if (timestampB == null) return -1;

        return timestampB.compareTo(timestampA);
      });

      return chats;
    });
  }

  /// Ottiene tutti gli utenti disponibili per chattare (escluso l'utente corrente)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final querySnapshot = await _firestore.collection('users').get();

    return querySnapshot.docs
        .where((doc) => doc.id != uid)
        .map((doc) {
      final data = doc.data();
      final firstName = data['firstName'] ?? '';
      final lastName = data['lastName'] ?? '';
      final fullName = '${firstName} ${lastName}'.trim();

      return {
        'id': doc.id,
        'name': fullName.isEmpty ? 'Utente' : fullName,
        'email': data['email'] ?? '',
      };
    })
        .toList();
  }

  /// Ottiene il numero totale di messaggi non letti per l'utente corrente
  Stream<int> getTotalUnreadMessages() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final unreadCount = doc.data()['unreadCount']?[uid] ?? 0;
        total += unreadCount as int;
      }
      return total;
    });
  }

  /// Elimina un messaggio specifico
  Future<void> deleteMessage(String chatId, String messageId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Verifica che l'utente sia il mittente del messaggio
    final messageDoc = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (!messageDoc.exists) return;

    final messageData = messageDoc.data()!;
    if (messageData['senderId'] != uid) {
      throw Exception('Non hai i permessi per eliminare questo messaggio');
    }

    // Elimina il messaggio
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

}