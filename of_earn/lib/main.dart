import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(EarningApp());
}

class EarningApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.gold),
      home: AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) return HomePage();
        return LoginPage();
      },
    );
  }
}

// --- Login Page ---
class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login & Start Earning")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: emailController.text, password: passwordController.text);
                } catch (e) {
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: emailController.text, password: passwordController.text);
                  FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).set({
                    'points': 0,
                    'email': emailController.text,
                  });
                }
              },
              child: Text("Login / Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Home Page ---
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int points = 0;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    fetchPoints();
  }

  fetchPoints() async {
    var doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      points = doc['points'];
    });
  }

  addPoints() {
    FirebaseFirestore.instance.collection('users').doc(uid).update({
      'points': FieldValue.increment(10),
    });
    fetchPoints();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("10 Points Added!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Earn Money")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Your Balance:", style: TextStyle(fontSize: 20)),
            Text("$points Points", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green)),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: addPoints,
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
              child: Text("WATCH AD (Earn 10 pts)"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Withdrawal logic here
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Withdrawal request sent!")));
              },
              child: Text("Withdraw Points"),
            ),
            TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: Text("Logout"))
          ],
        ),
      ),
    );
  }
}