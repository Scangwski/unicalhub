import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'studente/home_screen.dart';
import 'admin/admin_screen.dart'; // Importa la schermata admin
import 'professore/professore_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  String _firstName = '';
  String _lastName = '';
  bool _admin = false;
  bool _professore = false;
  bool _isLogin = true;
  bool _isLoading = false;
  String _errorMessage = '';

  void _switchAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = '';
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isLogin) {
        // Login esistente
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        _checkUserRole(userCredential.user?.uid); // Controlla il ruolo dell'utente
      } else {
        // Nuova registrazione
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );

        // Aggiungere nome, cognome ed email a Firestore
        try {
          await _firestore.collection('users').doc(userCredential.user?.uid).set({
            'firstName': _firstName,
            'lastName': _lastName,
            'email': _email,
            'admin': _admin,
            'professore': _professore,
          });
          _checkUserRole(userCredential.user?.uid); // Controlla il ruolo dell'utente registrato
        } catch (firestoreError) {
          setState(() {
            _errorMessage = 'Errore durante il salvataggio in Firestore: ${firestoreError.toString()}';
          });
        }
      }
    } on FirebaseAuthException catch (error) {
      String message = 'Si è verificato un errore durante l\'autenticazione';
      if (error.code == 'weak-password') {
        message = 'La password è troppo debole.';
      } else if (error.code == 'email-already-in-use') {
        message = 'Esiste già un account con questa email.';
      } else if (error.code == 'user-not-found') {
        message = 'Nessun utente trovato con questa email.';
      } else if (error.code == 'wrong-password') {
        message = 'Password non corretta.';
      } else if (error.code == 'invalid-email') {
        message = 'L\'email non è valida.';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Si è verificato un errore: ${error.toString()}';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkUserRole(String? uid) async {
    if (uid == null) return;

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>?; // Converte il documento in una mappa
        print('User Data: $data'); // Stampa tutto il documento per debug

        bool isAdmin = data?['admin'] ?? false;
        bool isProfessore = data?['professore'] ?? false;

        print('isAdmin: $isAdmin'); // Debug
        print('isProfessore: $isProfessore'); // Debug

        if (isAdmin) {
          _navigateToAdmin();
          return;
        }
        if (isProfessore) {
          _navigateToProfessore();
          return;
        }

        print('Navigating to Home'); // Debug
        _navigateToHome();
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }

  }


  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _navigateToAdmin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AdminScreen()),
    );
  }
  void _navigateToProfessore() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ProfessoreScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Registrazione'),
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isLogin) ...[
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci il tuo nome';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _firstName = value!;
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Cognome'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci il tuo cognome';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _lastName = value!;
                      },
                    ),
                  ],
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Inserisci un indirizzo email valido';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _email = value!.trim();
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 6) {
                        return 'La password deve contenere almeno 6 caratteri';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _password = value!;
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                      ),
                      child: Text(_isLogin ? 'ACCEDI' : 'REGISTRATI'),
                    ),
                  TextButton(
                    onPressed: _switchAuthMode,
                    child: Text(
                      _isLogin
                          ? 'CREA UN NUOVO ACCOUNT'
                          : 'HAI GIÀ UN ACCOUNT? ACCEDI',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
