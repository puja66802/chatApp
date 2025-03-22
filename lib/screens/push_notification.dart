import 'package:http/http.dart' as http;
import 'dart:convert';
import '../server/get_server_key.dart';

Future<void> sendPushNotification(String fcmToken, String senderName, String message) async {
  try {
    String accessToken = await GetServerKey().getServerKeyToken(); // 🔹 Get OAuth Token

    var url = Uri.parse('https://fcm.googleapis.com/v1/projects/testingapp-75ac7/messages:send');

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken', // 🔹 Use OAuth Token
    };

    var body = jsonEncode({
      "message": {
        "token": fcmToken,
        "notification": {
          "title": senderName,
          "body": message,
        },
        "android": {
          "notification": {
            "sound": "default"  // ✅ Sound for Android
          }
        },
        "apns": {
          "payload": {
            "aps": {
              "sound": "default"  // ✅ Sound for iOS
            }
          }
        },
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "senderId": "YOUR_SENDER_ID",
        }
      }
    });

    var response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      print("✅ Push notification sent successfully!");
    } else {
      print("❌ Error sending push notification: ${response.body}");
    }
  } catch (e) {
    print("❌ Exception while sending push notification: $e");
  }
}

