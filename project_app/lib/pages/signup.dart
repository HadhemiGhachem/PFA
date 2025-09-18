import 'package:flutter/material.dart';
import 'package:project_app/pages/login.dart';
import 'package:project_app/pages/auth_service.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final AuthService _authService = AuthService();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Fonction pour valider le format de l'email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _signup() async {
    // Vérification des champs vides avec messages spécifiques
    if (_firstnameController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text('Please enter your firstname'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    if (_lastnameController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text('Please enter your lastname'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    if (_emailController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text('Please enter your email'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    if (_passwordController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text('Please enter your password'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Vérification du format de l'email
    if (!_isValidEmail(_emailController.text)) {
      print('Format d\'email invalide : ${_emailController.text}');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text('Please enter a valid email address'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Si tout est valide, tentative d'inscription
    try {
      await _authService.signup(
        _firstnameController.text,
        _lastnameController.text,
        _emailController.text,
        _passwordController.text,
      );
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Login()));
    } catch (e) {
      print('Erreur d\'inscription : $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text('Signup failed'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff14141d),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset("images/signin.png"),
            Padding(
              padding: const EdgeInsets.only(left: 30.0, right: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sign up",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 45.0,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 50.0),
                  Text(
                    "Firstname",
                    style: TextStyle(
                        color: const Color.fromARGB(158, 255, 255, 255),
                        fontSize: 20.0,
                        fontWeight: FontWeight.w500),
                  ),
                  TextField(
                    controller: _firstnameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Enter your Firstname",
                      hintStyle: TextStyle(
                          color: const Color.fromARGB(219, 255, 255, 255)),
                      suffixIcon: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 30.0),
                  Text(
                    "Lastname",
                    style: TextStyle(
                        color: const Color.fromARGB(158, 255, 255, 255),
                        fontSize: 20.0,
                        fontWeight: FontWeight.w500),
                  ),
                  TextField(
                    controller: _lastnameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Enter your Lastname",
                      hintStyle: TextStyle(
                          color: const Color.fromARGB(219, 255, 255, 255)),
                      suffixIcon: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 30.0),
                  Text(
                    "Email",
                    style: TextStyle(
                        color: const Color.fromARGB(158, 255, 255, 255),
                        fontSize: 20.0,
                        fontWeight: FontWeight.w500),
                  ),
                  TextField(
                    controller: _emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Enter your email",
                      hintStyle: TextStyle(
                          color: const Color.fromARGB(219, 255, 255, 255)),
                      suffixIcon: Icon(Icons.email, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 30.0),
                  Text(
                    "Password",
                    style: TextStyle(
                        color: const Color.fromARGB(158, 255, 255, 255),
                        fontSize: 20.0,
                        fontWeight: FontWeight.w500),
                  ),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Enter your Password",
                      hintStyle: TextStyle(
                          color: const Color.fromARGB(219, 255, 255, 255)),
                      suffixIcon: Icon(Icons.password, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 40.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _signup,
                        child: Container(
                          width: 170,
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Color(0xff6b63ff),
                              borderRadius: BorderRadius.circular(30)),
                          child: Center(
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: TextStyle(
                            color: const Color.fromARGB(158, 255, 255, 255),
                            fontSize: 20.0,
                            fontWeight: FontWeight.w500),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => Login()));
                        },
                        child: Text(
                          "LogIn",
                          style: TextStyle(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}