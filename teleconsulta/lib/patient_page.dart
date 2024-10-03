import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart';
import 'consultations_page.dart';

class PatientPage extends StatefulWidget {
  const PatientPage({super.key});

  @override
  _PatientPageState createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  String _patientName = 'Nome completo do paciente';

  @override
  void initState() {
    super.initState();
    _loadPatientName();
  }

  Future<void> _loadPatientName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DatabaseReference userRef = _databaseReference.child('users/patients').child(user.uid);
      final snapshot = await userRef.child('nomeCompleto').get();
      if (snapshot.exists) {
        setState(() {
          _patientName = snapshot.value.toString();
        });
      }
    }
  }

  void _logout() {
    _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _logout,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF149393),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    _patientName,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMenuButton('CONSULTAS'),
            const SizedBox(height: 20),
            _buildMenuButton('EXAMES E RECEITAS'),
            const SizedBox(height: 20),
            _buildMenuButton('MINHA CONTA'),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(String text) {
    return SizedBox(
      width: 200,
      height: 200,
      child: ElevatedButton(
        onPressed: () {
          if (text == 'CONSULTAS') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ConsultationsPage()),
            );
          }
          // Adicione navegação para outras páginas aqui, se necessário.
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF149393),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
