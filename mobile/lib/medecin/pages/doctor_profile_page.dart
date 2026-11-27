import 'package:flutter/material.dart';

import 'package:mobile/shared/widgets/sepsis_ui.dart';
import 'package:mobile/core/brand.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/theme/colors.dart';
import 'package:mobile/medecin/widgets/sepsis_bottom_nav.dart';

class DoctorProfilePage extends StatefulWidget {
  const DoctorProfilePage({super.key});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  String _nom = '';
  String? _sexe;
  String? _identifiant;
  String? _role;
  bool _showPasswordForm = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      AuthService.getUserName(),
      AuthService.getUserSexe(),
      AuthService.getIdentifiant(),
      AuthService.getRole(),
    ]);
    if (!mounted) return;
    setState(() {
      _nom = values[0] ?? '';
      _sexe = values[1];
      _identifiant = values[2];
      _role = values[3];
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void _onPasswordChanged() {
    setState(() => _showPasswordForm = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mot de passe modifié avec succès')),
    );
  }

  // "ahmed ben-ali" -> "Ahmed Ben-Ali"
  String _capitalize(String text) => text.toLowerCase().replaceAllMapped(
    RegExp(r'(^|[\s-])(\p{L})', unicode: true),
    (m) => '${m[1]}${m[2]!.toUpperCase()}',
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const SepsisCareBottomNav(currentIndex: 3),
    appBar: AppBar(
      title: const Text(
        'Mon profil',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    // SingleChildScrollView : le formulaire reste monté quand on fait défiler
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: SepsisUI.gradient,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: Image.asset(
                      _sexe?.trim().toUpperCase() == 'F'
                          ? 'assets/images/avatar_femme.png'
                          : 'assets/images/avatar_homme.png',
                      width: 82,
                      height: 82,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _nom.isEmpty ? 'Nom non disponible' : _capitalize(_nom),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _role == 'admin' ? 'Administrateur' : 'Médecin',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          _item(
            Icons.badge_outlined,
            'Identifiant',
            _identifiant?.isNotEmpty == true ? _identifiant! : '—',
          ),
          _item(
            Icons.wc_rounded,
            'Sexe',
            _sexe == 'F'
                ? 'Femme'
                : _sexe == 'M'
                ? 'Homme'
                : '—',
          ),
          _item(
            Icons.info_outline_rounded,
            'À propos de SepsisCare',
            appSlogan,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () =>
                setState(() => _showPasswordForm = !_showPasswordForm),
            icon: Icon(
              _showPasswordForm
                  ? Icons.close_rounded
                  : Icons.lock_reset_rounded,
            ),
            label: Text(
              _showPasswordForm ? 'Annuler' : 'Changer le mot de passe',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: SepsisColors.teal,
              minimumSize: const Size.fromHeight(42),
            ),
          ),
          const SizedBox(height: 10),
          if (_showPasswordForm) ...[
            _ChangePasswordForm(onSuccess: _onPasswordChanged),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Se déconnecter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: SepsisColors.navy,
              minimumSize: const Size.fromHeight(42),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _item(IconData icon, String title, String value) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(14),
    decoration: SepsisUI.card(radius: 14),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: SepsisColors.blueLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: SepsisColors.teal, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: SepsisColors.muted, fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: SepsisColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Formulaire affiché directement dans la page profil.
class _ChangePasswordForm extends StatefulWidget {
  const _ChangePasswordForm({required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _ancien = TextEditingController();
  final _nouveau = TextEditingController();
  final _confirmation = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ancien.dispose();
    _nouveau.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await AuthService.changePassword(
      ancien: _ancien.text,
      nouveau: _nouveau.text,
    );
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      return;
    }
    widget.onSuccess();
  }

  String? _validateNew(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'Au moins 8 caractères';
    if (v.length > 72) return '72 caractères maximum';
    if (!RegExp(r'\p{L}', unicode: true).hasMatch(v) ||
        !RegExp(r'\d').hasMatch(v)) {
      return 'Ajoutez au moins une lettre et un chiffre';
    }
    if (v == _ancien.text) return 'Doit être différent de l\'ancien';
    return null;
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String? Function(String?) validator, {
    bool last = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextFormField(
      style: const TextStyle(fontSize: 13),
      controller: controller,
      validator: validator,
      enabled: !_loading,
      obscureText: _obscure,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: last ? (_) => _submit() : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 11),
        errorMaxLines: 2,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: SepsisColors.teal,
          size: 18,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 38,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SepsisColors.border),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: _card(),
    ),
  );

  Widget _card() => Container(
    padding: const EdgeInsets.all(12),
    decoration: SepsisUI.card(radius: 14),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Au moins 8 caractères, avec une lettre et un chiffre.',
            style: TextStyle(color: SepsisColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 10),
          _field(
            _ancien,
            'Mot de passe actuel',
            (v) => (v ?? '').isEmpty ? 'Champ obligatoire' : null,
          ),
          _field(_nouveau, 'Nouveau mot de passe', _validateNew),
          _field(
            _confirmation,
            'Confirmer le nouveau mot de passe',
            (v) => v != _nouveau.text
                ? 'Les mots de passe ne correspondent pas'
                : null,
            last: true,
          ),
          Material(
            type: MaterialType.transparency,
            child: CheckboxListTile(
              value: !_obscure,
              onChanged: (v) => setState(() => _obscure = !(v ?? false)),
              title: const Text(
                'Afficher les mots de passe',
                style: TextStyle(fontSize: 11),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              visualDensity: VisualDensity.compact,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          FilledButton(
            onPressed: _loading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: SepsisColors.teal,
              minimumSize: const Size.fromHeight(40),
            ),
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );
}
