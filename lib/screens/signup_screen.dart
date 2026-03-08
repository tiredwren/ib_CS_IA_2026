import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupState();
}

class _SignupState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstN = TextEditingController();
  final _lastN = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _position = TextEditingController();
  final _code = TextEditingController();

  String _program = 'Pee Wee Kickers (ages 3 - 5)';
  bool _loading = false;
  bool _hidePass = true;
  bool _isAdmin = false;
  bool _hideCode = true;

  final List<String> _programs = [
    'Pee Wee Kickers (ages 3 - 5)',
    'Teen/Adult (ages 13+)',
    'Family (all ages)',
    'SNAP (special needs)',
    'Kickboxing Fitness',
  ];

  @override
  void dispose() {
    _firstN.dispose();
    _lastN.dispose();
    _email.dispose();
    _pass.dispose();
    _position.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final auth = Provider.of<AuthService>(context, listen: false);
    final err = await auth.signUp(
      email: _email.text.trim(),
      password: _pass.text,
      firstName: _firstN.text.trim(),
      lastName: _lastN.text.trim(),
      program: _program,
      position: _isAdmin ? _position.text.trim() : null,
      adminCode: _isAdmin ? _code.text.trim() : null,
    );

    setState(() => _loading = false);

    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: const Color(0xFFCC0000)),
      );
    } else if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  // ensure password is strong
  String? _validatePass(String? val) {
    if (val == null || val.isEmpty) return 'Please enter a password';
    if (val.length < 8) return 'Must be at least 8 characters';
    if (!val.contains(RegExp(r'[A-Z]'))) return 'Must contain an uppercase letter';
    if (!val.contains(RegExp(r'[0-9]'))) return 'Must contain a number';
    if (!val.contains(RegExp(r'[!@#\$&*~%^()_\-+=]'))) return 'Must contain a special character';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // go back to login page
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/logo.jpeg',
                    height: 80,
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      alignment: Alignment.center,
                      child: const Icon(Icons.sports_martial_arts, size: 60, color: Color(0xFFCC0000)), // fallback icon if image load fails
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sign up for an account',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  const Text('First name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _firstN,
                    decoration: const InputDecoration(hintText: 'Enter first name'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Please enter your first name' : null,
                  ),
                  const SizedBox(height: 20),

                  const Text('Last name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _lastN,
                    decoration: const InputDecoration(hintText: 'Enter last name'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Please enter your last name' : null,
                  ),
                  const SizedBox(height: 20),

                  const Text('Account type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<bool>(
                    value: _isAdmin,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    items: const [
                      DropdownMenuItem(value: false, child: Text('Student')),
                      DropdownMenuItem(value: true, child: Text('Admin')),
                    ],
                    onChanged: (v) => setState(() => _isAdmin = v!), // change what dropdown displays (responding to user clicks)
                  ),
                  const SizedBox(height: 20),

                  if (!_isAdmin) ...[ // ask for program from students
                    const Text('Program', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _program,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: _programs.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (v) => setState(() => _program = v!),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_isAdmin) ...[ // ask for position and code from admin
                    const Text('Position', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _position,
                      decoration: const InputDecoration(hintText: 'eg. Front Desk Manager'),
                      validator: (v) => (_isAdmin && (v == null || v.isEmpty)) ? 'Please enter your position' : null,
                    ),
                    const SizedBox(height: 20),

                    const Text('Admin Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _code,
                      obscureText: _hideCode,
                      decoration: InputDecoration(
                        hintText: 'Enter admin code',
                        suffixIcon: IconButton(
                          icon: Icon(_hideCode ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _hideCode = !_hideCode),
                        ),
                      ),
                      validator: (v) => (_isAdmin && (v == null || v.isEmpty)) ? 'Please enter the admin code' : null,
                    ),
                    const SizedBox(height: 20),
                  ],

                  const Text('Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'Enter your email'),
                    validator: (v) { // ensure valid email so TMA can send emails in the future (extensibility)
                      if (v == null || v.isEmpty) return 'Please enter your email';
                      if (!v.contains('@')) return 'Please enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  const Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pass,
                    obscureText: _hidePass,
                    decoration: InputDecoration(
                      hintText: 'Create a password',
                      helperText: 'Requirements: 8 chars, 1 uppercase, 1 number, 1 special character',
                      helperMaxLines: 2,
                      suffixIcon: IconButton(
                        icon: Icon(_hidePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _hidePass = !_hidePass),
                      ),
                    ),
                    validator: _validatePass,
                  ),
                  const SizedBox(height: 32),

                  // sign up button > home page
                  SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCC0000),
                        foregroundColor: Colors.white,
                      ),
                      child: _loading
                          ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                          : const Text('Sign up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? '), // link text to login screen
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Login', style: TextStyle(color: Color(0xFFCC0000), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}