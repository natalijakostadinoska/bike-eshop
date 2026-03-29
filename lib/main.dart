import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'firebase_options.dart'; // Uncomment this once you run 'flutterfire configure'

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure you've initialized Firebase before running the app
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BikeShopApp());
}

class BikeShopApp extends StatelessWidget {
  const BikeShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BICIKLA',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        fontFamily: 'Inter',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

// --- LOGIN PAGE ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('BICIKLA', style: TextStyle(letterSpacing: 12, fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 60),
              const Text('Professional Grade', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const Text('Sign in to your racing portal.', style: TextStyle(color: Colors.black45)),
              const SizedBox(height: 40),
              _buildField('Email', _emailController, false),
              const SizedBox(height: 20),
              _buildField('Password', _passwordController, true),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: const Text('AUTHENTICATE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, bool obscure) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: Colors.black38),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
      ),
    );
  }
}

// --- HOME PAGE (FIRESTORE DRIVEN) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text('BICIKLA', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.bold, fontSize: 14)),
        centerTitle: true,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.shopping_cart_outlined, size: 20))],
      ),
      drawer: _buildDrawer(context),
      body: StreamBuilder<QuerySnapshot>(
        // Streaming from 'bikes' collection in Firestore
        stream: FirebaseFirestore.instance.collection('bikes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Data Load Error"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)));
          }

          final bikes = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('CURRENT COLLECTION', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.black45, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('The Spring Race Series', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              ...bikes.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildBikeCard(data);
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF0F172A)),
            accountName: Text("NATALIE ROSSI", style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text("pro.rider@veloluxe.com"),
            currentAccountPicture: CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
          ),
          _menuItem(context, Icons.person_outline, 'My Account', 'Manage performance data'),
          _menuItem(context, Icons.map_outlined, 'Ride Routes', 'Discover high-altitude trails'),
          _menuItem(context, Icons.architecture, 'Bike Designer', 'Custom carbon configurations'),
          const Spacer(),
          const Divider(),
          _menuItem(context, Icons.logout, 'Logout', null, color: Colors.redAccent),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, String? sub, {Color color = Colors.black87}) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: sub != null ? Text(sub, style: const TextStyle(fontSize: 11)) : null,
      onTap: () => Navigator.pop(context),
    );
  }

  Widget _buildBikeCard(Map<String, dynamic> bike) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                image: DecorationImage(
                  image: NetworkImage(bike['img'] ?? 'https://via.placeholder.com/500'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (bike['brand'] ?? 'Unknown').toString().toUpperCase(),
                    style: const TextStyle(fontSize: 10, letterSpacing: 1, color: Colors.black38, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    bike['name'] ?? 'Generic Model',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              Text('\$${bike['price'] ?? '0'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w300)),
            ],
          ),
        ],
      ),
    );
  }
}