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
        children: [
          Container(
            height: 200,
            margin: EdgeInsets.symmetric(vertical: 16.0),
            child: Swiper(
              itemBuilder: (BuildContext context, int index) {
                List<String> imageUrls = [
                  "data:image/jpeg;base64,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",
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
            child: StaggeredGridView.countBuilder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              itemCount: 7, // Vous avez 7 URL d'images à afficher
              itemBuilder: (BuildContext context, int index) {
                List<String> imageUrls = [
                  // Ajoutez vos URL d'images ici
                  "https://media.istockphoto.com/id/75404984/fr/photo/équipe-de-football-dans-un-huddle.jpg?s=612x612&w=0&k=20&c=J4XhanIIUyYhI5iIr17p9exRKoWcLq7RmSXy-JF7g8M=",
                  "https://mir-s3-cdn-cf.behance.net/project_modules/hd/59c8a618959511.562d2496304b8.png",
                  "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTX7EtCfB3g0JthpwPUDH37lkwxiVVzdHH5ztNCzxqllTlWGfRALOkZKe9XGiEmhQoEP7k&usqp=CAU",
                  "https://fiverr-res.cloudinary.com/images/q_auto,f_auto/gigs/188241821/original/06c7729b544aa63bc3698687ad747767b6e7a1b9/do-sports-edits-in-photoshop.jpg",
                  "https://t3.ftcdn.net/jpg/05/68/91/26/360_F_568912687_xLEhw6lEaF8coSlWvNKPbUibhJQoAUxU.jpg",
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
