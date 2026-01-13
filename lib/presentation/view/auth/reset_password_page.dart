import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _message;

  Future<void> _reset() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailCtrl.text.trim(),
      );
      setState(() {
        _message = 'Revisa tu correo para recuperar la contraseña';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = e.message ?? 'Error al enviar correo';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _reset,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Enviar'),
              ),
            ),
            const SizedBox(height: 16),
            if (_message != null) Text(_message!),
          ],
        ),
      ),
    );
  }
}
