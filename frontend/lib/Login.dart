import 'package:civicsense/Home.dart';
import 'package:civicsense/officialHome.dart';
import 'package:civicsense/services/userApiService.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  bool isPasswordVisible = false;
  bool isRegister = false;
  var box = Hive.box('appBox');
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
        body: Stack(
      children: [
        Image.asset('assets/bg.png'),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.06),
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.1),
              child: CircleAvatar(
                radius: screenWidth * 0.2,
                backgroundColor: Colors.blue,
                backgroundImage: AssetImage('assets/logo.png'),
              ),
            ),
            SizedBox(height: screenHeight * 0.05),
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.1),
              child: Text(
                'WELCOME',
                style: GoogleFonts.amaranth(
                  fontSize: screenWidth * 0.1,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Center(
              child: Container(
                  width: screenWidth * 0.9,
                  height: screenHeight * .5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.01),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isRegister == false
                                      ? Color(0xFF3A59D1)
                                      : Color(0xFF3A59D1).withOpacity(0.1),
                                  width: 2.0,
                                ),
                              ),
                            ),
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  isRegister = false;
                                });
                              },
                              child: Text(
                                'Login',
                                style: GoogleFonts.amaranth(
                                  fontSize: screenWidth * 0.05,
                                  color: Color(0xFF3A59D1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.1),
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isRegister == true
                                      ? Color(0xFF3A59D1)
                                      : Color(0xFF3A59D1).withOpacity(0.1),
                                  width: 2.0,
                                ),
                              ),
                            ),
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  isRegister = true;
                                });
                              },
                              child: Text(
                                'Register',
                                style: GoogleFonts.amaranth(
                                  fontSize: screenWidth * 0.05,
                                  color: Color(0xFF3A59D1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.05),
                      isRegister
                          ? Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.05),
                                  child: TextField(
                                    controller: nameController,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.person,
                                        color: Colors.grey[600],
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.transparent)),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.transparent)),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.transparent)),
                                      hintText: 'Name',
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.05),
                                  child: TextField(
                                    controller: emailController,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.email,
                                        color: Colors.grey[600],
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.transparent)),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.transparent)),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.transparent)),
                                      hintText: 'Email',
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.05),
                                  child: TextField(
                                    controller: phoneController,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.phone,
                                        color: Colors.grey[600],
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.transparent)),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.transparent)),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.transparent)),
                                      hintText: 'Phone',
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.05),
                                  child: TextField(
                                    controller: passwordController,
                                    obscureText: !isPasswordVisible,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.lock,
                                        color: Colors.grey[600],
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          isPasswordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            isPasswordVisible =
                                                !isPasswordVisible;
                                          });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.transparent)),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.transparent)),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.transparent)),
                                      hintText: 'Password',
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                ElevatedButton(
                                  onPressed: () {
                                    var response = UserApiService.registerUser(
                                      emailController.text,
                                      passwordController.text,
                                      nameController.text,
                                      phoneController.text,
                                    );
                                    response.then((user) {
                                      box.put('name', user['user']['username']);
                                      box.put('email', user['user']['email']);
                                      box.put('type', user['user']['type']);
                                      box.put('phone', user['user']['phone']);
                                      print(
                                          'user phone: ${user['user']['phone']}');
                                      box.put('userId', user['user']['id']);
                                      box.put('isLoggedIn', true);
                                      if (user['user']['type'] == 'Citizen') {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Home(),
                                          ),
                                        );
                                      } else if (user['user']['type'] ==
                                          'Official') {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                Officialhome(),
                                          ),
                                        );
                                      }
                                    }).catchError((error) {
                                      print(error);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text('Invalid Details',
                                                  style: TextStyle(
                                                      color:
                                                          Color(0xFF3A59D1))),
                                              backgroundColor: Colors.white));
                                    });
                                  },
                                  child: Text(
                                    'Next',
                                    style: GoogleFonts.amaranth(
                                      fontSize: screenWidth * 0.05,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF3A59D1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.1,
                                        vertical: screenHeight * 0.01),
                                  ),
                                )
                              ],
                            )
                          : Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.05),
                                  child: TextField(
                                    controller: emailController,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.email,
                                        color: Colors.grey[600],
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.transparent)),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.transparent)),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.transparent)),
                                      hintText: 'Email',
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.05),
                                  child: TextField(
                                    controller: passwordController,
                                    obscureText: !isPasswordVisible,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.lock,
                                        color: Colors.grey[600],
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          isPasswordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            isPasswordVisible =
                                                !isPasswordVisible;
                                          });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.transparent)),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.transparent)),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.transparent)),
                                      hintText: 'Password',
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                ElevatedButton(
                                  onPressed: () {
                                    var response = UserApiService.loginUser(
                                        emailController.text,
                                        passwordController.text);
                                    response.then((user) {
                                      box.put('name', user['user']['username']);
                                      box.put('email', user['user']['email']);
                                      box.put('type', user['user']['type']);
                                      box.put(
                                          'userId',
                                          user['user']
                                              ['id']); // Store the user ID
                                      box.put('isLoggedIn', true);
                                      box.put('phone', user['user']['phone']);
                                      box.put('userId', user['user']['id']);
                                      if (user['user']['type'] == 'Citizen') {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Home(),
                                          ),
                                        );
                                      } else if (user['user']['type'] ==
                                          'Official') {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                Officialhome(),
                                          ),
                                        );
                                      }
                                    }).catchError((error) {
                                      print(error);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text('Invalid Details',
                                                  style: TextStyle(
                                                      color:
                                                          Color(0xFF3A59D1))),
                                              backgroundColor: Colors.white));
                                    });
                                  },
                                  child: Text(
                                    'Login',
                                    style: GoogleFonts.amaranth(
                                      fontSize: screenWidth * 0.05,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF3A59D1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.1,
                                        vertical: screenHeight * 0.01),
                                  ),
                                ),
                              ],
                            )
                    ],
                  )),
            ),
          ],
        ),
      ],
    ));
  }
}
