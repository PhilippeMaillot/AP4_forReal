import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 0; // Indice de l'option sélectionnée
  List<String> _options = ['Changer de pseudo', 'Changer d\'adresse e-mail', 'Changer de mot de passe']; // Liste des options de modification

  // Controllers pour les champs de saisie
  TextEditingController _userNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  // URL de votre backend
  final String apiUrl = 'http://localhost:8080/mobileuser/update'; // Assurez-vous de remplacer localhost par votre IP ou domaine si nécessaire

  // Fonction pour soumettre les modifications au backend
  Future<void> _submitChanges() async {
    final userId = await _getUserIdFromToken();
    switch (_selectedIndex) {
      case 0:
        print('Changement de pseudo en cours...');
        // Récupérer le nouveau pseudo
        String newUserName = _userNameController.text;
        
        // Appeler l'API pour mettre à jour le pseudo
        await updateUser({'id_user': userId , 'user_name': newUserName} as Map<String, dynamic>); 
        break;
      case 1:
        print('Changement d\'adresse e-mail en cours...');
        // Récupérer la nouvelle adresse e-mail
        String newEmail = _emailController.text;
        // Appeler l'API pour mettre à jour l'adresse e-mail
        await updateUser({'id_user': userId ,'email': newEmail}as Map<String, dynamic>);
        break;
      case 2:
        print('Changement de mot de passe en cours...');
        // Récupérer le nouveau mot de passe
        String newPassword = _passwordController.text;
        String confirmPassword = _confirmPasswordController.text;
        // Vérifier si les mots de passe correspondent
        if (newPassword == confirmPassword) {
          // Appeler l'API pour mettre à jour le mot de passe
          await updateUser({'id_user': userId ,'password_hash': newPassword} as Map<String, dynamic>);
        } else {
          print('Les mots de passe ne correspondent pas.');
          // Afficher un message d'erreur à l'utilisateur
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Les mots de passe ne correspondent pas.'),
          ));
        }
        break;
    }
  }

  // Fonction pour appeler l'API pour mettre à jour les informations utilisateur
  Future<void> updateUser(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        print('Modification réussie.');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Modification réussie.'),
        ));
      } else {
        print('Échec de la modification.');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Échec de la modification.'),
        ));
      }
    } catch (error) {
      print('Erreur lors de la mise à jour : $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur lors de la mise à jour.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Liste des options de modification
            ListView.builder(
              shrinkWrap: true,
              itemCount: _options.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_options[index]),
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  selected: _selectedIndex == index,
                );
              },
            ),
            // Interface utilisateur pour chaque option de modification
            _selectedIndex == 0
                ? _buildChangeUserNameForm()
                : _selectedIndex == 1
                    ? _buildChangeEmailForm()
                    : _buildChangePasswordForm(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _submitChanges();
              },
              child: Text('Enregistrer les modifications'),
            ),
          ],
        ),
      ),
    );
  }

  // Interface utilisateur pour changer de pseudo
  Widget _buildChangeUserNameForm() {
    return TextFormField(
      controller: _userNameController,
      decoration: InputDecoration(labelText: 'Nouveau pseudo'),
    );
  }

  // Interface utilisateur pour changer d'adresse e-mail
  Widget _buildChangeEmailForm() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(labelText: 'Nouvelle adresse e-mail'),
    );
  }

  // Interface utilisateur pour changer de mot de passe
  Widget _buildChangePasswordForm() {
    return Column(
      children: [
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(labelText: 'Nouveau mot de passe'),
          obscureText: true,
        ),
        TextFormField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(labelText: 'Confirmer le nouveau mot de passe'),
          obscureText: true,
        ),
      ],
    );
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