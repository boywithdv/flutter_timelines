import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timelines/view/components/custom_button.dart';
import 'package:flutter_timelines/view/components/custom_text_field.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  final errorTextController = TextEditingController();

  bool isVisible = true;

  //sign user in
  void signIn() async {
    //show loading circle
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailTextController.text,
          password: passwordTextController.text);
      //pop loading circle
      if (context.mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      //pop loading circle
      Navigator.pop(context);
      //display error message
      setState(() {
        errorTextController.text = "ログインできません😢";
      });
    }
  }

  //display a dialog message
  void displayMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message),
      ),
    );
  }

  void visibility_on_off() {
    setState(() {
      isVisible = !isVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            children: [
              SizedBox(height: height * 0.1),
              // logo
              const Icon(
                Icons.lock,
                size: 100,
              ),
              SizedBox(
                height: height * 0.04,
              ),
              // welcome back message
              const Text(
                'Welcome back, you`ve been missed!',
              ),
              Text(
                errorTextController.text,
                style: const TextStyle(color: Colors.red),
              ),
              SizedBox(
                height: height * 0.03,
              ),
              //email textfield
              CustomTextField(
                controller: emailTextController,
                hintText: 'Email',
                obscureText: false,
                prefixIcon: const Icon(Icons.mail),
              ),
              const SizedBox(
                height: 10,
              ),
              // password textfield
              CustomTextField(
                controller: passwordTextController,
                hintText: "Password",
                obscureText: isVisible,
                prefixIcon: const Icon(
                  Icons.password,
                ),
                suffixIcon: isVisible
                    ? IconButton(
                        icon: const Icon(
                          Icons.visibility,
                        ),
                        onPressed: visibility_on_off,
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.visibility_off,
                        ),
                        onPressed: visibility_on_off,
                      ),
              ),
              const SizedBox(
                height: 10,
              ),
              // sign in button
              CustomButton(
                text: 'Sign in',
                onTap: signIn,
              ),
              const SizedBox(
                height: 25,
              ),
              // go to register page
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Not a member? ',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: const Text(
                      "Register now ",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  )
                ],
              )
            ],
          ),
        )),
      ),
    );
  }
}
