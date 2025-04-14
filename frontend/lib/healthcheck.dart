import 'package:civicsense/MLApiCalls.dart';
import 'package:civicsense/Profile.dart';
import 'package:civicsense/chatbot.dart';
import 'package:civicsense/posts.dart';
import 'package:civicsense/widgets/parallelogram_shape.dart'; // Import the custom shape
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:civicsense/services/complaintsApiService.dart'; // Import the complaints service
import 'package:hive_flutter/hive_flutter.dart';

class HealthCheck extends StatefulWidget {
  const HealthCheck({super.key});

  @override
  State<HealthCheck> createState() => _HealthCheckState();
}

class _HealthCheckState extends State<HealthCheck> {
  final mlApi = MLApiService();

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Profile(),
                    ),
                  );
                },
                icon: Icon(Icons.person,
                    color: Colors.white, size: screenWidth * 0.08)),
          ],
          title: Row(
            children: [
              CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: screenWidth * 0.05,
                  backgroundImage: AssetImage('assets/logo.png')),
              SizedBox(width: screenWidth * 0.02),
              Text(
                'CivicSense',
                style: GoogleFonts.instrumentSans(
                  fontSize: screenWidth * 0.06,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Replace FloatingActionButton with our custom ParallelogramButton
        floatingActionButton: ParallelogramButton(
          color: Color(0xFF71B340),
          width: 60,
          height: 50,
          skewAmount: 12.0,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Chatbot(),
              ),
            );
          },
          child: Icon(Icons.chat_rounded, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: Stack(
          children: [
            Container(
              height: screenHeight,
              width: screenWidth,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3D84D6), Color(0xFF3A59D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.15),
                  Image.asset('assets/bot2.png', height: screenHeight * 0.235),
                  Container(
                    width: screenWidth,
                    height: screenHeight * 0.552,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(screenWidth * 0.05),
                        topRight: Radius.circular(screenWidth * 0.05),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: screenWidth * 0.05,
                          right: screenWidth * 0.05,
                          top: screenHeight * 0.02,
                          bottom: screenHeight * 0.02,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Choose your predictor",
                                style: GoogleFonts.instrumentSans(
                                  fontSize: screenWidth * 0.06,
                                  fontWeight: FontWeight.w600
                                )),
                            SizedBox(height: screenHeight * 0.02),
                            GestureDetector(
                              child: Image.asset(
                                'assets/button1.png',
                                height: screenHeight * 0.15,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            GestureDetector(
                              child: Image.asset(
                                'assets/button2.png',
                                height: screenHeight * 0.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.home_rounded,
                              color: Colors.white, size: screenWidth * 0.1)),
                      SizedBox(width: screenWidth * 0.05),
                      IconButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Posts(),
                              ),
                            );
                          },
                          icon: Icon(Icons.feed_rounded,
                              color: Colors.white, size: screenWidth * 0.1)),
                      SizedBox(width: screenWidth * 0.05),
                      IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.medical_services_rounded,
                              color: Colors.white, size: screenWidth * 0.1)),
                      SizedBox(width: screenWidth * 0.05),
                    ],
                  )
                ],
              ),
            )
          ],
        ));
  }  
}
