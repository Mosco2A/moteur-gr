/// LES PROVIDERS DU MARCHEUR SIMULE — sortis de `marcheur_simule.dart` par la
/// garde de taille ECR-15 a la tache 747, comme [pointSurLaTrace] l'avait ete
/// a la tache 744.
///
/// CE FICHIER RE-EXPORTE LE MOTEUR : les appelants importent celui-ci et
/// obtiennent le marcheur AVEC ses providers, exactement comme avant le
/// decoupage. Aucun import de l'application ne change de cible, et il n'y a
/// AUCUN cycle — le moteur ne connait pas ce fichier.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'marcheur_simule.dart';

export 'marcheur_simule.dart';

/// LE MARCHEUR SIMULE DE L'APPLICATION — un seul, comme le robinet GPS.
///
/// UN SEUL, ET C'EST LA MEME RAISON QUE POUR LE ROBINET (lot 671-00) : la
/// source de positions de l'interface est unique. Le marcheur est la source
/// pendant une demo ; deux marcheurs, ce seraient deux verites sur l'endroit
/// ou se trouve le randonneur.
///
/// IL N'EST PAS CREE PAR LA DEMO : il existe toujours, et il ne fait rien tant
/// que personne ne l'a fait [MarcheurSimule.demarrer]. C'est ce qui permet au
/// robinet de s'abonner a son flux une fois pour toutes, sans attendre qu'une
/// simulation commence.
final marcheurSimuleProvider = Provider<MarcheurSimule>((ref) {
  final marcheur = MarcheurSimule();
  ref.onDispose(marcheur.fermer);
  return marcheur;
});

/// Le flux des etats du marcheur, abonne pour reveiller les ecrans.
final _fluxDesEtatsProvider = StreamProvider<EtatDuMarcheur>(
  (ref) => ref.watch(marcheurSimuleProvider).etats,
);

/// OU EN EST LA MARCHE SIMULEE, lisible par les ecrans.
///
/// La VALEUR AUTORITAIRE reste celle du marcheur ([MarcheurSimule.etat]) ; le
/// flux ne sert qu'a faire recalculer ce provider au bon moment. Lire les deux
/// evite le piege du flux seul : un ecran qui s'abonne APRES un changement
/// aurait rate l'emission et affiche l'etat d'avant, alors que le champ, lui,
/// est toujours a jour.
final etatDuMarcheurSimuleProvider = Provider<EtatDuMarcheur>((ref) {
  ref.watch(_fluxDesEtatsProvider);
  return ref.watch(marcheurSimuleProvider).etat;
});
