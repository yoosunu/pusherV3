// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pusher_v3/pages/home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});

  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  Future<void> login() async {
    const String url = "https://backend.apotb.shop/api/v1/users/jwt-login";

    final response = await http.post(Uri.parse(url),
        body: json.encode({
          "username": _usernameController.text,
          "password": _passwordController.text,
        }),
        headers: {
          'Content-Type': 'application/json',
        });

    if (response.statusCode == 200) {
      var userData = json.decode(response.body);
      String accessToken = userData["access_token"];
      String refreshToken = userData["refresh_token"];

      await _storage.write(key: "access_token", value: accessToken);
      await _storage.write(key: "refresh_token", value: refreshToken);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage(title: "Home")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to login")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign In"),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
            child: IconButton(
              iconSize: 34,
              onPressed: () async {
                await _storage.deleteAll();
              },
              icon: const Icon(Icons.delete),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: const Text("LogIn"),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Implementing...")),
                );
              },
              child: const Text("Sign Up"),
            )
          ],
        ),
      ),
    );
  }
}
