import 'package:aichat/screens/webview_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/pdf_utils.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? pdfFileName;
  bool isLoading = false;
  final TextEditingController _messageController = TextEditingController();

  bool showGamePrompt = false;
  bool showGameOptions = false;

  void uploadPdf() async {
    setState(() {
      isLoading = true;
    });

    final text = await PdfUtils.extractTextFromPdf();
    setState(() {
      isLoading = false;
    });

    if (text != null) {
      setState(() {
        pdfFileName = PdfUtils.fileName; // File name from PdfUtils
        showGamePrompt = true; // Show the game prompt after uploading the PDF
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF '${pdfFileName}' uploaded successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload PDF.")),
      );
    }
  }

  // Launch a URL
  void _launchUrl(String url) {
    Navigator.push(context, MaterialPageRoute(builder: (context)=> WebViewScreen(url: url)));
  }

  // Show game options slider
  Widget gameOptions() {
    List<Map<String, String>> games = [
      {
        "name": "Mario Game",
        "url": "https://www.gameyoutube.com/question",
        "description": 'step into the world of Mario and enjou!',
        "image":"assets/mario.jpg"
      },
      {
        "name": "Monster Game",
        "url": "https://www.gameyoutube.com/question",
        "description": 'Test your knowledge by playing the monster game!',
        "image":'assets/monster game.jpg'
      },
      {
        "name": "Mine Game",
        "url": "https://www.gameyoutube.com/question",
        "description": 'Dig deeper and find treasures in this fun game',
        "image":'assets/mine game.jpg'
      },
      {
        "name": "Classic MCQ",
        "url": "https://www.gameyoutube.com/question",
        "description": 'Challenge yourself with classic multiple-choice quizzes',
        "image":'assets/classic mcq.jpg'
      }
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
                  onTap: () => _launchUrl(games[index]["url"]!),
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
            left: 10,
            top: 100,
            bottom: 100,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 32),
              onPressed: previousPage,
            ),
          ),
          Positioned(
            right: 10,
            top: 100,
            bottom: 100,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 32,color: Colors.black,),
              onPressed: nextPage,

            ),
          ),
        ],
      ),
    );
  }

  // Handle response to "Do you want to play a game?"
  void processGameResponse() {
    final userResponse = _messageController.text.trim().toLowerCase();
    if (userResponse == "yes") {
      setState(() {
        showGamePrompt = false; // Hide the prompt after "Yes"
        showGameOptions = true; // Show the game options
      });
    } else if (userResponse == "no") {
      setState(() {
        showGamePrompt = false; // Hide the prompt after "No"
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF chat"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Chat bubble with uploaded PDF
                if (pdfFileName != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.red),
                          const SizedBox(width: 8.0),
                          Text(
                            pdfFileName!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Chat bubble example
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Text(
                      "Welcome! Upload a PDF or ask a question.",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                if (showGamePrompt)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Text(
                        "Do you want to play a game? Type 'Yes' or 'No'.",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                if (showGameOptions) gameOptions(),
              ],
            ),
          ),
          // Loading Indicator
          if (isLoading)
            const Center(child: CircularProgressIndicator()),

          // Upload PDF Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: "Write a message...",
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    if (showGamePrompt) {
                      processGameResponse(); // Process game response
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: uploadPdf,
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (showGamePrompt) {
                    processGameResponse(); // Process game response
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

