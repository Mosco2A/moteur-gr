// ignore_for_file: avoid_print
//
// S13 — LE REFUS, L EFFACEMENT, ET LES MOTS (tache 559, passe finale).
//
// Ce fichier joue sur l emulateur les quatre choses qui n y avaient JAMAIS ete
// jouees, et dont trois viennent de defauts que cette campagne a trouves :
//
//   1. LE REFUS DU CONSENTEMENT ARTICLE 9. En premiere passe, la morphologie
//      etait enregistree MALGRE le refus : je relisais 72 / 172 / 88 apres
//      redemarrage. On rejoue le meme geste, a l identique, et on exige cette
//      fois que rien ne parte, que l ecran RESTE avec une raison lisible, que
//      la saisie ne soit pas perdue, et qu un second tap apres avoir coche
//      enregistre normalement. Puis on REVOQUE depuis les Reglages et on exige
//      que ce qui etait deja la SOIT EFFACE — pas seulement que l appli cesse
//      d ecrire.
//   2. L EFFACEMENT DE MES DONNEES, qui n existait pas. Bouton inerte tant que
//      la case n est pas cochee, dialogue qui dit ce qui part / ce qui reste /
//      que c est definitif, puis effacement REEL : on redemarre et ON COMPTE
//      ce qui reste, ecran par ecran.
//   3. LE VOCABULAIRE PROSCRIT, dans les cinq langues, pendant la saisie.
//   4. LE PLURIEL de l itineraire.
//
// CE FICHIER NE MODIFIE AUCUN CODE APPLICATIF : il pilote l UI reelle.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'S13_RGPD';
const String kTrailId = 'mare-a-mare-centre';

/// Les mots qu un randonneur ne doit JAMAIS lire sur sa propre morphologie
/// (regle #7-d de Chris), dans les cinq langues livrees.
const Map<String, List<String>> kMotsProscrits = <String, List<String>>{
  'Français': ['Surpoids', 'surpoids', 'Corpulence', 'corpulence', 'Maigreur'],
  'English': ['Overweight', 'overweight', 'Obese', 'Underweight'],
  'Deutsch': ['Übergewicht', 'Untergewicht', 'Fettleibig'],
  'Italiano': ['Sovrappeso', 'sovrappeso', 'Sottopeso'],
  'Español': ['Sobrepeso', 'sobrepeso', 'Bajo peso'],
};

