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
  final _ageController = TextEditingController(); // Controlador para a idade
  final _weightController = TextEditingController(); // Controlador para o peso
  final _heightController = TextEditingController(); // Controlador para a altura
  final _rgController = TextEditingController(); // Controlador para o RG
  final _addressController = TextEditingController(); // Controlador para o endereço
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
          'idade': _ageController.text.trim(),
          'peso': _weightController.text.trim(),
          'altura': _heightController.text.trim(),
          'rg': _rgController.text.trim(),
          'endereco': _addressController.text.trim(),
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
        backgroundColor: const Color(0xFF149393),
        title: const Text('Registrar Conta', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Selecione o tipo de usuário:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF149393)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => _selectUserType('Médico'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        decoration: BoxDecoration(
                          color: _selectedUserType == 'Médico' ? const Color(0xFF149393) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Text(
                          'Médico',
                          style: TextStyle(
                            color: _selectedUserType == 'Médico' ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _selectUserType('Paciente'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        decoration: BoxDecoration(
                          color: _selectedUserType == 'Paciente' ? const Color(0xFF149393) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Text(
                          'Paciente',
                          style: TextStyle(
                            color: _selectedUserType == 'Paciente' ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                if (_showRegistrationForm) ...[
                  _buildTextField(_nameController, 'Nome Completo', Icons.person),
                  const SizedBox(height: 15),
                  _buildTextField(_emailController, 'E-mail', Icons.email),
                  const SizedBox(height: 15),
                  _buildTextField(_passwordController, 'Senha', Icons.lock, obscureText: true),
                  const SizedBox(height: 15),
                  _buildTextField(_dateOfBirthController, 'Data de Nascimento', Icons.calendar_today,
                      onTap: () => _selectDate(context), readOnly: true),
                  if (_selectedUserType == 'Paciente') ...[
                    const SizedBox(height: 15),
                    _buildTextField(_ageController, 'Idade', Icons.cake),
                    const SizedBox(height: 15),
                    _buildTextField(_weightController, 'Peso (kg)', Icons.monitor_weight),
                    const SizedBox(height: 15),
                    _buildTextField(_heightController, 'Altura (cm)', Icons.height),
                    const SizedBox(height: 15),
                    _buildTextField(_rgController, 'RG', Icons.perm_identity),
                    const SizedBox(height: 15),
                    _buildTextField(_addressController, 'Endereço', Icons.location_on),
                  ],
                  if (_selectedUserType == 'Médico') ...[
                    const SizedBox(height: 15),
                    _buildTextField(_crmController, 'CRM', Icons.badge),
                    const SizedBox(height: 15),
                    _buildTextField(_specialtyController, 'Especialidade', Icons.arrow_drop_down),
                  ],
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: const Color(0xFF149393),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Registrar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool obscureText = false, VoidCallback? onTap, bool readOnly = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: const Color(0xFF149393)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF149393)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF149393), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
    );
  }
}
