import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // Para formatar a data

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _crmController = TextEditingController();
  final _specialtyController = TextEditingController(); // Controlador para a especialidade
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _selectedUserType;
  bool _showRegistrationForm = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  void _formatDateOfBirth(String value) {
    String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length > 8) {
      digitsOnly = digitsOnly.substring(0, 8);
    }

    String formattedDate = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2 || i == 4) {
        formattedDate += '/';
      }
      formattedDate += digitsOnly[i];
    }

    _dateOfBirthController.text = formattedDate;
    _dateOfBirthController.selection = TextSelection.fromPosition(
      TextPosition(offset: _dateOfBirthController.text.length),
    );
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

  Future<void> _register() async {
    try {
      if (_selectedUserType == 'Médico') {
        String crm = _crmController.text.trim();
        if (crm.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CRM é obrigatório para médicos.')),
          );
          return;
        }
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child('users');

      if (_selectedUserType == 'Médico') {
        usersRef.child('doctors').child(userCredential.user!.uid).set({
          'nomeCompleto': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'dataNascimento': _dateOfBirthController.text.trim(),
          'crm': _crmController.text.trim(),
          'especialidade': _specialtyController.text.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        });
      } else if (_selectedUserType == 'Paciente') {
        usersRef.child('patients').child(userCredential.user!.uid).set({
          'nomeCompleto': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'dataNascimento': _dateOfBirthController.text.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada com sucesso!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao criar conta: $e')),
      );
    }
  }

  void _selectUserType(String userType) {
    setState(() {
      _selectedUserType = userType;
      _showRegistrationForm = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Conta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Selecione o tipo de usuário:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _selectUserType('Médico'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedUserType == 'Médico' ? Colors.green : Colors.grey,
                    ),
                    child: const Text('Médico'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => _selectUserType('Paciente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedUserType == 'Paciente' ? Colors.blue : Colors.grey,
                    ),
                    child: const Text('Paciente'),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              if (_showRegistrationForm) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome Completo'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _dateOfBirthController,
                  decoration: InputDecoration(
                    labelText: 'Data de Nascimento',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                    hintText: 'dd/mm/aaaa',
                  ),
                  keyboardType: TextInputType.datetime,
                  onChanged: _formatDateOfBirth,
                ),

                if (_selectedUserType == 'Médico') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _crmController,
                    decoration: const InputDecoration(labelText: 'CRM'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _specialtyController,
                    decoration: const InputDecoration(
                      labelText: 'Especialidade',
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    onTap: _selectSpecialty,
                    readOnly: true,
                  ),
                ],

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _register,
                  child: const Text('Registrar'),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
