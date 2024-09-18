// Importa os pacotes necessários.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'package:firebase_database/firebase_database.dart';

// Função principal que inicializa o aplicativo.
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Garante que os widgets do Flutter estejam vinculados.
  await Firebase.initializeApp( // Inicializa o Firebase com as opções atuais da plataforma.
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp()); // Executa o aplicativo.
}

// Classe principal do aplicativo.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), // Define o tema do aplicativo.
        useMaterial3: true,
      ),
      home: const LoginPage(), // Define a página inicial como a página de login.
    );
  }
}

// Classe para a página inicial do aplicativo.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// Estado da classe MyHomePage.
class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0; // Inicializa um contador.
  String? _userEmail; // Armazena o e-mail do usuário.

  // Referência ao banco de dados do Firebase.
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Carrega os dados do usuário ao inicializar o estado.
  }

  // Método para carregar os dados do usuário.
  void _loadUserData() {
    User? user = FirebaseAuth.instance.currentUser; // Obtém o usuário atual.
    if (user != null) {
      // Cria uma referência ao nó 'users' no banco de dados.
      DatabaseReference userRef = _databaseReference.child('users').child(user.uid);
      userRef.once().then((DatabaseEvent event) {
        setState(() {
          // Atualiza o estado com o e-mail do usuário.
          _userEmail = event.snapshot.child('email').value.toString();
        });
      });
    }
  }

  // Método para incrementar o contador.
  void _incrementCounter() {
    setState(() {
      _counter++; // Incrementa o contador.
      // Atualiza o valor do contador no banco de dados.
      _databaseReference.child('counter').set(_counter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title), // Define o título do AppBar.
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Exibe o e-mail do usuário ou uma mensagem de carregando.
            Text(
              _userEmail != null ? 'Logado como: $_userEmail' : 'Carregando...',
            ),
            const Text(
              'Você pressionou o botão esta quantidade de vezes:',
            ),
            Text(
              '$_counter', // Exibe o valor do contador.
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      // Botão flutuante para incrementar o contador.
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter, // Chama o método de incrementar ao pressionar.
        tooltip: 'Incrementar',
        child: const Icon(Icons.add),
      ),
    );
  }
}
