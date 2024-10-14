import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart';
import 'user_account_page.dart';
import 'prontuario_page.dart'; // Importe a nova página de prontuário

class DoctorPage extends StatefulWidget {
  const DoctorPage({super.key});

  @override
  _DoctorPageState createState() => _DoctorPageState();
}

class _DoctorPageState extends State<DoctorPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  String _doctorName = "Carregando...";
  bool _isHoveringLogout = false;
  List<Map<String, dynamic>> _patientConsultations = []; // Lista para armazenar consultas agendadas.

  @override
  void initState() {
    super.initState();
    _fetchDoctorName();
    _fetchPatientConsultations(); // Carregar as consultas ao iniciar a página.
  }

  Future<void> _fetchDoctorName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DatabaseReference doctorRef = _databaseReference.child('users/doctors').child(user.uid);
      final snapshot = await doctorRef.child('nomeCompleto').get();
      if (snapshot.exists) {
        setState(() {
          _doctorName = snapshot.value.toString();
        });
      } else {
        setState(() {
          _doctorName = "Nome não encontrado";
        });
      }
    }
  }

  Future<void> _fetchPatientConsultations() async {
    DatabaseReference consultationsRef = _databaseReference.child('users/patients');
    final snapshot = await consultationsRef.get();

    if (snapshot.exists) {
      List<Map<String, dynamic>> consultations = [];
      Map<dynamic, dynamic> patients = snapshot.value as Map<dynamic, dynamic>;

      patients.forEach((patientId, patientData) {
        if (patientData['consultations'] != null) {
          Map<dynamic, dynamic> patientConsultations = patientData['consultations'];
          patientConsultations.forEach((key, value) {
            consultations.add({
              'patientName': patientData['nomeCompleto'],
              'specialty': value['specialty'],
              'date': value['date'],
              'time': value['time'],
            });
          });
        }
      });

      setState(() {
        _patientConsultations = consultations;
      });
    }
  }

  void _logout() {
    _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _navigateToUserAccountPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserAccountPage()),
    );
  }

  void _showConsultationsPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Consultas Agendadas'),
          content: SizedBox(
            width: double.maxFinite,
            child: _patientConsultations.isEmpty
                ? const Text('Nenhuma consulta agendada.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _patientConsultations.length,
                    itemBuilder: (context, index) {
                      final consultation = _patientConsultations[index];
                      return ListTile(
                        title: Text('Paciente: ${consultation['patientName']}'),
                        subtitle: Text(
                            'Especialidade: ${consultation['specialty']}\nData: ${consultation['date']}'),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToProntuarioPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProntuarioPage()), // Navega para a página de Prontuário
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
        leading: MouseRegion(
          onEnter: (_) => setState(() => _isHoveringLogout = true),
          onExit: (_) => setState(() => _isHoveringLogout = false),
          child: GestureDetector(
            onTap: _logout,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: _isHoveringLogout ? Colors.red[300] : Colors.transparent,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Icon(Icons.logout, color: Color(0xFF149393)),
            ),
          ),
        ),
        title: Text(
          _doctorName,
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
            itemCount: 5, // Atualize o número de botões para incluir o novo botão de prontuário
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return _buildMenuButton(
                    context,
                    'MINHA CONTA',
                    Icons.account_circle,
                    _navigateToUserAccountPage,
                  );
                case 1:
                  return _buildMenuButton(
                    context,
                    'CONSULTAS AGENDADAS',
                    Icons.event_note,
                    _showConsultationsPopup,
                  );
                case 2:
                  return _buildMenuButton(
                    context,
                    'SOLICITAR EXAMES',
                    Icons.medical_services,
                    () {
                      // Implemente a navegação para a página "Solicitar Exames"
                    },
                  );
                case 3:
                  return _buildMenuButton(
                    context,
                    'RECEITAS',
                    Icons.receipt,
                    () {
                      // Implemente a navegação para a página "Receitas"
                    },
                  );
                case 4:
                  return _buildMenuButton(
                    context,
                    'PRONTUÁRIO',
                    Icons.assignment,
                    _navigateToProntuarioPage, // Navega para a página de Prontuário
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

  Widget _buildMenuButton(BuildContext context, String title, IconData icon, VoidCallback onPressed) {
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
