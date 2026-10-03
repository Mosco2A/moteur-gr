// TACHE 630 — LA FICHE D'URGENCE N'AVAIT AUCUNE IDENTITE, ET LA LISTE EXISTAIT
// DEPUIS LE 26/09.
//
// ---------------------------------------------------------------------------
// CE QUI A DECLENCHE CE LOT
// ---------------------------------------------------------------------------
//
// Christophe teste StepWays sur son telephone le 29/09 au matin. Il ouvre la
// fiche sante et dit, verbatim : « Je ne vois toujours pas les infos complete
// dans info sante, dans la version en cours? » puis « Mais on avait dit nom,
// prenom, info de contact, tu avais fait la liste !!! ». La liste existait en
// base depuis le 26/09 (entree #100661) et n'avait jamais ete codee.
//
// L'ETAT MESURE, ET IL ETAIT PIRE QUE DECRIT :
//  * CINQ champs, et aucune identite. Un secouriste apprenait un groupe sanguin
//    et des allergies sans savoir QUI il soignait ni qui prevenir.
//  * les contacts a prevenir existaient comme modele... sans AUCUN ecran pour en
//    ajouter un (`addContact` n'etait appele par aucune ligne de `lib/`) et sans
//    disque (liste en memoire). Meme saisis, ils mouraient au redemarrage.
//  * la notification d'ecran verrouille recopiait TROIS champs sur cinq.
//  * le groupe sanguin etait une SAISIE LIBRE alors qu'il n'en existe que huit.
//
// ---------------------------------------------------------------------------
// CE QUE CE FICHIER PROUVE, PAR ORDRE D'IMPORTANCE POUR UN BLESSE
// ---------------------------------------------------------------------------
//
//  1. QUE LA FICHE DIT QUI ET QUI PREVENIR, et que ces deux blocs survivent au
//     disque. C'est la demande, et c'est ce qu'un secouriste lit en premier.
//  2. QU'UNE FICHE DEJA SAISIE NE PERD RIEN. Consigne 630, mot pour mot. Un
//     randonneur qui met a jour l'application ne doit pas retrouver sa fiche
//     amputee — ce serait pire que le defaut qu'on corrige.
//  3. QUE CE QU'UN SECOURISTE LIT SANS DEVERROUILLER EST LA FICHE ENTIERE, dans
//     l'ordre de la fiche. Trois champs sur cinq etait le defaut ; onze sur onze
//     est la correction, et l'ordre en fait partie.
//  4. QUE LES DEUX PHOTOS DE CARTE PASSENT PAR LA MEME PORTE QUE LA FICHE. C'est
//     la condition que Christophe a posee dans la meme phrase que la demande :
//     « tout reste sur le tel ». Meme dossier, meme exclusion, meme effacement.
//     AUCUNE seconde porte.
//  5. QUE LE REFUS DE L'APPAREIL PHOTO N'EST PAS UNE PANNE.
//
// ---------------------------------------------------------------------------
// CE QUE CE FICHIER NE PROUVE PAS, ET IL FAUT LE SAVOIR
// ---------------------------------------------------------------------------
//
// Il ne prouve pas qu'un secouriste voit REELLEMENT la notification sur un
// telephone : cela se mesure sur un appareil, pas dans un test de widgets. Il
// prouve ce qui est verifiable ici — que le CONTENU est complet et ordonne, et
// que la notification est DECLAREE integralement visible ecran verrouille
// (`VISIBILITY_PUBLIC`, sans quoi Android n'affiche que le titre).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/services/exclusion_sauvegarde_icloud.dart';
import 'package:moteur_gr/core/services/sauvegarde_systeme.dart';
import 'package:moteur_gr/features/safety/data/emergency_contacts_service.dart';
import 'package:moteur_gr/features/safety/data/health_info_file.dart';
import 'package:moteur_gr/features/safety/data/health_info_repository.dart';
import 'package:moteur_gr/features/safety/data/lockscreen_widget_service.dart';
import 'package:moteur_gr/features/safety/data/card_photo_capture.dart';
import 'package:moteur_gr/features/safety/domain/health_bounds.dart';
import 'package:moteur_gr/features/safety/domain/models/emergency_contact.dart';
import 'package:moteur_gr/features/safety/domain/models/health_info.dart';

