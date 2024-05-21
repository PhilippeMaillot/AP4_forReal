import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BetPage extends StatefulWidget {
  final int tournamentId;

  BetPage({required this.tournamentId});

  @override
  _BetPageState createState() => _BetPageState();
}

class _BetPageState extends State<BetPage> {
  late Future<Map<String, dynamic>> futureTournamentInfo;
  late Future<List<Map<String, dynamic>>> futureParticipants;

  @override
  void initState() {
    super.initState();
    futureTournamentInfo = fetchTournamentInfo(widget.tournamentId);
    futureParticipants = fetchParticipants(widget.tournamentId);
  }

  Future<Map<String, dynamic>> fetchTournamentInfo(int id) async {
    final response = await http.get(Uri.parse('http://localhost:8080/tournament/info/$id'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse[0];
    } else {
      throw Exception('Failed to load tournament info');
    }
  }

  Future<List<Map<String, dynamic>>> fetchParticipants(int id) async {
    final response = await http.get(Uri.parse('http://localhost:8080/tournament/infopart/$id'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((participant) => participant as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load participants');
    }
  }

  void _showBetDialog(BuildContext context, String clubName, int clubId) {
    TextEditingController amountController = TextEditingController();
    String prediction = 'Victoire';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Parier sur $clubName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: "Entrez le montant"),
              ),
              DropdownButton<String>(
                value: prediction,
                onChanged: (String? newValue) {
                  setState(() {
                    prediction = newValue!;
                  });
                },
                items: <String>['Victoire', 'Défaite'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text("Annuler"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text("Parier"),
              onPressed: () async {
                double amount = double.parse(amountController.text);
                await placeBet(widget.tournamentId, clubId, amount, prediction);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> placeBet(int tournamentId, int clubId, double amount, String prediction) async {
    final userId = await _getUserIdFromToken();
    if (userId != null) {
      final response = await http.post(
        Uri.parse('http://localhost:8080/bet/add'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'id_tournament': tournamentId,
          'id_club': clubId,
          'bet_amount': amount,
          'bet_prediction': prediction,
          'id_user': userId,
        }),
      );

      if (response.statusCode == 200) {
        // Pari réussi
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pari placé avec succès!')));
      } else {
        // Erreur lors du placement du pari
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors du placement du pari.')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : Utilisateur non connecté.')));
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
        title: Text('Détails du Tournoi'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureTournamentInfo,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              var tournament = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      tournament['tournament_name'],
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Date: ${tournament['tournament_date']}'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Adresse: ${tournament['field_adress']}'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Ville: ${tournament['field_town']}'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Type de Sport: ${tournament['sport_type']}'),
                  ),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: futureParticipants,
                      builder: (context, participantSnapshot) {
                        if (participantSnapshot.connectionState == ConnectionState.done) {
                          if (participantSnapshot.hasData) {
                            return ListView.builder(
                              itemCount: participantSnapshot.data!.length,
                              itemBuilder: (context, index) {
                                var participant = participantSnapshot.data![index];
                                return ListTile(
                                  title: Text(participant['club_name']),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      _showBetDialog(context, participant['club_name'], participant['id_club']);
                                    },
                                    child: Text('Parier'),
                                  ),
                                );
                              },
                            );
                          } else if (participantSnapshot.hasError) {
                            return Center(child: Text("${participantSnapshot.error}"));
                          }
                        }
                        return Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              return Center(child: Text("${snapshot.error}"));
            }
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
