import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project/info_handler/app_info.dart';
import 'package:project/screens/login_screen.dart';
import 'package:project/screens/main_screen.dart';
import 'package:project/screens/register_screen.dart';
import 'package:project/spalsh_screen/spalsh_screen.dart';
import 'package:project/theme_provider/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb)
  {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyDVrtrjF_2MTBa-IqoDx4jAX0DalVaiVK0",
        appId: "1:714178446102:web:67e3e2f357acb5e2d3c637",
        messagingSenderId: "714178446102",
        projectId: "automate-49bb6",
        authDomain: "automate-49bb6.firebaseapp.com",
        databaseURL: "https://automate-49bb6-default-rtdb.firebaseio.com",
        storageBucket: "automate-49bb6.appspot.com",
      ),
    );
  }

  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppInfo(),
      child: MaterialApp(
        title: 'Flutter Demo',
        themeMode: ThemeMode.system,
        theme: MyThemes.lightTheme,
        darkTheme: MyThemes.darkTheme,
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      ),
    );
  }
}
