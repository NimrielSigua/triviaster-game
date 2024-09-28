import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:triviaster/triviaStation.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trivia Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EnterGamePage(),
    );
  }
}

class EnterGamePage extends StatefulWidget {
  @override
  _EnterGamePageState createState() => _EnterGamePageState();
}

class _EnterGamePageState extends State<EnterGamePage> {
  final usernameController = TextEditingController();
  final yearController = TextEditingController();
  final courseController = TextEditingController();
  final departmentController = TextEditingController();

  void enterGame() async {
    // Uri uri = Uri.parse('http://10.0.0.57/api/triviasGameAPI.php');
    Uri uri =
        Uri.parse('http://192.168.0.108/triviaster/api/triviasGameAPI.php');

    Map<String, dynamic> data = {
      'operation': 'EnterGameStudent',
      'json': jsonEncode({
        'fullname': usernameController.text,
        'role': 'student', // Pass the role here
      }),
    };

    try {
      http.Response response = await http.post(uri, body: data);

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

        showMessageBox(
          context,
          responseData['exists'] == true ? "Notice" : "Success",
          responseData['exists'] == true
              ? "Welcome back, ${responseData['fullname']}!"
              : "Welcome to the game ${responseData['fullname']}",
          responseData['user_id'].toString(),
          responseData['fullname'],
          responseData['role'], // Pass the role here
        );
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
    // Uri uri = Uri.parse('http://10.0.0.57/api/triviasGameAPI.php');
    Uri uri =
        Uri.parse('http://192.168.0.108/triviaster/api/triviasGameAPI.php');

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
              Icon(
                Icons.videogame_asset_rounded, // Gaming-related icon
                color: Colors.greenAccent, // Neon color for gaming theme
              ),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
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
                style: TextStyle(
                  color: Colors
                      .white, // White text for contrast against dark background
                  fontSize: 16,
                  fontFamily: 'Orbitron', // Futuristic font
                ),
              ),
              SizedBox(height: 20),
              if (userId != null)
                Text(
                  'Player ID: $userId',
                  style: TextStyle(
                    color: Colors.cyanAccent, // Another neon accent color
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (role != null)
                Text(
                  'Role: $role',
                  style: TextStyle(
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
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
              child: Text(
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
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          color: const Color.fromARGB(255, 0, 80, 3),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'TRIVIASTER',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent, // A more vibrant color
                        fontSize: 40, // Larger font for a more dynamic feel
                        fontStyle: FontStyle.italic, // Adds a playful touch
                        shadows: [
                          Shadow(
                            blurRadius: 10.0, // Gives it a glowing effect
                            color: Colors.black54, // Shadow color
                            offset: Offset(3, 3), // Shadow position
                          ),
                        ],
                      ),
                    ),
                    TextField(
                      controller: usernameController,
                      style: TextStyle(
                        color: Colors.white, // Changes the text color
                        fontSize:
                            18, // Slightly larger font for better readability
                        fontWeight:
                            FontWeight.bold, // Makes the input text bold
                      ),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: TextStyle(
                          color: Colors.white, // Changes the label color
                          fontSize: 16, // Slightly larger label text
                        ),
                        filled: true,
                        fillColor: Colors
                            .black45, // Adds a background color to the input field
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(15), // Rounded corners
                          borderSide: BorderSide(
                            color: Colors
                                .orangeAccent, // Border color when focused
                            width: 2.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              15), // Rounded corners when not focused
                          borderSide: BorderSide(
                            color:
                                Colors.white, // Border color when not focused
                            width: 1.5,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 20), // Adds padding inside the field
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            width: 100,
                            child: ElevatedButton(
                              onPressed: () {
                                enterGame();
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black,
                                backgroundColor:
                                    Colors.greenAccent, // Text color
                                padding: EdgeInsets.symmetric(
                                    vertical: 15), // Increases button height
                                textStyle: TextStyle(
                                  fontSize:
                                      18, // Larger font size for a bold look
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      20), // Rounded corners
                                ),
                                elevation: 10, // Adds shadow effect
                              ),
                              child: Text('Student'),
                            ),
                          ),
                        ),
                        SizedBox(width: 20), // Adds space between the buttons
                        Expanded(
                          child: Container(
                            width: 100,
                            child: ElevatedButton(
                              onPressed: () {
                                verifyAdmin();
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.redAccent, // Text color
                                padding: EdgeInsets.symmetric(
                                    vertical: 15), // Increases button height
                                textStyle: TextStyle(
                                  fontSize:
                                      18, // Larger font size for a bold look
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      20), // Rounded corners
                                ),
                                elevation: 10, // Adds shadow effect
                              ),
                              child: Text('Admin'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
