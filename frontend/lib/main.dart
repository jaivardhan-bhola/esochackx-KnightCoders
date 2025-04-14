import 'package:civicsense/Home.dart';
import 'package:civicsense/Login.dart';
import 'package:civicsense/officialHome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Hive.openBox('appBox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var box = Hive.box('appBox');
    var isLoggedIn = box.get('isLoggedIn');
    var userType = box.get('type');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn == true
          ? userType == 'Citizen' ? Home() : userType == 'Official' ? Officialhome() : Scaffold()
          : const Login(),
    );
  }
}
