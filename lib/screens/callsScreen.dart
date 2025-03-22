import 'package:flutter/material.dart';
import 'package:testapp/server/get_server_key.dart';

class CallsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child:
      Text(
        "Calls Screen",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),

      // Container(
      //   width: 200,
      //   height: 200,
      //   decoration: BoxDecoration(
      //     color: Colors.red,
      //     borderRadius: BorderRadius.circular(20.0),
      //   ),
      //   child: TextButton(
      //     child: Text(
      //       "Confirm button",
      //       style: TextStyle(color: Colors.black),
      //     ),
      //     onPressed: () async {
      //       GetServerKey getServerKey = GetServerKey();
      //       String acessToken = await getServerKey.getServerKeyToken();
      //       print("////////////////////////////  $acessToken");
      //     },
      //   ),
      // )
    );
  }
}
