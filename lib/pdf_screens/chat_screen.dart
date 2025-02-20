import 'package:aichat/pdf_screens/webview_screen.dart';
import 'package:flutter/material.dart';
import 'package:aichat/utils/pdf_utils.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? pdfFileName;
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool showGameOptions = false;
  bool showUploadQuestions = false;
  bool questionsCompleted = false;
  bool postGameQuestionsAnswered = false;
  bool chatEnded = false; // Track if all questions are completed


  int questionIndex = 0;
  bool showInitialOptions = true;

  Map<int, String> selectedAnswers =
      {}; // Stores the selected answer for each question

  final List<Map<String, dynamic>> initialQuestions = [
    {
      "question": "Welcome to the PDF Chat! How are you feeling today?",
    },
    {
      "question": "Thanks for sharing! Would you like to try something new today?",
      "options": ["Yes, show me new things!", "I’m looking for something specific", "I just want to relax"]
    },
    {
      "question": "What interests you the most these days?",
    },
    {
      "question": "Hey there! Would you like to upload a PDF so I can assist you better?",
      "options": ["Yes, I have a PDF to upload", "No, I just want to ask general questions"]
    },
    {
      "question": "Upload your PDF now",
    }
  ];

  final List<Map<String, dynamic>> uploadQuestions = [
    {
      "question": "Let's keep that aside. Would you like to play a game?",
      "options": ["Yes", "No"]
    },
    {
      "question": "What was your last favorite game?",
    },
    {
      "question": "What type of games do you enjoy the most?",
      "options": ["Puzzle games", "Adventure games", "Strategy games", "Casual games"]
    },
    {
      "question": "Would you like to try a new game recommendation?",
      "options": ["Yes, recommend one", "No, I have my favorites"]
    },
  ];

  List<Map<String, dynamic>> postGameQuestions = [
    {
      "question": "What did you like most about the game?",
    },
    {
      "question": "Did you feel that Good Game Theory is interesting?",
      "options": ["Yes, it helps in understanding strategic decision-making", "Maybe, I need to explore more"]
    },
  ];

  int postGameQuestionIndex = 0;

  void askPostGameQuestions() {
    postGameQuestionIndex = 0;
    conversation.add({
      "text": postGameQuestions[postGameQuestionIndex]["question"],
      "isUser": false,
      if (postGameQuestions[postGameQuestionIndex].containsKey("options"))
        "options": postGameQuestions[postGameQuestionIndex]["options"],
    });
    setState(() {});
    _scrollToBottom();
  }

  List<Map<String, dynamic>> conversation = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_scrollToBottom);
    conversation.add({
      "text": initialQuestions[questionIndex]["question"],
      "isUser": false,
      if (initialQuestions[questionIndex].containsKey("options"))
        "options": initialQuestions[questionIndex]["options"],
    });
  }

  void processPostGameQuestionResponse(String answer) {
    if (chatEnded) return;
    setState(() {
      conversation.add({"text": answer, "isUser": true});

      postGameQuestionIndex++;
      if (postGameQuestionIndex < postGameQuestions.length) {
        var nextQuestion = postGameQuestions[postGameQuestionIndex];
        conversation.add({
          "text": nextQuestion["question"],
          "isUser": false,
          if (nextQuestion.containsKey("options")) "options": nextQuestion["options"],
        });
      } else {
        conversation.add({
          "text": "Thanks for participating! Hope you had fun!",
          "isUser": false,
        });
        chatEnded = true;
      }
    });

    _scrollToBottom();
  }

  void processQuestionResponse(String answer) {
    if (chatEnded) return;  // Prevent further processing if chat is ended

    setState(() {
      conversation.add({"text": answer, "isUser": true});
      questionIndex++;

      if (questionIndex < initialQuestions.length) {
        var nextQuestion = initialQuestions[questionIndex];

        conversation.add({
          "text": nextQuestion["question"],
          "isUser": false,
          if (nextQuestion.containsKey("options")) "options": nextQuestion["options"],
        });

        // ✅ Unlock PDF upload when reaching the last question (without options)
        if (questionIndex == initialQuestions.length - 1 && !nextQuestion.containsKey("options")) {
          questionsCompleted = true;
          showInitialOptions = false;
        }
      } else {
        // ✅ Ensure PDF unlocks even if all questions are answered
        questionsCompleted = true;
        showInitialOptions = false;
      }
    });

    _scrollToBottom();  // Ensure smooth scrolling
  }


  void processUploadQuestionResponse(String answer) {
    if (chatEnded) return;
    setState(() {
      conversation.add({"text": answer, "isUser": true});
      questionIndex++;

      if (questionIndex < uploadQuestions.length) {
        var nextQuestion = uploadQuestions[questionIndex];
        conversation.add({
          "text": nextQuestion["question"],
          "isUser": false,
          if (nextQuestion.containsKey("options")) "options": nextQuestion["options"],
        });
      } else {
        showGameOptions = true;
        showUploadQuestions = false;

        conversation.add({
          "text": "Based on your answers, here are some game recommendations:",
          "isUser": false
        });
      }

    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_focusNode.hasFocus) {
      Future.delayed(Duration(milliseconds: 200), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void uploadPdf() async {
    if (!questionsCompleted) return;

    setState(() {
      isLoading = true;
    });

    final text = await PdfUtils.extractTextFromPdf();

    setState(() {
      isLoading = false;
      if (text != null) {
        pdfFileName = PdfUtils.fileName;

        showUploadQuestions = true;
        questionIndex = 0;
        conversation.add({
          "text": "PDF uploaded successfully: $pdfFileName",
          "isUser": false
        });
        conversation.add({
          "text": uploadQuestions[questionIndex]["question"],
          "options": uploadQuestions[questionIndex]["options"],
          "isUser": false
        });

        _scrollToBottom(); // Ensure scrolling continues after PDF upload
      } else {
        conversation.add({"text": "Failed to load PDF.", "isUser": false});
        _scrollToBottom(); // Ensure scrolling continues even if PDF fails
      }
    });
  }

  void processResponse(String answer) {
    setState(() {
      conversation.add({"text": answer, "isUser": true});
      questionIndex++;

      List<Map<String, dynamic>> currentQuestions = showUploadQuestions
          ? uploadQuestions
          : showGameOptions
          ? postGameQuestions
          : initialQuestions;

      if (questionIndex < currentQuestions.length) {
        var nextQuestion = currentQuestions[questionIndex];
        conversation.add({
          "text": nextQuestion["question"],
          "isUser": false,
          if (nextQuestion.containsKey("options")) "options": nextQuestion["options"],
        });

        // ✅ Unlock PDF Upload when reaching last initial question
        if (questionIndex == initialQuestions.length - 1) {
          showUploadQuestions = true;
        }
      } else {
        if (showUploadQuestions) {
          showGameOptions = true;
          showUploadQuestions = false;
        } else if (showGameOptions) {
          chatEnded = true;
          conversation.add({"text": "Thanks for participating! Hope you had fun!", "isUser": false});
        } else {
          showUploadQuestions = true;
        }
      }
    });

    _scrollToBottom();
  }



  Widget buildOptions(
      List<String> options, Function(String) onSelect, int questionIndex) {
    return SizedBox(
      width: MediaQuery.of(context).size.width *
          0.7, // Matches question container width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: options.map((option) {
          bool isSelected = selectedAnswers[questionIndex] == option;

          return Column(
            children: [
              TextButton(
                onPressed: () {
                  setState(
                    () {
                      selectedAnswers[questionIndex] = option;
                    },
                  );
                  onSelect(option);
                },
                style: TextButton.styleFrom(
                  foregroundColor: isSelected ? Colors.blue : Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    option,
                    style: TextStyle(fontSize: 16, color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if (option != options.last)
                Divider(
                    color: Colors.grey, thickness: 0.2), // Line between options
            ],
          );
        }).toList(),
      ),
    );
  }

  void _handleGameSelection(String url) async {
    if (url.isEmpty) {
      print("Error: Invalid URL");
      return;
    }
    // Navigate to WebViewScreen and wait for user to return
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WebViewScreen(url: url)),
    );

    // Ask post-game questions after returning
    askPostGameQuestions();
  }



  Widget buildGameOptions() {
    List<Map<String, String>> games = [
      {
        "name": "Mario Game",
        "url": "https://www.gameyoutube.com/",
        "description": 'Step into the world of Mario and enjoy!',
        "image": "assets/mario.jpg"
      },
      {
        "name": "Monster Game",
        "url": "https://www.gameyoutube.com/",
        "description": 'Test your knowledge by playing the monster game!',
        "image": 'assets/monster game.jpg'
      },
      {
        "name": "Mine Game",
        "url": "https://www.gameyoutube.com/",
        "description": 'Dig deeper and find treasures in this fun game',
        "image": 'assets/mine game.jpg'
      },
      {
        "name": "Classic MCQ",
        "url": "https://www.gameyoutube.com/",
        "description": 'Challenge yourself with classic multiple-choice quizzes',
        "image": 'assets/classic mcq.jpg'
      },
      {
        "name": "Snake Game",
        "url": "https://dev-game-yt.vercel.app/snakegame/DHjqpvDnNGE/mcqs/easy/fb4fbcefe833aec9b26a0b7702264ffcc020f7c2eda9c07bdeac997728543851/",
        "description": 'Test your knowledge by playing the snake game!',
        "image": 'assets/snake game.jpg'
      },
      {
        "name": "Question Construction",
        "url": "https://dev-game-yt.vercel.app/questionconstruction/DHjqpvDnNGE/tfs/easy/fb4fbcefe833aec9b26a0b7702264ffcc020f7c2eda9c07bdeac997728543851",
        "description": 'Challenge yourself with classic multiple-choice quizzes',
        "image": 'assets/Question Construction.jpg'
      },
    ];

    PageController pageController = PageController(viewportFraction: 1.0);

    void nextPage() {
      if (pageController.hasClients) {
        pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }

    void previousPage() {
      if (pageController.hasClients) {
        pageController.previousPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: games.length,
            controller: pageController,
            itemBuilder: (context, index) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
                child: GestureDetector(
                  key: ValueKey(games[index]["image"]),
                  onTap: () => _handleGameSelection(games[index]["url"]!),

                  child: Card(
                    elevation: 5.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Image.asset(
                        games[index]["image"]!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            right: 10,
            top: 100,
            bottom: 100,
            child: IconButton(
              color: Colors.black,
              icon: const Icon(
                Icons.arrow_forward_ios,
                size: 32,
                color: Colors.black,
              ),
              onPressed: nextPage,
            ),
          ),
          Positioned(
            left: 10,
            top: 100,
            bottom: 100,
            child: IconButton(
              color: Colors.black,
              icon: const Icon(Icons.arrow_back_ios, size: 32),
              onPressed: previousPage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_scrollToBottom);
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("PDF Chat",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(10),
                itemCount: conversation.length,
                itemBuilder: (context, index) {
                  return Align(
                    alignment: conversation[index]['isUser']
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            conversation[index]['text'],
                            style: TextStyle(color: Colors.black, fontSize: 16),
                          ),
                          SizedBox(height: 8),

                          // Show normal question options
                          if (!conversation[index]['isUser'] &&
                              conversation[index].containsKey("options"))
                            buildOptions(conversation[index]["options"],
                                (answer) {
                                  if (showInitialOptions) {
                                    processQuestionResponse(answer);
                                  } else if (showUploadQuestions) {
                                    processUploadQuestionResponse(answer);
                                  } else {
                                    processPostGameQuestionResponse(answer); // Handle post-game questions
                                  }
                                }, index),
                          // Show game options if it's the last question
                          if (showGameOptions &&
                              conversation[index]['text'] ==
                                  "Based on your answers, here are some game recommendations:")
                            Column(
                              children: [
                                SizedBox(height: 12),
                                buildGameOptions(),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                }),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    style: TextStyle(color: Colors.black),
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: TextStyle(color: Colors.black),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  color: Colors.black,
                  onPressed: uploadPdf,
                  icon: Icon(Icons.attach_file),
                ),
                IconButton(
                  color: Colors.black,
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_messageController.text.trim().isNotEmpty) {
                      processResponse(_messageController.text.trim());
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
