import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'studente/home_screen.dart';
import 'admin/admin_screen.dart';
import 'professore/professore_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _email = '';
  String _password = '';
  String _firstName = '';
  String _lastName = '';
  bool _admin = false;
  bool _professore = false;
  bool _isLogin = true;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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

  void _switchAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = '';
    });
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      await FirebaseAuth.instance.signOut();

      if (_isLogin) {
        try {
          UserCredential userCredential = await _auth.signInWithEmailAndPassword(
            email: _email, password: _password,
          );
          _checkUserRole(userCredential.user?.uid);
        } catch (e) {
          if (e.toString().contains('A network error') || e.toString().contains('RecaptchaAction')) {
            await Future.delayed(Duration(seconds: 1));
            UserCredential userCredential = await _auth.signInWithEmailAndPassword(
              email: _email, password: _password,
            );
            _checkUserRole(userCredential.user?.uid);
          } else {
            throw e;
          }
        }
      } else {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _email, password: _password,
        );

        try {
          await _firestore.collection('users').doc(userCredential.user?.uid).set({
            'firstName': _firstName, 'lastName': _lastName, 'email': _email,
            'admin': _admin, 'professore': _professore,
            'createdAt': FieldValue.serverTimestamp(),
          });
          _checkUserRole(userCredential.user?.uid);
        } catch (firestoreError) {
          setState(() => _errorMessage = 'Errore durante il salvataggio: $firestoreError');
        }
      }
    } on FirebaseAuthException catch (error) {
      String message = 'Errore di autenticazione';

      Map<String, String> errorMessages = {
        'weak-password': 'La password è troppo debole.',
        'email-already-in-use': 'Esiste già un account con questa email.',
        'user-not-found': 'Nessun utente trovato con questa email.',
        'wrong-password': 'Password non corretta.',
        'invalid-email': 'L\'email non è valida.',
        'web-context-canceled': 'Verifica reCAPTCHA fallita. Riprova.',
      };

      setState(() => _errorMessage = errorMessages[error.code] ?? message);
    } catch (error) {
      setState(() => _errorMessage = 'Si è verificato un errore: $error');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _checkUserRole(String? uid) async {
    if (uid == null) return;

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>?;

        bool isAdmin = data?['admin'] ?? false;
        bool isProfessore = data?['professore'] ?? false;

        if (isAdmin) {
          _navigateToAdmin();
          return;
        }
        if (isProfessore) {
          _navigateToProfessore();
          return;
        }

        _navigateToHome();
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _errorMessage = 'Errore durante il caricamento del profilo utente';
      });
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade700,
              Colors.blue.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: size.height - MediaQuery.of(context).padding.top,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Logo o titolo dell'app
                  Icon(
                    Icons.school,
                    size: 80,
                    color: Colors.white,
                  ),
                  Text(
                    'UnicalHub',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _isLogin ? 'Accedi' : 'Crea Account',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                if (!_isLogin) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          decoration: InputDecoration(
                                            labelText: 'Nome',
                                            prefixIcon: const Icon(Icons.person_outline),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
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
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          decoration: InputDecoration(
                                            labelText: 'Cognome',
                                            prefixIcon: const Icon(Icons.person_outline),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
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
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'esempio@email.com',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
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
                                const SizedBox(height: 16),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
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
                                const SizedBox(height: 16),
                                if (_errorMessage.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(color: Colors.red.shade800),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: Colors.blue.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : Text(
                                      _isLogin ? 'ACCEDI' : 'REGISTRATI',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: _switchAuthMode,
                                  child: Text(
                                    _isLogin
                                        ? 'Non hai un account? Registrati'
                                        : 'Hai già un account? Accedi',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blueAccent
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}