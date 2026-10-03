/// Les travaux que les features posent DEVANT l'amorcage, qui les execute sans
/// savoir qui les fournit (lot 645-05, cas K1).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Un travail d'amorcage : il rend la main, ou il leve.
typedef TacheDAmorcage = Future<void> Function();

/// LE SOCLE N'IMPORTE PLUS D'ECRAN — C'EST L'ECRAN QUI S'ANNONCE.
///
/// CE QUE C'ETAIT. `app_bootstrap_provider.dart`, dans `core/`, importait
/// `features/safety/presentation/health_info_screen.dart` pour y prendre
/// `healthInfoFileProvider` et appeler `garantirExclusion()`. Le socle
/// connaissait donc un ECRAN : la fleche la plus couteuse du depot, puisqu'elle
/// rend `core/` illisible et inextractible sans la couche presentation d'une
/// feature (cas K1 du lot 645-05, ECR-23 (a)).
///
/// CE QUE C'EST MAINTENANT. L'amorcage declare un BESOIN — « voila la liste des
/// travaux a faire avant le premier ecran » — et ne nomme aucun fournisseur.
/// Les features qui ont un travail d'amorcage le posent ici, et c'est
/// `main.dart` qui noue les deux : il est au-dessus des deux couches, donc le
/// seul endroit qui a le droit de connaitre l'une et l'autre.
///
/// POURQUOI LA LISTE EST VIDE PAR DEFAUT, ET QUE CE N'EST PAS UN OUBLI. Un
/// defaut vide rend l'amorcage testable sans monter aucune feature, et une
/// feature oubliee ne casse pas le demarrage : elle ne fait rien. Le cablage
/// reel est dans `main.dart`, surcharge de ce provider.
///
/// L'ORDRE EST CELUI DE LA LISTE, et il compte : l'amorcage les execute une par
/// une, en sequence, et attend chacune. Voir `app_bootstrap_provider.dart`,
/// dont l'en-tete explique pourquoi l'ordre des etapes d'amorcage n'est pas
/// indifferent.
final tachesDAmorcageProvider = Provider<List<TacheDAmorcage>>(
  (ref) => const <TacheDAmorcage>[],
);
