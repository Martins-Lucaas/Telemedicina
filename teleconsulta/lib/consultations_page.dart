import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'new_appointment_page.dart'; // Importa a nova página para criar um agendamento

class ConsultationsPage extends StatefulWidget {
  const ConsultationsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ConsultationsPageState createState() => _ConsultationsPageState();
}

class _ConsultationsPageState extends State<ConsultationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  String _patientName = 'Nome completo do paciente';
  List<Map<String, dynamic>> _consultations = [];

  @override
  void initState() {
    super.initState();
    _loadPatientName();
    _fetchConsultations();
  }

  Future<void> _loadPatientName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DatabaseReference userRef = _databaseReference.child('users/pacientes').child(user.uid);
      final snapshot = await userRef.child('name').get();
      if (snapshot.exists) {
        setState(() {
          _patientName = snapshot.value.toString();
        });
      }
    }
  }

  Future<void> _fetchConsultations() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DatabaseReference consultationsRef = _databaseReference.child('users/pacientes').child(user.uid).child('consultations');
      final snapshot = await consultationsRef.get();
      if (snapshot.exists) {
        List<Map<String, dynamic>> consultations = [];
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          consultations.add({
            'id': key, // Store the consultation ID for later deletion
            'specialty': value['specialty'],
            'date': value['date'],
            'time': value['time'],
            'status': value['status'] ?? 'Agendado', // Default to "Agendado"
          });
        });

        setState(() {
          _consultations = consultations;
        });
      }
    }
  }

  Future<void> _cancelConsultation(String consultationId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      DatabaseReference consultationRef = _databaseReference.child('users/pacientes').child(user.uid).child('consultations').child(consultationId);
      await consultationRef.remove();
      _fetchConsultations();
    }
  }

  void _showCancelConfirmationDialog(String consultationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar Consulta'),
          content: const Text('Tem certeza de que deseja cancelar esta consulta?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fechar o pop-up
              },
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () {
                _cancelConsultation(consultationId);
                Navigator.of(context).pop(); // Fechar o pop-up após confirmar
              },
              child: const Text('Sim'),
            ),
          ],
        );
      },
    );
  }

  void _goBack() {
    Navigator.pop(context);
  }

  void _navigateToNewAppointment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewAppointmentPage()),
    ).then((_) {
      _fetchConsultations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _goBack,
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Consultas agendadas',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Center( // Centraliza a tabela
              child: _consultations.isEmpty
                  ? const Center(child: Text('Sem consultas agendadas.')) // Mensagem atualizada
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 30, // Espaçamento entre as colunas
                        headingRowColor: WidgetStateColor.resolveWith((states) => const Color(0xFF149393)),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Especialidade',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Data',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Horário',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Situação',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Cancelar',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: _consultations.map((consultation) {
                          return DataRow(
                            cells: [
                              DataCell(Text(consultation['specialty'], style: const TextStyle(fontSize: 16))),
                              DataCell(Text(consultation['date'], style: const TextStyle(fontSize: 16))),
                              DataCell(Text(consultation['time'], style: const TextStyle(fontSize: 16))),
                              DataCell(Text(consultation['status'], style: const TextStyle(fontSize: 16))),
                              DataCell(
                                ElevatedButton(
                                  onPressed: () {
                                    _showCancelConfirmationDialog(consultation['id']);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEC2222), // Cor do botão de cancelamento
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'CANCELAR',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateToNewAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF149393),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: const Text(
                'SOLICITAR NOVO AGENDAMENTO',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
