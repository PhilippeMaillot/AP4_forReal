import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'tournamentPage.dart';  // Assurez-vous d'importer la page des tournois
import 'login_page.dart';
import 'register_page.dart';
import 'viewBetPage.dart';  // Importez la page de visualisation des paris

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

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    Text('Home Page Content'),  // Contenu de la page d'accueil
    TournamentListPage(),       // Page des tournois
    Placeholder(),     // Remplacez par une vue vide temporaire
  ];

  void _onItemTapped(int index) async {
    if (index == 2) {  // Si l'utilisateur clique sur 'Paris'
      final userId = await _getUserIdFromToken();
      if (userId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewBetPage(userId: userId),
          ),
        );
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<int?> _getUserIdFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      // Récupérer l'ID de l'utilisateur à partir du token
      final jwtPayload = json.decode(
          ascii.decode(base64.decode(base64.normalize(token.split(".")[1]))));
      final userId = jwtPayload['id'];
      return userId;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Tournois',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Paris',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
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
    await prefs.remove('token'); // Supprimez le token des préférences partagées
    await prefs.remove('user_id'); // Supprimez l'ID de l'utilisateur des préférences partagées
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false); // Redirigez vers la page de connexion et supprimez toutes les routes empilées
  }
}
