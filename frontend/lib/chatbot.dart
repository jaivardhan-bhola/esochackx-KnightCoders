import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:flutter/material.dart';

import 'package:civicsense/messages.dart';

class Chatbot extends StatefulWidget {
  const Chatbot({super.key});

  @override
  State<Chatbot> createState() => _ChatbotState();
}

class _ChatbotState extends State<Chatbot> {
  late DialogFlowtter dialogFlowtter;
  final TextEditingController _controller = TextEditingController();

  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    _initializeDialogFlow();
  }

  Future<void> _initializeDialogFlow() async {
    try {
      dialogFlowtter = await DialogFlowtter(
        jsonPath: "assets/dialog_flow_auth.json",
      );
    } catch (e) {
      print('Error initializing DialogFlow: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF3A59D1),
                Color(0xFF3D90D7),
              ],
            ),
          ),
        ),
        title: Text('CSBot', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/chatbot_bg.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            child: Column(
              children: [
            Expanded(child: MessagesScreen(messages: messages)),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.01),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3D90D7), Color(0xFF3A59D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                    children: [
                      Expanded(
                          child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: Colors.white,
                            )),
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      )),
                      IconButton(
                        onPressed: () {
                          String text = _controller.text.trim();

                          if (text.toLowerCase() == 'features') {
                            // sleep for 2 secs 
                            Future.delayed(const Duration(seconds: 2), () {
                              setState(() {
                                messages.add({
                                  'message': text,
                                  'isUserMessage': true,
                                });

                                messages.add({
                                  'message': '- Detect crop diseases and their common indicators.\n- Learn precautions to prevent diseases in the future.\n- Easily check current rates of various fertilizers.\n- Access weather forecasts for your location.\n- Upload your soil report to analyze its characteristics.\n- Receive personalized fertilizer suggestions based on the data provided.',
                                  'isUserMessage': false,
                                });
                              });
                            });
                            // setState(() {
                            //   messages.add({
                            //     'message': text,
                            //     'isUserMessage': true,
                            //   });

                            //   messages.add({
                            //     'message': '- Detect crop diseases and their common indicators.\n- Learn precautions to prevent diseases in the future.\n- Easily check current rates of various fertilizers.\n- Access weather forecasts for your location.\n- Upload your soil report to analyze its characteristics.\n- Receive personalized fertilizer suggestions based on the data provided.',
                            //     'isUserMessage': false,
                            //   });
                            // });
                          } else {
                            sendMessage(text);
                          }
                          _controller.clear();
                        },
                        icon: const Icon(Icons.send, color: Colors.white),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      messages.add({
        'message': text,
        'isUserMessage': true,
      });
    });

    try {
      DetectIntentResponse response = await dialogFlowtter.detectIntent(
        queryInput: QueryInput(text: TextInput(text: text)),
      );

     String? botMessage = response.queryResult?.fulfillmentMessages?.firstOrNull?.text?.text?.firstOrNull ?? 
        "I didn't understand that.";

      setState(() {
        messages.add({
          'message': botMessage,
          'isUserMessage': false,
        });
      });
    } catch (e) {
      print('Error sending message: $e');
      setState(() {
        messages.add({
          'message': 'Sorry, I encountered an error.',
          'isUserMessage': false,
        });
      });
    }
  }

  void addMessage({
    required dynamic message,
    required bool isUserMessage,
  }) {
    String messageText = message is Message ? 
        message.text?.text?.firstOrNull ?? 'No message' : 
        message.toString();

    messages.add({
      'message': messageText,
      'isUserMessage': isUserMessage,
    });
  }
}