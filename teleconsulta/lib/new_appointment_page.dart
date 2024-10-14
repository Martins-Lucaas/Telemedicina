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
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();
  String? _convenio = 'Nenhum';
  String _patientName = 'Nome completo do paciente';
  String _selectedDoctorId = '';
  Map<String, dynamic> _doctorSchedules = {}; // Armazena horários disponíveis por médico
  final List<Map<String, String>> _doctorList = []; // Lista de médicos pré-carregada
  final Map<String, dynamic> _doctorMap = {}; // Dados dos médicos pré-carregados

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  final String _whatsappNumber = '6294024674'; // Número de WhatsApp

  Color _specialtyButtonColor = Colors.white; // Cor inicial do botão de especialidade
  Color _dateButtonColor = Colors.white; // Cor inicial do botão de data
  Color _convenioButtonColor = Colors.white; // Cor inicial do botão de convênio

  // List of available "convênio" options
  final List<String> _convenioOptions = ['Nenhum', 'Plano A', 'Plano B', 'Plano C'];

  @override
  void initState() {
    super.initState();
    _loadPatientName();
    _loadDoctorData(); // Carregar os dados dos médicos na inicialização
  }

  @override
  void dispose() {
    _specialtyController.dispose();
    _phoneController.dispose();
    _dateController.dispose(); // Limpar o controlador
    super.dispose();
  }

  Future<void> _loadPatientName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DatabaseReference userRef = _databaseReference.child('users/patients').child(user.uid);
      final snapshot = await userRef.child('nomeCompleto').get();
      if (snapshot.exists) {
        setState(() {
          _patientName = snapshot.value?.toString() ?? 'Nome não disponível';
        });
      }
    }
  }

  Future<void> _loadDoctorData() async {
    // Buscar especialidades e horários disponíveis dos médicos no banco de dados
    DatabaseReference doctorsRef = _databaseReference.child('users/doctors');
    final snapshot = await doctorsRef.get();

    if (snapshot.exists) {
      Map<dynamic, dynamic> doctors = snapshot.value as Map<dynamic, dynamic>;

      doctors.forEach((key, value) {
        _doctorList.add({
          'id': key,
          'nomeCompleto': value['nomeCompleto']?.toString() ?? 'Nome não disponível',
          'especialidade': value['especialidade']?.toString() ?? 'Especialidade não disponível',
        });
        _doctorMap[key] = Map<String, dynamic>.from(value['disponibilidade'] ?? {}); // Puxa a disponibilidade do médico
      });

      setState(() {}); // Atualizar o estado após carregar os dados
    }
  }

  Future<void> _selectConvenio() async {
    // Exibir lista de convênios para seleção
    String? selectedConvenio = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Selecione o Convênio'),
          children: _convenioOptions.map((convenio) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, convenio);
              },
              child: Text(convenio),
            );
          }).toList(),
        );
      },
    );

    if (selectedConvenio != null) {
      setState(() {
        _convenio = selectedConvenio;
      });
    }
  }

  Future<void> _selectSpecialty() async {
    // Exibir lista de médicos e especialidades para seleção
    String? selectedDoctorId = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        if (_doctorList.isEmpty) {
          return AlertDialog(
            title: const Text('Erro'),
            content: const Text('Nenhum médico encontrado.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          );
        }
        return SimpleDialog(
          title: const Text('Selecione um Médico e Especialidade'),
          children: _doctorList.map((doctor) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, doctor['id']);
              },
              child: Text('${doctor['nomeCompleto']} - ${doctor['especialidade']}'),
            );
          }).toList(),
        );
      },
    );

    if (selectedDoctorId != null) {
      setState(() {
        _selectedDoctorId = selectedDoctorId;
        _specialtyController.text = _doctorList.firstWhere((doc) => doc['id'] == selectedDoctorId)['especialidade'] ?? 'Especialidade não disponível';
        _doctorSchedules = _doctorMap[selectedDoctorId] ?? {}; // Carregar horários do médico selecionado
      });
    }
  }

  Future<void> _selectDate() async {
    if (_selectedDoctorId.isEmpty) {
      // Mostrar uma mensagem se nenhum médico foi selecionado
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um médico primeiro.')),
      );
      return;
    }

    // Filtrar e processar horários disponíveis do médico
    List<String> availableSlots = [];
    _doctorSchedules.forEach((day, slots) {
      if (slots is List && slots.isNotEmpty && slots[0] != "Não trabalhará") {
        for (var slot in slots) {
          List<String> splitSlot = slot.split(' - ');
          if (splitSlot.length == 2) {
            String startTime = splitSlot[0];
            String endTime = splitSlot[1];

            DateTime start = _parseTime(startTime);
            DateTime end = _parseTime(endTime);

            while (start.isBefore(end)) {
              availableSlots.add('$day - ${_formatTime(start)}');
              start = start.add(const Duration(hours: 1));
            }
          }
        }
      }
    });

    // Exibir horários disponíveis para seleção
    String? selectedDateTime = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Selecione um Horário'),
          children: availableSlots.map((slot) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, slot);
              },
              child: Text(slot),
            );
          }).toList(),
        );
      },
    );

    if (selectedDateTime != null) {
      setState(() {
        _dateController.text = selectedDateTime;
      });
    }
  }

  DateTime _parseTime(String time) {
    final timeParts = time.split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    return DateTime(0, 1, 1, hour, minute);
  }

  String _formatTime(DateTime time) {
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Validação do número de telefone
  bool _isPhoneValid(String phone) {
    final phonePattern = RegExp(r'^[0-9]{10,11}$'); // Aceita números de 10 a 11 dígitos
    return phonePattern.hasMatch(phone);
  }

  Future<void> _saveAppointment() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String specialty = _specialtyController.text.isNotEmpty ? _specialtyController.text : 'Especialidade não disponível';
      String date = _dateController.text.isNotEmpty ? _dateController.text : 'Data não selecionada';
      String phone = _phoneController.text;

      // Validação do número de telefone
      if (!_isPhoneValid(phone)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Número de telefone inválido. Por favor, insira um número válido.')),
        );
        return;
      }

      if (specialty.isNotEmpty && date.isNotEmpty && phone.isNotEmpty) {
        DatabaseReference consultationsRef = _databaseReference.child('users/patients').child(user.uid).child('consultations');
        String newConsultationId = consultationsRef.push().key!;

        await consultationsRef.child(newConsultationId).set({
          'specialty': specialty,
          'date': date,
          'convenio': _convenio ?? 'Nenhum',
          'phone': phone,
        });

        _scheduleWhatsAppMessages(specialty, date);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agendamento confirmado com sucesso!')),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, preencha todos os campos.')),
        );
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

  void _scheduleWhatsAppMessages(String specialty, String date) {
    _sendWhatsAppMessage('Sua consulta em $specialty foi agendada para o dia $date.');

    DateTime consultationDateTime = DateTime.parse(date);
    DateTime oneDayBefore = consultationDateTime.subtract(const Duration(days: 1));
    _scheduleNotification(oneDayBefore, 'Lembrete: Sua consulta em $specialty é amanhã.');

    DateTime oneHourBefore = consultationDateTime.subtract(const Duration(hours: 1));
    _scheduleNotification(oneHourBefore, 'Lembrete: Sua consulta em $specialty é em uma hora.');
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
        backgroundColor: Colors.white,
        elevation: 5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _goBack,
        ),
        title: const Text(
          'Novo Agendamento',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: ListTile(
                  title: const Text(
                    'Nome completo do paciente',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF149393),
                    ),
                  ),
                  subtitle: Text(
                    _patientName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildSpecialtyButton(), // Botão para selecionar a especialidade
              const SizedBox(height: 20),
              _buildConvenioButton(), // Botão para selecionar o convênio
              const SizedBox(height: 20),
              _buildDateButton(), // Botão para selecionar a data
              const SizedBox(height: 20),
              _buildTextField('Telefone', _phoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF149393), // Cor do botão
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Confirmar Agendamento'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialtyButton() {
    return InkWell(
      onTap: _selectSpecialty,
      onHover: (isHovering) {
        setState(() {
          _specialtyButtonColor = isHovering ? Colors.grey[300]! : Colors.white;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: _specialtyButtonColor,
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _specialtyController.text.isEmpty ? 'Selecione a Especialidade' : _specialtyController.text,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildConvenioButton() {
    return InkWell(
      onTap: _selectConvenio,
      onHover: (isHovering) {
        setState(() {
          _convenioButtonColor = isHovering ? Colors.grey[300]! : Colors.white;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: _convenioButtonColor,
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _convenio ?? 'Selecione o Convênio',
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton() {
    return InkWell(
      onTap: _selectDate,
      onHover: (isHovering) {
        setState(() {
          _dateButtonColor = isHovering ? Colors.grey[300]! : Colors.white;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: _dateButtonColor,
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _dateController.text.isEmpty ? 'Selecione a Data e Hora' : _dateController.text,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {VoidCallback? onTap, TextInputType keyboardType = TextInputType.text}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: ListTile(
          title: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
            ),
            readOnly: onTap != null,
            keyboardType: keyboardType,
          ),
        ),
      ),
    );
  }
}
