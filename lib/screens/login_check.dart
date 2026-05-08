// ignore_for_file: deprecated_member_use

import 'package:final_app/screens/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AuthWrapper extends StatelessWidget {
  final Widget child;
  const AuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset('assets/MainLogo.png'),
              Text("KhajaKham",style: TextStyle(fontSize: 32),),
              Text('Please log into continue'),
              IconButton(onPressed: ()=>Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_)=> const LoginPage())), icon: FaIcon(FontAwesomeIcons.signIn))
            ],
          ),
        ),
      );
    }
    return child;
  }
}
