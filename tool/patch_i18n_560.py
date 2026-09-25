# -*- coding: utf-8 -*-
"""Patch i18n de la tache 560 (LOT I), applique UNE FOIS et conserve pour trace.

Trois retouches, cinq langues, edition TEXTUELLE ciblee (aucun reformatage du
fichier : le diff ne montre que ce qui change) :

  N2  retrait de `hikerProfile.bmiLabel` et de `hikerProfile.bmiCategories` —
      l'IMC et sa categorie ne s'affichent plus sur la fiche d'info (ni ailleurs,
      plus aucun appelant). « IMC » figure au vocabulaire proscrit a l'ecran
      (body_weight_reference.dart #7) et le jugement s'affichait AVANT tout
      consentement.
  N1  ajout de `hikerProfile.errorConsentRequired` — le refus de consentement
      article 9 est DIT au randonneur au lieu de fermer l'ecran comme un succes.
  N4  `itinerary.stageCount` passe au PLURIEL SLANG (`stageCount(plural)`,
      parametre par defaut `n`) au lieu d'un « {count} etapes » substitue a la
      main, qui affichait « 1 etapes ». Les regles de pluriel CLDR de chaque
      langue s'appliquent alors (en francais, `one` couvre 0 et 1).

      PIEGE A CONNAITRE : ce projet est en interpolation SLANG « dart », donc le
      parametre s'ecrit `$n`. Les `{count}` que l'on croise dans les autres cles
      ne sont PAS des parametres Slang : c'est du texte litteral que le code
      substitue lui-meme par `replaceAll`. Ecrire `{n}` dans un pluriel rendrait
      « {n} etape » a l'ecran — teste par
      `test/features/trek/presentation/planning/accord_pluriel_etapes_test.dart`.

Rejoue a blanc : le script exige EXACTEMENT une occurrence de chaque motif et
s'arrete sinon — il ne peut pas patcher deux fois ni patcher a cote.
"""
import io
import json
import os
import sys

BASE = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "assets", "i18n",
)

# --- N2 : bloc IMC a supprimer, langue par langue -------------------------
BMI = {
    "fr": '    "bmiLabel": "IMC",\n'
          '    "bmiCategories": {\n'
          '      "underweight": "Maigreur",\n'
          '      "normal": "Corpulence normale",\n'
          '      "overweight": "Surpoids",\n'
          '      "obese": "Fort surpoids"\n'
          '    },\n',
    "en": '    "bmiLabel": "BMI",\n'
          '    "bmiCategories": {\n'
          '      "underweight": "Underweight",\n'
          '      "normal": "Normal weight",\n'
          '      "overweight": "Overweight",\n'
          '      "obese": "Significant overweight"\n'
          '    },\n',
    "de": '    "bmiLabel": "BMI",\n'
          '    "bmiCategories": {\n'
          '      "underweight": "Untergewicht",\n'
          '      "normal": "Normalgewicht",\n'
          '      "overweight": "Übergewicht",\n'
          '      "obese": "Starkes Übergewicht"\n'
          '    },\n',
    "es": '    "bmiLabel": "IMC",\n'
          '    "bmiCategories": {\n'
          '      "underweight": "Bajo peso",\n'
          '      "normal": "Peso normal",\n'
          '      "overweight": "Sobrepeso",\n'
          '      "obese": "Sobrepeso elevado"\n'
          '    },\n',
    "it": '    "bmiLabel": "IMC",\n'
          '    "bmiCategories": {\n'
          '      "underweight": "Sottopeso",\n'
          '      "normal": "Normopeso",\n'
          '      "overweight": "Sovrappeso",\n'
          '      "obese": "Forte sovrappeso"\n'
          '    },\n',
}

# --- N1 : refus de sauvegarde faute de consentement ----------------------
ERROR_EMPTY = {
    "fr": '    "errorEmpty": "Fiche vide : renseignez au moins l\'âge, la taille ou le poids.",\n',
    "en": '    "errorEmpty": "Empty profile: enter at least your age, height or weight.",\n',
    "de": '    "errorEmpty": "Leeres Profil: Geben Sie mindestens Alter, Grösse oder Gewicht an.",\n',
    "es": '    "errorEmpty": "Ficha vacía: indique al menos la edad, la altura o el peso.",\n',
    "it": '    "errorEmpty": "Scheda vuota: inserisca almeno l\'età, l\'altezza o il peso.",\n',
}

