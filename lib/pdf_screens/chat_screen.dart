import 'package:aichat/pdf_screens/webview_screen.dart';
import 'package:flutter/material.dart';
import 'package:aichat/utils/pdf_utils.dart';
import 'package:provider/provider.dart';
import 'package:side_sheet/side_sheet.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../page/ChatPage.dart';
import '../stores/AIChatStore.dart';
import '../utils/Time.dart';
import '../utils/Utils.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Add this new state variable at the top with other state variables
  bool showingGameHistory = false;
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
      "question":
          "Thanks for sharing! Would you like to try something new today?",
      "options": [
        "Yes, show me new things!",
        "I’m looking for something specific",
        "I just want to relax"
      ]
    },
    {
      "question": "What interests you the most these days?",
    },
    {
      "question":
          "Hey there! Would you like to upload a PDF so I can assist you better?",
      "options": [
        "Yes, I have a PDF to upload",
        "No, I just want to ask general questions"
      ]
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
      "options": [
        "Puzzle games",
        "Adventure games",
        "Strategy games",
        "Casual games"
      ]
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
      "options": [
        "Yes, it helps in understanding strategic decision-making",
        "Maybe, I need to explore more"
      ]
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
          if (nextQuestion.containsKey("options"))
            "options": nextQuestion["options"],
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
    if (chatEnded) return; // Prevent further processing if chat is ended

    setState(() {
      conversation.add({"text": answer, "isUser": true});
      questionIndex++;

      if (questionIndex < initialQuestions.length) {
        var nextQuestion = initialQuestions[questionIndex];

        conversation.add({
          "text": nextQuestion["question"],
          "isUser": false,
          if (nextQuestion.containsKey("options"))
            "options": nextQuestion["options"],
        });

        // ✅ Unlock PDF upload when reaching the last question (without options)
        if (questionIndex == initialQuestions.length - 1 &&
            !nextQuestion.containsKey("options")) {
          questionsCompleted = true;
          showInitialOptions = false;
        }
      } else {
        // ✅ Ensure PDF unlocks even if all questions are answered
        questionsCompleted = true;
        showInitialOptions = false;
      }
    });

    _scrollToBottom(); // Ensure smooth scrolling
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
          if (nextQuestion.containsKey("options"))
            "options": nextQuestion["options"],
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
          if (nextQuestion.containsKey("options"))
            "options": nextQuestion["options"],
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
          conversation.add({
            "text": "Thanks for participating! Hope you had fun!",
            "isUser": false
          });
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

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    String chatId,
  ) async {
    final store = Provider.of<AIChatStore>(context, listen: false);
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm deletion?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () async {
                await store.deleteChatById(chatId);
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _genChatItemWidget(Map chat, {bool isLastInGroup = false}) {
    return InkWell(
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: () {
        final store = Provider.of<AIChatStore>(context, listen: false);
        store.fixChatList();
        Utils.jumpPage(
          context,
          ChatPage(
            chatId: chat['id'],
            autofocus: false,
            chatType: chat['ai']['type'],
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Color.fromARGB(33, 255, 255, 255),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat['messages'][0]['content'],
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 24 / 16,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 22),
                  color: const Color.fromARGB(255, 255, 255, 255),
                  onPressed: () {
                    _showDeleteConfirmationDialog(context, chat['id']);
                  },
                ),
              ],
            ),
          ),
          // const SizedBox(height: 12),
          if (isLastInGroup) ...[
            const SizedBox(height: 16), // Added spacing before divider
            const Divider(
              height: 2,
              color: Color.fromRGBO(166, 166, 166, 1.0),
            ),
          ],
        ],
      ),
    );
  }

  Widget _renderChatListWidget(List chatList) {
    final store = Provider.of<AIChatStore>(context, listen: false);
    final groupedChats = store.getGroupedChatList();

    return Expanded(
      child: ListView(
        shrinkWrap: true,
        children: groupedChats.entries.map((entry) {
          if (entry.value.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...entry.value.asMap().entries.map((chatEntry) {
                final isLastInGroup = chatEntry.key == entry.value.length - 1;
                return _genChatItemWidget(chatEntry.value,
                    isLastInGroup: isLastInGroup);
              }).toList(),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  GestureDetector buildSideSheet(BuildContext context, List<dynamic> chatList) {
    return GestureDetector(
      onTap: () {
        SideSheet.left(
          sheetColor: Color.fromARGB(255, 43, 131, 218),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    style: const ButtonStyle(
                      padding: WidgetStatePropertyAll(EdgeInsets.zero),
                    ),
                    onPressed: () {},
                    icon: const FaIcon(
                      FontAwesomeIcons.gamepad,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Gameyoutube",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    style: const ButtonStyle(
                      padding: WidgetStatePropertyAll(EdgeInsets.zero),
                    ),
                    onPressed: () {
                      setState(() {
                        showingGameHistory = true;
                      });
                    },
                    icon: const FaIcon(
                      FontAwesomeIcons.clockRotateLeft,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Game History",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    "History",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  _renderChatListWidget(chatList),
                ],
              ),
            ),
          ),
          context: context,
        );
      },
      child: const Icon(Icons.menu_rounded),
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
        "description":
            'Challenge yourself with classic multiple-choice quizzes',
        "image": 'assets/classic mcq.jpg'
      },
      {
        "name": "Snake Game",
        "url":
            "https://dev-game-yt.vercel.app/snakegame/DHjqpvDnNGE/mcqs/easy/fb4fbcefe833aec9b26a0b7702264ffcc020f7c2eda9c07bdeac997728543851/",
        "description": 'Test your knowledge by playing the snake game!',
        "image": 'assets/snake game.jpg'
      },
      {
        "name": "Question Construction",
        "url":
            "https://dev-game-yt.vercel.app/questionconstruction/DHjqpvDnNGE/tfs/easy/fb4fbcefe833aec9b26a0b7702264ffcc020f7c2eda9c07bdeac997728543851",
        "description":
            'Challenge yourself with classic multiple-choice quizzes',
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

  // Replace buildSideSheet with buildDrawer
  Widget buildDrawer(BuildContext context, List<dynamic> chatList) {
    return Drawer(
      backgroundColor: Color.fromARGB(255, 43, 131, 218),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: showingGameHistory
              ? _buildGameHistoryView(chatList)
              : _buildDefaultDrawerView(chatList),
        ),
      ),
    );
  }

  // Add this new method for default drawer view
  Widget _buildDefaultDrawerView(List<dynamic> chatList) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          style: const ButtonStyle(
            padding: WidgetStatePropertyAll(EdgeInsets.zero),
          ),
          onPressed: () {},
          icon: const FaIcon(
            FontAwesomeIcons.gamepad,
            color: Colors.white,
          ),
          label: const Text(
            "Gameyoutube",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        TextButton.icon(
          style: const ButtonStyle(
            padding: WidgetStatePropertyAll(EdgeInsets.zero),
          ),
          onPressed: () {
            setState(() {
              showingGameHistory = true;
            });
          },
          icon: const FaIcon(
            FontAwesomeIcons.clockRotateLeft,
            color: Colors.white,
          ),
          label: const Text(
            "Game History",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        const Divider(color: Colors.white54),
        const SizedBox(height: 8),
        const Text(
          "History",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        _renderChatListWidget(chatList),
      ],
    );
  }

  // Add this new method for game history view
  Widget _buildGameHistoryView(List<dynamic> chatList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                setState(() {
                  showingGameHistory = false;
                });
              },
            ),
            const Text(
              "Game History",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: chatList.length,
            itemBuilder: (context, index) {
              final chat = chatList[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Color.fromARGB(33, 255, 255, 255),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    chat['messages'][0]['content'],
                    style: const TextStyle(
                      color: Colors.white,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.sports_esports,
                    color: Colors.white,
                  ),
                  onTap: () {
                    // Handle game history item tap
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Update the build method to use Drawer
  @override
  Widget build(BuildContext context) {
    final store = Provider.of<AIChatStore>(context, listen: true);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: buildDrawer(context, store.sortChatList),
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
                                processPostGameQuestionResponse(
                                    answer); // Handle post-game questions
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
