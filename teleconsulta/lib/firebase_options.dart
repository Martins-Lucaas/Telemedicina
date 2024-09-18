import 'package:firebase_core/firebase_core.dart';

/// Classe que fornece as opções padrão de configuração do Firebase.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "AIzaSyC_p0P4RczIbHWVjhi1u8rMgPCrP4MAf6M",
      authDomain: "esp32-biomedicaleng.firebaseapp.com",
      databaseURL: "https://esp32-biomedicaleng-default-rtdb.firebaseio.com",
      projectId: "esp32-biomedicaleng",
      storageBucket: "esp32-biomedicaleng.appspot.com",
      messagingSenderId: "916855352760",
      appId: "1:916855352760:web:73cc8d198ef4fb8673f34d",
      measurementId: "G-HSHNQ1MPY6",
    );
  }
}