void main() {
  initHarness();

  testWidgets('S13 — le refus du consentement, l effacement, et les mots',
      (tester) async {
    reinitialiserExigences();
    final poigneeSemantique = tester.ensureSemantics();

    logStep(P, 'boot', 'Lancement de app.main() sur la branche d integration');
    installerVeilleEcranSysteme(P);
    app.main();
    await settleAndShoot(tester, P, '01_boot',
        timeout: const Duration(seconds: 15));
    await completeOnboardingIfPresent(tester, P);

    // =====================================================================
    // 1 — LE REFUS DU CONSENTEMENT ARTICLE 9, REJOUE A L IDENTIQUE
    // =====================================================================
    await _aller(tester, '/trail/$kTrailId/hiker-profile');
    await settleAndShoot(tester, P, '02_fiche_vierge');
    await _saisirMorpho(tester, age: '72', taille: '172', poids: '88');
    final refuse = _consentementRefuse(tester);
    logStep(P, 'art9',
        'Consentement morphologie LAISSE A REFUSE = $refuse — c est le geste '
        'exact de la premiere passe');
    exige(P, 'art9', refuse,
        'le consentement morphologie est bien laisse REFUSE avant d enregistrer');

    // ETAT DU STOCKAGE AVANT LE REFUS : sans lui, on ne peut pas dire ce que
    // le refus AJOUTE. Le correctif ferme la cle que j avais mesuree ; rien ne
    // garantit qu aucune autre ecriture n a lieu. On compare, on ne suppose pas.
    await sonderLeStockage(P, 'avant-refus-art9');
    await tapIfPresent(tester, find.text(t.hikerProfile.save), P, 'art9',
        'toucher Enregistrer SANS avoir consenti', warnIfMissing: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 4));
    await settleAndShoot(tester, P, '03_refus_consentement');
    logEcran(P, 'art9', max: 40);

    final surLaFiche = present(find.text(t.hikerProfile.title));
    final raison = texteContenant('Sans votre accord');
    logStep(P, 'art9',
        'APRES le tap : toujours sur la fiche = $surLaFiche ; raison lue = '
        '"${raison ?? "(aucune)"}"');
    exige(P, 'art9', surLaFiche,
        'l ecran RESTE OUVERT quand le consentement est refuse — il ne se '
        'referme pas comme un enregistrement reussi');
    exige(P, 'art9', raison != null,
        'le refus est EXPLIQUE a l ecran (lu : "${raison ?? "(aucune)"}")');

    // LA SAISIE NE DOIT PAS ETRE PERDUE : c est ce qui separe un refus poli
    // d une punition.
    final ageEncoreLa = _valeurDuChamp(tester, 'Âge');
    final tailleEncoreLa = _valeurDuChamp(tester, 'Taille');
    final poidsEncoreLa = _valeurDuChamp(tester, 'Poids');
    logStep(P, 'art9',
        'SAISIE APRES LE REFUS : age="$ageEncoreLa" taille="$tailleEncoreLa" '
        'poids="$poidsEncoreLa"');
    exige(P, 'art9',
        ageEncoreLa == '72' && tailleEncoreLa == '172' && poidsEncoreLa == '88',
        'la saisie en cours n est PAS perdue par le refus (relu : '
        '$ageEncoreLa / $tailleEncoreLa / $poidsEncoreLa)');

    // RIEN NE DOIT AVOIR ETE ECRIT : on redemarre et on relit.
    await redemarrageAChaud(tester, P, app.main);
    await _aller(tester, '/trail/$kTrailId/hiker-profile');
    await settleAndShoot(tester, P, '04_apres_redemarrage_refus');
    final ageApresRefus = _valeurDuChamp(tester, 'Âge');
    final tailleApresRefus = _valeurDuChamp(tester, 'Taille');
    final poidsApresRefus = _valeurDuChamp(tester, 'Poids');
    logStep(P, 'art9',
        'APRES REDEMARRAGE (consentement refuse) : age="$ageApresRefus" '
        'taille="$tailleApresRefus" poids="$poidsApresRefus" — en premiere '
        'passe je relisais 72 / 172 / 88');
    exige(P, 'art9',
        ageApresRefus != null && tailleApresRefus != null &&
            poidsApresRefus != null,
        'les trois champs sont REELLEMENT lus apres le redemarrage');
    exige(P, 'art9',
        (ageApresRefus ?? 'x').isEmpty &&
            (tailleApresRefus ?? 'x').isEmpty &&
            (poidsApresRefus ?? 'x').isEmpty,
        'RIEN N A ETE ENREGISTRE malgre le tap sur Enregistrer : la '
        'morphologie refusee ne survit pas au redemarrage (relu : '
        '"$ageApresRefus" / "$tailleApresRefus" / "$poidsApresRefus")');

    // LE STOCKAGE DOIT LE CONFIRMER, PAS SEULEMENT L ECRAN.
    await sonderLeStockage(P, 'apres-refus-art9');

    // LE SECOND TAP, APRES AVOIR COCHE, DOIT ENREGISTRER NORMALEMENT.
    await _saisirMorpho(tester, age: '72', taille: '172', poids: '88');
    await _accepterConsentement(tester);
    // ON LIT LA BASCULE, ON NE SUPPOSE PAS QU ELLE EST COCHEE. Sans cette
    // lecture, « l appli refuse encore » et « mon tap n a pas porte » se
    // ressemblent — et l un accuse le produit quand l autre accuse le test.
    final bascules = find.byType(SwitchListTile);
    final valeurBascule = bascules.evaluate().isEmpty
        ? null
        : tester.widget<SwitchListTile>(bascules.first).value;
    logStep(P, 'art9',
        'ETAT REEL DE LA BASCULE avant d enregistrer = $valeurBascule '
        '(${bascules.evaluate().length} bascule(s) sur l ecran)');
    exige(P, 'art9', valeurBascule == true,
        'la bascule de consentement est REELLEMENT cochee avant le second '
        'enregistrement (lue : $valeurBascule)');
    await tapIfPresent(tester, find.text(t.hikerProfile.save), P, 'art9',
        'enregistrer APRES avoir coche la bascule', warnIfMissing: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    await settleAndShoot(tester, P, '05_consentement_donne');
    // CE QUE L ECRAN FAIT APRES LE TAP EST LE SIGNAL DECISIF, et sans lui on
    // ne sait pas distinguer « l appli refuse encore » de « mon tap n a pas
    // coche la bascule ». Un enregistrement REUSSI referme la fiche ; un refus
    // la garde ouverte avec sa raison.
    final resteOuverte = present(find.text(t.hikerProfile.title));
    final raisonEncore = texteContenant('Sans votre accord');
    logStep(P, 'art9',
        'APRES LE TAP AVEC CONSENTEMENT : fiche encore ouverte = $resteOuverte ; '
        'raison de refus encore lue = "${raisonEncore ?? "(aucune)"}"');
    exige(P, 'art9', raisonEncore == null,
        'avec le consentement coche, l appli ne rend PLUS le refus '
        '(lu : "${raisonEncore ?? "(aucune)"}")');
    await redemarrageAChaud(tester, P, app.main);
    await _aller(tester, '/trail/$kTrailId/hiker-profile');
    await settleAndShoot(tester, P, '06_profil_apres_accord');
    final ageAccord = _valeurDuChamp(tester, 'Âge');
    logStep(P, 'art9',
        'APRES ACCORD ET REDEMARRAGE : age relu = "$ageAccord"');
    exige(P, 'art9', ageAccord == '72',
        'une fois la bascule cochee, l enregistrement fonctionne NORMALEMENT '
        '(age relu apres redemarrage = "$ageAccord")');

    // =====================================================================
    // 1bis — LA REVOCATION DEPUIS LES REGLAGES DOIT EFFACER
    // =====================================================================
    await _aller(tester, '/consent');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    await settleAndShoot(tester, P, '07_ecran_consentements');
    logEcran(P, 'revocation', max: 40);
    await sonderLeStockage(P, 'avant-revocation');
    // CARTOGRAPHIE DE L ECRAN, AVANT DE TOUCHER QUOI QUE CE SOIT. Trois passes
    // de suite, mon geste de retrait a ACCORDE au lieu de retirer. Deux causes
    // possibles, et elles s excluent : soit l ecran n affiche pas l etat reel,
    // soit MA visee tombe sur la mauvaise finalite. On releve donc, pour
    // CHAQUE finalite, son titre et l etat de la bascule que je lui associe —
    // et on comparera au stockage, qui ne ment pas.
    _cartographierLesConsentements(tester);
    final avantBascule = _etatConsentementSante(tester);
    final revoque = await _basculerConsentementSante(tester);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    await settleAndShoot(tester, P, '08_consentement_revoque');
    final apresBascule = _etatConsentementSante(tester);
    logStep(P, 'revocation',
        'BASCULE « ${t.consent.purposes.healthData} » LUE : avant '
        '$avantBascule, apres $apresBascule');
    exige(P, 'revocation', revoque,
        'le consentement « ${t.consent.purposes.healthData} » se retire depuis '
        'les Reglages');
    // ON LIT LA BASCULE, ON NE SUPPOSE PAS. Sans cela, « l appli n efface pas »
    // et « mon tap n a pas porte » se ressemblent — et l un accuse le produit
    // quand l autre accuse le test.
    exige(P, 'revocation', avantBascule == true,
        'le consentement accorde depuis la fiche est VU comme accorde sur '
        'l ecran Confidentialite (lu : $avantBascule) — c est ce qui manquait '
        'aux passes precedentes et rendait le retrait injouable');
    exige(P, 'revocation', apresBascule == false,
        'la bascule est REELLEMENT retiree apres le tap (lue : $apresBascule)');

    await _aller(tester, '/trail/$kTrailId/hiker-profile');
    await settleAndShoot(tester, P, '09_profil_apres_revocation');
    final ageApresRevoc = _valeurDuChamp(tester, 'Âge');
    final tailleApresRevoc = _valeurDuChamp(tester, 'Taille');
    final poidsApresRevoc = _valeurDuChamp(tester, 'Poids');
    logStep(P, 'revocation',
        'APRES REVOCATION : age="$ageApresRevoc" taille="$tailleApresRevoc" '
        'poids="$poidsApresRevoc"');
    exige(P, 'revocation',
        (ageApresRevoc ?? '').isEmpty &&
            (tailleApresRevoc ?? '').isEmpty &&
            (poidsApresRevoc ?? '').isEmpty,
        'retirer le consentement EFFACE ce qui etait deja la — l appli ne se '
        'contente pas de cesser d ecrire (relu : "$ageApresRevoc" / '
        '"$tailleApresRevoc" / "$poidsApresRevoc")');

    await sonderLeStockage(P, 'apres-revocation');

    // =====================================================================
    // 1ter — LE CAS VOISIN : UNE FICHE QUI PORTE AUSSI LE PAYS
    // =====================================================================
    // Le pays n est PAS une donnee de sante : il n a aucune raison de partir
    // avec la morphologie. Ici la cle du profil doit donc SURVIVRE au refus —
    // amputee de l age, de la taille et du poids, mais avec son pays intact.
    // C est la contre-partie du cas precedent : exiger la disparition de la
    // cle PARTOUT effacerait une donnee que l utilisateur n a jamais refusee.
    await _aller(tester, '/trail/$kTrailId/hiker-profile');
    await _saisirMorpho(tester, age: '44', taille: '168', poids: '70');
    final paysPose = await _choisirPays(tester, 'France');
    logStep(P, 'pays', 'Pays choisi sur la fiche = $paysPose');
    await _accepterConsentement(tester);
    await tapIfPresent(tester, find.text(t.hikerProfile.save), P, 'pays',
        'enregistrer la fiche avec le pays', warnIfMissing: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 5));
    await sonderLeStockage(P, 'avant-refus-avec-pays');

    await _aller(tester, '/trail/$kTrailId/hiker-profile');
    await _retirerConsentement(tester);
    await tapIfPresent(tester, find.text(t.hikerProfile.save), P, 'pays',
        'enregistrer apres avoir RETIRE l accord, fiche avec pays',
        warnIfMissing: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 5));
    await settleAndShoot(tester, P, '09b_refus_avec_pays');
    await sonderLeStockage(P, 'apres-refus-avec-pays');

    // =====================================================================
    // 2 — LE VOCABULAIRE PROSCRIT, DANS LES CINQ LANGUES, PENDANT LA SAISIE
    // =====================================================================
    // On saisit une morphologie qui, en premiere passe, faisait apparaitre
    // « IMC 29.7 / Surpoids » : 172 cm pour 88 kg.
    for (final entree in kMotsProscrits.entries) {
      final langue = entree.key;
      final mots = entree.value;
      await _choisirLangue(tester, langue);
      await _aller(tester, '/trail/$kTrailId/hiker-profile');
      await _saisirMorphoParIndex(tester, ['72', '172', '88']);
      await settleAndShoot(tester, P, '10_vocabulaire_$langue');
      logEcran(P, 'vocabulaire_$langue', max: 30);
      final trouves = <String>[];
      for (final mot in mots) {
        if (find.textContaining(mot, findRichText: true).evaluate().isNotEmpty) {
          trouves.add(mot);
        }
      }
      logStep(P, 'vocabulaire',
          'EN $langue, morphologie 172 cm / 88 kg saisie — mots proscrits lus '
          'a l ecran : ${trouves.isEmpty ? "aucun" : trouves.join(", ")}');
      exige(P, 'vocabulaire', trouves.isEmpty,
          'aucun jugement sur le corps en $langue pendant la saisie '
          '(lus : ${trouves.join(", ")})');
    }
    await _choisirLangue(tester, 'Français');

    // =====================================================================
    // 3 — LE PLURIEL DE L ITINERAIRE
    // =====================================================================
    await _aller(tester, '/trail/$kTrailId/itinerary');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    await settleAndShoot(tester, P, '11_itineraire');
    logEcran(P, 'pluriel', max: 40);
    final pluriel = texteContenant('1 étapes');
    logStep(P, 'pluriel',
        'ACCORD LU SUR L ITINERAIRE — « 1 étapes » present = '
        '"${pluriel ?? "(aucun)"}"');
    exige(P, 'pluriel', pluriel == null,
        'l itineraire accorde le pluriel : jamais « 1 étapes » '
        '(lu : "${pluriel ?? "(aucun)"}")');
    exigeAucuneAbsurdite(P, 'pluriel');

    // =====================================================================
    // 4 — L EFFACEMENT DE MES DONNEES
    // =====================================================================
    // On repose d abord des donnees a effacer, pour que la mesure ait un sens.
    await _aller(tester, '/consent');
    await _basculerConsentementSante(tester);
    await pumpAndSettleTolerant(tester);
    await _aller(tester, '/trail/$kTrailId/hiker-profile');
    await _saisirMorpho(tester, age: '72', taille: '172', poids: '88');
    await _accepterConsentement(tester);
    await tapIfPresent(tester, find.text(t.hikerProfile.save), P, 'effacement',
        'enregistrer la fiche avant effacement', warnIfMissing: false);
    await pumpAndSettleTolerant(tester);
    await _ajouterUneRandoPassee(tester);
    // Un reglage d affichage, qui doit SURVIVRE a l effacement.
    await _aller(tester, '/settings');
    await tapIfPresent(tester, find.text(t.settings.light), P, 'effacement',
        'passer en theme clair (doit survivre a l effacement)',
        warnIfMissing: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 4));
    final themeAvant = luminositeAlEcran(tester);
    await settleAndShoot(tester, P, '12_avant_effacement');
    logStep(P, 'effacement',
        'ETAT AVANT EFFACEMENT : morphologie posee, une rando passee, theme '
        'lu = ${themeAvant?.name}');

    // L entree doit etre la, dans une section qui se nomme.
    await scrollUntil(tester, find.text(t.erasure.entry), P, 'effacement',
        'entree « ${t.erasure.entry} »');
    exige(P, 'effacement', present(find.text(t.erasure.section)),
        'les Reglages portent une section « ${t.erasure.section} »');
    await exigeTap(tester, find.text(t.erasure.entry), P, 'effacement',
        'ouvrir « ${t.erasure.entry} »');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 4));
    await settleAndShoot(tester, P, '13_dialogue_effacement');
    logEcran(P, 'effacement', max: 40);

    // LE DIALOGUE DOIT DIRE TROIS CHOSES.
    exige(P, 'effacement', present(find.text(t.erasure.goesTitle)),
        'le dialogue dit CE QUI PART (« ${t.erasure.goesTitle} »)');
    exige(P, 'effacement', present(find.text(t.erasure.staysTitle)),
        'le dialogue dit CE QUI RESTE (« ${t.erasure.staysTitle} »)');
    final achatsPreserves = texteContenant('achats');
    exige(P, 'effacement', achatsPreserves != null,
        'le dialogue dit explicitement que les ACHATS survivent (lu : '
        '"${achatsPreserves ?? "(rien)"}")');
    exige(P, 'effacement', present(find.text(t.erasure.finalWarning)),
        'le dialogue dit que c est DEFINITIF (« ${t.erasure.finalWarning} »)');

    // LE BOUTON ROUGE DOIT ETRE INERTE TANT QUE LA CASE N EST PAS COCHEE.
    await tapIfPresent(tester, find.text(t.erasure.confirm), P, 'effacement',
        'toucher « ${t.erasure.confirm} » SANS avoir coche',
        warnIfMissing: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 3));
    final dialogueTientBon = present(find.text(t.erasure.dialogTitle));
    logStep(P, 'effacement',
        'Tap sur le bouton rouge SANS cocher — dialogue toujours ouvert = '
        '$dialogueTientBon');
    exige(P, 'effacement', dialogueTientBon,
        'le bouton « ${t.erasure.confirm} » est INERTE tant que la case n est '
        'pas cochee : rien ne part par un tap distrait');

    // On coche, puis on efface pour de vrai.
    await exigeTap(tester, find.text(t.erasure.confirmCheckbox), P,
        'effacement', 'cocher « ${t.erasure.confirmCheckbox} »');
    await pumpAndSettleTolerant(tester);
    await exigeTap(tester, find.text(t.erasure.confirm), P, 'effacement',
        'effacer definitivement');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 10));
    await settleAndShoot(tester, P, '14_apres_effacement');
    logEcran(P, 'effacement_apres', max: 40);
    final confirmation = texteContenant('effacées');
    logStep(P, 'effacement',
        'CONFIRMATION LUE APRES EFFACEMENT = "${confirmation ?? "(aucune)"}"');
    exige(P, 'effacement', confirmation != null,
        'l appli CONFIRME l effacement a l ecran (lu : '
        '"${confirmation ?? "(aucune)"}")');
    exige(P, 'effacement', !present(find.text(t.erasure.error)),
        'l effacement ne rend PAS le message d echec');

    // ON REDEMARRE ET ON COMPTE CE QUI RESTE.
    await redemarrageAChaud(tester, P, app.main);
    await settleAndShoot(tester, P, '15_apres_redemarrage_efface');
    logEcran(P, 'apres_effacement', max: 30);
    // LA MESURE LA PLUS DURE : ce que l appareil GARDE apres un effacement
    // qui se dit complet. L ecran a deja repondu ; le stockage n avait jamais
    // ete lu.
    await sonderLeStockage(P, 'apres-effacement');
    // L EFFACEMENT REND L APPLI A SON PREMIER LANCEMENT — c est la preuve la
    // plus forte qu il a porte, et c est aussi un piege de mesure : tant que
    // l onboarding n est pas repasse, sa garde ramene TOUTES les routes vers
    // lui, et on croit lire une fiche alors qu on lit un ecran d accueil.
    final revenuAuDebut = present(textFrEn('Passer', 'Skip')) ||
        texteContenant('Bienvenue') != null;
    logStep(P, 'reste',
        'APRES EFFACEMENT, l appli est revenue a son premier lancement '
        '(onboarding a l ecran) = $revenuAuDebut');
    exige(P, 'reste', revenuAuDebut,
        'l effacement rend l appli a son etat de premiere installation : '
        'l onboarding se represente');
    await completeOnboardingIfPresent(tester, P);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));

    await _aller(tester, '/trail/$kTrailId/hiker-profile');
    await settleAndShoot(tester, P, '16_fiche_apres_effacement');
    final ageReste = _valeurDuChamp(tester, 'Âge');
    final tailleReste = _valeurDuChamp(tester, 'Taille');
    final poidsReste = _valeurDuChamp(tester, 'Poids');
    logStep(P, 'reste',
        'APRES EFFACEMENT + REDEMARRAGE — fiche : age="$ageReste" '
        'taille="$tailleReste" poids="$poidsReste"');
    // LECTURE STRICTE, ET ELLE COMPTE : un champ INTROUVABLE rend `null`, et
    // « null est vide » serait une exigence qui se tient toute seule. On exige
    // donc que les trois champs soient TROUVES **et** vides — sinon on ne
    // prouve rien, on constate seulement qu on n a pas su regarder.
    final champsLus = ageReste != null && tailleReste != null &&
        poidsReste != null;
    exige(P, 'reste', champsLus,
        'les trois champs de la fiche sont REELLEMENT lus apres effacement '
        '(sinon la mesure ne vaut rien)');
    exige(P, 'reste',
        champsLus && ageReste.isEmpty && tailleReste.isEmpty &&
            poidsReste.isEmpty,
        'la fiche randonneur a REELLEMENT disparu (relu : "$ageReste" / '
        '"$tailleReste" / "$poidsReste")');

    await _aller(tester, '/trail/$kTrailId/past-hikes');
    await settleAndShoot(tester, P, '17_randos_apres_effacement');
    logEcran(P, 'randos_apres_effacement', max: 40);
    final randosVides = present(find.text(t.pastHikes.empty));
    logStep(P, 'reste',
        'APRES EFFACEMENT — la liste des randos se declare vide = $randosVides');
    exige(P, 'reste', randosVides,
        'les randonnees passees ont REELLEMENT disparu');

    await _aller(tester, '/trail/$kTrailId/feasibility');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    await settleAndShoot(tester, P, '18_faisabilite_apres_effacement');
    final verdictReste = _verdictLu();
    logStep(P, 'reste',
        'APRES EFFACEMENT — verdict de faisabilite lu = '
        '"${verdictReste ?? "(aucun)"}"');
    exige(P, 'reste', verdictReste == null,
        'plus aucun verdict n est rendu apres effacement : le moteur n a plus '
        'de quoi juger (lu : "${verdictReste ?? "(aucun)"}")');

    // CE QUI DOIT RESTER : les reglages d affichage, que le dialogue promet.
    final themeApres = luminositeAlEcran(tester);
    logStep(P, 'reste',
        'THEME APRES EFFACEMENT = ${themeApres?.name} (avant : '
        '${themeAvant?.name}) — le dialogue promet que les reglages restent');
    exige(P, 'reste', themeApres == themeAvant,
        'le reglage d affichage SURVIT a l effacement, comme le dialogue le '
        'promet (avant ${themeAvant?.name}, apres ${themeApres?.name})');

    poigneeSemantique.dispose();
    retirerVeilleEcranSysteme();
    verdictPersona(P, minimumExigences: 25);
    await finalizeScenario(tester, P);
    await flushJournal(P);
  });
}

