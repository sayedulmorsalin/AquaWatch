import 'package:flutter/material.dart';
import 'package:aquawatch/authentication/login.dart';
import 'package:aquawatch/authentication/location_selection_dialog.dart';
import 'package:aquawatch/services/auth_service.dart';
import 'package:aquawatch/services/location_service.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authorityCodeController = TextEditingController();

  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  bool _isLoading = false;
  String _selectedUserType = 'User';
  final _authService = AuthService();
  LocationData? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _authorityCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedUserType == 'Authority' &&
        _authorityCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the authority verification code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedUserType == 'Authority' &&
        _authorityCodeController.text.trim() != '1720') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid authority verification code. Please use 1720 for admin registration.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.registerWithProfile(
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        email: _emailController.text,
        password: _passwordController.text,
        userRole: _selectedUserType,
        location: _selectedLocation?.toMap(),
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade600,
              Colors.cyan.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                        width: 1.2,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.2),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.water_drop,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'AquaWatch',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create Your Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                _buildUserTypeDropdown(),
                                const SizedBox(height: 16),
                                if (_selectedUserType == 'Authority')
                                  Column(
                                    children: [
                                      _buildTextField(
                                        controller: _authorityCodeController,
                                        label: 'Authority Verification Code',
                                        icon: Icons.verified_user_outlined,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                _buildTextField(
                                  controller: _nameController,
                                  label: 'Full Name',
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Email Address',
                                  icon: Icons.mail_outline,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _phoneController,
                                  label: 'Phone Number',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _addressController,
                                  label: 'Address',
                                  icon: Icons.location_on_outlined,
                                ),
                                const SizedBox(height: 16),
                                _buildLocationSelectionButton(),
                                const SizedBox(height: 16),
                                _buildPasswordTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  isObscure: _isPasswordHidden,
                                  toggleVisibility: () {
                                    setState(
                                      () => _isPasswordHidden =
                                          !_isPasswordHidden,
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildPasswordTextField(
                                  controller: _confirmPasswordController,
                                  label: 'Confirm Password',
                                  isObscure: _isConfirmPasswordHidden,
                                  toggleVisibility: () {
                                    setState(
                                      () => _isConfirmPasswordHidden =
                                          !_isConfirmPasswordHidden,
                                    );
                                  },
                                ),
                                const SizedBox(height: 28),
                                _buildRegisterButton(),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Already have an account? ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginPage(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Login',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _commonDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
      prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.85)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.75),
          width: 1.5,
        ),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: _commonDecoration(hint: label, icon: icon),
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String label,
    required bool isObscure,
    required VoidCallback toggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: _commonDecoration(
        hint: label,
        icon: Icons.lock_outline,
        suffixIcon: GestureDetector(
          onTap: toggleVisibility,
          child: Icon(
            isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedUserType,
        dropdownColor: Colors.blue.shade900,
        icon: Icon(
          Icons.arrow_drop_down,
          color: Colors.white.withValues(alpha: 0.85),
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.people_outline,
            color: Colors.white.withValues(alpha: 0.85),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        items: const [
          DropdownMenuItem(value: 'User', child: Text('User')),
          DropdownMenuItem(value: 'Authority', child: Text('Authority')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedUserType = value);
          }
        },
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Colors.blue.shade100]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleRegister,
          borderRadius: BorderRadius.circular(12),
          child: _isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                )
              : const Center(
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLocationSelectionButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => LocationSelectionDialog(
            onLocationSelected: (location) {
              setState(() {
                _selectedLocation = location;
              });
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedLocation != null
                ? Colors.green.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.35),
            width: _selectedLocation != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _selectedLocation != null
                  ? Icons.check_circle
                  : Icons.location_on_outlined,
              color: _selectedLocation != null
                  ? Colors.green
                  : Colors.white.withValues(alpha: 0.85),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedLocation != null
                        ? 'Location Selected'
                        : 'Select Your Location',
                    style: TextStyle(
                      color: _selectedLocation != null
                          ? Colors.green.shade300
                          : Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_selectedLocation != null)
                    Text(
                      _selectedLocation!.toString(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      'Auto-detect or manually select',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.65),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
