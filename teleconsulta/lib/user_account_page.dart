import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:table_calendar/table_calendar.dart';

class UserAccountPage extends StatefulWidget {
  const UserAccountPage({super.key});

  @override
  _UserAccountPageState createState() => _UserAccountPageState();
}

class _UserAccountPageState extends State<UserAccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  final Map<String, String> _userData = {
    'Nome Completo': 'Carregando...',
    'Email': 'Carregando...',
    'Data de Nascimento': 'Carregando...',
    'CRM': 'Carregando...',
    'Especialidade': 'Carregando...',
  };

  // Disponibilidade mensal
  Map<DateTime, List<String>> _availability = {};

  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  DateTime? _selectedDay;

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
          _databaseReference.child('users/doctors').child(user.uid).child('disponibilidadeMensal');
      final snapshot = await availabilityRef.get();
      if (snapshot.exists) {
        Map<String, dynamic> availabilityData = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _availability = availabilityData.map((key, value) =>
              MapEntry(DateTime.parse(key), List<String>.from(value)));
        });
      }
    }
  }

  Future<void> _saveAvailability() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DatabaseReference availabilityRef =
          _databaseReference.child('users/doctors').child(user.uid).child('disponibilidadeMensal');
      final formattedAvailability = _availability.map((key, value) {
        // Formatar a chave como uma string segura
        String safeKey = '${key.year}${key.month.toString().padLeft(2, '0')}${key.day.toString().padLeft(2, '0')}';
        return MapEntry(safeKey, value);
      });

      try {
        await availabilityRef.set(formattedAvailability);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disponibilidade mensal salva com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar a disponibilidade: $e')),
        );
      }
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
    if (_selectedDay != null && _startTimeController.text.isNotEmpty && _endTimeController.text.isNotEmpty) {
      setState(() {
        String timeSlot = '${_startTimeController.text} - ${_endTimeController.text}';
        if (_availability.containsKey(_selectedDay)) {
          _availability[_selectedDay]!.add(timeSlot);
        } else {
          _availability[_selectedDay!] = [timeSlot];
        }
      });
      _startTimeController.clear();
      _endTimeController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma data e insira os horários de início e término.')),
      );
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
              }),
              const SizedBox(height: 20),
              // Disponibilidade mensal
              const Text(
                'Definir Disponibilidade Mensal',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2025, 12, 31),
                focusedDay: DateTime.now(),
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: const BoxDecoration(
                    color: Colors.orangeAccent,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: const Color(0xFF149393),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  weekendTextStyle: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  defaultTextStyle: const TextStyle(
                    color: Colors.white,
                  ),
                  outsideTextStyle: const TextStyle(
                    color: Colors.grey,
                  ),
                  holidayTextStyle: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  todayTextStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  markersAutoAligned: true,
                  markersMaxCount: 3,
                  markerDecoration: const BoxDecoration(
                    color: Colors.deepOrange,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  titleTextStyle: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronIcon: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                  ),
                  rightChevronIcon: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF149393),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  weekendStyle: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addTimeSlot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF149393),
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
                      '${entry.key.day}/${entry.key.month}/${entry.key.year}',
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
              }),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAvailability,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF149393),
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
