import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart'; 

/// Página de login do aplicativo.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

/// Estado da página de login.
class _LoginPageState extends State<LoginPage> {
  // Controladores de texto para os campos de email e senha.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Instância do FirebaseAuth para autenticação.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Método para registrar um novo usuário.
  Future<void> _register() async {
    try {
      // Cria um novo usuário com email e senha fornecidos.
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Adiciona o usuário ao Realtime Database.
      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child('users');
      usersRef.child(userCredential.user!.uid).set({
        'email': _emailController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Mensagem de sucesso ao criar conta.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada com sucesso!')),
      );
    } catch (e) {
      // Mensagem de erro ao criar conta.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao criar conta: $e')),
      );
    }
  }

  /// Método para realizar login.
  Future<void> _login() async {
    try {
      // Realiza login com email e senha fornecidos.
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Mensagem de sucesso ao fazer login.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login realizado com sucesso!')),
      );
      // Navega para a próxima página (ex: MyHomePage).
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Página Inicial')),
      );
    } catch (e) {
      // Mensagem de erro ao fazer login.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao fazer login: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página de Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Campo para inserir email.
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            // Campo para inserir senha.
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            // Botão para fazer login.
            ElevatedButton(
              onPressed: _login,
              child: const Text('Entrar'),
            ),
            // Botão para registrar.
            ElevatedButton(
              onPressed: _register,
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}
