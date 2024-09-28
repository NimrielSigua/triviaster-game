import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
// import 'package:confetti/confetti.dart';

class TriviaStation extends StatefulWidget {
  final String? userId;
  final String? fullname;
  final String? year;
  final String? course;
  final String? role; // Added role field

  TriviaStation({
    this.userId,
    this.fullname,
    this.year,
    this.course,
    this.role, // Added role field
  });

  @override
  _TriviaStationState createState() => _TriviaStationState();
}

class _TriviaStationState extends State<TriviaStation>
    with SingleTickerProviderStateMixin {
  List<dynamic> _triviaQuestions = [];
  int? _selectedOption;
  Map<String, dynamic>? _currentQuestion;
  Timer? _countdownTimer;
  Timer? _pollingTimer;
  int _timeRemaining = 10; // Countdown timer in seconds
  List<String> _correctUsers = []; // Store correct users locally
  // final ConfettiController _confettiController =
  //     ConfettiController(duration: Duration(seconds: 5));
  String _status = 'active';
  String _userAnswer = '';

  late AnimationController _controller;
  late Animation<double> _animation;
  late List<String> _names;
  late double _angle;

  @override
  void initState() {
    super.initState();
    if (widget.role == 'admin') {
      _fetchTriviaQuestions();
      _startPollingForQuestionsAdmin();
    } else {
      _startPollingForQuestions();
    }

    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..addListener(() {
        setState(() {
          _angle += _animation.value;
        });
      });

    _animation = Tween<double>(begin: 0.0, end: 2 * pi).animate(_controller);
  }

  void _startPollingForQuestions() {
    // Poll every 5 seconds (5000 milliseconds)
    _pollingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _startTriviaForStudents(); // Fetch new trivia question
    });
  }

  void _startPollingForQuestionsAdmin() {
    // Poll every 5 seconds (5000 milliseconds)
    _pollingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _startTriviaForStudents(); // Fetch new trivia question
    });
  }

  Future<void> _fetchTriviaQuestions() async {
    // String url = "http://10.0.0.57/api/triviasGameAPI.php";
    String url = "http://192.168.0.108/triviaster/api/triviasGameAPI.php";
    final Map<String, dynamic> queryParams = {
      "operation": "displayTrivia",
      'json': "",
    };

    try {
      http.Response response = await http.get(
        Uri.parse(url).replace(queryParameters: queryParams),
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        print('Fetched Trivia Data: $jsonData'); // Debug print statement
        if (mounted) {
          setState(() {
            _triviaQuestions = jsonData;
          });
        }
      } else {
        print(
            "Failed to fetch trivia questions. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching trivia questions: $e");
    }
  }

  void _startTriviaForStudents() async {
    // String url = "http://10.0.0.57/api/triviasGameAPI.php";
    String url = "http://192.168.0.108/triviaster/api/triviasGameAPI.php";
    final Map<String, dynamic> queryParams = {
      "operation": "getActiveTrivia",
      'json': jsonEncode({'user_id': widget.userId}),
    };

    try {
      http.Response response = await http.get(
        Uri.parse(url).replace(queryParameters: queryParams),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = jsonDecode(response.body);
        print('Active Trivia Data: $jsonData'); // Debug print statement

        if (mounted && jsonData.isNotEmpty) {
          // Only update if there's a new question
          if (_currentQuestion == null ||
              _currentQuestion!['question_id'] != jsonData['question_id']) {
            setState(() {
              _currentQuestion = jsonData;
              _selectedOption = null;
              _timeRemaining = 10; // 10 seconds for students to answer
              _startCountdown();
            });
          }
        }
      } else {
        print(
            "Failed to fetch active trivia question. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching active trivia question: $e");
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeRemaining > 0) {
            _timeRemaining--;
          } else {
            timer.cancel();

            _showCorrectUsers();
            _updateTriviaStatus();
          }
        });
      }
    });
  }

  void _showCorrectUsers() async {
    if (widget.role != 'admin') {
      // If the user is not an admin, don't show the dialog
      return;
    }

    // String url = "http://10.0.0.57/api/triviasGameAPI.php";
    String url = "http://192.168.0.108/triviaster/api/triviasGameAPI.php";
    final Map<String, dynamic> queryParams = {
      "operation": "displayCorrectUser",
      'json': jsonEncode({'question_id': _currentQuestion!['question_id']}),
    };

    try {
      http.Response response = await http.get(
        Uri.parse(url).replace(queryParameters: queryParams),
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        print('Fetched Correct Users Data: $jsonData');

        setState(() {
          _correctUsers =
              jsonData.map((user) => user['fullname'] as String).toList();
        });

        if (_correctUsers.isNotEmpty) {
          _showCorrectUsersDialog(); // Only admin will reach this point
        } else {
          _showNoCorrectUsersDialog(); // Only admin will reach this point
        }
      } else {
        print(
            "Failed to fetch correct users. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching correct users: $e");
    }
  }

  void _showCorrectUsersDialog() {
    // This method will only be called for admin users
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.videogame_asset_rounded, color: Colors.greenAccent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Users who got the correct answer",
                  style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: SpinnerWidget(
              names: _correctUsers,
              onWinnerSelected: (winner) {
                Navigator.of(context).pop();
                _showWinnerDialog(winner);
              },
            ),
          ),
        );
      },
    );
  }

  void _showNoCorrectUsersDialog() {
    // This method will only be called for admin users
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "No correct users found.",
            style: TextStyle(
                color: Colors.redAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _showWinnerDialog(String winner) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Lucky Winner"),
          content: Container(
            width: double.maxFinite,
            height: 150,
            child: Stack(
              children: [
                // ConfettiWidget(
                //   confettiController: _confettiController,
                //   blastDirection: pi / 4,
                //   emissionFrequency: 0.1,
                //   numberOfParticles: 20,
                //   shouldLoop: false,
                // ),
                Center(
                  child: _AnimatedWinnerText(winner),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );

    // _confettiController.play();
  }

  void _selectLuckyWinner() {
    if (_correctUsers.isNotEmpty) {
      // Create a new instance of Random
      final random = Random();

      // Ensure that _correctUsers has the correct data
      print('Correct Users List: $_correctUsers');

      // Select a random index
      int index = random.nextInt(_correctUsers.length);
      String luckyWinner = _correctUsers[index];

      // Debug print statements
      print('Randomly Selected Index: $index');
      print('Lucky Winner: $luckyWinner');

      // Show the dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Lucky Winner"),
            content: Container(
              width: double.maxFinite,
              height: 150,
              child: Stack(
                children: [
                  // Add confetti animations
                  // ConfettiWidget(
                  //   confettiController: _confettiController,
                  //   blastDirection: pi / 4,
                  //   emissionFrequency: 0.1,
                  //   numberOfParticles: 20,
                  //   shouldLoop: false,
                  // ),
                  Center(
                    child: _AnimatedWinnerText(luckyWinner),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the lucky winner dialog
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );

      // _confettiController.play(); // Start confetti animation
    } else {
      print('No users available to select a winner.');
    }
  }

  void _submitAnswer() async {
    if (_userAnswer.isEmpty) {
      // No answer provided, show a warning or return
      return;
    }

    // Uri uri = Uri.parse('http://10.0.0.57/api/triviasGameAPI.php');
    Uri uri =
        Uri.parse('http://192.168.0.108/triviaster/api/triviasGameAPI.php');
    String correctAnswer = _currentQuestion!['correct_answer'];
    int questionId = _currentQuestion!['question_id'];

    // Prepare data to send to the PHP API
    Map<String, dynamic> data = {
      'operation': 'submitAnswer',
      'json': jsonEncode({
        'user_id': widget.userId,
        'answer': _userAnswer,
        'trivia_id': questionId,
      }),
    };

    try {
      http.Response response = await http.post(uri, body: data);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        // Ensure the 'success' key is present and is a boolean
        bool isSuccess = jsonResponse['success'] ?? false;

        if (isSuccess) {
          // Handle the correct or incorrect answer dialog
          if (_userAnswer.toLowerCase() == correctAnswer.toLowerCase()) {
            _showAnswerDialog('Correct!',
                'Well done, ${widget.fullname}! Your answer is correct.');
          } else {
            _showAnswerDialog('Incorrect',
                'Sorry, ${widget.fullname}. The correct answer was $correctAnswer.');
          }
        } else {
          // Handle the failure case
          print('Failed to save the answer: ${jsonResponse['message']}');
        }
      } else {
        // Handle HTTP error
        print(
            'Failed to submit the answer. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error submitting the answer: $e");
    }
  }

  void _showAnswerDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startTrivia() async {
    if (_triviaQuestions.isNotEmpty) {
      Random random = Random();
      var selectedQuestion =
          _triviaQuestions[random.nextInt(_triviaQuestions.length)];

      // Save the trivia question ID to the database
      // String url = "http://10.0.0.57/api/triviasGameAPI.php";
      String url = "http://192.168.0.108/triviaster/api/triviasGameAPI.php";
      final Map<String, dynamic> queryParams = {
        "operation": "startTrivia",
        'json': jsonEncode(
            {'trivia_id': selectedQuestion['trivia_id'], 'status': _status}),
      };

      try {
        http.Response response = await http.post(
          Uri.parse(url),
          body: queryParams,
        );

        if (response.statusCode == 200) {
          print("Trivia started successfully.");
          if (mounted) {
            setState(() {
              _currentQuestion = selectedQuestion;
              _selectedOption = null;
              _timeRemaining = 10; // 10 seconds for students to answer
              _startCountdown();
            });
          }
        } else {
          print("Failed to start trivia. Status code: ${response.statusCode}");
        }
      } catch (e) {
        print("Error starting trivia: $e");
      }
    }
  }

  Future<void> _updateTriviaStatus() async {
    // String url = "http://10.0.0.57/api/triviasGameAPI.php";
    String url = "http://192.168.0.108/triviaster/api/triviasGameAPI.php";
    final Map<String, dynamic> queryParams = {
      "operation": "updateTriviaStatus",
      'json': jsonEncode(
          {'question_id': _currentQuestion!['question_id'], 'status': 'done'}),
    };

    try {
      http.Response response = await http.post(
        Uri.parse(url),
        body: queryParams,
      );

      if (response.statusCode == 200) {
        print("Trivia status updated successfully");
      } else {
        print(
            "Failed to update trivia status. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error updating trivia status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Triviasters'),
        backgroundColor:
            Colors.green[800], // Sets a game-like color theme for the app bar
      ),
      body: Center(
        child: Container(
          color: const Color.fromARGB(
              255, 0, 80, 3), // Background color of the game screen
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Welcome to the Game:",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize:
                              20, // Increase font size for a more prominent title
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "${widget.fullname}",
                        style: TextStyle(
                          color: Colors
                              .orangeAccent, // Make the username standout with a vibrant color
                          fontWeight: FontWeight.w800,
                          fontSize: 22, // Larger font for emphasis
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    '$_timeRemaining',
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Countdown text color
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color:
                              Colors.black54, // Adding shadow for depth effect
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                if (_currentQuestion != null) ...[
                  if (_timeRemaining > 0) ...[
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            15), // Rounded corners for the card
                      ),
                      color: Colors
                          .white, // Make the card background white for contrast
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Center(
                          child: Text(
                            'Question: ${_currentQuestion!['trivia']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(
                                  255, 0, 0, 0), // Darker color for readability
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    if (widget.role == 'admin') ...[
                      Text(
                        'Correct Answer: ${_currentQuestion!['correct_answer']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors
                              .white, // Only admins see the correct answer
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                    if (widget.role == 'student') ...[
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _userAnswer = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter your answer',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: Colors.black),
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _submitAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            padding: EdgeInsets.symmetric(
                                vertical: 15, horizontal: 25),
                            textStyle: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text('Submit'),
                        ),
                      ),
                    ],
                  ] else ...[
                    Center(
                      child: Text(
                        'Wait for the next trivia question',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (widget.role == 'admin') ...[
                      Center(
                        child: ElevatedButton(
                          onPressed: _startTrivia,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.redAccent, // Button color for admin
                            padding: EdgeInsets.symmetric(
                                vertical: 15, horizontal: 25),
                            textStyle: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text('Start Trivia'),
                        ),
                      ),
                    ],
                  ],
                ] else if (widget.role == 'admin') ...[
                  Center(
                    child: ElevatedButton(
                      onPressed: _startTrivia,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.redAccent, // Button color for admin
                        padding:
                            EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                        textStyle: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text('Start Trivia'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // Cancel polling when the widget is disposed
    _countdownTimer?.cancel();
    // _confettiController.dispose();
    super.dispose();
  }
}

class _AnimatedWinnerText extends StatefulWidget {
  final String winnerName;

  _AnimatedWinnerText(this.winnerName);

  @override
  __AnimatedWinnerTextState createState() => __AnimatedWinnerTextState();
}

class __AnimatedWinnerTextState extends State<_AnimatedWinnerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: ScaleTransition(
        scale: _animation,
        child: Text(
          "Congratulations, ${widget.winnerName}!",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class SpinnerWidget extends StatefulWidget {
  final List<String> names;
  final ValueChanged<String> onWinnerSelected;

  SpinnerWidget({required this.names, required this.onWinnerSelected});

  @override
  _SpinnerWidgetState createState() => _SpinnerWidgetState();
}

class _SpinnerWidgetState extends State<SpinnerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _angle;

  @override
  void initState() {
    super.initState();
    _angle = 0.0;

    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..addListener(() {
        setState(() {
          _angle += _animation.value;
        });
      });

    _animation = Tween<double>(begin: 0.0, end: 2 * pi).animate(_controller);
  }

  void _spinWheel() {
    if (widget.names.isEmpty) return;

    _controller.forward().then((_) {
      _controller.reset();
      final selectedIndex =
          (widget.names.length * (_angle / (2 * pi))).toInt() %
              widget.names.length;
      widget.onWinnerSelected(widget.names[selectedIndex]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 300,
            height: 300,
            child: CustomPaint(
              painter: WheelPainter(angle: _angle, names: widget.names),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _spinWheel,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.orangeAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              textStyle: TextStyle(
                fontFamily: 'PressStart2P', // Gaming-themed font
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Spin the Wheel'),
          ),
        ],
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final double angle;
  final List names;
  final int maxNameLength = 10; // Define max length for truncation
  final double baseFontSize = 16; // Base font size
  final double minFontSize = 4; // Minimum font size for very thin slices

  WheelPainter({required this.angle, required this.names});

  // Truncate text function
  String truncateText(String name, int maxLength) {
    return name.length > maxLength
        ? name.substring(0, maxLength) + '...'
        : name;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final double sliceAngle = 2 * pi / names.length;

    // Draw each slice of the wheel
    for (int i = 0; i < names.length; i++) {
      final double startAngle = sliceAngle * i + angle;
      final double sweepAngle = sliceAngle;

      // Draw slice with gradient effect
      final Paint paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.primaries[i % Colors.primaries.length],
            Colors.primaries[(i + 1) % Colors.primaries.length],
          ],
          stops: [0.5, 1.0],
        ).createShader(
            Rect.fromCircle(center: Offset(radius, radius), radius: radius))
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Use truncateText to shorten the name if necessary
      final truncatedName = truncateText(names[i], maxNameLength);

      // Calculate a dynamic font size based on slice angle
      double adjustedFontSize;
      if (sweepAngle < 0.1) {
        // Adjust based on threshold for very thin slices
        adjustedFontSize = minFontSize;
      } else {
        adjustedFontSize =
            baseFontSize * (sweepAngle / (2 * pi / names.length));
        adjustedFontSize = adjustedFontSize.clamp(minFontSize,
            baseFontSize); // Ensure it does not exceed the base size
      }

      // Prepare text painter for rendering
      final double textAngle =
          startAngle + sweepAngle / 2; // Center angle of the slice
      final double x = radius * 0.65 * cos(textAngle); // Positioning adjustment
      final double y = radius * 0.65 * sin(textAngle); // Positioning adjustment

      canvas.save();
      canvas.translate(
          radius + x, radius + y); // Translate to the center of the text

      // Rotate text to align with the slice
      canvas.rotate(textAngle);

      // Draw the whole name at once (centered)
      final TextPainter textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: truncatedName,
          style: TextStyle(
            color: Colors.white,
            fontSize: adjustedFontSize, // Apply dynamic font size
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.7),
              ),
            ],
          ),
        ),
      );
      textPainter.layout();

      // Paint the text centered
      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

      canvas.restore();
    }

    // Draw wheel border
    final Paint borderPaint = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(Offset(radius, radius), radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
