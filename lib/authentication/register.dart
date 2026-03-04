import 'package:flutter/material.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {

  // Password visibility states
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "AquaWatch",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                const SizedBox(height: 40),

                const Text(
                  "Create your Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),

                const SizedBox(height: 30),

                buildTextField(hint: "Enter Your Name"),

                const SizedBox(height: 20),

                buildTextField(hint: "Enter phone number"),

                const SizedBox(height: 20),

                buildTextField(hint: "Enter address"),

                const SizedBox(height: 20),

                buildTextField(hint: "Enter email"),

                const SizedBox(height: 20),

                buildTextField(
                  hint: "Enter password",
                  isPassword: true,
                ),

                const SizedBox(height: 20),

                buildTextField(
                  hint: "Re-enter password",
                  isConfirmPassword: true,
                ),

                const SizedBox(height: 15),

                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      
                    },
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      
                    },
                    child: const Text(
                      "Submit",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required String hint,
    bool isPassword = false,
    bool isConfirmPassword = false,
  }) {
    return TextField(
      obscureText: isPassword
          ? _isPasswordHidden
          : isConfirmPassword
          ? _isConfirmPasswordHidden
          : false,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Colors.grey,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Colors.blue,
            width: 2,
          ),
        ),
        suffixIcon: isPassword || isConfirmPassword
            ? IconButton(
          icon: Icon(
            (isPassword
                ? _isPasswordHidden
                : _isConfirmPasswordHidden)
                ? Icons.visibility_off
                : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              if (isPassword) {
                _isPasswordHidden = !_isPasswordHidden;
              } else {
                _isConfirmPasswordHidden =
                !_isConfirmPasswordHidden;
              }
            });
          },
        )
            : null,
      ),
    );
  }
}