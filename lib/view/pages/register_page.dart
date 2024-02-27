import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timelines/view/components/custom_button.dart';
import 'package:flutter_timelines/view/components/custom_text_field.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  final confirmPasswordTextController = TextEditingController();
  // sign user up
  void signUp() async {
    // show loading circle
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    // make sure passwords match
    if (passwordTextController.text != confirmPasswordTextController.text) {
      //pp loading circle
      Navigator.pop(context);
      //show error to user
      displayMessage("Passwords don't match!");
      return;
    }
    //try creating the user
    try {
      // create the user
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailTextController.text,
        password: passwordTextController.text,
      );
      //after creating the user, create a new document in cloud firestore called Users
      FirebaseFirestore.instance
          .collection('Users')
          .doc(userCredential.user!.email!)
          .set(
        {
          'username':
              emailTextController.text.split('@')[0], // initial username
          'bio': 'Empty bio...' // initially empty bio
          // add any additional fields as needs
        },
      );
      if (context.mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      //show error to user
      displayMessage(e.code);
    }
  }

  void displayMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message),
      ),
    );
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
              Icon(
                Icons.lock,
                size: 100,
              ),
              SizedBox(
                height: height * 0.04,
              ),
              // welcome back message
              Text('Lets create an account for you'),
              SizedBox(
                height: height * 0.03,
              ),
              //email textfield
              CustomTextField(
                  controller: emailTextController,
                  hintText: 'Email',
                  obscureText: false),
              SizedBox(
                height: 10,
              ),
              CustomTextField(
                  controller: passwordTextController,
                  hintText: "Password",
                  obscureText: true),
              SizedBox(
                height: 10,
              ),
              // password textfield
              CustomTextField(
                  controller: confirmPasswordTextController,
                  hintText: "Confirm Password",
                  obscureText: true),
              SizedBox(
                height: 10,
              ),
              // sign up button
              CustomButton(
                text: 'Sign Up',
                onTap: signUp,
              ),
              SizedBox(
                height: 25,
              ),
              // go to register page
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(
                    width: 4,
                  ),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Text(
                      "Login now ",
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
