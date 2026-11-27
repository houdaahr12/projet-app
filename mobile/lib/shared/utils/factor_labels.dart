const _names = {
  'HR': 'Fréquence cardiaque',
  'O2Sat': 'SpO₂',
  'Temp': 'Température',
  'SBP': 'Pression systolique',
  'MAP': 'Pression moyenne',
  'DBP': 'Pression diastolique',
  'Resp': 'Fréquence respiratoire',
  'EtCO2': 'CO₂ expiré',
  'FiO2': 'FiO₂',
  'Lactate': 'Lactate',
  'WBC': 'Globules blancs',
  'Creatinine': 'Créatinine',
  'Platelets': 'Plaquettes',
  'BUN': 'Urée',
  'Bilirubin_total': 'Bilirubine totale',
  'Glucose': 'Glycémie',
  'HCO3': 'Bicarbonates',
  'pH': 'pH',
  'PaCO2': 'PaCO₂',
  'ICULOS': 'Durée en réanimation',
  'sofa_like': 'Score SOFA estimé',
  'sofa_rise24': 'Hausse du score SOFA (24 h)',
  'sirs_count': 'Critères SIRS',
  'qsofa_like': 'Score qSOFA estimé',
  'shock_index': 'Index de choc',
};

class FactorLabel {
  final String text;
  final bool
  isTiming; // about how often/when it was measured, not the value itself
  const FactorLabel(this.text, this.isTiming);
}

FactorLabel describeFactor(String feature) {
  String name(String base) => _names[base] ?? base;

  const timing = {
    '_hours_since': 'Ancienneté de la dernière mesure de',
    '_count': 'Nombre de mesures de',
    '_obs': 'Mesure récente de',
  };
  for (final e in timing.entries) {
    if (feature.endsWith(e.key)) {
      final base = feature.substring(0, feature.length - e.key.length);
      return FactorLabel('${e.value} ${name(base)}', true);
    }
  }

  const stats = {
    '_mean6': 'moyenne 6 h',
    '_mean12': 'moyenne 12 h',
    '_mean24': 'moyenne 24 h',
    '_min6': 'minimum 6 h',
    '_max6': 'maximum 6 h',
    '_trend': 'tendance',
    '_max_since_admission': "maximum depuis l'admission",
    '_min_since_admission': "minimum depuis l'admission",
    '_change12': 'variation sur 12 h',
  };
  for (final e in stats.entries) {
    if (feature.endsWith(e.key)) {
      final base = feature.substring(0, feature.length - e.key.length);
      return FactorLabel('${name(base)} · ${e.value}', false);
    }
  }
  return FactorLabel(name(feature), false); // unknown names stay as they are
}
