import 'package:flutter/material.dart';
import 'auth_controller.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Welcome")),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text("Your data is private by default. Sign in to start your diary.", textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await signInWithGoogle();
            },
            child: const Text("Continue"),
          ),
        ]),
      ),
    );
  }
}
