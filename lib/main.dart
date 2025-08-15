import 'package:alpha_state_app/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const login_page(),
    );
  }
}

class login_page extends StatefulWidget {
  const login_page({super.key});

  @override
  State<login_page> createState() => _LoginPageState();
}

class _LoginPageState extends State<login_page> {
  bool secure_pass = true;
  final TextEditingController email_controller = TextEditingController();
  final TextEditingController passwordd = TextEditingController();

  Future<void> signUser() async {
    final regNumber = email_controller.text.trim(); 
    final password = passwordd.text.trim();

    // Convert reg number to Firebase-compatible email
    final email = "$regNumber@alpha-state.edu";

    try {
      
      await authService.value.signIn(email: email, password: password);

     
      final uid = authService.value.currentUser?.uid;
      // print("hey");
      // print(authService.value.currentUser?.uid);
      // print("now");


      if (uid != null) {
  final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

  if (doc.exists && doc.data()!.containsKey('name')) {
    final name = doc['name']; 

    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text("Welcome $name!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), 
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'No account found for that registration number.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      } else {
        errorMessage = e.message ?? 'Login failed.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('CPC'),
          backgroundColor: Colors.blue[900],
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(25)))),
      body: Center(
        child: Container(
          width: 300,
          height: 350,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 80,
                width: 100,
              ),
              const SizedBox(height: 5),
              TextField(
                controller: email_controller,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordd,
                obscureText: secure_pass,
                decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        secure_pass ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          secure_pass = !secure_pass;
                        });
                      },
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(onPressed: signUser, child: const Text("login")),
            ],
          ),
        ),
      ),
    );
  }
}
