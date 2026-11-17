class DemoPatient {
  final String code;
  final String bed;
  final int age;
  final String sex;
  final int risk;
  final String level;
  final double change;
  final String updated;
  final List<String> factors;

  const DemoPatient({
    required this.code,
    required this.bed,
    required this.age,
    required this.sex,
    required this.risk,
    required this.level,
    required this.change,
    required this.updated,
    required this.factors,
  });
}

// Données fictives pour la première présentation uniquement.
// Elles ne proviennent ni du modèle ML ni d'un dossier médical réel.
const demoPatients = <DemoPatient>[
  DemoPatient(code: 'CH-024', bed: '04', age: 67, sex: 'Homme', risk: 87,
    level: 'Élevé', change: 12, updated: 'Il y a 4 min',
    factors: ['Fréquence cardiaque élevée', 'Pression artérielle basse', 'Lactate à surveiller']),
  DemoPatient(code: 'CH-018', bed: '02', age: 59, sex: 'Femme', risk: 64,
    level: 'Modéré', change: 5, updated: 'Il y a 8 min',
    factors: ['Température élevée', 'Fréquence respiratoire élevée']),
  DemoPatient(code: 'CH-031', bed: '07', age: 72, sex: 'Homme', risk: 22,
    level: 'Stable', change: -3, updated: 'Il y a 12 min',
    factors: ['Paramètres globalement stables']),
  DemoPatient(code: 'CH-011', bed: '01', age: 48, sex: 'Femme', risk: 76,
    level: 'Élevé', change: 8, updated: 'Il y a 2 min',
    factors: ['Leucocytes élevés', 'Évolution récente à surveiller']),
  DemoPatient(code: 'CH-029', bed: '06', age: 63, sex: 'Homme', risk: 41,
    level: 'Modéré', change: -2, updated: 'Il y a 15 min',
    factors: ['Surveillance clinique recommandée']),
];

const demoAlertCount = 2;
const demoModerateCount = 2;
const demoStableCount = 1;
