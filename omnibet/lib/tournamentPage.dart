import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'betPage.dart';  // Importez la page de pari
import 'package:intl/intl.dart';

class Tournament {
  final int id;
  final String name;
  final DateTime date;
  final int fieldId;

  Tournament({
    required this.id,
    required this.name,
    required this.date,
    required this.fieldId,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id_tournament'],
      name: json['tournament_name'],
      date: DateTime.parse(json['tournament_date']),
      fieldId: json['id_field'],
    );
  }
}

Future<List<Tournament>> fetchTournaments() async {
  final response = await http.get(Uri.parse('http://localhost:8080/tournament'));

  if (response.statusCode == 200) {
    List jsonResponse = json.decode(response.body);
    return jsonResponse.map((tournament) => Tournament.fromJson(tournament)).toList();
  } else {
    throw Exception('Failed to load tournaments');
  }
}

class TournamentListPage extends StatefulWidget {
  @override
  _TournamentListPageState createState() => _TournamentListPageState();
}

class _TournamentListPageState extends State<TournamentListPage> {
  late Future<List<Tournament>> futureTournaments;

  @override
  void initState() {
    super.initState();
    futureTournaments = fetchTournaments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paris Sportifs'),
      ),
      body: FutureBuilder<List<Tournament>>(
        future: futureTournaments,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Tournament> validTournaments = snapshot.data!.where((tournament) {
              DateTime currentDateOnly = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
              DateTime tournamentDateOnly = DateTime(tournament.date.year, tournament.date.month, tournament.date.day);
              return tournamentDateOnly.isAfter(currentDateOnly.subtract(Duration(days: 1)));
            }).toList();

            return ListView.builder(
              itemCount: validTournaments.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(validTournaments[index].name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(validTournaments[index].date.toLocal().toString()),
                      CountdownTimer(tournamentDate: validTournaments[index].date),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BetPage(tournamentId: validTournaments[index].id),
                        ),
                      );
                    },
                    child: Text('Parier'),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("${snapshot.error}"));
          }

          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class CountdownTimer extends StatelessWidget {
  final DateTime tournamentDate;

  CountdownTimer({required this.tournamentDate});

  @override
  Widget build(BuildContext context) {
    return buildCountdownText();
  }

  Widget buildCountdownText() {
    DateTime currentDate = DateTime.now();
    DateTime tournamentDateOnly = DateTime(tournamentDate.year, tournamentDate.month, tournamentDate.day);
    DateTime currentDateOnly = DateTime(currentDate.year, currentDate.month, currentDate.day);

    Duration difference = tournamentDateOnly.difference(currentDateOnly);

    if (difference.inDays > 0) {
      return Text(
        'Il reste ${difference.inDays} jours',
        style: TextStyle(fontSize: 16, color: Colors.redAccent),
      );
    } else {
      Duration hoursDifference = tournamentDate.difference(currentDate);
      if (hoursDifference.inHours > 0) {
        return Text(
          'Il reste ${hoursDifference.inHours} heures',
          style: TextStyle(fontSize: 16, color: Colors.redAccent),
        );
      } else {
        return Text(
          'Tournoi en cours ou terminé',
          style: TextStyle(fontSize: 16, color: Colors.redAccent),
        );
      }
    }
  }
}
