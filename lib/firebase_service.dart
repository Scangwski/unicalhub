import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  //  Ottiene tutti i corsi disponibili
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

  Future<void> pubblicaPost(String corsoId,
      String contenuto,
      List<String> fileUrls,) async {
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
  Future<void> aggiungiCommento(String corsoId,
      String postId,
      String testo) async {
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
  Future<void> eliminaCommento(String corsoId, String postId,
      Map<String, dynamic> commento) async {
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
        final corsoDoc = await _firestore.collection('corsi')
            .doc(corsoId)
            .get();
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
    final querySnapshot = await _firestore.collection('users').where(
        'corsi', arrayContains: corsoId).get();

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
  Future<void> registraPresenza(String corsoId, String lezioneId,
      String studenteId, bool presente) async {
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
  Future<Map<String, bool>> getPresenzeLezione(String corsoId,
      String lezioneId) async {
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
  Future<List<Map<String, dynamic>>> getPresenzePerStudente(
      String corsoId) async {
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

        final presente = presenzaDoc.exists &&
            presenzaDoc.data()?['presente'] == true;

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

        final participantNames = data['participantNames'] as Map<String,
            dynamic>? ?? {};
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

  // Struttura dati per le notifiche
  Future<List<Map<String, dynamic>>> getAttivitaRecenti(int limit) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    List<Map<String, dynamic>> attivita = [];

    // 1. Ottieni nuovi post nei corsi a cui sei iscritto (per studenti) o che insegni (per docenti)
    List<String> corsiIds = [];

    // Per studenti
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists && userDoc.data()!.containsKey('corsi')) {
      corsiIds.addAll(List<String>.from(userDoc.data()!['corsi'] ?? []));
    }

    // Per docenti
    final corsiDocenti = await _firestore.collection('corsi')
        .where('docenti', arrayContains: uid)
        .get();

    corsiDocenti.docs.forEach((doc) {
      if (!corsiIds.contains(doc.id)) {
        corsiIds.add(doc.id);
      }
    });

    // Raccolta post recenti da tutti i corsi pertinenti
    for (String corsoId in corsiIds) {
      final corsoDoc = await _firestore.collection('corsi').doc(corsoId).get();
      final String nomeCorso = corsoDoc.data()?['nome'] ?? 'Corso';

      final posts = await _firestore
          .collection('corsi')
          .doc(corsoId)
          .collection('posts')
          .orderBy('creato_il', descending: true)
          .limit(3)
          .get();

      for (var post in posts.docs) {
        // Escludi i post creati dall'utente corrente
        if (post.data()['autoreId'] != uid) {
          attivita.add({
            'tipo': 'post',
            'titolo': 'Nuovo post in $nomeCorso',
            'subtitle': '${post
                .data()['autoreNome']} ha pubblicato un nuovo post',
            'time': _formatTimestamp(post.data()['creato_il']),
            'icon': Icons.description.codePoint,
            'color': Colors.blue[600]!.value,
            'corsoId': corsoId,
            'postId': post.id,
            'timestamp': post.data()['creato_il'],
          });
        }
      }
    }

    // 2. Ottieni nuovi messaggi nelle chat
    final chats = await _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .get();

    for (var chat in chats.docs) {
      final messages = await _firestore
          .collection('chats')
          .doc(chat.id)
          .collection('messages')
          .where('senderId', isNotEqualTo: uid) // Solo messaggi ricevuti
          .orderBy('senderId') // Necessario per usare il where non equals
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      for (var message in messages.docs) {
        // Verifica se il messaggio è stato letto
        final unreadCounts = chat.data()['unreadCount'] as Map<String,
            dynamic>? ?? {};
        final int unreadCount = unreadCounts[uid] ?? 0;

        if (unreadCount > 0) {
          final senderName = chat.data()['participantNames'][message
              .data()['senderId']] ?? 'Utente';

          attivita.add({
            'tipo': 'messaggio',
            'titolo': 'Nuovo messaggio',
            'subtitle': 'Hai ricevuto un messaggio da $senderName',
            'time': _formatTimestamp(message.data()['timestamp']),
            'icon': Icons.message.codePoint,
            'color': Colors.purple[400]!.value,
            'chatId': chat.id,
            'timestamp': message.data()['timestamp'],
          });
        }
      }
    }

    // 3. Ottieni registrazioni presenze recenti (solo per i docenti)
    for (String corsoId in corsiIds) {
      // Controlla se è un docente
      final corsoDoc = await _firestore.collection('corsi').doc(corsoId).get();
      final docenti = List<String>.from(corsoDoc.data()?['docenti'] ?? []);

      if (docenti.contains(uid)) {
        final String nomeCorso = corsoDoc.data()?['nome'] ?? 'Corso';

        // Ottieni le lezioni recenti
        final lezioni = await _firestore
            .collection('corsi')
            .doc(corsoId)
            .collection('lezioni')
            .orderBy('creato_il', descending: true)
            .limit(2)
            .get();

        for (var lezione in lezioni.docs) {
          attivita.add({
            'tipo': 'lezione',
            'titolo': 'Lezione registrata in $nomeCorso',
            'subtitle': 'Presenze registrate per "${lezione.data()['titolo']}"',
            'time': _formatTimestamp(lezione.data()['creato_il']),
            'icon': Icons.people.codePoint,
            'color': Colors.green[600]!.value,
            'corsoId': corsoId,
            'lezioneId': lezione.id,
            'timestamp': lezione.data()['creato_il'],
          });
        }
      }
    }

    // Ordina le attività per timestamp e prendi solo le più recenti
    attivita.sort((a, b) {
      final timestampA = a['timestamp'] as Timestamp?;
      final timestampB = b['timestamp'] as Timestamp?;

      if (timestampA == null && timestampB == null) return 0;
      if (timestampA == null) return 1;
      if (timestampB == null) return -1;

      return timestampB.compareTo(timestampA);
    });

    // Limita il numero di attività da restituire
    if (attivita.length > limit) {
      attivita = attivita.sublist(0, limit);
    }

    return attivita;
  }

  // Helper per formattare i timestamp
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Ora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min fa';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ore fa';
    } else if (difference.inDays < 2) {
      return 'Ieri';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} giorni fa';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Stream per ottenere aggiornamenti in tempo reale sulle attività
  Stream<List<Map<String, dynamic>>> streamAttivitaRecenti(int limit) {
    return Stream.periodic(const Duration(seconds: 30))
        .asyncMap((_) => getAttivitaRecenti(limit));
  }

  // Crea un nuovo appello d'esame
  Future<String> creaAppello(String corsoId, String titolo, DateTime data,
      String descrizione) async {
    final docRef = await _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('appelli')
        .add({
      'titolo': titolo,
      'data': Timestamp.fromDate(data),
      'descrizione': descrizione,
      'iscritti': [],
      'creato_il': FieldValue.serverTimestamp(),
      'stato': 'aperto', // Stati possibili: 'aperto', 'chiuso', 'valutato'
    });

    return docRef.id;
  }

// Ottiene tutti gli appelli di un corso
  Stream<List<Map<String, dynamic>>> getAppelliCorso(String corsoId) {
    return _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('appelli')
        .orderBy('data', descending: false)
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

// Iscrizione di uno studente ad un appello
  Future<void> iscrivitiAppello(String corsoId, String appelloId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Ottieni info dell'utente
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final firstName = userDoc.data()?['firstName'] ?? '';
    final lastName = userDoc.data()?['lastName'] ?? '';
    final fullName = '${firstName} ${lastName}'.trim();
    final email = userDoc.data()?['email'] ?? '';

    // Verifica disponibilità posti
    final appelloDoc = await _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('appelli')
        .doc(appelloId)
        .get();

    if (!appelloDoc.exists) throw Exception('Appello non trovato');

    final appelloData = appelloDoc.data()!;
    final iscritti = List<Map<String, dynamic>>.from(
        appelloData['iscritti'] ?? []);

    // Controlla se lo studente è già iscritto
    if (iscritti.any((iscritto) => iscritto['id'] == uid)) {
      throw Exception('Sei già iscritto a questo appello');
    }


    // Controlla che l'appello sia aperto
    if (appelloData['stato'] != 'aperto') {
      throw Exception('Le iscrizioni per questo appello sono chiuse');
    }

    // Aggiungi lo studente alla lista degli iscritti
    await _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('appelli')
        .doc(appelloId)
        .update({
      'iscritti': FieldValue.arrayUnion([
        {
          'id': uid,
          'nome': fullName.isEmpty ? 'Utente' : fullName,
          'email': email,
          'iscritto_il': Timestamp.now(),
          'voto': null,
          // Il voto sarà inserito dal professore
          'stato': 'iscritto',
          // Stati possibili: 'iscritto', 'presente', 'assente'
        }
      ])
    });
  }

// Cancella iscrizione di uno studente ad un appello
  Future<void> cancellaIscrizioneAppello(String corsoId,
      String appelloId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Ottieni l'iscrizione attuale dello studente
    final appelloDoc = await _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('appelli')
        .doc(appelloId)
        .get();

    if (!appelloDoc.exists) throw Exception('Appello non trovato');

    final appelloData = appelloDoc.data()!;
    final iscritti = List<Map<String, dynamic>>.from(
        appelloData['iscritti'] ?? []);

    // Trova l'iscrizione dello studente
    final iscrizioneStudente = iscritti.firstWhere(
          (iscritto) => iscritto['id'] == uid,
      orElse: () => <String, dynamic>{},
    );

    if (iscrizioneStudente.isEmpty) {
      throw Exception('Non sei iscritto a questo appello');
    }

    // Controlla che l'appello sia ancora aperto
    if (appelloData['stato'] != 'aperto') {
      throw Exception('Non è più possibile cancellarsi da questo appello');
    }

    // Rimuovi lo studente dalla lista degli iscritti
    await _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('appelli')
        .doc(appelloId)
        .update({
      'iscritti': FieldValue.arrayRemove([iscrizioneStudente])
    });
  }

// Ottieni appelli a cui uno studente è iscritto
  Stream<List<Map<String, dynamic>>> getAppelliIscritto() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    // Ottieni tutti i corsi a cui lo studente è iscritto
    return getCorsiIscritti().asyncMap((corsiIds) async {
      List<Map<String, dynamic>> appelliIscritto = [];

      for (String corsoId in corsiIds) {
        final corsoDoc = await _firestore.collection('corsi')
            .doc(corsoId)
            .get();
        final nomeCorso = corsoDoc.data()?['nome'] ?? 'Corso';

        // Ottieni tutti gli appelli del corso
        final appelliSnapshot = await _firestore
            .collection('corsi')
            .doc(corsoId)
            .collection('appelli')
            .get();

        for (var appelloDoc in appelliSnapshot.docs) {
          final appelloData = appelloDoc.data();
          final iscritti = List<Map<String, dynamic>>.from(
              appelloData['iscritti'] ?? []);

          // Controlla se lo studente è iscritto
          final iscrizioneStudente = iscritti.firstWhere(
                (iscritto) => iscritto['id'] == uid,
            orElse: () => <String, dynamic>{},
          );

          if (iscrizioneStudente.isNotEmpty) {
            appelliIscritto.add({
              'id': appelloDoc.id,
              'corsoId': corsoId,
              'nomeCorso': nomeCorso,
              'titolo': appelloData['titolo'],
              'data': appelloData['data'],
              'descrizione': appelloData['descrizione'],
              'stato': appelloData['stato'],
              'voto': iscrizioneStudente['voto'],
              'statoStudente': iscrizioneStudente['stato'],
            });
          }
        }
      }

      // Ordina gli appelli per data
      appelliIscritto.sort((a, b) {
        final dataA = (a['data'] as Timestamp).toDate();
        final dataB = (b['data'] as Timestamp).toDate();
        return dataA.compareTo(dataB);
      });

      return appelliIscritto;
    });
  }

// Ottieni gli appelli di un professore
  Stream<List<Map<String, dynamic>>> getAppelliProfessore() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    // Prima ottieni i corsi di cui il professore è docente
    return _firestore
        .collection('corsi')
        .where('docenti', arrayContains: uid)
        .snapshots()
        .asyncMap((corsiSnapshot) async {
      List<Map<String, dynamic>> appelli = [];

      for (var corsoDoc in corsiSnapshot.docs) {
        final corsoId = corsoDoc.id;
        final nomeCorso = corsoDoc.data()['nome'] ?? 'Corso';

        // Ottieni gli appelli di ogni corso
        final appelliSnapshot = await _firestore
            .collection('corsi')
            .doc(corsoId)
            .collection('appelli')
            .orderBy('data')
            .get();

        for (var appelloDoc in appelliSnapshot.docs) {
          final appelloData = appelloDoc.data();
          appelli.add({
            'id': appelloDoc.id,
            'corsoId': corsoId,
            'nomeCorso': nomeCorso,
            'titolo': appelloData['titolo'],
            'data': appelloData['data'],
            'descrizione': appelloData['descrizione'],
            'stato': appelloData['stato'],
            'iscritti': appelloData['iscritti'] ?? [],

          });
        }
      }

      // Ordina gli appelli per data
      appelli.sort((a, b) {
        final dataA = (a['data'] as Timestamp).toDate();
        final dataB = (b['data'] as Timestamp).toDate();
        return dataA.compareTo(dataB);
      });

      return appelli;
    });
  }

// Chiudi le iscrizioni a un appello
  Future<void> chiudiAppello(String corsoId, String appelloId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Verifica che l'utente sia un docente del corso
    final corsoDoc = await _firestore.collection('corsi').doc(corsoId).get();
    if (!corsoDoc.exists) throw Exception('Corso non trovato');

    final docenti = List<String>.from(corsoDoc.data()?['docenti'] ?? []);
    if (!docenti.contains(uid)) {
      throw Exception('Non hai i permessi per modificare questo appello');
    }

    // Aggiorna lo stato dell'appello
    await _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('appelli')
        .doc(appelloId)
        .update({
      'stato': 'chiuso'
    });
  }

// Registra presenza/assenza degli studenti all'appello
  Future<void> registraPresenzaAppello(String corsoId, String appelloId,
      String studenteId, bool presente) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Verifica che l'utente sia un docente del corso
    final corsoDoc = await _firestore.collection('corsi').doc(corsoId).get();
    if (!corsoDoc.exists) throw Exception('Corso non trovato');

    final docenti = List<String>.from(corsoDoc.data()?['docenti'] ?? []);
    if (!docenti.contains(uid)) {
      throw Exception('Non hai i permessi per registrare le presenze');
    }

    // Ottieni l'appello e gli iscritti
    final appelloDoc = await _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('appelli')
        .doc(appelloId)
        .get();

    if (!appelloDoc.exists) throw Exception('Appello non trovato');

    final appelloData = appelloDoc.data()!;
    List<Map<String, dynamic>> iscritti = List<Map<String, dynamic>>.from(
        appelloData['iscritti'] ?? []);

    // Trova l'iscrizione dello studente e aggiorna lo stato
    for (int i = 0; i < iscritti.length; i++) {
      if (iscritti[i]['id'] == studenteId) {
        // Crea una copia dell'elemento per modificarlo
        Map<String, dynamic> iscrittoAggiornato = Map<String, dynamic>.from(
            iscritti[i]);

        // Aggiorna lo stato
        iscrittoAggiornato['stato'] = presente ? 'presente' : 'assente';

        // Rimuovi il vecchio elemento e aggiungi quello aggiornato
        await _firestore
            .collection('corsi')
            .doc(corsoId)
            .collection('appelli')
            .doc(appelloId)
            .update({
          'iscritti': FieldValue.arrayRemove([iscritti[i]])
        });

        await _firestore
            .collection('corsi')
            .doc(corsoId)
            .collection('appelli')
            .doc(appelloId)
            .update({
          'iscritti': FieldValue.arrayUnion([iscrittoAggiornato])
        });

        break;
      }
    }
  }

