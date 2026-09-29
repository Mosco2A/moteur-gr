import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';

/// Origine des données météo affichées.
///
/// ELLE N A PLUS QUE DEUX VALEURS DEPUIS LE LOT 625, et les deux retirées
/// n'étaient pas des sources. `api` (« Données en direct ») serait devenu un
/// mensonge : l'application n'appelle plus aucun fournisseur. `cache` et
/// `offline` décrivaient l'état du RÉSEAU, pas la provenance de la donnée — or la
/// donnée vient désormais toujours du même endroit, la base, où notre serveur l'a
/// déposée. La question utile au randonneur n'est plus « d'où ça vient » mais
/// « de quand ça date », et c'est la fraîcheur qui y répond.
enum WeatherSource {
  /// La météo fabriquée par notre serveur et recopiée en base.
  server,

  /// Un jeu de démonstration, jamais présenté comme une vraie prévision.
  demo,
}

/// Bandeau discret : d'où vient la météo, et QUAND ELLE A ÉTÉ FABRIQUÉE.
///
/// LA DATE AFFICHÉE EST CELLE DE FABRICATION PAR LE MODÈLE, pas celle du
/// téléchargement — demande explicite de Christophe le 28/09. Les deux peuvent
/// différer de plusieurs heures, et c'est cet écart qui trompait : un bulletin
/// téléchargé à l'instant peut avoir été fabriqué la veille.
class WeatherSourceBanner extends StatelessWidget {
  const WeatherSourceBanner({
    super.key,
    required this.source,
    required this.fraicheur,
  });

  final WeatherSource source;

  /// PHRASE D AGE DEJA REDIGEE, venue de `weatherFreshness`.
  ///
  /// LE BANDEAU NE FORMULE PLUS L AGE LUI-MEME, ET C EST LA CORRECTION DE FOND.
  /// Il le faisait avec `formatWeatherDate`, pendant que la liste du programme et
  /// l ecran incendie le faisaient avec `weatherFreshness` — trois endroits, trois
  /// formulations, et c est exactement le defaut que la tache 572 a deja eu a
  /// corriger une fois. Un seul endroit decide comment on dit l age d un bulletin.
  final String fraicheur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = Translations.of(context);
    final muted = theme.colorScheme.onSurface.withAlpha(140);

    final (IconData icon, String label) = switch (source) {
      WeatherSource.server => (Icons.cloud_done_outlined, t.weather.source.server),
      WeatherSource.demo => (Icons.science_outlined, t.weather.source.demo),
    };

    final parts = <String>[label, fraicheur];

    return Row(
      children: [
        Icon(icon, size: 14, color: muted),
        const SizedBox(width: AppTheme.spacingXs),
        Expanded(
          child: Text(
            parts.join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
