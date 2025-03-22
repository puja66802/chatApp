import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'bloc/chat_bloc.dart'; // Import ChatBloc
import 'screens/login_screen.dart';
import 'screens/navigation_bar.dart';

// 🔹 Initialize Firebase Messaging Handler for background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 Background Message: ${message.notification?.title} - ${message.notification?.body}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 🔹 Setup Firebase Messaging
  await setupFirebaseMessaging();

  runApp(const MyApp());
}

// ✅ Function to setup Firebase Messaging
Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 🔹 Request permission for notifications
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("✅ Notification permission granted!");
  } else {
    print("🚫 Notification permission denied!");
  }

  // 🔹 Handle foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("🔔 Foreground Message: ${message.notification?.title} - ${message.notification?.body}");
    _showLocalNotification(message);
  });

  // 🔹 Handle background & terminated state notifications
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

// ✅ Function to show local notification when a message is received
void _showLocalNotification(RemoteMessage message) async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: androidInitializationSettings);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'channel_id',
    'Chat Notifications',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title,
    message.notification?.body,
    notificationDetails,
  );
}

// ✅ Auth Wrapper
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          return NavigationBarScreen(); // Home Screen
        } else {
          return LoginScreen(); // Login Screen
        }
      },
    );
  }
}

// ✅ Main App
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (context) => ChatBloc())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AuthWrapper(),
      ),
    );
  }
}