// Registra il voto di uno studente per un appello
  Future<void> registraVotoAppello(String corsoId, String appelloId,
      String studenteId, dynamic voto) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Verifica che l'utente sia un docente del corso
    final corsoDoc = await _firestore.collection('corsi').doc(corsoId).get();
    if (!corsoDoc.exists) throw Exception('Corso non trovato');

    final docenti = List<String>.from(corsoDoc.data()?['docenti'] ?? []);
    if (!docenti.contains(uid)) {
      throw Exception('Non hai i permessi per registrare i voti');
    }

    // Ottieni l'appello e gli iscritti
    final appelloDoc = await _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('appelli')
        .doc(appelloId)
        .get();

    if (!appelloDoc.exists) throw Exception('Appello non trovato');

    final appelloData = appelloDoc.data()!;
    List<Map<String, dynamic>> iscritti = List<Map<String, dynamic>>.from(
        appelloData['iscritti'] ?? []);

    // Trova l'iscrizione dello studente e aggiorna il voto
    for (int i = 0; i < iscritti.length; i++) {
      if (iscritti[i]['id'] == studenteId) {
        // Crea una copia dell'elemento per modificarlo
        Map<String, dynamic> iscrittoAggiornato = Map<String, dynamic>.from(
            iscritti[i]);

        // Aggiorna il voto
        iscrittoAggiornato['voto'] = voto;

        // Rimuovi il vecchio elemento e aggiungi quello aggiornato
        await _firestore
            .collection('corsi')
            .doc(corsoId)
            .collection('appelli')
            .doc(appelloId)
            .update({
          'iscritti': FieldValue.arrayRemove([iscritti[i]])
        });

        await _firestore
            .collection('corsi')
            .doc(corsoId)
            .collection('appelli')
            .doc(appelloId)
            .update({
          'iscritti': FieldValue.arrayUnion([iscrittoAggiornato])
        });

        break;
      }
    }
  }

