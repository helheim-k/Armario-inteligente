import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthController authController = AuthController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Validar campos vacíos
    if (email.isEmpty || password.isEmpty) {
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

    setState(() {
      isLoading = true;
    });

    try {
      await authController.login(
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
      case 'user-not-found':
        return 'No existe una cuenta con ese correo.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';

      case 'invalid-email':
        return 'El correo no es válido.';

      case 'too-many-requests':
        return 'Demasiados intentos. Intenta nuevamente más tarde.';

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.checkroom,
                size: 90,
                color: Colors.pink,
              ),

              const SizedBox(height: 20),

              const Text(
                "Armario Inteligente",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

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

              const SizedBox(height: 30),

              CustomButton(
                text: "Iniciar sesión",
                onPressed: login,
                isLoading: isLoading,
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.register,
                        );
                      },
                child: const Text("Crear cuenta"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}