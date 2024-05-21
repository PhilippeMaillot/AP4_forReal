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
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((bet) => bet as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load bets');
    }
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> bet) {
    TextEditingController amountController = TextEditingController(text: bet['bet_amount'].toString());
    String prediction = bet['bet_prediction'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier le pari'),
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
              child: Text("Supprimer"),
              onPressed: () async {
                await deleteBet(bet['id_bet']);
                Navigator.of(context).pop();
                setState(() {
                  futureBets = fetchBets(widget.userId);
                });
              },
            ),
            ElevatedButton(
              child: Text("Modifier"),
              onPressed: () async {
                double amount = double.parse(amountController.text);
                await updateBet(bet['id_bet'], amount, prediction);
                Navigator.of(context).pop();
                setState(() {
                  futureBets = fetchBets(widget.userId);
                });
              },
            ),
            ElevatedButton(
              child: Text("Annuler"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> updateBet(int betId, double amount, String prediction) async {
    final response = await http.put(
      Uri.parse('http://localhost:8080/bet/update/$betId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'bet_amount': amount,
        'bet_prediction': prediction,
      }),
    );

    if (response.statusCode == 200) {
      // Bet updated successfully
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pari modifié avec succès!')));
    } else {
      // Error updating bet
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la modification du pari.')));
    }
  }

  Future<void> deleteBet(int betId) async {
    final response = await http.delete(
      Uri.parse('http://localhost:8080/bet/delete/$betId'),
    );

    if (response.statusCode == 200) {
      // Bet deleted successfully
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pari supprimé avec succès!')));
    } else {
      // Error deleting bet
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la suppression du pari.')));
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
                  return ListTile(
                    title: Text('Tournoi ID: ${bet['id_tournament']} - Club ID: ${bet['id_club']}'),
                    subtitle: Text('Montant: ${bet['bet_amount']} - Prédiction: ${bet['bet_prediction']}'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        _showEditDialog(context, bet);
                      },
                      child: Text('Modifier'),
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
