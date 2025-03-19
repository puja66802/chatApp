// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'bloc/chat_bloc.dart'; // Import your ChatBloc
// import 'screens/login_screen.dart'; // Ensure correct import
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider(create: (context) => ChatBloc()), // Provide ChatBloc globally
//       ],
//       child: MaterialApp(
//         debugShowCheckedModeBanner: false,
//         home: LoginScreen(), // Start with login screen
//       ),
//     );
//   }
// }



import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/chat_bloc.dart'; // Import your ChatBloc
import 'screens/login_screen.dart';
import 'screens/navigation_bar.dart'; // Your Home Screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ChatBloc()), // Provide ChatBloc globally
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AuthWrapper(), // ✅ Check user authentication status
      ),
    );
  }
}

// ✅ Wrapper to check authentication status
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()), // Show loading
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return NavigationBarScreen(); // ✅ Go to home if logged in
        } else {
          return LoginScreen(); // ✅ Otherwise, show login screen
        }
      },
    );
  }
}