// ===========================================================================
// OUTILS DU SCENARIO
// ===========================================================================

Future<void> _aller(WidgetTester tester, String route) async {
  final ctx = tester.element(find.byType(Navigator).first);
  GoRouter.of(ctx).go(route);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
  await dismissAdsConsentIfPresent(tester, P);
}

String? _verdictLu() {
  final v = t.feasibility.formula.verdicts;
  for (final texte in textesAlEcran()) {
    if (texte == v.green || texte == v.orange || texte == v.red) return texte;
  }
  return null;
}

String? _valeurDuChamp(WidgetTester tester, String libelle) {
  final champ = find.widgetWithText(TextFormField, libelle);
  if (champ.evaluate().isEmpty) return null;
  final edits = find.descendant(
    of: champ.first,
    matching: find.byType(EditableText),
  );
  if (edits.evaluate().isEmpty) return null;
  return tester.widget<EditableText>(edits.first).controller.text;
}

Future<void> _saisirMorpho(
  WidgetTester tester, {
  required String age,
  required String taille,
  required String poids,
}) async {
  final valeurs = <String, String>{
    'Âge': age,
    'Taille': taille,
    'Poids': poids,
  };
  for (final e in valeurs.entries) {
    final champ = find.widgetWithText(TextFormField, e.key);
    if (champ.evaluate().isEmpty) {
      logStep(P, 'saisie', 'COINCE : champ « ${e.key} » introuvable');
      continue;
    }
    await tester.enterText(champ.first, e.value);
    await pumpAndSettleTolerant(tester);
  }
  logStep(P, 'saisie', 'Morphologie saisie : $age ans, $taille cm, $poids kg');
}