/// UN APPEL VU PAR LE CANAL NATIF, AVEC L'ETAT DU DISQUE A CET INSTANT.
///
/// Meme dispositif que la suite du lot 615, et pour la meme raison : il ne
/// suffit pas de savoir QUE l'exclusion a ete demandee, il faut savoir QUAND.
/// L'espion lit le fichier au moment de l'appel, ce qui permet de prouver un
/// ordre (avant / apres le renommage) plutot que de le supposer.
class _Appel {
  _Appel(this.methode, this.chemin, this.octetsAuMomentDeLAppel);

  final String methode;
  final String chemin;
  final int? octetsAuMomentDeLAppel;
}

class _NatifEspion {
  final List<_Appel> appels = [];

  void brancher() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(ExclusionSauvegardeIcloud.nomDuCanal),
          (appel) async {
            final chemin =
                (appel.arguments
                        as Map)[ExclusionSauvegardeIcloud.argumentChemin]
                    as String;
            final f = File(chemin);
            int? octets;
            try {
              if (f.existsSync()) octets = f.lengthSync();
            } on FileSystemException {
              octets = null;
            }
            appels.add(
              _Appel(appel.method, chemin.replaceAll(r'\', '/'), octets),
            );
            return true;
          },
        );
  }

  void debrancher() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(ExclusionSauvegardeIcloud.nomDuCanal),
          null,
        );
  }

  void oublier() => appels.clear();

  List<_Appel> exclusionsDe(String chemin) => appels
      .where(
        (a) =>
            a.methode == ExclusionSauvegardeIcloud.methodeExclure &&
            a.chemin == chemin.replaceAll(r'\', '/'),
      )
      .toList();
}

