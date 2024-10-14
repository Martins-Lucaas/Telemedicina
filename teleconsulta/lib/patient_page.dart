import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:teleconsulta/PatientAccountPage.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth < 600 ? 1 : screenWidth < 900 ? 2 : 3;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 5,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF149393)),
          onPressed: _logout,
        ),
        title: Text(
          _patientName,
          style: const TextStyle(
            color: Color(0xFF149393),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF149393), Color(0xFF0B6A69)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 20.0,
              crossAxisSpacing: 20.0,
              childAspectRatio: 1.2,
            ),
            itemCount: 3, // Quantidade de botões (3 no total)
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return _buildMenuButton(
                    context,
                    'CONSULTAS',
                    Icons.event_note,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ConsultationsPage()),
                      );
                    },
                  );
                case 1:
                  return _buildMenuButton(
                    context,
                    'EXAMES E RECEITAS',
                    Icons.medical_services,
                    () {
                      // Implemente a navegação para a página de Exames e Receitas
                    },
                  );
                case 2:
                  return _buildMenuButton(
                    context,
                    'MINHA CONTA',
                    Icons.account_circle,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PatientAccountPage()),
                      );
                    },
                  );
                default:
                  return Container();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: const Color(0xFF149393),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF149393),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
