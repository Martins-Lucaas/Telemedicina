import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  Future<void> sendWhatsAppMessage(String phoneNumber, String message) async {
    String url = 'https://wa.me/$phoneNumber?text=${Uri.encodeFull(message)}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void scheduleMessagesForConsultation(String consultationId, String phoneNumber, String specialty, String date, String time) {
    // Mensagem para quando a consulta é agendada
    sendWhatsAppMessage(phoneNumber, 'Sua consulta em $specialty foi agendada para o dia $date às $time.');

    // Data e hora da consulta
    DateTime consultationDateTime = DateTime.parse('$date $time');

    // Um dia antes da consulta
    DateTime oneDayBefore = consultationDateTime.subtract(Duration(days: 1));
    _scheduleNotification(oneDayBefore, phoneNumber, 'Lembrete: Sua consulta em $specialty é amanhã às $time.');

    // Uma hora antes da consulta
    DateTime oneHourBefore = consultationDateTime.subtract(Duration(hours: 1));
    _scheduleNotification(oneHourBefore, phoneNumber, 'Lembrete: Sua consulta em $specialty é em uma hora, às $time.');
  }

  void _scheduleNotification(DateTime scheduledTime, String phoneNumber, String message) {
    // Para simplificação, use a função Future.delayed apenas como demonstração
    Duration delay = scheduledTime.difference(DateTime.now());
    if (delay.isNegative) return; // Não agende se a data/hora já passou

    Future.delayed(delay, () {
      sendWhatsAppMessage(phoneNumber, message);
    });
  }
}
