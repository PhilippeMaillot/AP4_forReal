import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ViewBetPage extends StatefulWidget {
  final int userId;

  ViewBetPage({required this.userId});

  @override
  _ViewBetPageState createState() => _ViewBetPageState();
}

class _ViewBetPageState extends State<ViewBetPage> {
  late Future<List<Map<String, dynamic>>> futureBets;

  @override
  void initState() {
    super.initState();
    futureBets = fetchBets(widget.userId);
    print('User ID bets: ${widget.userId}');
  }

  Future<List<Map<String, dynamic>>> fetchBets(int userId) async {
    final response = await http.get(Uri.parse('http://localhost:8080/bet/user/$userId'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load bets');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Paris'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: futureBets,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var bet = snapshot.data![index];
                  double betAmount = bet['bet_amount'];
                  double potentialGain = betAmount * 2;

                  return Container(
                    margin: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nom du tournoi: ${bet['tournament_name']}', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 5.0),
                          Text('Montant du pari: $betAmount'),
                          SizedBox(height: 5.0),
                          Text('Gain potentiel: $potentialGain'),
                          SizedBox(height: 5.0),
                          Text('Prédiction: ${bet['bet_prediction']}'),
                        ],
                      ),
                    ),
                  );
                },
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
