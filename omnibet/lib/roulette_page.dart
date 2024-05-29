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
  List<String> items = [
    '10 points', '10 points', '10 points', '10 points', // 4 instances
    '30 points', '30 points', '30 points',              // 3 instances
    '50 points', '50 points',                           // 2 instances
    '100 points',                                       // 1 instance
    '1000 points',                                      // 1 instance
  ];
  final ScrollController scrollController = ScrollController();
  bool _isSpinning = false;
  String _result = '';
  Timer? _timer;
  double _velocity = 0.0;
  final int _spinDuration = 7000; // Durée totale de la roulette en millisecondes (7 secondes)

  RouletteProvider() {
    items.shuffle(); // Mélanger les éléments pour une disposition aléatoire
  }

  bool get isSpinning => _isSpinning;
  String get result => _result;

  void startSpin() async {
    if (_isSpinning) return;
    _isSpinning = true;
    _result = '';
    _velocity = 3000.0; // Vitesse initiale plus élevée
    notifyListeners();

    // Jouer le son
    final _audioPlayer = AudioPlayer();
    await _audioPlayer.play(AssetSource('roulette.mp3'));

    // Timer pour gérer la décélération
    _timer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (_velocity > 0.1) {
        scrollController.jumpTo(scrollController.offset + _velocity * 0.016);
        _velocity *= 0.99; // Réduire la vitesse progressivement
      } else {
        timer.cancel();
        _selectResult();
      }
    });

    // Arrêter la rotation après la durée spécifiée
    Future.delayed(Duration(milliseconds: _spinDuration), () {
      _velocity = 0.1; // Ralentir la vitesse pour un arrêt en douceur
    });
  }

  void _selectResult() {
    // Calculer la position de la flèche
    double offset = scrollController.offset + 100; // Ajuster pour centrer sur l'élément

    // Diviser l'offset par la largeur de chaque élément (100) et obtenir l'index arrondi
    int itemIndex = (offset / 100).round() % items.length; // Ajuster pour centrer sur l'élément

    // Mettre à jour le résultat avec l'élément à l'index calculé
    _result = items[itemIndex];

    // Marquer la fin du spin
    _isSpinning = false;

    // Notifier les écouteurs de changement
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

    // Dégradés de couleur en fonction de la valeur de récompense
    final Map<String, Gradient> gradients = {
      '10 points': LinearGradient(
        colors: [Colors.transparent, Colors.green.withOpacity(0.8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      '30 points': LinearGradient(
        colors: [Colors.transparent, Colors.blue.withOpacity(0.8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      '50 points': LinearGradient(
        colors: [Colors.transparent, Colors.purple.withOpacity(0.8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      '100 points': LinearGradient(
        colors: [Colors.transparent, Colors.red.withOpacity(0.8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      '1000 points': LinearGradient(
        colors: [Colors.transparent, Colors.yellow.withOpacity(0.8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    };

    return Stack(
      alignment: Alignment.center,
      children: [
        // Roue de la roulette
        Container(
          height: 100,
          width: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: NeverScrollableScrollPhysics(),
            controller: provider.scrollController,
            itemBuilder: (context, index) {
              final itemIndex = index % provider.items.length;
              return Container(
                width: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  gradient: gradients[provider.items[itemIndex]]!,
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
        // Trait jaune pour indiquer le résultat
        Positioned(
          left: 150, // Ajuster cette valeur pour centrer le trait
          child: Container(
            width: 2,
            height: 100,
            color: Colors.yellow,
          ),
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