String _n(String chemin) => chemin.replaceAll(r'\', '/');

/// Quelques octets qui ressemblent a une image : ce qui compte ici n'est pas
/// qu'ils se decodent, c'est ou ils atterrissent et qui les efface.
final _photo = List<int>.generate(4096, (i) => i % 256);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory bac;
  late HealthInfoFile fichier;
  late HealthInfoRepository repo;
  late _NatifEspion natif;

  setUp(() {
    bac = Directory.systemTemp.createTempSync('fiche630');
    natif = _NatifEspion()..brancher();
    fichier = HealthInfoFile(
      dossierApplicatif: () async => bac,
      // LA CIBLE IPHONE EST FORCEE : la suite tourne sur une machine de
      // developpement, ou `Platform.isIOS` est faux. Sans ce forcage, les
      // verifications d exclusion iCloud des photos ne mesureraient rien —
      // exactement la lecon de la suite du lot 615.
      exclusionIcloud: ExclusionSauvegardeIcloud(cibleIos: true),
    );
    repo = HealthInfoRepository(fichier: fichier);
  });

  tearDown(() {
    natif.debrancher();
    if (bac.existsSync()) bac.deleteSync(recursive: true);
  });

  /// La fiche complete telle qu'un randonneur la remplit apres ce lot.
  const laFicheComplete = HealthInfo(
    fullName: 'Christophe Mosconi',
    birthDate: '1972-04-03',
    address: '12 rue des Lilas, 20000 Ajaccio',
    emergencyContacts: [
      EmergencyContact(
        id: 'perso-0',
        name: 'Marie Mosconi',
        phone: '06 12 34 56 78',
        priority: 1,
      ),
    ],
    allergies: 'Penicilline',
    treatments: 'Levothyrox 50mg/j',
    conditions: 'Diabete type 1',
    bloodType: 'O-',
    organDonor: kOrganDonorYes,
    doctorContact: 'Dr Dupont 04 95 00 00 00',
    insuranceNumber: 'CEAM 80123456789',
  );

  // =========================================================================
  group('630 — la fiche dit enfin QUI, et QUI PREVENIR', () {
    test('l identite et les contacts a prevenir survivent a un aller-retour '
        'disque', () async {
      await repo.save(laFicheComplete);
      final relue = await repo.get();

      // QUI.
      expect(relue.fullName, 'Christophe Mosconi');
      expect(relue.birthDate, '1972-04-03');
      expect(relue.address, '12 rue des Lilas, 20000 Ajaccio');

      // QUI PREVENIR — ils sont DANS la fiche, pas a cote. Avant ce lot ils
      // vivaient dans une liste en memoire qu aucun ecran ne remplissait.
      expect(relue.emergencyContacts, hasLength(1));
      expect(relue.emergencyContacts.single.name, 'Marie Mosconi');
      expect(relue.emergencyContacts.single.phone, '06 12 34 56 78');

      // LE VITAL, y compris les deux champs ajoutes par ce lot.
      expect(relue.conditions, 'Diabete type 1');
      expect(relue.organDonor, kOrganDonorYes);
    });

    test('une fiche qui ne porte QUE des contacts compte comme remplie', () async {
      // `hasData` pilote DEUX choses : la porte de demarrage du trek et
      // l ECRITURE MEME du fichier (une fiche sans donnee est effacee, pour ne
      // pas laisser de trace de passage). Un champ oublie dans `hasData` serait
      // donc un champ qui ne s enregistre pas.
      const rienQueDesContacts = HealthInfo(
        emergencyContacts: [
          EmergencyContact(
            id: 'perso-0',
            name: 'Marie',
            phone: '0612345678',
            priority: 1,
          ),
        ],
      );
      expect(rienQueDesContacts.hasData, isTrue);
      await repo.save(rienQueDesContacts);
      expect((await repo.get()).emergencyContacts, hasLength(1));
    });

    test('CHAQUE champ ajoute par ce lot entre dans hasData', () async {
      // Verification exhaustive plutot qu un echantillon : c est exactement le
      // genre d oubli qui ne se voit que le jour ou un randonneur enregistre une
      // fiche qui ne porte que son nom, et la retrouve vide.
      const parChamp = <String, HealthInfo>{
        'fullName': HealthInfo(fullName: 'X'),
        'birthDate': HealthInfo(birthDate: '1972-04-03'),
        'address': HealthInfo(address: 'X'),
        'conditions': HealthInfo(conditions: 'X'),
        'organDonor': HealthInfo(organDonor: kOrganDonorYes),
        'carteVitaleFichier': HealthInfo(carteVitaleFichier: 'x.jpg'),
        'carteMutuelleFichier': HealthInfo(carteMutuelleFichier: 'x.jpg'),
      };
      for (final entree in parChamp.entries) {
        expect(
          entree.value.hasData,
          isTrue,
          reason:
              'le champ ${entree.key} doit rendre la fiche NON vide, '
              'sinon il ne s enregistre jamais',
        );
      }
    });

    test('les contacts personnels du service viennent de la fiche', () {
      final service = EmergencyContactsService();
      // Au depart : le 112 seul. C est EXACTEMENT ce que voyait Christophe.
      expect(service.getContacts().where((c) => !c.isAutomatic), isEmpty);

      service.chargerDepuisLaFiche(laFicheComplete.emergencyContacts);
      final perso = service.getContacts().where((c) => !c.isAutomatic).toList();
      expect(perso, hasLength(1));
      expect(perso.single.name, 'Marie Mosconi');

      // ET IL REMPLACE, IL NE FUSIONNE PAS : un contact retire de la fiche ne
      // doit pas survivre dans le service, sinon un numero perime reste sur
      // l ecran verrouille d un blesse.
      service.chargerDepuisLaFiche(const []);
      expect(service.getContacts().where((c) => !c.isAutomatic), isEmpty);
    });
  });

  // =========================================================================
  group('630 — le groupe sanguin est une liste FERMEE de huit', () {
    test('huit groupes, plus « je ne sais pas », et rien d autre', () {
      // SOURCE : Etablissement francais du sang — la combinaison ABO x Rhesus
      // donne HUIT groupes. Christophe, 29/09 : un groupe mal saisi sur une
      // fiche d urgence est PIRE qu un champ vide.
      expect(kBloodTypes, hasLength(8));
      expect(kBloodTypesOrdonnes, hasLength(8));
      expect(kBloodTypeChoices, hasLength(9));
      expect(kBloodTypeChoices.last, kBloodTypeUnknown);
      for (final g in ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']) {
        expect(kBloodTypes.contains(g), isTrue);
      }
    });

    test('une valeur inventee ne correspond a aucune entree de la liste', () {
      expect(valeurListeGroupeSanguin('XYZ123!!'), isNull);
      expect(valeurListeGroupeSanguin('C+'), isNull);
      expect(valeurListeGroupeSanguin(''), isNull);
      // Et elle est RECONNUE COMME HERITEE, ce qui declenche l avertissement au
      // lieu d un effacement silencieux.
      expect(estGroupeSanguinHerite('XYZ123!!'), isTrue);
      expect(estGroupeSanguinHerite(''), isFalse);
      expect(estGroupeSanguinHerite('O-'), isFalse);
    });

    test('la forme heritee valide est ramenee a la forme canonique', () {
      expect(valeurListeGroupeSanguin(' ab+ '), 'AB+');
      expect(valeurListeGroupeSanguin('o-'), 'O-');
      expect(valeurListeGroupeSanguin(kBloodTypeUnknown), kBloodTypeUnknown);
    });

    test('« je ne sais pas » n est PAS un groupe sanguin valide', () {
      // Les deux notions ne se confondent pas : c est une reponse, pas un
      // groupe. Un code qui transfuserait sur cette valeur serait un desastre.
      expect(isValidBloodType(kBloodTypeUnknown), isFalse);
    });
  });

  // =========================================================================
  group('630 — MIGRATION : une fiche deja saisie ne perd RIEN', () {
    test(
      'un fichier a CINQ champs se relit avec ses cinq valeurs intactes',
      () async {
        // Le JSON exact qu ecrivait la version precedente, ecrit A LA MAIN pour ne
        // pas dependre du modele actuel : c est ce qui est REELLEMENT sur le
        // telephone de Christophe.
        final f = File(
          '${bac.path}/${SauvegardeSysteme.dossierExclu}/'
          '${HealthInfoFile.nomFichier}',
        );
        f.parent.createSync(recursive: true);
        f.writeAsStringSync(
          jsonEncode({
            'bloodType': 'O-',
            'allergies': 'Penicilline',
            'treatments': 'Levothyrox 50mg/j',
            'doctorContact': 'Dr Dupont',
            'insuranceNumber': 'CEAM 80123456789',
          }),
        );

        final relue = await repo.get();
        expect(relue.bloodType, 'O-');
        expect(relue.allergies, 'Penicilline');
        expect(relue.treatments, 'Levothyrox 50mg/j');
        expect(relue.doctorContact, 'Dr Dupont');
        expect(relue.insuranceNumber, 'CEAM 80123456789');

        // ET LES HUIT CHAMPS AJOUTES SONT VIDES, pas absents : la fiche est
        // utilisable telle quelle, le randonneur complete ce qu il veut.
        expect(relue.fullName, '');
        expect(relue.birthDate, '');
        expect(relue.address, '');
        expect(relue.conditions, '');
        expect(relue.organDonor, '');
        expect(relue.carteVitaleFichier, '');
        expect(relue.carteMutuelleFichier, '');
        expect(relue.emergencyContacts, isEmpty);
      },
    );

    test(
      'completer une fiche heritee ne perd aucune de ses cinq valeurs',
      () async {
        final f = File(
          '${bac.path}/${SauvegardeSysteme.dossierExclu}/'
          '${HealthInfoFile.nomFichier}',
        );
        f.parent.createSync(recursive: true);
        f.writeAsStringSync(
          jsonEncode({
            'bloodType': 'O-',
            'allergies': 'Penicilline',
            'treatments': 'Levothyrox 50mg/j',
            'doctorContact': 'Dr Dupont',
            'insuranceNumber': 'CEAM 80123456789',
          }),
        );

        final heritee = await repo.get();
        await repo.save(heritee.copyWith(fullName: 'Christophe Mosconi'));

        final relue = await repo.get();
        expect(relue.fullName, 'Christophe Mosconi');
        expect(relue.allergies, 'Penicilline');
        expect(relue.insuranceNumber, 'CEAM 80123456789');
      },
    );

    test(
      'une valeur de groupe sanguin non reconnue reste SUR LE DISQUE',
      () async {
        // Elle n est pas effacee : l ecran la montre au randonneur et lui demande
        // de choisir. « Les fiches deja saisies ne perdent RIEN. »
        await repo.save(const HealthInfo(bloodType: 'XYZ123!!'));
        expect((await repo.get()).bloodType, 'XYZ123!!');
      },
    );
  });

  // =========================================================================
  group('630 — ce qu un secouriste lit SANS DEVERROUILLER', () {
    LockscreenWidgetService serviceAvec(HealthInfo fiche) {
      final contacts = EmergencyContactsService()
        ..chargerDepuisLaFiche(fiche.emergencyContacts);
      return LockscreenWidgetService(
        contactsService: contacts,
        trailName: 'Mare a Mare Centre',
      );
    }

    test(
      'la notification porte la fiche ENTIERE, plus trois champs sur cinq',
      () async {
        final service = serviceAvec(laFicheComplete);
        await service.updateSecurityData(healthInfo: laFicheComplete);
        final corps = service.buildNotificationContent(
          service.contactsService.getContacts(),
        );

        // LES TROIS CHAMPS QUI Y ETAIENT DEJA.
        expect(corps, contains('Penicilline'));
        expect(corps, contains('Levothyrox 50mg/j'));
        expect(corps, contains('O-'));
        // LES DEUX QUI MANQUAIENT — c est le defaut nomme par la consigne.
        expect(
          corps,
          contains('Dr Dupont 04 95 00 00 00'),
          reason: 'le medecin traitant n etait PAS recopie',
        );
        expect(
          corps,
          contains('CEAM 80123456789'),
          reason: 'l assurance n etait PAS recopiee',
        );
        // ET TOUT CE QUI N EXISTAIT MEME PAS.
        expect(corps, contains('Christophe Mosconi'));
        expect(corps, contains('1972-04-03'));
        expect(corps, contains('12 rue des Lilas, 20000 Ajaccio'));
        expect(corps, contains('Marie Mosconi'));
        expect(corps, contains('06 12 34 56 78'));
        expect(corps, contains('Diabete type 1'));
        expect(corps, contains(kOrganDonorYes));
      },
    );

    test(
      'l ordre lu est celui de la fiche : qui, qui prevenir, puis le vital',
      () async {
        final service = serviceAvec(laFicheComplete);
        await service.updateSecurityData(healthInfo: laFicheComplete);
        final corps = service.buildNotificationContent(
          service.contactsService.getContacts(),
        );

        final rangIdentite = corps.indexOf('Christophe Mosconi');
        final rangContact = corps.indexOf('Marie Mosconi');
        final rangAllergies = corps.indexOf('Penicilline');
        final rangTraitements = corps.indexOf('Levothyrox');
        final rangAntecedents = corps.indexOf('Diabete');
        final rangSang = corps.indexOf('O-');

        expect(
          rangIdentite,
          lessThan(rangContact),
          reason:
              'un secouriste qui appelle un proche doit pouvoir dire de QUI '
              'il parle des la premiere seconde',
        );
        expect(
          rangContact,
          lessThan(rangAllergies),
          reason:
              'Apple : « who to contact in case of an emergency » est ce que '
              'voient les premiers intervenants',
        );
        // ORDRE SAMPLE : Allergies, Medicaments, Antecedents. Une allergie tue au
        // moment du soin, sur le sentier ; le groupe sanguin sert a l hopital.
        expect(rangAllergies, lessThan(rangTraitements));
        expect(rangTraitements, lessThan(rangAntecedents));
        expect(rangAntecedents, lessThan(rangSang));
      },
    );

    test('une fiche vide ne fabrique pas un bloc SANTE vide', () async {
      final service = serviceAvec(const HealthInfo());
      await service.updateSecurityData(healthInfo: const HealthInfo());
      final corps = service.buildNotificationContent(
        service.contactsService.getContacts(),
      );
      expect(corps, isNot(contains('SANTE')));
      // Mais le 112 reste : c est une constante de l application, pas une donnee
      // du randonneur.
      expect(corps, contains('112'));
    });

    test('la notification est DECLAREE integralement visible sur l ecran '
        'verrouille', () {
      // SANS `VISIBILITY_PUBLIC`, Android n affiche que le titre : le defaut est
      // `VISIBILITY_PRIVATE`, « only basic information [...] shows on the lock
      // screen ». Un secouriste verrait « Secours Mare a Mare Centre » et rien
      // d autre. C est une invariante de SOURCE parce qu elle ne se verifie pas
      // autrement qu en lancant un vrai Android.
      final source = File(
        'lib/features/safety/data/lockscreen_widget_service.dart',
      ).readAsStringSync();
      expect(
        source,
        contains('visibility: NotificationVisibility.public'),
        reason: 'la fiche d urgence doit etre lisible EN ENTIER sans code',
      );
    });
  });

  // =========================================================================
  group('630 — les deux photos de carte passent par la MEME porte', () {
    test(
      'elles atterrissent dans le dossier de la fiche, pas ailleurs',
      () async {
        await fichier.enregistrerCarte(HealthInfoFile.nomCarteVitale, _photo);

        final image = File(
          '${bac.path}/${SauvegardeSysteme.dossierExclu}/'
          '${HealthInfoFile.nomCarteVitale}',
        );
        expect(image.existsSync(), isTrue);
        expect(image.lengthSync(), _photo.length);

        // VOISINE DE `fiche.json` : c est CE qui lui donne la protection du lot
        // 612 (exclusion Android de `file/medical/`) et celle du lot 617
        // (inclusion unique : tout le reste est dehors).
        final laFiche = await fichier.fichier();
        expect(_n(image.parent.path), _n(laFiche.parent.path));
      },
    );

    test('elles ne sont PAS dans le seul dossier que la sauvegarde emporte', () {
      // Le lot 617 a renverse la regle : une SEULE inclusion, tout le reste
      // dehors. Les photos sont sous `medical/`, jamais sous le dossier
      // sauvegardable — donc dehors par construction, et pas par une liste a
      // tenir a jour.
      expect(SauvegardeSysteme.inclusions, hasLength(1));
      expect(
        SauvegardeSysteme.inclusions.single.chemin,
        '${SauvegardeSysteme.dossierSauvegardable}/',
      );
      expect(
        SauvegardeSysteme.dossierExclu,
        isNot(SauvegardeSysteme.dossierSauvegardable),
      );
      // Et l exclusion explicite du lot 612 couvre le dossier ENTIER, donc les
      // images avec la fiche — pas seulement `fiche.json`.
      expect(
        SauvegardeSysteme.exclusions.any(
          (e) => e.chemin == '${SauvegardeSysteme.dossierExclu}/',
        ),
        isTrue,
      );
    });

    test('l exclusion iCloud est posee sur le temporaire AVANT le renommage et '
        'sur le fichier final APRES', () async {
      natif.oublier();
      await fichier.enregistrerCarte(HealthInfoFile.nomCarteVitale, _photo);

      final chemin =
          '${bac.path}/${SauvegardeSysteme.dossierExclu}/'
          '${HealthInfoFile.nomCarteVitale}';
      final temporaire = '$chemin${HealthInfoFile.suffixeTemporaire}';

      // LE TEMPORAIRE : l image est deja sur le disque quand on l exclut, sinon
      // il existe une fenetre ou une carte Vitale est en clair sans attribut.
      final surLeTmp = natif.exclusionsDe(temporaire);
      expect(
        surLeTmp,
        isNotEmpty,
        reason:
            'sans cette pose, la photo existe sur le disque sans '
            'attribut pendant toute l ecriture',
      );
      expect(surLeTmp.last.octetsAuMomentDeLAppel, _photo.length);

      // LE FICHIER FINAL : c est CE geste qui ferme le piege de l ecriture
      // atomique (mesure du lot 615 : l attribut appartient au FICHIER, et le
      // fichier final est l ancien `.tmp`, qui ne l a jamais porte).
      final surLeFinal = natif.exclusionsDe(chemin);
      expect(surLeFinal, isNotEmpty);
      expect(
        surLeFinal.last.octetsAuMomentDeLAppel,
        _photo.length,
        reason:
            'l exclusion doit etre posee APRES le renommage, donc sur un '
            'chemin qui porte deja la photo',
      );

      // ET LE DOSSIER.
      expect(
        natif.exclusionsDe('${bac.path}/${SauvegardeSysteme.dossierExclu}'),
        isNotEmpty,
      );
    });

    test('effacer la fiche emporte les DEUX photos', () async {
      await repo.save(
        laFicheComplete.copyWith(
          carteVitaleFichier: HealthInfoFile.nomCarteVitale,
          carteMutuelleFichier: HealthInfoFile.nomCarteMutuelle,
        ),
      );
      await fichier.enregistrerCarte(HealthInfoFile.nomCarteVitale, _photo);
      await fichier.enregistrerCarte(HealthInfoFile.nomCarteMutuelle, _photo);

      final dossier = Directory(
        '${bac.path}/${SauvegardeSysteme.dossierExclu}',
      );
      expect(dossier.listSync(), hasLength(3));

      await repo.delete();

      // « Effacer ma fiche » qui laisserait une photo de carte Vitale sur le
      // disque serait un effacement qui ment — et c est la MEME methode que
      // l effacement de compte.
      expect(dossier.existsSync() ? dossier.listSync() : const [], isEmpty);
    });

    test(
      'garantirExclusion repose l attribut sur des photos deja presentes',
      () async {
        // Le cas du randonneur qui a photographie sa carte avec la version
        // precedente puis met a jour : `enregistrerCarte` ne repassera jamais, et
        // sans cette reprise l image resterait dans iCloud pour toujours. Meme
        // raisonnement que la tache 615 pour la fiche elle-meme.
        await fichier.enregistrerCarte(HealthInfoFile.nomCarteVitale, _photo);
        natif.oublier();

        await fichier.garantirExclusion();

        expect(
          natif.exclusionsDe(
            '${bac.path}/${SauvegardeSysteme.dossierExclu}/'
            '${HealthInfoFile.nomCarteVitale}',
          ),
          isNotEmpty,
        );
      },
    );

    test('un nom d image qui ne vient pas de nous est REFUSE', () async {
      // Reprendre le nom rendu par l appareil photo ferait entrer dans le
      // dossier protege une chaine choisie par le systeme. Deux noms fixes,
      // jamais plus.
      expect(
        () => fichier.fichierCarte('../../ailleurs.jpg'),
        throwsA(isA<ArgumentError>()),
      );
      expect(HealthInfoFile.nomsCartes, hasLength(2));
    });

    test('la fiche sait qu elle porte une carte', () {
      expect(const HealthInfo().aUneCarte, isFalse);
      expect(
        const HealthInfo(carteVitaleFichier: 'carte_vitale.jpg').aUneCarte,
        isTrue,
      );
    });
  });

  // =========================================================================
  group('630 — le refus de l appareil photo n est pas une panne', () {
    test('refus, annulation et echec sont TROIS issues distinctes', () {
      // Les confondre ferait dire « impossible de prendre la photo » a quelqu un
      // qui a simplement appuye sur Annuler — et traiterait un droit (refuser
      // l acces a son appareil photo) comme un incident.
      expect(const CardPhotoResult.refus().issue, CardPhotoOutcome.refus);
      expect(const CardPhotoResult.annule().issue, CardPhotoOutcome.annule);
      expect(const CardPhotoResult.echec().issue, CardPhotoOutcome.echec);

      expect(const CardPhotoResult.refus().aUneImage, isFalse);
      expect(const CardPhotoResult.annule().aUneImage, isFalse);
      expect(CardPhotoResult.reussite(_photo).aUneImage, isTrue);
    });

    test('la resolution retenue reste lisible par un humain et bornee', () {
      // Format ID-1 (ISO/CEI 7810) : 85,6 mm de grand cote. A 300 points par
      // pouce — la densite de numerisation de document — cela fait 1011 pixels.
      // La borne retenue laisse une marge sur le texte le plus petit d une carte
      // sans jamais approcher les 12 millions de pixels d un capteur moderne.
      const pixelsA300ppp = 85.6 / 25.4 * 300;
      expect(kLargeurMaxCarte, greaterThan(pixelsA300ppp));
      expect(kLargeurMaxCarte, lessThanOrEqualTo(2000));
      expect(kQualiteJpegCarte, inInclusiveRange(70, 90));
    });
  });

  // =========================================================================
  group('630 — la loi du projet ne bouge pas d un millimetre', () {
    test('le modele de la fiche ne connait aucun chemin de sortie', () {
      // « Les donnees medicales RESTENT sur le tel » (Christophe, 27/09 et 28/09,
      // en majuscules). Le nom et l adresse sont des donnees personnelles de
      // PLUS, pas d une autre nature : elles ne sortent pas davantage. Cette
      // invariante relit la source du modele et du stockage.
      for (final chemin in [
        'lib/features/safety/domain/models/health_info.dart',
        'lib/features/safety/data/health_info_file.dart',
        'lib/features/safety/data/health_info_repository.dart',
      ]) {
        final source = File(chemin).readAsStringSync();
        // ON LIT LES `import`, PAS LE TEXTE. Les commentaires de ces fichiers
        // CITENT les sources officielles Apple et Google, donc ils contiennent
        // « https » — chercher la sous-chaine ferait echouer la garde sur
        // exactement ce que ce lot devait apporter : les sources.
        final imports = const LineSplitter()
            .convert(source)
            .where((l) => l.trimLeft().startsWith('import '))
            .join('\n');
        for (final transport in [
          'cloud_firestore',
          'firebase',
          'package:http',
          'dart:io\' show HttpClient',
          'http_client',
        ]) {
          expect(
            imports.contains(transport),
            isFalse,
            reason:
                '$chemin ne doit importer AUCUN transport distant '
                '(trouve : $transport)',
          );
        }
      }
    });
  });
}