/// Saisie PAR INDEX : en allemand, en italien... les libelles changent, et
/// viser « Âge » ne marche plus. Les trois premiers champs de la fiche sont,
/// dans l ordre, age, taille et poids.
Future<void> _saisirMorphoParIndex(
    WidgetTester tester, List<String> valeurs) async {
  final champs = find.byType(TextFormField);
  final n = champs.evaluate().length;
  for (var i = 0; i < n && i < valeurs.length; i++) {
    await tester.enterText(champs.at(i), valeurs[i]);
    await pumpAndSettleTolerant(tester);
  }
  logStep(P, 'saisie',
      'Morphologie saisie par index ($n champs) : ${valeurs.join(" / ")}');
}

bool _consentementRefuse(WidgetTester tester) {
  final consent = find.byType(SwitchListTile);
  if (consent.evaluate().isEmpty) return false;
  return tester.widget<SwitchListTile>(consent.first).value != true;
}

/// Coche la bascule de consentement morphologie, et VERIFIE qu elle a bascule.
///
/// LE PIEGE, MESURE LE 25/09. L ancienne version tapait la bascule sans la
/// rendre visible et sans relire son etat. Apres un refus, le message
/// d explication s insere dans la page et POUSSE la bascule hors de la zone
/// atteignable : le tap partait dans le vide, en silence, et le scenario
/// concluait que l application refusait un consentement pourtant donne. On
/// passe donc par `tapIfPresent` (qui rend visible puis verifie le hit-test)
/// et on RELIT la bascule ; un second essai est tente si elle n a pas bouge.
Future<bool> _accepterConsentement(WidgetTester tester) async {
  for (var essai = 0; essai < 2; essai++) {
    final consent = find.byType(SwitchListTile);
    if (consent.evaluate().isEmpty) {
      logStep(P, 'consentement', 'COINCE : aucune bascule de consentement');
      return false;
    }
    if (tester.widget<SwitchListTile>(consent.first).value == true) return true;
    await tapIfPresent(tester, consent.first, P, 'consentement',
        'cocher la bascule de consentement morphologie (essai ${essai + 1})',
        warnIfMissing: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 3));
  }
  final apres = find.byType(SwitchListTile);
  final valeur = apres.evaluate().isEmpty
      ? null
      : tester.widget<SwitchListTile>(apres.first).value;
  logStep(P, 'consentement',
      'Etat de la bascule apres deux essais = $valeur');
  return valeur == true;
}