// Imposta l'appello come valutato (tutti i voti sono stati assegnati)
  Future<void> completaValutazioneAppello(String corsoId,
      String appelloId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Verifica che l'utente sia un docente del corso
    final corsoDoc = await _firestore.collection('corsi').doc(corsoId).get();
    if (!corsoDoc.exists) throw Exception('Corso non trovato');

    final docenti = List<String>.from(corsoDoc.data()?['docenti'] ?? []);
    if (!docenti.contains(uid)) {
      throw Exception('Non hai i permessi per modificare questo appello');
    }

    // Aggiorna lo stato dell'appello
    await _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('appelli')
        .doc(appelloId)
        .update({
      'stato': 'valutato'
    });
  }

// Ottieni statistiche degli appelli di un corso
  Future<Map<String, dynamic>> getStatisticheAppelli(String corsoId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return _emptyStatistiche();

    // Verifica che l'utente sia un docente del corso
    final corsoDoc = await _firestore.collection('corsi').doc(corsoId).get();
    if (!corsoDoc.exists) return _emptyStatistiche();

    final docenti = List<String>.from(corsoDoc.data()?['docenti'] ?? []);
    if (!docenti.contains(uid)) {
      return _emptyStatistiche();
    }

    // Ottieni tutti gli appelli del corso
    final appelliSnapshot = await _firestore
        .collection('corsi')
        .doc(corsoId)
        .collection('appelli')
        .where('stato', isEqualTo: 'valutato')
        .get();

    if (appelliSnapshot.docs.isEmpty) {
      return _emptyStatistiche();
    }

    int totaleAppelli = appelliSnapshot.docs.length;
    int totaleIscritti = 0;
    int totalePresenti = 0;
    int studentiPromossi = 0; // Aggiungiamo questo contatore
    List<dynamic> voti = [];

    for (var appelloDoc in appelliSnapshot.docs) {
      final iscritti = List<Map<String, dynamic>>.from(
          appelloDoc.data()['iscritti'] ?? []);
      totaleIscritti += iscritti.length;

      for (var iscritto in iscritti) {
        if (iscritto['stato'] == 'presente') {
          totalePresenti++;
        }

        // Conta studenti promossi (voto >= 18)
        if (iscritto['voto'] != null && iscritto['voto'] is num &&
            iscritto['voto'] >= 18) {
          studentiPromossi++;
        }

        if (iscritto['voto'] != null) {
          voti.add(iscritto['voto']);
        }
      }
    }

    // Calcola media voti
    double mediaVoti = 0.0;
    if (voti.isNotEmpty) {
      double somma = 0.0;
      for (var voto in voti) {
        if (voto is num) {
          somma += voto.toDouble();
        }
      }
      mediaVoti = somma / voti.length;
    }

    // Calcola distribuzione dei voti
    Map<String, int> distribuzioneMap = {};
    for (var voto in voti) {
      if (voto is num) {
        String fascia = '';
        if (voto < 18)
          fascia = '< 18';
        else if (voto >= 18 && voto < 21)
          fascia = '18-20';
        else if (voto >= 21 && voto < 24)
          fascia = '21-23';
        else if (voto >= 24 && voto < 27)
          fascia = '24-26';
        else if (voto >= 27 && voto < 30)
          fascia = '27-29';
        else
          fascia = '30/30L';

        distribuzioneMap[fascia] = (distribuzioneMap[fascia] ?? 0) + 1;
      }
    }

    List<Map<String, dynamic>> distribuzione = distribuzioneMap.entries.map((
        entry) {
      return {
        'fascia': entry.key,
        'numero': entry.value,
      };
    }).toList();

    return {
      'totaleAppelli': totaleAppelli,
      'totaleIscritti': totaleIscritti,
      'totalePresenti': totalePresenti,
      'studentiPromossi': studentiPromossi, // Aggiungiamo questo campo
      'mediaVoti': mediaVoti,
      'distribuzione': distribuzione,
    };
  }

// Helper method that returns empty statistics with all fields initialized
  Map<String, dynamic> _emptyStatistiche() {
    return {
      'totaleAppelli': 0,
      'totaleIscritti': 0,
      'totalePresenti': 0,
      'studentiPromossi': 0,
      'mediaVoti': 0.0,
      'distribuzione': [],
    };
  }
}