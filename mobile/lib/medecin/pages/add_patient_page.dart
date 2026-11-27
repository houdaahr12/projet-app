// lib/medecin/pages/add_patient_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/theme/colors.dart';

class _Measure {
  const _Measure(this.key, this.label, this.unit, this.min, this.max);
  final String key; // nom de la colonne en base
  final String label;
  final String unit;
  final double min;
  final double max;
}

const _vitals = <_Measure>[
  _Measure('hr', 'Fréquence cardiaque', 'bpm', 20, 250),
  _Measure('o2sat', 'SpO₂', '%', 50, 100),
  _Measure('temp', 'Température', '°C', 30, 43),
  _Measure('sbp', 'Pression systolique', 'mmHg', 40, 300),
  _Measure('map', 'Pression moyenne', 'mmHg', 20, 250),
  _Measure('dbp', 'Pression diastolique', 'mmHg', 20, 200),
  _Measure('resp', 'Fréquence respiratoire', '/min', 4, 60),
  _Measure('etco2', 'EtCO₂', 'mmHg', 5, 100),
];
const _mainLabs = <_Measure>[
  _Measure('lactate', 'Lactate', 'mg/dL', 0.1, 30),
  _Measure('wbc', 'Leucocytes', '10³/µL', 0.1, 100),
  _Measure('platelets', 'Plaquettes', '10³/µL', 1, 1500),
  _Measure('creatinine', 'Créatinine', 'mg/dL', 0.1, 30),
  _Measure('bilirubin_total', 'Bilirubine totale', 'mg/dL', 0.1, 60),
  _Measure('glucose', 'Glucose', 'mg/dL', 20, 800),
];
const _bloodGases = <_Measure>[
  _Measure('ph', 'pH', '', 6.8, 7.8),
  _Measure('paco2', 'PaCO₂', 'mmHg', 10, 150),
  _Measure('sao2', 'SaO₂', '%', 40, 100),
  _Measure('hco3', 'HCO₃', 'mmol/L', 5, 50),
  _Measure('baseexcess', 'Excès de base', 'mmol/L', -30, 30),
  _Measure('fio2', 'FiO₂', '% ou fraction', 0.2, 100),
];
const _otherLabs = <_Measure>[
  _Measure('bun', 'Urée (BUN)', 'mg/dL', 1, 200),
  _Measure('ast', 'AST', 'UI/L', 1, 10000),
  _Measure('alkalinephos', 'Phosphatases alcalines', 'UI/L', 5, 3000),
  _Measure('bilirubin_direct', 'Bilirubine directe', 'mg/dL', 0, 30),
  _Measure('calcium', 'Calcium', '', 0.5, 20),
  _Measure('chloride', 'Chlorure', 'mmol/L', 60, 140),
  _Measure('magnesium', 'Magnésium', '', 0.5, 10),
  _Measure('phosphate', 'Phosphate', 'mg/dL', 0.5, 15),
  _Measure('potassium', 'Potassium', 'mmol/L', 1.5, 9),
  _Measure('troponini', 'Troponine I', 'ng/mL', 0, 500),
  _Measure('hct', 'Hématocrite', '%', 10, 65),
  _Measure('hgb', 'Hémoglobine', 'g/dL', 3, 25),
  _Measure('ptt', 'TCA (PTT)', 's', 10, 250),
  _Measure('fibrinogen', 'Fibrinogène', 'mg/dL', 20, 1500),
];
double? _parse(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  static const _titles = ['Admission', 'Signes vitaux', 'Analyses'];

  final _formKeys = List.generate(3, (_) => GlobalKey<FormState>());
  final _age = TextEditingController();
  final _lit = TextEditingController();
  final _service = TextEditingController(text: 'Réanimation');
  final _heures = TextEditingController();
  final Map<String, TextEditingController> _measures = {
    for (final m in [..._vitals, ..._mainLabs, ..._bloodGases, ..._otherLabs])
      m.key: TextEditingController(),
  };

  int _step = 0;
  String? _sexe;
  String? _unite;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_age, _lit, _service, _heures, ..._measures.values]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validateStep() {
    final ok = _formKeys[_step].currentState!.validate();
    setState(() => _error = ok ? null : 'Vérifiez les champs signalés.');
    return ok;
  }

  void _next() {
    if (!_validateStep()) return;
    FocusScope.of(context).unfocus();
    setState(() => _step++);
  }

  void _back() => setState(() {
    _step--;
    _error = null;
  });

  Future<void> _save() async {
    // Les étapes précédentes ont déjà été validées avec "Suivant".
    if (_saving || !_validateStep()) return;
    setState(() => _saving = true);

    final mesures = <String, double>{};
    _measures.forEach((key, controller) {
      final value = _parse(controller.text);
      if (value != null) mesures[key] = value; // champ vide = non mesuré
    });

    String? error;
    Map<String, dynamic>? created;
    try {
      final token = await AuthService.getToken();
      final response = await http
          .post(
            Uri.parse('${AuthService.baseUrl}/patients'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'age': _parse(_age.text),
              'sexe': _sexe,
              'lit': _lit.text.trim(),
              'service': _service.text.trim(),
              'unite': _unite,
              'heures_avant_rea': _parse(_heures.text),
              'mesures': mesures,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201) {
        created = Map<String, dynamic>.from(body as Map);
      } else if (response.statusCode == 401) {
        error = 'Session expirée, reconnectez-vous';
      } else {
        final detail = body is Map ? body['detail'] : null;
        error = detail is String ? detail : 'Erreur ${response.statusCode}';
      }
    } catch (_) {
      // La requête a peut-être abouti : éviter un doublon.
      error = 'Pas de réponse du serveur. Vérifiez la liste des patients avant de réessayer.';
    }
    if (!mounted) return;

    if (created == null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }

    final noScore =
        created['mesures_enregistrees'] == true &&
        created['prediction_calculee'] != true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Patient ${created['code_patient']} ajouté'
          '${noScore ? ' (score non calculé)' : ''}',
        ),
      ),
    );
    Navigator.pop(context, true);
  }

  // ───────────────────────── Champs ─────────────────────────

  InputDecoration _decoration(String label, [String unit = '']) =>
      InputDecoration(
        labelText: label,
        suffixText: unit.isEmpty ? null : unit,
        isDense: true,
        errorMaxLines: 2,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SepsisColors.border),
        ),
      );

  Widget _text(
    TextEditingController controller,
    String label, {
    String unit = '',
    bool number = false,
    int? maxLength,
    String? Function(String)? check,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 13),
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      decoration: _decoration(label, unit).copyWith(counterText: ''),
      validator: check == null ? null : (v) => check((v ?? '').trim()),
    ),
  );

  Widget _measureField(_Measure m) => _text(
    _measures[m.key]!,
    m.label,
    unit: m.unit,
    number: true,
    check: (v) {
      if (v.isEmpty) return null; // facultatif
      final x = _parse(v);
      if (x == null) return 'Nombre invalide';
      var valid = x >= m.min && x <= m.max;
      if (m.key == 'fio2')
        valid = (x >= 0.2 && x <= 1) || (x >= 20 && x <= 100);
      if (m.key == 'calcium')
        valid = (x >= 0.5 && x <= 2.5) || (x >= 3 && x <= 20);
      return valid ? null : 'Valeur attendue entre ${m.min} et ${m.max}';
    },
  );

  Widget _group(String title, List<_Measure> list) => ExpansionTile(
    title: Text(title, style: const TextStyle(fontSize: 13)),
    maintainState: true,
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(top: 8),
    children: list.map(_measureField).toList(),
  );

  // ───────────────────────── Étapes ─────────────────────────

  List<Widget> _admission() => [
    _text(
      _age,
      'Âge *',
      unit: 'ans',
      number: true,
      check: (v) {
        final x = _parse(v);
        return x == null || x < 0 || x > 120 ? 'Âge entre 0 et 120' : null;
      },
    ),
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        decoration: _decoration('Sexe *'),
        items: const [
          DropdownMenuItem(value: 'F', child: Text('Femme')),
          DropdownMenuItem(value: 'M', child: Text('Homme')),
        ],
        onChanged: (v) => _sexe = v,
        validator: (v) => v == null ? 'Champ obligatoire' : null,
      ),
    ),
    _text(
      _lit,
      'Numéro de lit *',
      maxLength: 10,
      check: (v) => v.isEmpty ? 'Champ obligatoire' : null,
    ),
    _text(_service, 'Service', maxLength: 100),
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        decoration: _decoration('Type de réanimation'),
        items: const [
          DropdownMenuItem(value: 'medicale', child: Text('Médicale')),
          DropdownMenuItem(value: 'chirurgicale', child: Text('Chirurgicale')),
        ],
        onChanged: (v) => _unite = v,
      ),
    ),
    _text(
      _heures,
      'Temps à l’hôpital avant la réa',
      unit: 'heures',
      number: true,
      check: (v) {
        if (v.isEmpty) return null;
        final x = _parse(v);
        return x == null || x < 0 || x > 10000
            ? 'Nombre d’heures invalide'
            : null;
      },
    ),
  ];

  List<Widget> _stepFields(int step) => switch (step) {
    0 => _admission(),
    1 => _vitals.map(_measureField).toList(),
    _ => [
      ..._mainLabs.map(_measureField),
      _group('Gaz du sang', _bloodGases),
      _group('Autres analyses', _otherLabs),
    ],
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nouveau patient')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(
                    value: (_step + 1) / 3,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Étape ${_step + 1}/3 · ${_titles[_step]}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _step == 0
                        ? '* Champs obligatoires'
                        : 'Laissez vide ce qui n’a pas été mesuré.',
                    style: const TextStyle(
                      color: SepsisColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    // Offstage : les valeurs sont conservées d'une étape à l'autre.
                    for (var i = 0; i < 3; i++)
                      Offstage(
                        offstage: _step != i,
                        child: Form(
                          key: _formKeys[i],
                          child: Column(children: _stepFields(i)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: SepsisColors.high,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        if (_step > 0)
                          IconButton(
                            tooltip: 'Étape précédente',
                            onPressed: _saving ? null : _back,
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving ? null : _save,
                            child: Text(
                              _saving ? 'Enregistrement…' : 'Enregistrer',
                            ),
                          ),
                        ),
                        if (_step < 2) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: _saving ? null : _next,
                              child: const Text('Suivant'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
