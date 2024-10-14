import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:xml/xml.dart' as xml;

class ProntuarioPage extends StatefulWidget {
  const ProntuarioPage({super.key});

  @override
  _ProntuarioPageState createState() => _ProntuarioPageState();
}

class _ProntuarioPageState extends State<ProntuarioPage> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  
  // Controladores para os campos de paciente
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _idadeController = TextEditingController();
  final TextEditingController _dataNascimentoController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _alturaController = TextEditingController();
  final TextEditingController _rgController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();

  // Controlador para Observações e CID-10
  final TextEditingController _observacoesController = TextEditingController();
  final TextEditingController _cidController = TextEditingController();

  // Dados do CID-10 carregados do XML
  final List<Map<String, String>> _cid10List = [];
  List<Map<String, String>> _filteredCID10 = [];

  @override
  void initState() {
    super.initState();
    _loadCID10FromFile(); // Carrega os dados do CID-10 ao inicializar
  }

  // Função para carregar o CID-10 a partir do arquivo XML
  Future<void> _loadCID10FromFile() async {
    final xmlString = await rootBundle.loadString('assets/CID10.xml');
    final document = xml.XmlDocument.parse(xmlString);
    
    final categories = document.findAllElements('categoria');
    for (var category in categories) {
      final code = category.getAttribute('codcat')!;
      final name = category.findElements('nome').first.text;
      
      _cid10List.add({'codigo': code, 'nome': name});
    }

    // Verifique se os dados foram carregados
    print('CID-10 loaded: ${_cid10List.length} items');
  }

  // Função para filtrar as sugestões de CID-10
  void _filterCID10(String query) {
    setState(() {
      _filteredCID10 = _cid10List
          .where((cid) => cid['nome']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });

    // Verifique as sugestões filtradas
    print('Filtered CID-10: ${_filteredCID10.length} items');
  }

  // Função para buscar pacientes do Firebase
  Future<List<Map<String, dynamic>>> _getPatientsSuggestions(String query) async {
    DatabaseReference patientsRef = _databaseReference.child('users/patients');
    DataSnapshot snapshot = await patientsRef.get();

    if (snapshot.exists) {
      Map<dynamic, dynamic> patients = snapshot.value as Map<dynamic, dynamic>;
      return patients.values
          .where((patient) =>
              (patient['nomeCompleto'] as String).toLowerCase().contains(query.toLowerCase()))
          .map((patient) => Map<String, dynamic>.from(patient))
          .toList();
    }
    return [];
  }

  // Função para preencher os detalhes do paciente
  void _fillPatientDetails(Map<String, dynamic> patient) {
    _idadeController.text = patient['idade'].toString();
    _dataNascimentoController.text = patient['dataNascimento'];
    _pesoController.text = patient['peso'].toString();
    _alturaController.text = patient['altura'].toString();
    _rgController.text = patient['rg'];
    _enderecoController.text = patient['endereco'];
  }

  // Função para salvar o prontuário no Firebase
  Future<void> _saveProntuario() async {
    DatabaseReference prontuarioRef = FirebaseDatabase.instance.ref().child('prontuarios').push();
    await prontuarioRef.set({
      'cid10': _cidController.text,
      'observacoes': _observacoesController.text,
      'createdAt': DateTime.now().toIso8601String(),
      'nomePaciente': _nomeController.text,
      'idade': _idadeController.text,
      'dataNascimento': _dataNascimentoController.text,
      'peso': _pesoController.text,
      'altura': _alturaController.text,
      'rg': _rgController.text,
      'endereco': _enderecoController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prontuário salvo com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF149393),
        title: const Text('Prontuário Eletrônico'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            width: 600, // Largura fixa para manter o layout centralizado
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome do paciente com autocomplete
                TypeAheadFormField<Map<String, dynamic>>(
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do paciente',
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  suggestionsCallback: (query) async {
                    return await _getPatientsSuggestions(query);
                  },
                  itemBuilder: (context, Map<String, dynamic> suggestion) {
                    return ListTile(
                      title: Text(suggestion['nomeCompleto']),
                    );
                  },
                  onSuggestionSelected: (suggestion) {
                    _nomeController.text = suggestion['nomeCompleto'];
                    _fillPatientDetails(suggestion);
                  },
                  noItemsFoundBuilder: (context) => const Text('Nenhum paciente encontrado'),
                ),
                const SizedBox(height: 20),

                // Linha com Idade, Data de nascimento, Peso e Altura
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _idadeController,
                        decoration: const InputDecoration(
                          labelText: 'Idade',
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _dataNascimentoController,
                        decoration: const InputDecoration(
                          labelText: 'Data de nascimento',
                          hintText: 'DD/MM/AAAA',
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _pesoController,
                        decoration: const InputDecoration(
                          labelText: 'Peso (kg)',
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _alturaController,
                        decoration: const InputDecoration(
                          labelText: 'Altura (cm)',
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // RG e Endereço
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _rgController,
                        decoration: const InputDecoration(
                          labelText: 'RG',
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _enderecoController,
                        decoration: const InputDecoration(
                          labelText: 'Endereço',
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Observações
                TextField(
                  controller: _observacoesController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Campo de busca para CID-10
                TextField(
                  controller: _cidController,
                  decoration: const InputDecoration(
                    labelText: 'CID-10',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _filterCID10,
                ),
                // Exibe as sugestões de CID-10
                _filteredCID10.isNotEmpty
                    ? SizedBox(
                        height: 200, // Define uma altura para as sugestões
                        child: ListView.builder(
                          itemCount: _filteredCID10.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text('${_filteredCID10[index]['codigo']} - ${_filteredCID10[index]['nome']}'),
                              onTap: () {
                                setState(() {
                                  _cidController.text = '${_filteredCID10[index]['codigo']} - ${_filteredCID10[index]['nome']}';
                                  _filteredCID10.clear(); // Limpa as sugestões após a seleção
                                });
                              },
                            );
                          },
                        ),
                      )
                    : const SizedBox(),
                const SizedBox(height: 20),

                // Botão Concluir
                Center(
                  child: ElevatedButton(
                    onPressed: _saveProntuario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF149393),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Concluir',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