/// La bascule « donnees de sante » de l ecran Confidentialite, visee par LA
/// CLE QUE LE PRODUIT LUI DONNE.
///
/// POURQUOI CE CHANGEMENT, ET IL EXPLIQUE TROIS PASSES D ECHECS. Je visais
/// jusqu ici « la bascule la plus proche verticalement du titre ». La
/// cartographie de l ecran a montre que cette heuristique tombe juste pour les
/// trois premieres finalites (ecart 47 a 62 px) et FAUX pour la quatrieme :
/// « Donnees de sante » se voyait attribuer la bascule de « Signalement
/// public », a 160 px — sa carte est plus haute, car elle porte un badge et un
/// avertissement. Je lisais donc l etat d une autre finalite, et mon geste de
/// retrait ACCORDAIT le signalement public. La sonde l avait montre sans que
/// j en comprenne la cause ; la cartographie l a nommee. Le produit, lui,
/// posait depuis le debut une cle sur chaque bascule.
Finder _basculeSante() =>
    find.byKey(const ValueKey('consent-toggle-healthData'));

bool? _etatConsentementSante(WidgetTester tester) {
  final f = _basculeSante();
  if (f.evaluate().isEmpty) return null;
  return tester.widget<SwitchListTile>(f.first).value;
}

/// Bascule la finalite « donnees de sante », et verifie qu elle a bouge.
Future<bool> _basculerConsentementSante(WidgetTester tester) async {
  final avant = _etatConsentementSante(tester);
  if (avant == null) {
    await scrollUntil(tester, _basculeSante(), P, 'revocation',
        'bascule « ${t.consent.purposes.healthData} »');
  }
  if (_basculeSante().evaluate().isEmpty) {
    logStep(P, 'revocation',
        'COINCE : bascule « ${t.consent.purposes.healthData} » introuvable');
    return false;
  }
  final depart = _etatConsentementSante(tester);
  for (var essai = 0; essai < 2; essai++) {
    await tapIfPresent(tester, _basculeSante(), P, 'revocation',
        'basculer « ${t.consent.purposes.healthData} » (essai ${essai + 1})',
        warnIfMissing: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 4));
    if (_etatConsentementSante(tester) != depart) return true;
  }
  logStep(P, 'revocation',
      'La bascule n a pas bouge : lue $depart avant et apres deux essais');
  return false;
}

