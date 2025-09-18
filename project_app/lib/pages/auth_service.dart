import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'http://10.0.2.2:6006/auth';

  Future<void> signup(String firstname, String lastname, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstname': firstname,
        'lastname': lastname,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur lors de l\'inscription : ${response.body}');
    }
  }

  Future<String> login(String email, String password) async {
    print('Envoi de la requête à $baseUrl/login');
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    print('Réponse reçue - Statut: ${response.statusCode}, Corps: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      String accessToken = data['accessToken'] ?? data['access_token'];
      if (accessToken == null) {
        throw Exception('Token non trouvé dans la réponse : ${response.body}');
      }

      // Décoder le token pour extraire userId
      try {
        final decoded = JwtDecoder.decode(accessToken);
        final userId = decoded['userId'] as String?;
        if (userId != null) {
          await saveUserId(userId);
          print('UserId sauvegardé : $userId');
        }
      } catch (e) {
        print('Erreur lors du décodage du token pour userId : $e');
      }

      await _saveToken(accessToken);
      return accessToken;
    } else {
      throw Exception('Erreur lors de la connexion : ${response.body}');
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken'); // Clé corrigée
    if (token == null) return null;

    try {
      final decoded = JwtDecoder.decode(token); // Correction : JwtDecoder.decode
      final exp = decoded['exp'] as int?;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (exp == null || exp < now) {
        print('Token expiré ou invalide : $token');
        await logout();
        return null;
      }
      return token;
    } catch (e) {
      print('Erreur lors du décodage du token : $e');
      await logout();
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('userId'); // Supprime aussi userId
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }
}