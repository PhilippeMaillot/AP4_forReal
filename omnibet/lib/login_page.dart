import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

Future<void> _login() async {
  final url = Uri.parse('http://localhost:8080/mobileuser/login');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'email': _email,
      'password': _password, // Utilisez "password" au lieu de "password_hash"
    }),
  );

  if (response.statusCode == 200) {
    final prefs = await SharedPreferences.getInstance();
    final body = json.decode(response.body);
    await prefs.setString('token', body['token']);
    debugPrint('Connexion réussie');
  } else {
    debugPrint('Erreur de connexion');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Veuillez entrer un email';
                  }
                  return null;
                },
                onSaved: (value) {
                  _email = value!;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Veuillez entrer un mot de passe';
                  }
                  return null;
                },
                onSaved: (value) {
                  _password = value!;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _login();
                  }
                },
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