CONSENT_REQUIRED = {
    "fr": '    "errorConsentRequired": "Sans votre accord, rien n\'est enregistré : '
          'âge, taille et poids sont des données de santé. Ce qui avait '
          'été enregistré vient d\'être effacé de cet appareil. '
          'Cochez l\'autorisation ci-dessus, puis enregistrez.",\n',
    "en": '    "errorConsentRequired": "Without your consent nothing is saved: age, '
          'height and weight are health data. Whatever had been saved has just been '
          'erased from this device. Tick the authorisation above, then save.",\n',
    "de": '    "errorConsentRequired": "Ohne Ihre Einwilligung wird nichts gespeichert: '
          'Alter, Grösse und Gewicht sind Gesundheitsdaten. Was gespeichert war, '
          'wurde soeben von diesem Gerät gelöscht. Aktivieren Sie oben die '
          'Zustimmung und speichern Sie erneut.",\n',
    "es": '    "errorConsentRequired": "Sin tu consentimiento no se guarda nada: edad, '
          'altura y peso son datos de salud. Lo que estaba guardado acaba de borrarse '
          'de este dispositivo. Marca la autorización de arriba y vuelve a '
          'guardar.",\n',
    "it": '    "errorConsentRequired": "Senza il tuo consenso non viene salvato nulla: '
          'età, altezza e peso sono dati sanitari. Quanto era salvato è appena '
          'stato cancellato da questo dispositivo. Spunta l\'autorizzazione qui sopra '
          'e salva di nuovo.",\n',
}

# --- N4 : pluriel slang (parametre par defaut `n`) ------------------------
STAGE_OLD = {
    "fr": '    "stageCount": "{count} étapes"\n',
    "en": '    "stageCount": "{count} stages"\n',
    "de": '    "stageCount": "{count} Etappen"\n',
    "es": '    "stageCount": "{count} etapas"\n',
    "it": '    "stageCount": "{count} tappe"\n',
}

STAGE_NEW = {
    "fr": '    "stageCount(plural)": {\n'
          '      "one": "$n étape",\n'
          '      "other": "$n étapes"\n'
          '    }\n',
    "en": '    "stageCount(plural)": {\n'
          '      "one": "$n stage",\n'
          '      "other": "$n stages"\n'
          '    }\n',
    "de": '    "stageCount(plural)": {\n'
          '      "one": "$n Etappe",\n'
          '      "other": "$n Etappen"\n'
          '    }\n',
    "es": '    "stageCount(plural)": {\n'
          '      "one": "$n etapa",\n'
          '      "other": "$n etapas"\n'
          '    }\n',
    "it": '    "stageCount(plural)": {\n'
          '      "one": "$n tappa",\n'
          '      "other": "$n tappe"\n'
          '    }\n',
}


def _once(text, old, new, loc, label):
    n = text.count(old)
    if n != 1:
        raise SystemExit(
            "%s / %s : %d occurrence(s) au lieu de 1 — patch refuse" % (loc, label, n)
        )
    return text.replace(old, new)


def patch(loc):
    path = os.path.join(BASE, "%s.i18n.json" % loc)
    with io.open(path, encoding="utf-8") as f:
        src = f.read()
    out = _once(src, BMI[loc], "", loc, "bmi")
    out = _once(out, ERROR_EMPTY[loc],
                ERROR_EMPTY[loc] + CONSENT_REQUIRED[loc], loc, "errorConsentRequired")
    out = _once(out, STAGE_OLD[loc], STAGE_NEW[loc], loc, "stageCount")
    with io.open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(out)
    return path


def main():
    for loc in ("fr", "en", "de", "es", "it"):
        path = patch(loc)
        with io.open(path, encoding="utf-8") as f:
            data = json.load(f)
        hp = data["hikerProfile"]
        assert "bmiLabel" not in hp, loc
        assert "bmiCategories" not in hp, loc
        assert "errorConsentRequired" in hp, loc
        assert "stageCount(plural)" in data["itinerary"], loc
        assert "stageCount" not in data["itinerary"], loc
        print("OK %s" % loc)


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    main()
