import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'tournamentPage.dart';  // Assurez-vous d'importer la page des tournois
import 'login_page.dart';
import 'register_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
      routes: {
        '/register': (context) => RegisterPage(),
        '/login': (context) => LoginPage(),
        '/home': (context) => MyHomePage(),
        '/tournament': (context) => TournamentListPage(),  // Ajoutez la route '/tournament
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<String>(
              future: _getUserInfo(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text('Bienvenue, ${snapshot.data}');
                } else if (snapshot.hasError) {
                  return Text('Erreur : ${snapshot.error}');
                }
                return CircularProgressIndicator();
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/tournament');
              },
              child: Text('Voir les tournois'),
            ),
            ElevatedButton(
              onPressed: () {
                _logout(context);
              },
              child: Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    );
  }

Future<String> _getUserInfo() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token != null) {
    // Récupérer l'ID de l'utilisateur à partir du token
    final jwtPayload = json.decode(
        ascii.decode(base64.decode(base64.normalize(token.split(".")[1]))));
    final userId = jwtPayload['id'];

    // Récupérer les informations de l'utilisateur à partir de la base de données
    final url = Uri.parse('http://localhost:8080/mobileuser/getUserInfo/$userId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
     
    );

    if (response.statusCode == 200) {
      final userInfo = json.decode(response.body);
      print(userInfo);
      final userName = userInfo[0];
      print(userName);
      return 'Nom d\'utilisateur: $userName'; // Retourner le nom d'utilisateur
    } else {
     
      return 'Erreur de récupération des informations de l\'utilisateur';
    }
  } else {
    return 'Aucun utilisateur connecté';
  }
}


  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('user_id'); // Supprimez l'ID de l'utilisateur des préférences partagées
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false); // Redirigez vers la page de connexion et supprimez toutes les routes empilées
  }
}