/// Releve, pour chaque finalite affichee, l etat de SA bascule (par sa cle).
void _cartographierLesConsentements(WidgetTester tester) {
  const noms = <String, String>{
    'locationNavigation': 'Navigation personnelle',
    'socialSharing': 'Partage social',
    'publicReporting': 'Signalement public',
    'healthData': 'Donnees de sante',
  };
  final lignes = <String>[];
  for (final entree in noms.entries) {
    final f = find.byKey(ValueKey('consent-toggle-${entree.key}'));
    if (f.evaluate().isEmpty) {
      lignes.add('${entree.value} : bascule ABSENTE de l arbre');
      continue;
    }
    lignes.add('${entree.value} = '
        '${tester.widget<SwitchListTile>(f.first).value}');
  }
  logStep(P, 'revocation',
      'ETAT DES CONSENTEMENTS LU PAR LEUR CLE : ${lignes.join(" | ")}');
}

/// Choisit un pays dans le selecteur, au doigt.
Future<bool> _choisirPays(WidgetTester tester, String nom) async {
  final champsAvant = find.byType(TextField).evaluate().length;
  if (!await tapIfPresent(
      tester,
      find.byKey(const ValueKey('hiker-profile-country-field')),
      P,
      'pays',
      'ligne Pays (ouvre le selecteur)',
      warnIfMissing: false)) {
    return false;
  }
  await pumpAndSettleTolerant(tester);
  final recherche = find.byType(TextField);
  if (recherche.evaluate().isNotEmpty) {
    await tester.enterText(recherche.last, nom);
    await pumpAndSettleTolerant(tester);
  }
  final resultat = find.text(nom).hitTestable();
  if (resultat.evaluate().isEmpty) {
    logStep(P, 'pays', 'COINCE : « $nom » introuvable dans le selecteur');
    return false;
  }
  await tester.tap(resultat.first, warnIfMissed: false);
  await pumpAndSettleTolerant(tester);
  // On ne referme RIEN si la feuille semble encore ouverte : un pop de repli
  // refermerait la fiche et fausserait tout ce qui suit (ecart trouve en
  // passe 3).
  if (find.byType(TextField).evaluate().length > champsAvant) {
    logStep(P, 'pays',
        'CONSTAT : le selecteur semble encore ouvert apres le choix. On ne '
        'referme rien.');
  }
  return true;
}

