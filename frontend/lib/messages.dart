import 'package:flutter/material.dart';

class MessagesScreen extends StatefulWidget {
  final List messages;
  const MessagesScreen({Key? key, required this.messages}) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return ListView.separated(
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.all(screenWidth * 0.025),
          child: Row(
            mainAxisAlignment: widget.messages[index]['isUserMessage']
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.02,
                  horizontal: screenWidth * 0.04,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(screenWidth * 0.05),
                    topRight: Radius.circular(screenWidth * 0.05),
                    bottomRight: Radius.circular(
                      widget.messages[index]['isUserMessage'] ? 0 : screenWidth * 0.05,
                    ),
                    topLeft: Radius.circular(
                      widget.messages[index]['isUserMessage'] ? screenWidth * 0.05 : 0,
                    ),
                  ),
                  color: widget.messages[index]['isUserMessage']
                      ? Color(0xFF3A59D1)
                      : Color(0xFF3D90D7)
                ),
                constraints: BoxConstraints(maxWidth: screenWidth * 2 / 3),
                child: Text(
                  widget.messages[index]['message'].toString(),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (_, i) => Padding(
        padding: EdgeInsets.only(top: screenHeight * 0.01),
      ),
      itemCount: widget.messages.length,
    );
  }
}