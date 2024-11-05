import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ConsultationHistoryPage extends StatefulWidget {
  const ConsultationHistoryPage({super.key});

  @override
  _ConsultationHistoryPageState createState() => _ConsultationHistoryPageState();
}

class _ConsultationHistoryPageState extends State<ConsultationHistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  List<Map<String, String>> _consultationHistory = [];

  @override
  void initState() {
    super.initState();
    _loadConsultationHistory();
  }

  Future<void> _loadConsultationHistory() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DatabaseReference consultationsRef = _databaseReference.child('users/patients').child(user.uid).child('consultations');
      final snapshot = await consultationsRef.get();
      if (snapshot.exists) {
        List<Map<String, String>> history = [];
        Map<dynamic, dynamic> consultationsMap = snapshot.value as Map<dynamic, dynamic>;
        consultationsMap.forEach((key, value) {
          history.add({
            'Especialidade': value['specialty'] ?? 'Especialidade não disponível',
            'Data': value['date'] ?? 'Data não disponível',
            'Horário': value['time'] ?? 'Hora não disponível',
            'Status': value['status'] ?? 'Status não disponível',
          });
        });
        setState(() {
          _consultationHistory = history;
        });
      }
    }
  }

  void _goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _goBack,
        ),
        title: const Text(
          'Histórico de Consultas',
          style: TextStyle(
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
          child: ListView(
            children: _consultationHistory.isEmpty
                ? [const Center(child: Text('Nenhuma consulta encontrada'))]
                : _consultationHistory.map((consultation) {
                    return Card(
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: ListTile(
                        title: Text(
                          'Especialidade: ${consultation['Especialidade']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF149393),
                          ),
                        ),
                        subtitle: Text(
                          'Data: ${consultation['Data']} às ${consultation['Horário']}\nStatus: ${consultation['Status']}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
          ),
        ),
      ),
    );
  }
}
