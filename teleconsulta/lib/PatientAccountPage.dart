import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PatientAccountPage extends StatefulWidget {
  const PatientAccountPage({super.key});

  @override
  _PatientAccountPageState createState() => _PatientAccountPageState();
}

class _PatientAccountPageState extends State<PatientAccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  final Map<String, String> _userData = {
    'Nome Completo': 'Carregando...',
    'Email': 'Carregando...',
    'Data de Nascimento': 'Carregando...',
    'Idade': 'Carregando...',
    'Peso (kg)': 'Carregando...',
    'Altura (cm)': 'Carregando...',
    'RG': 'Carregando...',
    'Endereço': 'Carregando...',
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DatabaseReference userRef = _databaseReference.child('users/patients').child(user.uid);
      final snapshot = await userRef.get();
      if (snapshot.exists) {
        setState(() {
          _userData['Nome Completo'] = snapshot.child('nomeCompleto').value.toString();
          _userData['Email'] = snapshot.child('email').value.toString();
          _userData['Data de Nascimento'] = snapshot.child('dataNascimento').value.toString();
          _userData['Idade'] = snapshot.child('idade').value.toString();
          _userData['Peso (kg)'] = snapshot.child('peso').value.toString();
          _userData['Altura (cm)'] = snapshot.child('altura').value.toString();
          _userData['RG'] = snapshot.child('rg').value.toString();
          _userData['Endereço'] = snapshot.child('endereco').value.toString();
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
              // Exibir todas as informações do paciente
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
            ],
          ),
        ),
      ),
    );
  }
}
