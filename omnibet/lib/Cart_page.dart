import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'Product.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late List<Product> cartItems = [];
  final String baseURL = 'http://localhost:8080';
  bool isLoading = true;
  int? userId; // Ajout d'une variable pour stocker l'ID de l'utilisateur
  int? cartId; // ID du panier

  @override
  void initState() {
    super.initState();
    fetchCartItems();
    fetchCartId().then((value) {
      setState(() {
        cartId = value; // Assign the value of fetchCartId() to cartId inside initState
      });
    });
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

  Future<void> fetchCartItems() async {
    try {
      userId = await _getUserIdFromToken(); // Récupérer et stocker l'ID de l'utilisateur

      if (userId != null) {
        print('Fetching cart items for user ID: $userId');
        final response = await http.get(Uri.parse('$baseURL/cart/getCartInfo/$userId'));

        if (response.statusCode == 200) {
          List<dynamic> data = json.decode(response.body);
          setState(() {
            cartItems = data.map((json) => Product(
              id: json['id_product'],
              title: json['product_title'],
              description: json['product_description'],
              price: json['product_price'],
              image: '$baseURL/uploads/${json['product_img']}',
              quantity: json['item_quantity'],
              idDuCart: json['id_cart_item'],
            )).toList();
            isLoading = false;
          });
        } else {
          throw Exception('Failed to load cart items');
        }
      } else {
        print('User ID is null');
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching cart items: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<int?> fetchCartId() async {
    print('Fetching cart ID');
    final userId = await _getUserIdFromToken();
    print('User ID: $userId');

    if (userId != null) {
      final response = await http.get(Uri.parse('$baseURL/cart/get/$userId'));
      if (response.statusCode == 200) {
        print('Cart ID response: ${response.body}');
        final cartData = json.decode(response.body);
        if (cartData.isNotEmpty) {
          setState(() {
            cartId = cartData[0]['id_cart']; // Mettre à jour l'ID du panier
          });
          return cartId;
        }
      }
    }
  }

  Future<void> updateCartItemQuantity(int idCartItem, int? idCart, String operation) async {
    if (idCart == null) {
      print('User ID is null, cannot update cart item quantity');
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('$baseURL/cart/update'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_cart_item': idCartItem,
          'id_cart': idCart,
          'operation': operation,
        }),
      );

      if (response.statusCode == 200) {
        fetchCartItems(); // Refresh cart items
      } else {
        throw Exception('Failed to update cart item quantity');
      }
    } catch (error) {
      print('Error updating cart item quantity: $error');
    }
  }

  Future<int?> _getUserBalance(int userId) async {
    final response = await http.get(Uri.parse('http://localhost:8080/mobileuser/getUserInfo/$userId'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse[0]['balance'];
    } else {
      return null;
    }
  }

  Future<void> deleteCartItem(int idCartItem) async {
    try {
      print('Deleting cart item with ID: $idCartItem');
      final response = await http.post(
        Uri.parse('$baseURL/cart/delete/$idCartItem'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        fetchCartItems(); // Refresh cart items
      } else {
        throw Exception('Failed to delete cart item');
      }
    } catch (error) {
      print('Error deleting cart item: $error');
    }
  }

  Future<void> _updateUserBalance(int userId, double cartAmount) async {
    final currentBalance = await _getUserBalance(userId);
    if (currentBalance != null) {
      var newBalance = currentBalance - cartAmount;
      final response = await http.post(
        Uri.parse('http://localhost:8080/mobileuser/update'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'id_user': userId,
          'new_balance': newBalance,
        }),
      );

      if (response.statusCode == 200) {
        // Solde mis à jour avec succès
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Solde mis à jour avec succès!')));
      } else {
        // Erreur lors de la mise à jour du solde
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la mise à jour du solde.')));
      }
    }
  }

  Future<void> _deleteAllItems() async {
    final userId = await _getUserIdFromToken();
    print("Deleting all cart items for user ID: $userId");
    try {
      final response = await http.post(
        Uri.parse('$baseURL/cart/deleteAll/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        fetchCartItems(); // Refresh cart items
      } else {
        throw Exception('Failed to delete all cart items');
      }
    } catch (error) {
      print('Error deleting all cart items: $error');
    }
  }

  Future<void> validatePurchase() async {
    if (userId == null) {
      print('User ID is null, cannot validate purchase');
      return;
    }

    int? userBalance = await _getUserBalance(userId!);
    double totalCost = calculateTotalCost();

    if (userBalance != null) {
      if (userBalance >= totalCost) {
        await _updateUserBalance(userId!, totalCost);
        await _deleteAllItems();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Succès'),
              content: Text('Paiement Effectué'),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Erreur'),
              content: Text('Pas assez d\'Omnipoints'),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  double calculateTotalCost() {
    double totalCost = 0;
    for (var item in cartItems) {
      totalCost += item.price * item.quantity;
    }
    return totalCost;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panier'),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : cartItems.isNotEmpty
              ? Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return ListTile(
                            leading: Image.network(item.image),
                            title: Text(item.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${item.price} points'),
                                Text('Quantité: ${item.quantity}'),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove),
                                      onPressed: () {
                                        updateCartItemQuantity(item.id, cartId, 'remove');
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add),
                                      onPressed: () {
                                        updateCartItemQuantity(item.id, cartId, 'add');
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        deleteCartItem(item.idDuCart);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            'Total: ${calculateTotalCost()} Omnipoints',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              validatePurchase();
                            },
                            child: Text('Valider'),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Text('Votre panier est vide'),
                ),
    );
  }
}
