import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import 'splash_screen.dart'; // Importez votre Splash Screen
import 'tournamentPage.dart'; // Assurez-vous d'importer la page des tournois
import 'login_page.dart';
import 'register_page.dart';
import 'viewBetPage.dart'; // Importez la page de visualisation des paris
import 'profile_page.dart'; // Importez la page de profil
import 'shop_page.dart'; // Importez la page de la boutique

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      // Utilisez votre Splash Screen comme page d'accueil
      home: SplashScreen(), 
      routes: {
        '/register': (context) => RegisterPage(),
        '/login': (context) => LoginPage(),
        '/home': (context) => MyHomePage(),
        '/tournament': (context) => TournamentListPage(), // Ajoutez la route '/tournament'
        '/profile': (context) => ProfilePage(), // Ajoutez la route '/profile'
        '/shop': (context) => ShopPage(), // Ajoutez la route '/shop'

      },
    );
  }
}

// Votre Splash Screen
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Vérifiez si l'utilisateur est connecté ou non
    if (token != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  late Future<int?> _userIdFuture;
  final BehaviorSubject<String> _userInfoSubject = BehaviorSubject<String>();

  @override
  void initState() {
    super.initState();
    _userIdFuture = _getUserIdFromToken();
    _fetchUserInfo();
  }

  @override
  void dispose() {
    _userInfoSubject.close();
    super.dispose();
  }

  Future<void> _fetchUserInfo() async {
    final userInfo = await _getUserInfo();
    _userInfoSubject.add(userInfo);
    // Actualiser périodiquement les informations de l'utilisateur
    Timer.periodic(Duration(seconds: 100), (Timer t) async {
      final userInfo = await _getUserInfo();
      _userInfoSubject.add(userInfo);
    });
  }

  static List<Widget> _widgetOptions = <Widget>[
    Text('Home Page Content'), // Contenu de la page d'accueil
    TournamentListPage(), // Page des tournois
  ];

  void _onItemTapped(int index) async {
    if (index == 2) {
      // Si l'utilisateur clique sur "Paris"
      int? userId = await _getUserIdFromToken();
      if (userId != null) {
        print('User ID: $userId');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ViewBetPage(userId: userId)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur : Utilisateur non connecté.')));
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<String>(
          stream: _userInfoSubject.stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(); // Retourne un widget vide pendant que les infos sont chargées
            } else {
              if (snapshot.hasError) {
                return Text('Erreur'); // Affiche un message d'erreur s'il y a eu une erreur
              } else {
                return Text(
                  snapshot.data ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ); // Affiche le nom d'utilisateur une fois qu'il est disponible
              }
            }
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: StreamBuilder<String>(
                stream: _userInfoSubject.stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(); // Retourne un widget vide pendant que les infos sont chargées
                  } else {
                    if (snapshot.hasError) {
                      return Text('Erreur'); // Affiche un message d'erreur s'il y a eu une erreur
                    } else {
                      return Text(
                        snapshot.data ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ); // Affiche le nom d'utilisateur une fois qu'il est disponible
                    }
                  }
                },
              ),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 0, 3, 5),
              ),
            ),
            ListTile(
              title: Text('Profil'),
              onTap: () {
                Navigator.pushNamed(context, '/profile'); // Redirige vers la page de profil
              },
            ),
            ListTile(
              title: Text('Se déconnecter'),
              onTap: () {
                _logout(context); // Déclenche la déconnexion
              },
            ),
          ],
        ),
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

      // Récupérer les informations de l'utilisateur àpartir de la base de données
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
    final userName = userInfo[0]['user_name'];
    final userBalance = userInfo[0]['balance'];
    // Obtenez uniquement le nom d'utilisateur
    print(userName);
    print('OMNIPOINT:' + userBalance.toString());

    return userName +
        ' OMNIPOINT: ' +
        userBalance.toString(); // Retourner le nom d'utilisateur + point
  } else {
    return 'Erreur de récupération des informations de l\'utilisateur';
  }
} else {
  return 'Aucun utilisateur connecté';
}
}

Future<int?> _getUserIdFromToken() async {
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('token');if (token != null) {
  // Récupérer l'ID de l'utilisateur à partir du token
  final jwtPayload = json.decode(
      ascii.decode(base64.decode(base64.normalize(token.split(".")[1]))));
  final userId = jwtPayload['id'];
  print(userId); // Affichez l'ID de l'utilisateur dans la console
  return userId;
} else {
  return null;
}
}

void _logout(BuildContext context) async {
final prefs = await SharedPreferences.getInstance();
await prefs.remove('token'); // Supprimez le token des préférences partagées
await prefs.remove('user_id'); // Supprimez l'ID de l'utilisateur des préférences partagées
Navigator.pushNamedAndRemoveUntil(
context, '/login', (route) => false); // Redirigez vers la page de connexion et supprimez toutes les routes empilées
}
}