import 'package:flutter/material.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import 'splash_screen.dart';
import 'tournamentPage.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'viewBetPage.dart';
import 'profile_page.dart';
import 'shop_page.dart'; // Importez la page de la boutique
import 'roulette_page.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  get userId => null;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
        ),
      ),
      home: SplashScreen(),
      routes: {
        '/register': (context) => RegisterPage(),
        '/login': (context) => LoginPage(),
        '/home': (context) => MyHomePage(),
        '/tournament': (context) => TournamentListPage(),
        'viewbetpage': (context) => ViewBetPage(userId: userId),
        '/profile': (context) => ProfilePage(),
        '/shop': (context) => ShopPage(), // Ajoutez la route '/
        '/roulette': (context) => RoulettePage(), 
        
      },
    );
  }
}

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
    Timer.periodic(Duration(seconds: 100), (Timer t) async {
      final userInfo = await _getUserInfo();
      _userInfoSubject.add(userInfo);
    });
  }

  static List<Widget> _widgetOptions = <Widget>[
    HomePageContent(),
    TournamentListPage(),
    ShopPage(), // Ajoutez le widget pour la boutique
  ];

  void _onItemTapped(int index) async {
    if (index == 3) { // L'index de ViewBetPage est maintenant 3
      int? userId = await _getUserIdFromToken();
      if (userId != null) {
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
              return Container();
            } else {
              if (snapshot.hasError) {
                return Text('Erreur');
              } else {
                return Text(
                  snapshot.data ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                );
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
                    return Container();
                  } else {
                    if (snapshot.hasError) {
                      return Text('Erreur');
                    } else {
                      return Text(
                        snapshot.data ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      );
                    }
                  }
                },
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('Profil'),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
                ListTile(
              title: Text('roulette'),
              onTap: () {
                Navigator.pushNamed(context, '/roulette');
              },
            ),
            ListTile(
              title: Text('Se déconnecter'),
              onTap: () {
                _logout(context);
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
            icon: Icon(Icons.shop_2),
            label: 'Boutique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Paris',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color.fromARGB(255, 0, 68, 255),
        unselectedItemColor: Color.fromARGB(255, 0, 68, 255).withOpacity(0.6),
        onTap: _onItemTapped,
      ),
    );
  }

  Future<String> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      final jwtPayload = json.decode(
          ascii.decode(base64.decode(base64.normalize(token.split(".")[1]))));
      final userId = jwtPayload['id'];
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
        final userName = userInfo[0]['user_name'];
        final userBalance = userInfo[0]['balance'];
        return userName + ' OMNIPOINT: ' + userBalance.toString();
      } else {
        return 'Erreur de récupération des informations de l\'utilisateur';
      }
    } else {
      return 'Aucun utilisateur connecté';
    }
  }

  Future<int?> _getUserIdFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      final jwtPayload = json.decode(
          ascii.decode(base64.decode(base64.normalize(token.split(".")[1]))));
      final userId = jwtPayload['id'];
      return userId;
    } else {
      return null;
    }
  }

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    Navigator.pushNamedAndRemoveUntil(
        context, '/login', (route) => false);
  }
}

class HomePageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 220,
            margin: EdgeInsets.symmetric(vertical: 16.0),
            child: Swiper(
              itemBuilder: (BuildContext context, int index) {
                List<String> imageUrls = [
                       "https://image-cdn.hypb.st/https%3A%2F%2Fhypebeast.com%2Fimage%2F2021%2F01%2Ftakehiko-inoue-slam-dunk-film-adaptation-manga-announcement-info-tw2.jpg?w=1080&cbr=1&q=90&fit=max",
                  "https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/490978f0-a9b8-4f06-af58-2522b3727632/dfq08go-522596c1-08f4-4f3a-b03f-b485c592bbdf.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiJcL2ZcLzQ5MDk3OGYwLWE5YjgtNGYwNi1hZjU4LTI1MjJiMzcyNzYzMlwvZGZxMDhnby01MjI1OTZjMS0wOGY0LTRmM2EtYjAzZi1iNDg1YzU5MmJiZGYuanBnIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.YgryQ0nzHBAeMhxpmPS3OJeYsOJXi4VP7I4P3FjSiEc",
                  "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRjI8JUJPgLJaHUiNWiYW1SJX0S8KM7kCcLzg&s",
                ];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    imageUrls[index],
                    fit: BoxFit.cover,
                  ),
                );
              },
              itemCount: 3,
              autoplay: true,
              pagination: SwiperPagination(),
            ),
          ),
     Padding(
  padding: const EdgeInsets.all(8.0),
  child: Column(
    children: [
      NewsCard(
        imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcScEfqJOccH20H5de29N6GsxuKM-v0lagAS0g&s',
        title: 'Marathon de Metz : Un record battu !',
        timeAgo: 'il y a environ 3 heures',
        description: 'Le Marathon de Metz a vu un nouveau record de parcours établi ce matin. Découvrez les moments forts de la course et les témoignages des participants.',
        readMoreUrl: '#',
      ),
      NewsCard(
        imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ8vd0uTt2Y8h9fNKlWu5oEPMxCafB_t3AOzw&s',
        title: 'Championnat de Lorraine de Basketball : Résultats du week-end',
        timeAgo: 'il y a environ 6 heures',
        description: 'Retour sur les matchs du week-end avec des performances exceptionnelles et des scores serrés. Consultez les résultats et les meilleurs moments.',
        readMoreUrl: '#',
      ),
      NewsCard(
        imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQigLqMJMAMnco4euMq8l_xGbuhZKm5vKHQxg&s',
        title: 'Les meilleurs paris sportifs pour la semaine',
        timeAgo: 'il y a environ 8 heures',
        description: 'Découvrez nos conseils et astuces pour les paris sportifs de cette semaine. Nos experts vous livrent leurs pronostics pour maximiser vos gains.',
        readMoreUrl: '#',
      ),
      NewsCard(
        imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTUEU1f32XjgyOZtjrTmVQTaK65XCNEOzILxA&s',
        title: 'Les jeunes talents du football lorrain',
        timeAgo: 'il y a environ 10 heures',
        description: 'Rencontre avec les jeunes espoirs du football en Lorraine. Leur parcours, leurs ambitions et les prochains matchs à ne pas manquer.',
        readMoreUrl: '#',
      ),
      NewsCard(
        imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSOlzkS49jUTb6KnKBHA2I-AoWkZV-XvJjSSA&s',
        title: 'Handball : Lorraine en finale nationale',
        timeAgo: 'il y a environ 12 heures',
        description: 'L\'équipe de Lorraine s\'est qualifiée pour la finale nationale. Retour sur un match intense et les perspectives pour la finale.',
        readMoreUrl: '#',
      ),
      NewsCard(
        imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT8VlXWSMnSi9_0Uk4g3XkFqKtXa7I6eyuV7i7i5FH-BJgyE4ncgkcK8yBQGtJjRJgmcFU&usqp=CAU',
        title: 'Esport : La Lorraine brille au tournoi national',
        timeAgo: 'hier',
        description: 'Les équipes d\'Esport de Lorraine ont fait sensation au tournoi national, remportant plusieurs médailles. Découvrez les coulisses de leur succès.',
        readMoreUrl: '#',
      ),
    ],
  ),
),

        ],
      ),
    );
  }
}

class NewsCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String timeAgo;
  final String description;
  final String readMoreUrl;
  final Color titleColor;
  final Color timeAgoColor;
  final Color descriptionColor;
  final Color readMoreColor;

  NewsCard({
    required this.imageUrl,
    required this.title,
    required this.timeAgo,
    required this.description,
    required this.readMoreUrl,
      this.titleColor = Colors.black,
    this.timeAgoColor = Colors.grey,
    this.descriptionColor = Colors.black,
    this.readMoreColor = Colors.blue,
  });

    @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Image.network(
              imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: titleColor,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: timeAgoColor,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: descriptionColor,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () {
                        // Handle "Lire la suite" tap
                      },
                      child: Text(
                        'Lire la suite »',
                        style: TextStyle(color: readMoreColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}