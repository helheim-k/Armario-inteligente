import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final AuthController authController = AuthController();

  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (isLoading) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmController.text.trim();

    // Validar campos vacíos
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage("Completa todos los campos.");
      return;
    }

    // Validar correo
    final emailRegex = RegExp(
      r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$',
    );

    if (!emailRegex.hasMatch(email)) {
      _showMessage("Ingresa un correo válido.");
      return;
    }

    // Validar contraseña
    if (password.length < 6) {
      _showMessage("La contraseña debe tener al menos 6 caracteres.");
      return;
    }

    // Confirmar contraseña
    if (password != confirmPassword) {
      _showMessage("Las contraseñas no coinciden.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await authController.register(
        name: name,
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.home,
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(_firebaseError(e.code));
    } catch (_) {
      _showMessage("Ocurrió un error inesperado.");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _firebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';

      case 'invalid-email':
        return 'El correo no es válido.';

      case 'weak-password':
        return 'La contraseña es demasiado débil.';

      case 'network-request-failed':
        return 'Sin conexión a Internet.';

      default:
        return 'Ocurrió un error. Intenta nuevamente.';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear cuenta"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: ListView(
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.person_add,
                size: 90,
                color: Colors.pink,
              ),

              const SizedBox(height: 20),

              const Text(
                "Crear Cuenta",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              CustomTextField(
                controller: nameController,
                hint: "Nombre",
                icon: Icons.person,
              ),

              const SizedBox(height: 20),

              CustomTextField(
                controller: emailController,
                hint: "Correo",
                icon: Icons.email,
              ),

              const SizedBox(height: 20),

              CustomTextField(
                controller: passwordController,
                hint: "Contraseña",
                icon: Icons.lock,
                obscureText: true,
              ),

              const SizedBox(height: 20),

              CustomTextField(
                controller: confirmController,
                hint: "Confirmar contraseña",
                icon: Icons.lock_outline,
                obscureText: true,
              ),

              const SizedBox(height: 30),

              CustomButton(
                text: "Crear cuenta",
                onPressed: register,
                isLoading: isLoading,
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "¿Ya tienes cuenta? Inicia sesión",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}