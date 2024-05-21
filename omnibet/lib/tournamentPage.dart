import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'betPage.dart';  // Importez la page de pari

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
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(snapshot.data![index].name),
                  subtitle: Text(snapshot.data![index].date.toLocal().toString()),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BetPage(tournamentId: snapshot.data![index].id),
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
