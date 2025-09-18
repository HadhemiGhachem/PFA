import 'package:flutter/material.dart';
import 'package:project_app/pages/signup.dart';
import 'package:project_app/pages/auth_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

 void _login() async {
  print('Bouton Login cliqué');
  try {
    await _authService.login(
      _emailController.text,
      _passwordController.text,
    );
    print('Avant navigation vers /home');
    Navigator.pushReplacementNamed(context, '/home');
    print('Après navigation vers /home'); // Ne s’affichera pas si ça échoue
  } catch (e) {
    print('Erreur de connexion : $e');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erreur'),
        content: Text('Incorrect email or password'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
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
                    "Welcome!",
                    style: TextStyle(
                        color: const Color.fromARGB(158, 255, 255, 255),
                        fontSize: 34.0,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "Login",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 45.0,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 90.0),
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
                  SizedBox(height: 40.0),
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
                  SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "Forgot Password?",
                        style: TextStyle(
                            color: Color(0xff6b63ff),
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  SizedBox(height: 60.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => SignUp()));
                        },
                        child: Container(
                          width: 170,
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30)),
                          child: Center(
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                  color: Color(0xff6b63ff),
                                  fontSize: 25.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _login,
                        child: Container(
                          width: 170,
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Color(0xff6b63ff),
                              borderRadius: BorderRadius.circular(30)),
                          child: Center(
                            child: Text(
                              "Login",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
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