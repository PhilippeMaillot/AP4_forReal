import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'Product.dart';
import 'Cart_page.dart'; // Import de la nouvelle page du panier

class ShopPage extends StatefulWidget {
  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late List<Product> products;
  final String baseURL = 'http://localhost:8080';
  int cartItemCount = 0; // Nombre d'articles dans le panier

  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchCartItemCount(); // Appel pour récupérer le nombre d'articles dans le panier
  }

  Future<void> fetchProducts() async {
    final response = await http.get(Uri.parse('$baseURL/product'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        products = data.map((json) => Product(
          id: json['id_product'],
          title: json['product_title'],
          description: json['product_description'],
          price: json['product_price'],
          image: '$baseURL/uploads/${json['product_img']}',
        )).toList();
      });
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<void> addToCart(int productId,) async {
    try {
      final Map<String, dynamic> requestData = {
        'id_product': productId,
        'id_cart': 1,
        'item_quantity': 1
      };

      final response = await http.post(
        Uri.parse('$baseURL/cart/add'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        print('Produit ajouté au panier avec succès');
        fetchCartItemCount(); // Mettre à jour le nombre d'articles dans le panier après l'ajout
      } else {
        print('Échec de l\'ajout au panier');
      }
    } catch (error) {
      print('Erreur lors de l\'ajout au panier: $error');
    }
  }

  Future<void> fetchCartItemCount() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId'); // Récupérer l'ID de l'utilisateur

    if (userId != null) {
      final response = await http.get(Uri.parse('$baseURL/cart/get/$userId'));
      if (response.statusCode == 200) {
        final List<dynamic> cartItems = json.decode(response.body);
        setState(() {
          cartItemCount = cartItems.length; // Mettre à jour le nombre d'articles dans le panier
        });
      }
    }
  }

  void _navigateToCartPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CartPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Boutique'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: _navigateToCartPage, // Naviguer vers la page du panier
              ),
              cartItemCount > 0
                  ? Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 8,
                        child: Text(
                          '$cartItemCount',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ],
          ),
        ],
      ),
      body: products != null
          ? ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 3,
                    child: InkWell(
                      onTap: () {
                        // Mettez ici ce que vous voulez faire au clic sur le produit
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                product.image,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(product.description),
                                  Text(
                                    '${product.price}\ points',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                addToCart(product.id);
                              },
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                              ),
                              child: Icon(Icons.add_shopping_cart),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
