/// Indicative score markers used ONLY to draw the zones/lines on the chart and the bars.
/// The level (Normal / Surveillance / Alerte) always comes from the backend.
///
/// Measured on the predictions table (model_version_id = 1):
///   alerte        : score from 0.0730 to 0.4714
///   surveillance  : score from 0.0281 to 0.0609
///   normal        : score from 0.0000 to 0.1159
/// The ranges overlap, so the backend does not decide the level from the score
/// alone. These values are the LOWEST score seen for each level: below them that
/// level never occurred. They are markers, not exact cut-offs.
///
/// TODO: once the backend rule that assigns `niveau` is found, document it here.
class RiskThresholds {
  static const double surveillance =
      0.028; // lowest score seen for Surveillance
  static const double alerte = 0.073; //       lowest score seen for Alerte

  static String pct(double v) {
    final p = v * 100;
    return p == p.roundToDouble()
        ? '${p.round()}%'
        : '${p.toStringAsFixed(1)}%';
  }
}
