import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:triviaster/triviaStation.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Triviaster',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      home: EnterGamePage(),
    );
  }
}

class EnterGamePage extends StatefulWidget {
  const EnterGamePage({super.key});

  @override
  _EnterGamePageState createState() => _EnterGamePageState();
}

class _EnterGamePageState extends State<EnterGamePage>
    with SingleTickerProviderStateMixin {
  final usernameController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..forward();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/green1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _animation,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: Colors.white.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TRIVIASTER',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                            fontSize: 36,
                            fontStyle: FontStyle.italic,
                            shadows: const [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black26,
                                offset: Offset(3, 3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            labelText: 'Student ID',
                            labelStyle: TextStyle(color: Colors.blue[800]),
                            prefixIcon:
                                Icon(Icons.person, color: Colors.blue[800]),
                            filled: true,
                            fillColor: Colors.blue[50],
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                  color: Colors.blue[800]!, width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                  color: Colors.blue[300]!, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 20),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: enterGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 5,
                          ),
                          child: Text('Login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void enterGame() async {
    Uri uri = Uri.parse('http://10.0.0.57/triviagame/triviaster/api/triviasGameAPI.php');

    Map<String, dynamic> data = {
      'operation': 'loginStudent',
      'json': jsonEncode({
        'studentId': usernameController.text,
      }),
    };

    try {
      http.Response response = await http.post(uri, body: data);

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

        if (responseData['success']) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TriviaStation(
                userId: responseData['user_id'].toString(),
                fullname: responseData['fullname'],
                role: responseData['role'],
              ),
            ),
          );
        } else {
          showMessageBox(
            context,
            "Error",
            responseData['message'],
            null,
            null,
            null,
          );
        }
      } else {
        showMessageBox(
          context,
          "Error",
          "The server returned a ${response.statusCode} error.",
          null,
          null,
          null,
        );
      }
    } catch (e) {
      showMessageBox(
        context,
        "Error",
        "An error occurred while processing your request.",
        null,
        null,
        null,
      );
    }
  }

  void verifyAdmin() async {
    Uri uri = Uri.parse('http://10.0.0.57/triviagame/triviaster/api/triviasGameAPI.php');
    // Uri uri = Uri.parse(
    //     'http://192.168.0.108/triviapi/triviaster-game/api/triviasGameAPI.php');

    Map<String, dynamic> data = {
      'operation': 'VerifyAdmin',
      'json': jsonEncode({
        'fullname': usernameController.text,
        'role': 'admin',
      }),
    };

    try {
      http.Response response = await http.post(uri, body: data);

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

        if (responseData['is_admin'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TriviaStation(
                userId: responseData['user_id'].toString(),
                fullname: responseData['fullname'],
                role: 'admin', // Set role as 'admin'
              ),
            ),
          );
        } else {
          showMessageBoxadminAlert(
            context,
            "Access Denied",
            "You are not authorized to enter as admin.",
            null,
            null,
            null,
          );
        }
      } else {
        showMessageBoxadminAlert(
          context,
          "Error",
          "The server returned a ${response.statusCode} error.",
          null,
          null,
          null,
        );
      }
    } catch (e) {
      showMessageBox(
        context,
        "Error",
        "An error occurred while processing your request.",
        null,
        null,
        null,
      );
    }
  }

  void enterAsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TriviaStation(
          userId: 'screen',
          fullname: 'Screen Display',
          role: 'screen',
        ),
      ),
    );
  }

  void showMessageBox(
    BuildContext context,
    String title,
    String content,
    String? userId,
    String? fullname,
    String? role,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87, // Dark, immersive background
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15), // Rounded corners for modern feel
          ),
          title: Row(
            children: [
              const Icon(
                Icons.videogame_asset_rounded, // Gaming-related icon
                color: Colors.greenAccent, // Neon color for gaming theme
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.greenAccent, // Futuristic neon color
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PressStart2P', // Retro gaming font
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                content,
                style: const TextStyle(
                  color: Colors
                      .white, // White text for contrast against dark background
                  fontSize: 16,
                  fontFamily: 'Orbitron', // Futuristic font
                ),
              ),
              const SizedBox(height: 20),
              if (userId != null)
                Text(
                  'Player ID: $userId',
                  style: const TextStyle(
                    color: Colors.cyanAccent, // Another neon accent color
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (role != null)
                Text(
                  'Role: $role',
                  style: const TextStyle(
                    color:
                        Colors.purpleAccent, // Different neon color for variety
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // Text color on the button
                backgroundColor: Colors.greenAccent, // Button with neon color
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TriviaStation(
                      userId: userId ?? '',
                      fullname: fullname,
                      role: role, // Pass the role here
                    ),
                  ),
                );
              },
              child: const Text(
                'Enter the Game', // More engaging button label
                style: TextStyle(
                  color: Colors.black, // Contrast for readability
                  fontFamily: 'PressStart2P', // Consistent gaming font
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showMessageBoxadminAlert(
    BuildContext context,
    String title,
    String content,
    String? userId,
    String? fullname,
    String? role,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}