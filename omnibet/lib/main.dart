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
        '/profile': (context) => ProfilePage(),
        '/tournament': (context) => TournamentListPage(), // Ajoutez la route '/tournament'
        '/profile': (context) => ProfilePage(), // Ajoutez la route '/profile'
        '/shop': (context) => ShopPage(), // Ajoutez la route '/shop'

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
  ];

  void _onItemTapped(int index) async {
    if (index == 2) {
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
        children: [
          Container(
            height: 200,
            margin: EdgeInsets.symmetric(vertical: 16.0),
            child: Swiper(
              itemBuilder: (BuildContext context, int index) {
                List<String> imageUrls = [
                  "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ63emjthouUvgWo_rCj0jcPiMV8ny1dNeImA&s",
                  "https://community.adobe.com/legacyfs/online/1188949_Prime%20Sports%20Edits.jpg",
                  "https://i.ytimg.com/vi/cqZFa8aivdY/maxresdefault.jpg",
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
            child: StaggeredGridView.countBuilder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              itemCount: 7, // Vous avez 7 URL d'images à afficher
              itemBuilder: (BuildContext context, int index) {
                List<String> imageUrls = [
                  // Ajoutez vos URL d'images ici
                  "data:image/jpeg;base64,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",
                  "data:image/jpeg;base64,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",
                  "https://mir-s3-cdn-cf.behance.net/project_modules/hd/59c8a618959511.562d2496304b8.png",
                  "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTX7EtCfB3g0JthpwPUDH37lkwxiVVzdHH5ztNCzxqllTlWGfRALOkZKe9XGiEmhQoEP7k&usqp=CAU",
                  "https://fiverr-res.cloudinary.com/images/q_auto,f_auto/gigs/188241821/original/06c7729b544aa63bc3698687ad747767b6e7a1b9/do-sports-edits-in-photoshop.jpg",
                  "https://www.befunky.com/images/wp/wp-2019-03-Sports-Photography-Tips-8.jpg?auto=avif,webp&format=jpg&width=944",
                  "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQFgL5r2y6K34Q70E_bpYGiBApEdw5Gio5H5A&s",
                ];
                if (index < imageUrls.length) {
                  return Container(
                    // Remplacez ce Container par un widget Image pour afficher une image
                    child: Image.network(
                      imageUrls[index],
                      fit: BoxFit.cover, // Vous pouvez ajuster le mode de redimensionnement de l'image selon vos besoins
                    ),
                  );
                } else {
                  // Si l'index dépasse le nombre d'URL d'image disponibles, vous pouvez afficher un conteneur vide ou un widget de remplacement
                  return Container(); // Vous pouvez ajuster ce comportement selon vos besoins
                }
              },
              staggeredTileBuilder: (int index) =>
                  StaggeredTile.count(2, index.isEven ? 2 : 1),
              mainAxisSpacing: 4.0,
              crossAxisSpacing: 4.0,
            ),
          ),
        ],
      ),
    );
  }
}
