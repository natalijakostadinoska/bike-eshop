import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';

// THEME: Racing Teal with Soft Edges
const Color kRacingTeal = Color(0xFF0E5A8D);
const double kBorderRadius = 24.0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        colorScheme: ColorScheme.fromSeed(seedColor: kRacingTeal),
        fontFamily: 'Inter',
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadius)),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const HomePage();
          }
          return const LoginPage();
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/routes': (context) => const RideRoutesPage(),
        '/customize': (context) => const CustomizerPage(),
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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Auth Failed'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_bike_rounded, size: 80, color: kRacingTeal),
                const SizedBox(height: 10),
                const Text('BICIKLA', style: TextStyle(letterSpacing: 8, fontWeight: FontWeight.w900, fontSize: 24)),
                const SizedBox(height: 60),
                Text(_isLogin ? 'Welcome Back' : 'Join the Race',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                _buildField('Email', _emailController, false),
                const SizedBox(height: 20),
                _buildField('Password', _passwordController, true),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRacingTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadius)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_isLogin ? 'SIGN IN' : 'CREATE ACCOUNT', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin ? "New rider? Register here" : "Already registered? Login",
                      style: const TextStyle(color: Colors.black54)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, bool obscure) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}

// --- HOME PAGE ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "Guest Rider";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('BICIKLA', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: _buildDrawer(context, userEmail),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bikes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final bikeDocs = snapshot.data?.docs ?? [];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildDesignOwnCard(context),
              const SizedBox(height: 30),
              const Text('The Spring Series', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...bikeDocs.map((doc) => _buildBikeCard(context, doc.data() as Map<String, dynamic>)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesignOwnCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/customize'),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kRacingTeal, Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(kBorderRadius),
          boxShadow: [BoxShadow(color: kRacingTeal.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CREATIVE STUDIO', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
                  Text('Design Your Own', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Build a custom bike to your specs.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.palette_rounded, color: Colors.white, size: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String email) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topRight: Radius.circular(kBorderRadius), bottomRight: Radius.circular(kBorderRadius))
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, left: 30, bottom: 30),
            decoration: const BoxDecoration(
              color: kRacingTeal,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(kBorderRadius)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(radius: 30, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(height: 15),
                Text(email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _menuItem(context, Icons.grid_view_rounded, 'Collection', onTap: () => Navigator.pop(context)),
          _menuItem(context, Icons.palette_outlined, 'Design Studio', onTap: () => Navigator.pushNamed(context, '/customize')),
          _menuItem(context, Icons.map_rounded, 'Ride Routes', onTap: () => Navigator.pushNamed(context, '/routes')),
          const Spacer(),
          _menuItem(context, Icons.logout_rounded, 'Logout', color: Colors.redAccent, onTap: () => FirebaseAuth.instance.signOut()),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, {Color color = Colors.black87, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  Widget _buildBikeCard(BuildContext context, Map<String, dynamic> bike) {
    final String heroTag = bike['name'] ?? UniqueKey().toString();
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BikeDetailsPage(bike: bike, heroTag: heroTag))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kBorderRadius),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(kBorderRadius)),
              child: Hero(tag: heroTag, child: Image.network(bike['img'] ?? '', height: 200, width: double.infinity, fit: BoxFit.cover)),
            ),
            ListTile(
              title: Text(bike['name'] ?? 'Model', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(bike['brand'] ?? 'Brand'),
              trailing: Text('\$${bike['price']}', style: const TextStyle(color: kRacingTeal, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CUSTOMIZER PAGE ---
class CustomizerPage extends StatefulWidget {
  const CustomizerPage({super.key});

  @override
  State<CustomizerPage> createState() => _CustomizerPageState();
}

class _CustomizerPageState extends State<CustomizerPage> {
  Color _selectedColor = kRacingTeal;
  String _selectedSize = 'M';
  bool _isSubmitting = false;

  final List<Color> _options = [kRacingTeal, Colors.black, Colors.redAccent, Colors.orangeAccent, Colors.blueGrey];
  final List<String> _sizes = ['S', 'M', 'L', 'XL'];

  Future<void> _submitCustomOrder() async {
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('custom_orders').add({
        'user_email': user?.email,
        'color': _selectedColor.value.toRadixString(16),
        'size': _selectedSize,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Pending Review',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order Sent! We'll contact you for the build."), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('CUSTOM STUDIO', style: TextStyle(letterSpacing: 2, fontSize: 14, fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bike_rounded, size: 220, color: _selectedColor),
                  const SizedBox(height: 10),
                  Text('SIZE: $_selectedSize', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black45)),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('1. SELECT COLOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black38)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _options.map((color) => GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: CircleAvatar(
                      backgroundColor: color,
                      radius: 22,
                      child: _selectedColor == color ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 25),
                const Text('2. SELECT FRAME SIZE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black38)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _sizes.map((size) => ChoiceChip(
                    label: Text(size),
                    selected: _selectedSize == size,
                    onSelected: (val) => setState(() => _selectedSize = size),
                    selectedColor: kRacingTeal,
                    labelStyle: TextStyle(color: _selectedSize == size ? Colors.white : Colors.black),
                  )).toList(),
                ),
                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitCustomOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRacingTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadius)),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SUBMIT DESIGN FOR QUOTE', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- RIDE ROUTES PAGE ---
class RideRoutesPage extends StatelessWidget {
  const RideRoutesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RIDE ROUTES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _routeCard('Vardar River Quay', '15km paved river track.', 'Vardar Quay, Skopje'),
          _routeCard('Matka Canyon', 'Off-road mountain trail.', 'Matka Canyon, Skopje'),
        ],
      ),
    );
  }

  Widget _routeCard(String title, String desc, String dest) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: kRacingTeal, child: Icon(Icons.map, color: Colors.white, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
        onTap: () async {
          final url = Uri.parse('https://www.google.com/maps/search/${Uri.encodeComponent(dest)}');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }
}

// --- DETAILS PAGE ---
class BikeDetailsPage extends StatelessWidget {
  final Map<String, dynamic> bike;
  final String heroTag;
  const BikeDetailsPage({super.key, required this.bike, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Hero(tag: heroTag, child: Image.network(bike['img'] ?? '', height: 450, width: double.infinity, fit: BoxFit.cover)),
          Positioned(top: 50, left: 20, child: CircleAvatar(backgroundColor: Colors.white, child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)))),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 400,
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bike['brand']?.toString().toUpperCase() ?? 'BRAND', style: const TextStyle(color: kRacingTeal, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  Text(bike['name'] ?? 'Model', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('\$${bike['price']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300)),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kRacingTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadius)),
                      ),
                      child: const Text('RESERVE NOW', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}