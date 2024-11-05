import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SolicitarExamesPage extends StatefulWidget {
  const SolicitarExamesPage({Key? key}) : super(key: key);

  @override
  _SolicitarExamesPageState createState() => _SolicitarExamesPageState();
}

class _SolicitarExamesPageState extends State<SolicitarExamesPage> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref().child('users/patients');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _doctorSpecialty = 'Especialidade não disponível';
  List<Map<String, dynamic>> _pacientes = [];
  String? _selectedPatientId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _fetchDoctorSpecialty();
  }

  Future<void> _fetchDoctorSpecialty() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DatabaseReference doctorRef = FirebaseDatabase.instance.ref().child('users/doctors').child(user.uid);
      final snapshot = await doctorRef.child('especialidade').get();
      if (snapshot.exists) {
        setState(() {
          _doctorSpecialty = snapshot.value.toString();
        });
      }
    }
  }

  Future<void> _loadPatients() async {
    final snapshot = await _databaseReference.get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> patientsMap = snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> patientsList = patientsMap.entries.map((entry) {
        return {
          'id': entry.key,
          'name': entry.value['nomeCompleto'] ?? 'Nome não disponível',
        };
      }).toList();

      setState(() {
        _pacientes = patientsList;
      });
    }
  }

  Future<void> _selectDateAndTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child ?? Container(),
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;
        });
      }
    }
  }

  void _marcarExame() {
    if (_selectedPatientId != null && _selectedDate != null && _selectedTime != null) {
      // Formatar a data e a hora para armazenar no banco de dados
      String formattedDateTime = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')} "
          "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}";

      // Salvar a consulta no Firebase
      DatabaseReference patientRef = _databaseReference.child(_selectedPatientId!).child('consultations').push();
      patientRef.set({
        'date': formattedDateTime, // Armazena a data e hora juntas
        'markedBy': 'Médico', // Indica que a consulta foi marcada pelo médico
        'specialty': _doctorSpecialty, // Armazena a especialidade do médico
        'convenio': 'Marcado pelo médico', // Indica que foi marcado pelo médico
        'status': 'Pendente', // Status inicial da consulta
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exame marcado com sucesso!')),
      );

      setState(() {
        _selectedDate = null;
        _selectedTime = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um paciente e uma data/hora para marcar o exame.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Exames'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _pacientes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _pacientes.length,
                      itemBuilder: (context, index) {
                        final paciente = _pacientes[index];
                        return ListTile(
                          title: Text(paciente['name']),
                          leading: Icon(
                            _selectedPatientId == paciente['id']
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: Colors.teal,
                          ),
                          onTap: () {
                            setState(() {
                              _selectedPatientId = paciente['id'];
                            });
                          },
                        );
                      },
                    ),
            ),
            ElevatedButton.icon(
              onPressed: _selectDateAndTime,
              icon: const Icon(Icons.calendar_today),
              label: const Text('Selecionar Data e Hora'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _marcarExame,
              icon: const Icon(Icons.add_box),
              label: const Text('Marcar Exame'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