/// Retire l accord morphologie s il est donne, et verifie qu il est bien tombe.
Future<bool> _retirerConsentement(WidgetTester tester) async {
  for (var essai = 0; essai < 2; essai++) {
    final consent = find.byType(SwitchListTile);
    if (consent.evaluate().isEmpty) return false;
    if (tester.widget<SwitchListTile>(consent.first).value == false) {
      return true;
    }
    await tapIfPresent(tester, consent.first, P, 'consentement',
        'retirer l accord morphologie (essai ${essai + 1})',
        warnIfMissing: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 3));
  }
  final reste = find.byType(SwitchListTile);
  return reste.evaluate().isNotEmpty &&
      tester.widget<SwitchListTile>(reste.first).value == false;
}

Future<void> _choisirLangue(WidgetTester tester, String libelle) async {
  await _aller(tester, '/settings');
  await tapIfPresent(tester, find.text(libelle), P, 'langue',
      'choisir la langue « $libelle »', warnIfMissing: false);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 5));
}

Future<void> _ajouterUneRandoPassee(WidgetTester tester) async {
  await _aller(tester, '/trail/$kTrailId/past-hikes');
  final tph = t.pastHikes;
  if (!await tapIfPresent(tester, find.text(tph.addHike), P, 'randos',
      'ouvrir le formulaire', warnIfMissing: false)) {
    return;
  }
  final valeurs = <String, String>{
    tph.fieldDays: '2',
    tph.fieldAvgHours: '5',
    tph.fieldElevation: '700',
    tph.fieldDistance: '16',
  };
  for (final e in valeurs.entries) {
    final champ = find.ancestor(
      of: find.text(e.key),
      matching: find.byType(TextFormField),
    );
    if (champ.evaluate().isEmpty) continue;
    await tester.enterText(champ.first, e.value);
    await pumpAndSettleTolerant(tester);
  }
  await tapIfPresent(tester, find.text(tph.save), P, 'randos',
      'enregistrer la rando', warnIfMissing: false);
  await pumpAndSettleTolerant(tester);
}
