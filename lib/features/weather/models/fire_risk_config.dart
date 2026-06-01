/// Configuration parametrable du risque incendie par sentier.
///
/// Conditions declenchant une alerte incendie :
/// - Mois dans la plage [riskMonthStart..riskMonthEnd]
/// - Temperature max >= temperatureThreshold
/// - Region du sentier match la liste des regions a risque
///
/// Les seuils sont parametrables par TrailConfig pour permettre
/// l'adaptation a differents sentiers sans recompilation.
class FireRiskConfig {
  const FireRiskConfig({
    this.riskMonthStart = 6,
    this.riskMonthEnd = 9,
    this.temperatureThreshold = 30.0,
    this.riskRegions = const ['Corse', 'PACA', 'Languedoc'],
    this.fireTipId = 'incendie-periode-risque',
  });

  /// Mois de debut de la periode a risque (1 = janvier, 12 = decembre)
  final int riskMonthStart;

  /// Mois de fin de la periode a risque (inclus)
  final int riskMonthEnd;

  /// Temperature max en degres C au-dessus de laquelle le risque est eleve
  final double temperatureThreshold;

  /// Regions geographiques a risque incendie
  final List<String> riskRegions;

  /// ID de la fiche conseil incendie a afficher (lien vers tips)
  final String fireTipId;

  /// Evalue si les conditions de risque incendie sont reunies.
  ///
  /// [month] : mois courant (1-12)
  /// [temperatureMax] : temperature max prevue en degres C
  /// [region] : region du sentier
  /// Retourne true si toutes les conditions sont reunies.
  bool isFireRiskActive({
    required int month,
    required double temperatureMax,
    required String region,
  }) {
    final inRiskPeriod = month >= riskMonthStart && month <= riskMonthEnd;
    final aboveThreshold = temperatureMax >= temperatureThreshold;
    final inRiskRegion = riskRegions.contains(region);
    return inRiskPeriod && aboveThreshold && inRiskRegion;
  }
}
