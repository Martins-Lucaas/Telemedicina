import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';
import 'register_page.dart'; // Importa a nova página de registro
import 'patient_page.dart'; // Importa a página dos pacientes

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  bool _isHoveringLogin = false;
  bool _isHoveringRegister = false;
  bool _isPressedLogin = false;
  bool _isPressedRegister = false;

  Future<void> _login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      User? user = _auth.currentUser;

      if (user != null) {
        DatabaseReference userRef = _databaseReference.child('users/pacientes').child(user.uid);
        userRef.once().then((DatabaseEvent event) {
          if (event.snapshot.exists) {
            // Redireciona para a página específica para pacientes
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PatientPage()),
            );
          } else {
            // Redireciona para a página inicial (caso não seja paciente)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Página Inicial')),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao fazer login: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          const containerWidth = 500.0;
          const containerHeight = 50.0;

          return Stack(
            children: [
              Positioned(
                left: 0,
                top: screenHeight * 0.5,
                child: Container(
                  width: screenWidth,
                  height: screenHeight * 0.5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF149393),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.jpg',
                        width: 120.0,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 250.0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF149393),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'SAÚDE +',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        width: containerWidth,
                        height: containerHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            hintText: 'Insira seu e-mail',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        width: containerWidth,
                        height: containerHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            hintText: 'Insira sua senha',
                            border: InputBorder.none,
                          ),
                          obscureText: true,
                        ),
                      ),
                      const SizedBox(height: 30),
                      MouseRegion(
                        onEnter: (_) => setState(() => _isHoveringLogin = true),
                        onExit: (_) => setState(() => _isHoveringLogin = false),
                        child: GestureDetector(
                          onTapDown: (_) => setState(() => _isPressedLogin = true),
                          onTapUp: (_) {
                            setState(() => _isPressedLogin = false);
                            _login();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _isPressedLogin ? containerWidth - 20 : containerWidth,
                            height: _isPressedLogin ? containerHeight - 5 : containerHeight,
                            decoration: BoxDecoration(
                              color: _isHoveringLogin ? Colors.grey[300] : Colors.white,
                              borderRadius: BorderRadius.circular(34),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Entrar',
                              style: TextStyle(
                                color: Color(0xFF149393),
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      MouseRegion(
                        onEnter: (_) => setState(() => _isHoveringRegister = true),
                        onExit: (_) => setState(() => _isHoveringRegister = false),
                        child: GestureDetector(
                          onTapDown: (_) => setState(() => _isPressedRegister = true),
                          onTapUp: (_) {
                            setState(() => _isPressedRegister = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterPage()), // Navega para a página de registro
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _isPressedRegister ? containerWidth - 20 : containerWidth,
                            height: _isPressedRegister ? containerHeight - 5 : containerHeight,
                            decoration: BoxDecoration(
                              color: _isHoveringRegister ? Colors.grey[300] : Colors.white,
                              borderRadius: BorderRadius.circular(34),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Registrar',
                              style: TextStyle(
                                color: Color(0xFF149393),
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
