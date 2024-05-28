import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';


class RoulettePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RouletteProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Roulette du jour OmniBet'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RouletteWidget(),
              SizedBox(height: 20),
              SpinButton(),
              SizedBox(height: 20),
              ResultDisplay(),
            ],
          ),
        ),
      ),
    );
  }
}

class RouletteProvider extends ChangeNotifier {
  final List<String> items = [
    '10 point',
    '30 point',
    '50 point',
    '100 point',
    '1000 point',
  ];
  final ScrollController scrollController = ScrollController();
  bool _isSpinning = false;
  String _result = '';
  Timer? _timer;
  double _velocity = 100.0; // Vitesse initiale élevée
  int _totalDuration = 600; // Durée totale de la roulette en millisecondes (9 secondes)

  bool get isSpinning => _isSpinning;
  String get result => _result;

  void startSpin () async {

    if (_isSpinning) return;
    _isSpinning = true;
    _result = '';
    notifyListeners();

    // Jouer le son

    final _audioPlayer = AudioPlayer();
    await _audioPlayer.play(AssetSource('roulette.mp3'));
    final random = Random();
   
    int spinDuration = random.nextInt(3000) + 6000; // Durée de rotation aléatoire entre 6 et 9 secondes

    _timer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (_velocity > 0.1) {
        scrollController.jumpTo(scrollController.offset + _velocity);
        _velocity *= 0.995; // Réduire lentement la vitesse pour une décélération plus lente
      } else {
        timer.cancel();
        _selectResult();
      }
    });

    // Arrêter la rotation après la durée spécifiée
    Future.delayed(Duration(milliseconds: _totalDuration), () {
      _velocity = 1.0; // Ralentir la vitesse pour un arrêt en douceur
    });
  }

  void _selectResult() {
    // Calculer la position de la flèche
    double offset = scrollController.offset + 200; // 200 pour aligner avec la flèche de droite
    int itemIndex = (offset / 100).round() % items.length; // Ajuster pour centrer sur l'élément
    _result = items[itemIndex];
    _isSpinning = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    scrollController.dispose();
    super.dispose();
  }
}

class RouletteWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RouletteProvider>(context);

    double arrowPositionX = 240; // Position de départ de la flèche
    double arrowPositionY = -20;

    // Récupérer la taille de la liste pour centrer la flèche
    double listWidth = 300;
    double listItemWidth = 100;
    double listCenterX = listWidth / 2 - listItemWidth / 2;

    // Si la roulette ne tourne pas, centrer la flèche
    if (!provider.isSpinning) {
      arrowPositionX = listCenterX;
    }

    return Stack(
      children: [
        Container(
          height: 100,
          width: listWidth,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: NeverScrollableScrollPhysics(),
            controller: provider.scrollController,
            itemBuilder: (context, index) {
              final itemIndex = index % provider.items.length;
              return Container(
                width: listItemWidth,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Center(
                  child: Text(
                    provider.items[itemIndex],
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
            itemCount: provider.items.length * 100,
          ),
        ),
        // Flèche avec position dynamique
        AnimatedPositioned(
          duration: Duration(milliseconds: 500), // Durée de l'animation
          curve: Curves.easeInOut, // Courbe d'animation
          left: arrowPositionX,
          top: arrowPositionY,
          child: Icon(Icons.arrow_drop_down, size: 40, color: Colors.red),
        ),
      ],
    );
  }
}

class SpinButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RouletteProvider>(context);

    return ElevatedButton(
      onPressed: provider.isSpinning ? null : () => provider.startSpin(),
      child: Text('Start Spin'),
      
    );
  }
}

class ResultDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RouletteProvider>(context);

    return Text(
      provider.result.isEmpty ? '' : 'You won: ${provider.result}',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }
}
