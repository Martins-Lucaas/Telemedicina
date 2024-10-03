import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserAccountPage extends StatefulWidget {
  const UserAccountPage({super.key});

  @override
  _UserAccountPageState createState() => _UserAccountPageState();
}

class _UserAccountPageState extends State<UserAccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  Map<String, String> _userData = {
    'Nome Completo': 'Carregando...',
    'Email': 'Carregando...',
    'Data de Nascimento': 'Carregando...',
    'CRM': 'Carregando...',
    'Especialidade': 'Carregando...',
  };

  // Disponibilidade semanal
  Map<String, List<String>> _availability = {
    'segunda-feira': [],
    'terça-feira': [],
    'quarta-feira': [],
    'quinta-feira': [],
    'sexta-feira': [],
    'sábado': [],
    'domingo': [],
  };

  TextEditingController _startTimeController = TextEditingController();
  TextEditingController _endTimeController = TextEditingController();
  String? _selectedDay;
  bool _willNotWork = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAvailability();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DatabaseReference userRef = _databaseReference.child('users/doctors').child(user.uid);
      final snapshot = await userRef.get();
      if (snapshot.exists) {
        setState(() {
          _userData['Nome Completo'] = snapshot.child('nomeCompleto').value.toString();
          _userData['Email'] = snapshot.child('email').value.toString();
          _userData['Data de Nascimento'] = snapshot.child('dataNascimento').value.toString();
          _userData['CRM'] = snapshot.child('crm').value.toString();
          _userData['Especialidade'] = snapshot.child('especialidade').value.toString();
        });
      }
    }
  }

  Future<void> _loadAvailability() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DatabaseReference availabilityRef =
          _databaseReference.child('users/doctors').child(user.uid).child('disponibilidade');
      final snapshot = await availabilityRef.get();
      if (snapshot.exists) {
        Map<String, dynamic> availabilityData = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _availability = availabilityData.map((key, value) => MapEntry(key, List<String>.from(value)));
        });
      }
    }
  }

  Future<void> _saveAvailability() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DatabaseReference availabilityRef =
          _databaseReference.child('users/doctors').child(user.uid).child('disponibilidade');
      await availabilityRef.set(_availability);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disponibilidade salva com sucesso!')),
      );
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        controller.text = formattedTime;
      });
    }
  }

  void _addTimeSlot() {
    if (_selectedDay != null) {
      setState(() {
        if (_willNotWork) {
          // Se a opção "não trabalhará" estiver marcada
          _availability[_selectedDay!] = ["Não trabalhará"];
        } else {
          // Caso contrário, adicione o horário selecionado
          String timeSlot = '${_startTimeController.text} - ${_endTimeController.text}';
          _availability[_selectedDay!]!.add(timeSlot);
        }
      });
      _startTimeController.clear();
      _endTimeController.clear();
      _willNotWork = false; // Resetar a opção
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
          'Minha Conta',
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
            children: [
              // Exibir informações do usuário
              ..._userData.entries.map((entry) {
                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: ListTile(
                    title: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF149393),
                      ),
                    ),
                    subtitle: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
              // Disponibilidade semanal
              const Text(
                'Definir Disponibilidade Semanal',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedDay,
                hint: const Text('Selecione um dia da semana'),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDay = newValue;
                    _willNotWork = false; // Resetar o checkbox ao mudar de dia
                  });
                },
                items: _availability.keys.map((String day) {
                  return DropdownMenuItem<String>(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              // Checkbox para "Não trabalhará"
              Row(
                children: [
                  Checkbox(
                    value: _willNotWork,
                    onChanged: (bool? value) {
                      setState(() {
                        _willNotWork = value ?? false;
                      });
                    },
                  ),
                  const Text('Não trabalhará nesse dia'),
                ],
              ),
              if (!_willNotWork) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Hora de Início',
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        readOnly: true,
                        onTap: () => _selectTime(_startTimeController),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _endTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Hora de Término',
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        readOnly: true,
                        onTap: () => _selectTime(_endTimeController),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addTimeSlot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF149393),
                ),
                child: const Text('Adicionar Horário'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Horários Definidos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              ..._availability.entries.map((entry) {
                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: ListTile(
                    title: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF149393),
                      ),
                    ),
                    subtitle: Text(
                      entry.value.join(', '),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAvailability,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF149393),
                ),
                child: const Text('Salvar Disponibilidade'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
