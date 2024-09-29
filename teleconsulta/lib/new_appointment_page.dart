import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class NewAppointmentPage extends StatefulWidget {
  const NewAppointmentPage({super.key});

  @override
  _NewAppointmentPageState createState() => _NewAppointmentPageState();
}

class _NewAppointmentPageState extends State<NewAppointmentPage> {
  final _specialtyController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _convenio = 'Nenhum';
  String _patientName = 'Nome completo do paciente';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  final String _whatsappNumber = '6294024674'; // Precisa criar um zap business

  @override
  void initState() {
    super.initState();
    _loadPatientName();
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

  Future<void> _selectSpecialty() async {
    List<String> specialties = [
      'Cardiologia',
      'Dermatologia',
      'Endocrinologia',
      'Gastroenterologia',
      'Geriatria',
      'Neurologia',
      'Oftalmologia',
      'Pediatria',
      'Psiquiatria',
    ];

    String? selectedSpecialty = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Selecione uma Especialidade'),
          children: specialties.map((String specialty) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, specialty);
              },
              child: Text(specialty),
            );
          }).toList(),
        );
      },
    );

    if (selectedSpecialty != null) {
      setState(() {
        _specialtyController.text = selectedSpecialty;
      });
    }
  }

  Future<void> _selectDate() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() {
        _dateController.text = selectedDate.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      final formattedTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      setState(() {
        _timeController.text = formattedTime;
      });
    }
  }

  Future<void> _saveAppointment() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String specialty = _specialtyController.text;
      String date = _dateController.text;
      String time = _timeController.text;
      String phone = _phoneController.text;

      if (specialty.isNotEmpty && date.isNotEmpty && time.isNotEmpty && phone.isNotEmpty) {
        DatabaseReference consultationsRef = _databaseReference.child('users/pacientes').child(user.uid).child('consultations');
        String newConsultationId = consultationsRef.push().key!;

        await consultationsRef.child(newConsultationId).set({
          'specialty': specialty,
          'date': date,
          'time': time,
          'convenio': _convenio,
          'phone': phone,
        });

        // Schedule WhatsApp messages
        _scheduleWhatsAppMessages(specialty, date, time);

        Navigator.pop(context);
      }
    }
  }

  Future<void> _sendWhatsAppMessage(String message) async {
    String url = 'https://wa.me/$_whatsappNumber?text=${Uri.encodeFull(message)}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _scheduleWhatsAppMessages(String specialty, String date, String time) {
    DateTime consultationDateTime = DateTime.parse('$date $time');

    // Message for when the appointment is scheduled
    _sendWhatsAppMessage('Sua consulta em $specialty foi agendada para o dia $date às $time.');

    // One day before the consultation
    DateTime oneDayBefore = consultationDateTime.subtract(Duration(days: 1));
    _scheduleNotification(oneDayBefore, 'Lembrete: Sua consulta em $specialty é amanhã às $time.');

    // One hour before the consultation
    DateTime oneHourBefore = consultationDateTime.subtract(Duration(hours: 1));
    _scheduleNotification(oneHourBefore, 'Lembrete: Sua consulta em $specialty é em uma hora, às $time.');
  }

  void _scheduleNotification(DateTime scheduledTime, String message) {
    Duration delay = scheduledTime.difference(DateTime.now());
    if (delay.isNegative) return;

    Future.delayed(delay, () {
      _sendWhatsAppMessage(message);
    });
  }

  void _goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Agendamento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Nome completo do paciente: $_patientName',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _specialtyController,
              decoration: const InputDecoration(
                labelText: 'Especialidade',
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              onTap: _selectSpecialty,
              readOnly: true,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Data',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: _selectDate,
              readOnly: true,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: 'Horário',
                suffixIcon: Icon(Icons.access_time),
              ),
              onTap: _selectTime,
              readOnly: true,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _convenio,
              onChanged: (String? newValue) {
                setState(() {
                  _convenio = newValue;
                });
              },
              items: <String>['Nenhum', 'Convênio 1', 'Convênio 2']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: 'Convênio'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Celular'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveAppointment,
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
