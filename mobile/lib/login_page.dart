// import 'package:flutter/material.dart';
// import 'home_page.dart';
// import 'services/api_service.dart';
// import 'services/token_storage.dart';
// import 'services/biometric_service.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _userCtrl = TextEditingController();
//   final _passCtrl = TextEditingController();
//   bool _hidePassword = true;
//   bool _loading = false;
//   String? _error;

//   @override
//   void dispose() {
//     _userCtrl.dispose();
//     _passCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//         try {
//       final data = await ApiService.login(
//         _userCtrl.text.trim(),
//         _passCtrl.text,
//       );
//       final token = data['access_token'] as String;
//       final name = (data['user']?['nom'] ?? '') as String;      await TokenStorage.save(token);

//       // Fingerprint offer
//       final bio = BiometricService();
//       if (await bio.isAvailable()) {
//         if (await bio.isEnabled()) {
//           // Already enabled: just refresh the stored token
//           await bio.enable(token: token, name: name);
//         } else {
//           if (!mounted) return;
//           final wantsIt = await showDialog<bool>(
//             context: context,
//             builder: (ctx) => AlertDialog(
//               title: const Text('Activer l\'empreinte ?'),
//               content: const Text(
//                 'Connectez-vous plus vite la prochaine fois avec votre empreinte.',
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(ctx, false),
//                   child: const Text('Plus tard'),
//                 ),
//                 TextButton(
//                   onPressed: () => Navigator.pop(ctx, true),
//                   child: const Text('Activer'),
//                 ),
//               ],
//             ),
//           );
//           if (wantsIt == true && await bio.authenticate()) {
//             await bio.enable(token: token, name: name);
//           }
//         }
//       }

//       if (!mounted) return;
//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(builder: (_) => HomePage(userName: name)),
//       );
//     } on ApiException catch (e) {
//       setState(() => _error = e.message);
//     } catch (e) {
//       debugPrint('LOGIN ERROR: $e');
//       setState(() => _error = 'Erreur : $e');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final primary = Theme.of(context).colorScheme.primary;

//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Icon(
//                     Icons.medical_services_rounded,
//                     size: 72,
//                     color: primary,
//                   ),
//                   const SizedBox(height: 16),
//                   const Text(
//                     'Connexion',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     'Espace médecin',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(color: Colors.grey.shade600),
//                   ),
//                   const SizedBox(height: 32),

//                   TextFormField(
//                     controller: _userCtrl,
//                     textInputAction: TextInputAction.next,
//                     autocorrect: false,
//                     decoration: _inputStyle(
//                       'Identifiant',
//                       Icons.person_outline,
//                     ),
//                     validator: (v) => (v == null || v.trim().isEmpty)
//                         ? 'Entrez votre identifiant'
//                         : null,
//                   ),
//                   const SizedBox(height: 16),

//                   TextFormField(
//                     controller: _passCtrl,
//                     obscureText: _hidePassword,
//                     onFieldSubmitted: (_) => _submit(),
//                     decoration: _inputStyle('Mot de passe', Icons.lock_outline)
//                         .copyWith(
//                           suffixIcon: IconButton(
//                             icon: Icon(
//                               _hidePassword
//                                   ? Icons.visibility_off
//                                   : Icons.visibility,
//                             ),
//                             onPressed: () =>
//                                 setState(() => _hidePassword = !_hidePassword),
//                           ),
//                         ),
//                     validator: (v) => (v == null || v.isEmpty)
//                         ? 'Entrez votre mot de passe'
//                         : null,
//                   ),

//                   if (_error != null) ...[
//                     const SizedBox(height: 16),
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.red.withValues(alpha: 0.08),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         _error!,
//                         style: const TextStyle(color: Colors.red),
//                       ),
//                     ),
//                   ],

//                   const SizedBox(height: 24),
//                   SizedBox(
//                     height: 52,
//                     child: FilledButton(
//                       onPressed: _loading ? null : _submit,
//                       style: FilledButton.styleFrom(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                       ),
//                       child: _loading
//                           ? const SizedBox(
//                               height: 22,
//                               width: 22,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2.5,
//                                 color: Colors.white,
//                               ),
//                             )
//                           : const Text(
//                               'Se connecter',
//                               style: TextStyle(fontSize: 16),
//                             ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   InputDecoration _inputStyle(String label, IconData icon) {
//     return InputDecoration(
//       labelText: label,
//       prefixIcon: Icon(icon),
//       filled: true,
//       fillColor: Colors.white,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(16),
//         borderSide: BorderSide.none,
//       ),
//     );
//   }
// }
