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

  const TriviaStation({
    super.key,
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
  final String _status = 'active';
  String _userAnswer = '';

  late AnimationController _controller;
  late Animation<double> _animation;
  late List<String> _names;
  late double _angle;
  bool _showSpinWheel = false;
  bool _showNoCorrectAnswerDialog = false;
  String _winner = '';
  bool _showWinner = false;

  @override
  void initState() {
    super.initState();
    if (widget.role == 'admin') {
      _fetchTriviaQuestions();
      _startPollingForQuestionsAdmin();
    } else if (widget.role == 'student' || widget.role == 'screen') {
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
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _startTriviaForStudents(); // Fetch new trivia question
    });
  }

  void _startPollingForQuestionsAdmin() {
    // Poll every 5 seconds (5000 milliseconds)
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _startTriviaForStudents(); // Fetch new trivia question
    });
  }

  Future<void> _fetchTriviaQuestions() async {
    // String url = "http://10.0.0.57/api/triviasGameAPI.php";
    String url =
        "http://192.168.0.108/triviapi/triviaster-game/api/triviasGameAPI.php";
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
    String url =
        "http://192.168.0.108/triviapi/triviaster-game/api/triviasGameAPI.php";
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
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    if (widget.role != 'screen') {
      return;
    }

    String url =
        "http://192.168.0.108/triviapi/triviaster-game/api/triviasGameAPI.php";
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
          if (_correctUsers.isEmpty) {
            _showNoCorrectAnswerDialog = true;
            _showSpinWheel = false;
          } else {
            _showSpinWheel = true;
            _showNoCorrectAnswerDialog = false;
          }
        });
      } else {
        print(
            "Failed to fetch correct users. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching correct users: $e");
    }
  }

  void _resetScreenState() {
    setState(() {
      _showSpinWheel = false;
      _showNoCorrectAnswerDialog = false;
      _showWinner = false;
      _winner = '';
      _currentQuestion = null;
      _timeRemaining = 0;
    });
  }

  void _showWinnerDialog(String winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Winner!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Congratulations!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text(winner,
                  style: const TextStyle(
                      fontSize: 36,
                      color: Colors.green,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
                _resetScreenState();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.role == 'screen') {
      return Scaffold(
        body: Container(
          color: const Color.fromARGB(255, 0, 80, 3),
          child: Center(
            child: _showSpinWheel
                ? SpinnerWidget(
                    names: _correctUsers,
                    onWinnerSelected: (winner) {
                      setState(() {
                        _winner = winner;
                        _showSpinWheel = false;
                      });
                      _showWinnerDialog(_winner);
                    },
                  )
                : _showNoCorrectAnswerDialog
                    ? AlertDialog(
                        title: const Text("No Correct Answers"),
                        content: const Text("No one got the correct answer."),
                        actions: [
                          TextButton(
                            onPressed: _resetScreenState,
                            child: const Text("Close"),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentQuestion == null
                                ? 'Wait for the next trivia question'
                                : '$_timeRemaining',
                            style: TextStyle(
                              fontSize: _currentQuestion == null ? 24 : 72,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 40),
                          if (_currentQuestion != null)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                '${_currentQuestion!['trivia']}',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
          ),
        ),
      );
    }

    // Admin and student roles
    return Scaffold(
      appBar: AppBar(
        title: const Text('Triviasters'),
        backgroundColor: Colors.green[800],
      ),
      body: Center(
        child: Container(
          color: const Color.fromARGB(255, 0, 80, 3),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
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
                        style: const TextStyle(
                          color: Colors
                              .orangeAccent, // Make the username standout with a vibrant color
                          fontWeight: FontWeight.w800,
                          fontSize: 22, // Larger font for emphasis
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    '$_timeRemaining',
                    style: const TextStyle(
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
                const SizedBox(height: 20),
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(
                                  255, 0, 0, 0), // Darker color for readability
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (widget.role == 'admin') ...[
                      Text(
                        'Correct Answer: ${_currentQuestion!['correct_answer']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors
                              .white, // Only admins see the correct answer
                        ),
                      ),
                      const SizedBox(height: 20),
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
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _submitAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 25),
                            textStyle: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Submit'),
                        ),
                      ),
                    ],
                  ] else ...[
                    const Center(
                      child: Text(
                        'Wait for the next trivia question',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ] else if (widget.role == 'admin') ...[
                  Center(
                    child: ElevatedButton(
                      onPressed: _startTrivia,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 25),
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Start Trivia'),
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

  Future<void> _startTrivia() async {
    if (_triviaQuestions.isNotEmpty) {
      Random random = Random();
      var selectedQuestion =
          _triviaQuestions[random.nextInt(_triviaQuestions.length)];

      // Save the trivia question ID to the database
      // String url = "http://10.0.0.57/api/triviasGameAPI.php";
      String url =
          "http://192.168.0.108/triviapi/triviaster-game/api/triviasGameAPI.php";
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
    String url =
        "http://192.168.0.108/triviapi/triviaster-game/api/triviasGameAPI.php";
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

  void _submitAnswer() async {
    if (_userAnswer.isEmpty) {
      print("No answer provided");
      _showAnswerDialog('Error', 'Please enter an answer before submitting.');
      return;
    }

    print("Submitting answer: $_userAnswer"); // Debug print

    Uri uri = Uri.parse(
        'http://192.168.0.108/triviapi/triviaster-game/api/triviasGameAPI.php');
    String correctAnswer = _currentQuestion!['correct_answer'];
    String questionId =
        _currentQuestion!['question_id'].toString(); // Convert to String

    Map<String, dynamic> data = {
      'operation': 'submitAnswer',
      'json': jsonEncode({
        'user_id': widget.userId,
        'answer': _userAnswer,
        'trivia_id': questionId,
      }),
    };

    try {
      print("Sending request to server"); // Debug print
      http.Response response = await http.post(uri, body: data);
      print(
          "Response received. Status code: ${response.statusCode}"); // Debug print

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        print("Server response: $jsonResponse"); // Debug print

        bool isSuccess = jsonResponse['success'] ?? false;

        if (isSuccess) {
          bool isCorrect =
              _userAnswer.toLowerCase() == correctAnswer.toLowerCase();
          String title = isCorrect ? 'Correct!' : 'Incorrect';
          String content = isCorrect
              ? 'Well done, ${widget.fullname}! Your answer is correct.'
              : 'Sorry, ${widget.fullname}. The correct answer was $correctAnswer.';

          print("Showing answer dialog: $title - $content"); // Debug print
          _showAnswerDialog(title, content);
        } else {
          print("Failed to save the answer: ${jsonResponse['message']}");
          _showAnswerDialog(
              'Error', 'Failed to submit your answer. Please try again.');
        }
      } else {
        print("HTTP error. Status code: ${response.statusCode}");
        _showAnswerDialog(
            'Error', 'Failed to submit your answer. Please try again.');
      }
    } catch (e) {
      print("Error submitting the answer: $e");
      _showAnswerDialog('Error', 'An error occurred. Please try again.');
    }
  }

  void _showAnswerDialog(String title, String content) {
    print("Showing dialog: $title - $content"); // Debug print
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
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

  const _AnimatedWinnerText(this.winnerName);

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
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class SpinnerWidget extends StatefulWidget {
  final List<String> names;
  final ValueChanged<String> onWinnerSelected;

  const SpinnerWidget(
      {super.key, required this.names, required this.onWinnerSelected});

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
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              textStyle: const TextStyle(
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
        ? '${name.substring(0, maxLength)}...'
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
          stops: const [0.5, 1.0],
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
                offset: const Offset(1, 1),
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
