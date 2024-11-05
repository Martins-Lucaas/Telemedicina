import 'dart:convert';
import 'package:http/http.dart' as http;

class WhatsAppHelper {
  final String accessToken = 'EAAZADl1dPmS8BO0EVu3LndbRvwQ4nfbaRa4ERyED664u4wjSh5sxQHEncX3TOIdDwKqFV6Rd6VxZBLR2Is7msoHufH3TyCF6MgdWNhy89wzjLAPTXvZBfp0govy1dEZAEDGok2MuTmEYVrtmhcC8J61McpuJE5pDFh4qd0ISPn1zKp155I0nZAiFVKJcenZB3p';
  final String fromPhoneNumberId = '470750332779819'; // ID do número de telefone registrado

  Future<void> sendTemplateMessage(String recipientNumber) async {
    final Uri url = Uri.parse('https://graph.facebook.com/v20.0/$fromPhoneNumberId/messages');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'messaging_product': 'whatsapp',
        'to': recipientNumber,
        'type': 'template',
        'template': {
          'name': 'hello_world', // Nome do template aprovado
          'language': {
            'code': 'en_US', // Idioma do template, conforme mostrado na imagem
          },
        },
      }),
    );

    if (response.statusCode == 200) {
      print('Template message sent successfully!');
    } else {
      print('Failed to send template message. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }
}
