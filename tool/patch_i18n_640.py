# -*- coding: utf-8 -*-
"""TACHE 640 — la rubrique des packs partiels sort des cinq langues, les libelles
des cartes du circuit prennent sa place.

Meme forme que tool/patch_i18n_560.py : on edite les cinq `assets/i18n/*.i18n.json`
en preservant l'ordre des cles, puis on regenere avec `dart run slang`.

Retour de Christophe du 30/09 (DEM-260930-1017), verbatim : « Le telechargement
doit telecharger les cartes pour le circuit propose. On ne propose pas de
demi-Mare a Mare, pas besoin de telecharger de demi-cartes ». Les quatre noms de
pack (Nord / Sud / Complet / Mare a Mare) que le lot 634 avait trouves ecrits en
dur disparaissent donc AVEC leur rubrique.
"""
import collections
import io
import json
import os

BASE = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "assets",
    "i18n",
)

CARTES = {
    "fr": {
        "title": "Cartes hors ligne",
        "intro": "Un seul téléchargement : les cartes de tout le circuit, pour marcher sans réseau.",
        "unSeulGeste": "Tout le circuit en une fois, pas de morceaux à choisir.",
        "poids": "$mo Mo à télécharger",
        "poidsTotal": "Poids total du circuit : $mo Mo",
        "reprise": "$mo Mo sont déjà sur le téléphone : la reprise ne téléchargera que le reste.",
        "telecharger": "TÉLÉCHARGER LES CARTES DU CIRCUIT",
        "reprendre": "REPRENDRE LE TÉLÉCHARGEMENT",
        "reessayer": "RÉESSAYER",
        "annuler": "ANNULER",
        "supprimer": "SUPPRIMER LES CARTES",
        "enCours": "$recus Mo sur $total Mo",
        "verification": "Vérification de la carte",
        "pretes": "Cartes prêtes hors ligne",
        "pretesPoids": "$mo Mo sur le téléphone",
        "libere": "Cartes supprimées, espace libéré.",
        "supprimerTitre": "Supprimer les cartes ?",
        "supprimerCorps": "Les cartes seront retirées du téléphone pour libérer de l'espace. Vous pourrez les retélécharger.",
        "supprimerAnnuler": "Annuler",
        "supprimerConfirmer": "Supprimer",
        "horsWifiTitre": "$mo Mo sur votre forfait ?",
        "horsWifiCorps": "Vous n'êtes pas en Wi-Fi. Les cartes d'un circuit peuvent peser lourd sur un forfait mobile.",
        "horsWifiAttendre": "Attendre le Wi-Fi",
        "horsWifiContinuer": "Télécharger quand même",
        "refus": {
            "niveauInsuffisant": "Les cartes descendent au moment où vous préparez le circuit pour le marcher.",
            "sentierInconnu": "Ce circuit n'est pas encore sur votre téléphone. Téléchargez-le depuis la liste des sentiers.",
            "aucuneCartePubliee": "Aucune carte hors ligne n'est publiée pour ce circuit pour le moment. Le tracé, lui, reste disponible.",
            "droitDeRealiserManquant": "Les cartes hors ligne font partie du circuit acheté.",
            "horsLigne": "Sans réseau, une carte ne peut pas être téléchargée. Reconnectez-vous puis réessayez.",
            "stockageIndisponible": "Le téléphone n'a pas répondu. Réessayez ; s'il insiste, redémarrez-le.",
        },
        "echec": {
            "reseau": "La liaison a été coupée. Ce qui est déjà téléchargé est gardé : reprenez quand vous voulez.",
            "empreinteInvalide": "La carte reçue ne correspond pas à celle publiée : elle a été écartée. Réessayez.",
            "tailleInattendue": "La carte reçue est incomplète : elle a été écartée. Réessayez.",
            "plusDePlace": "Il n'y a plus de place sur le téléphone. Libérez de l'espace, puis reprenez.",
            "ecritureImpossible": "L'écriture sur le téléphone a échoué. Ce qui est téléchargé est gardé : reprenez.",
            "stockageIndisponible": "Le téléphone n'a pas rendu son espace de stockage. Réessayez ; s'il insiste, redémarrez-le.",
            "annulee": "Téléchargement annulé. Ce qui est déjà téléchargé est gardé.",
        },
        "demoIndisponible": "Le téléchargement des cartes n'est pas disponible pendant la démonstration.",
        "a11y": {
            "bouton": "Télécharger les cartes de tout le circuit",
            "progression": "Téléchargement des cartes : $pourcent %",
        },
    },
    "en": {
        "title": "Offline maps",
        "intro": "One single download: the maps for the whole route, so you can walk without a network.",
        "unSeulGeste": "The whole route at once, no parts to choose from.",
        "poids": "$mo MB to download",
        "poidsTotal": "Total size for the route: $mo MB",
        "reprise": "$mo MB are already on the phone: resuming will only download the rest.",
        "telecharger": "DOWNLOAD THE MAPS FOR THE ROUTE",
        "reprendre": "RESUME THE DOWNLOAD",
        "reessayer": "TRY AGAIN",
        "annuler": "CANCEL",
        "supprimer": "DELETE THE MAPS",
        "enCours": "$recus MB of $total MB",
        "verification": "Checking the map",
        "pretes": "Maps ready offline",
        "pretesPoids": "$mo MB on the phone",
        "libere": "Maps deleted, space freed.",
        "supprimerTitre": "Delete the maps?",
        "supprimerCorps": "The maps will be removed from the phone to free up space. You can download them again.",
        "supprimerAnnuler": "Cancel",
        "supprimerConfirmer": "Delete",
        "horsWifiTitre": "$mo MB on your mobile data?",
        "horsWifiCorps": "You are not on Wi-Fi. A route's maps can weigh heavily on a mobile plan.",
        "horsWifiAttendre": "Wait for Wi-Fi",
        "horsWifiContinuer": "Download anyway",
        "refus": {
            "niveauInsuffisant": "The maps come down when you prepare the route to actually walk it.",
            "sentierInconnu": "This route is not on your phone yet. Download it from the trail list.",
            "aucuneCartePubliee": "No offline map has been published for this route yet. The track itself is still available.",
            "droitDeRealiserManquant": "Offline maps are part of the route you buy.",
            "horsLigne": "Without a network a map cannot be downloaded. Reconnect, then try again.",
            "stockageIndisponible": "The phone did not answer. Try again; if it persists, restart it.",
        },
        "echec": {
            "reseau": "The connection dropped. What is already downloaded is kept: resume whenever you like.",
            "empreinteInvalide": "The map received does not match the published one: it was discarded. Try again.",
            "tailleInattendue": "The map received is incomplete: it was discarded. Try again.",
            "plusDePlace": "There is no space left on the phone. Free up some space, then resume.",
            "ecritureImpossible": "Writing to the phone failed. What is downloaded is kept: resume.",
            "stockageIndisponible": "The phone did not give up its storage. Try again; if it persists, restart it.",
            "annulee": "Download cancelled. What is already downloaded is kept.",
        },
        "demoIndisponible": "Downloading the maps is not available during the demo.",
        "a11y": {
            "bouton": "Download the maps for the whole route",
            "progression": "Downloading maps: $pourcent %",
        },
    },
    "de": {
        "title": "Offline-Karten",
        "intro": "Ein einziger Download: die Karten der gesamten Route, um ohne Netz zu wandern.",
        "unSeulGeste": "Die ganze Route in einem Mal, keine Teile zum Auswählen.",
        "poids": "$mo MB zum Herunterladen",
        "poidsTotal": "Gesamtgröße der Route: $mo MB",
        "reprise": "$mo MB sind schon auf dem Telefon: die Fortsetzung lädt nur den Rest.",
        "telecharger": "KARTEN DER ROUTE HERUNTERLADEN",
        "reprendre": "DOWNLOAD FORTSETZEN",
        "reessayer": "ERNEUT VERSUCHEN",
        "annuler": "ABBRECHEN",
        "supprimer": "KARTEN LÖSCHEN",
        "enCours": "$recus MB von $total MB",
        "verification": "Karte wird geprüft",
        "pretes": "Karten offline bereit",
        "pretesPoids": "$mo MB auf dem Telefon",
        "libere": "Karten gelöscht, Speicher freigegeben.",
        "supprimerTitre": "Karten löschen?",
        "supprimerCorps": "Die Karten werden vom Telefon entfernt, um Speicher freizugeben. Sie können sie erneut herunterladen.",
        "supprimerAnnuler": "Abbrechen",
        "supprimerConfirmer": "Löschen",
        "horsWifiTitre": "$mo MB über Ihr Datenvolumen?",
        "horsWifiCorps": "Sie sind nicht im WLAN. Die Karten einer Route können ein Mobilfunkvolumen stark belasten.",
        "horsWifiAttendre": "Auf WLAN warten",
        "horsWifiContinuer": "Trotzdem herunterladen",
        "refus": {
            "niveauInsuffisant": "Die Karten kommen, wenn Sie die Route zum Wandern vorbereiten.",
            "sentierInconnu": "Diese Route ist noch nicht auf Ihrem Telefon. Laden Sie sie aus der Wegeliste.",
            "aucuneCartePubliee": "Für diese Route ist noch keine Offline-Karte veröffentlicht. Der Track bleibt verfügbar.",
            "droitDeRealiserManquant": "Offline-Karten gehören zur gekauften Route.",
            "horsLigne": "Ohne Netz lässt sich keine Karte laden. Verbinden Sie sich, dann erneut versuchen.",
            "stockageIndisponible": "Das Telefon hat nicht geantwortet. Erneut versuchen; wenn es bleibt, Telefon neu starten.",
        },
        "echec": {
            "reseau": "Die Verbindung wurde unterbrochen. Das Geladene bleibt erhalten: jederzeit fortsetzen.",
            "empreinteInvalide": "Die empfangene Karte passt nicht zur veröffentlichten: sie wurde verworfen. Erneut versuchen.",
            "tailleInattendue": "Die empfangene Karte ist unvollständig: sie wurde verworfen. Erneut versuchen.",
            "plusDePlace": "Auf dem Telefon ist kein Platz mehr. Speicher freigeben, dann fortsetzen.",
            "ecritureImpossible": "Das Schreiben auf das Telefon ist fehlgeschlagen. Das Geladene bleibt: fortsetzen.",
            "stockageIndisponible": "Das Telefon hat seinen Speicher nicht freigegeben. Erneut versuchen; wenn es bleibt, neu starten.",
            "annulee": "Download abgebrochen. Das bereits Geladene bleibt erhalten.",
        },
        "demoIndisponible": "Der Kartendownload ist während der Demo nicht verfügbar.",
        "a11y": {
            "bouton": "Die Karten der gesamten Route herunterladen",
            "progression": "Karten werden geladen: $pourcent %",
        },
    },
    "it": {
        "title": "Mappe offline",
        "intro": "Un solo download: le mappe di tutto il percorso, per camminare senza rete.",
        "unSeulGeste": "Tutto il percorso in una volta, nessun pezzo da scegliere.",
        "poids": "$mo MB da scaricare",
        "poidsTotal": "Peso totale del percorso: $mo MB",
        "reprise": "$mo MB sono già sul telefono: la ripresa scaricherà solo il resto.",
        "telecharger": "SCARICA LE MAPPE DEL PERCORSO",
        "reprendre": "RIPRENDI LO SCARICAMENTO",
        "reessayer": "RIPROVA",
        "annuler": "ANNULLA",
        "supprimer": "ELIMINA LE MAPPE",
        "enCours": "$recus MB su $total MB",
        "verification": "Verifica della mappa",
        "pretes": "Mappe pronte offline",
        "pretesPoids": "$mo MB sul telefono",
        "libere": "Mappe eliminate, spazio liberato.",
        "supprimerTitre": "Eliminare le mappe?",
        "supprimerCorps": "Le mappe saranno rimosse dal telefono per liberare spazio. Potrai scaricarle di nuovo.",
        "supprimerAnnuler": "Annulla",
        "supprimerConfirmer": "Elimina",
        "horsWifiTitre": "$mo MB sul tuo piano dati?",
        "horsWifiCorps": "Non sei in Wi-Fi. Le mappe di un percorso possono pesare molto su un piano mobile.",
        "horsWifiAttendre": "Aspetta il Wi-Fi",
        "horsWifiContinuer": "Scarica comunque",
        "refus": {
            "niveauInsuffisant": "Le mappe arrivano quando prepari il percorso per camminarlo davvero.",
            "sentierInconnu": "Questo percorso non è ancora sul telefono. Scaricalo dalla lista dei sentieri.",
            "aucuneCartePubliee": "Nessuna mappa offline è ancora pubblicata per questo percorso. Il tracciato resta disponibile.",
            "droitDeRealiserManquant": "Le mappe offline fanno parte del percorso acquistato.",
            "horsLigne": "Senza rete una mappa non può essere scaricata. Riconnettiti, poi riprova.",
            "stockageIndisponible": "Il telefono non ha risposto. Riprova; se insiste, riavvialo.",
        },
        "echec": {
            "reseau": "La connessione si è interrotta. Ciò che è già scaricato è conservato: riprendi quando vuoi.",
            "empreinteInvalide": "La mappa ricevuta non corrisponde a quella pubblicata: è stata scartata. Riprova.",
            "tailleInattendue": "La mappa ricevuta è incompleta: è stata scartata. Riprova.",
            "plusDePlace": "Non c'è più spazio sul telefono. Libera spazio, poi riprendi.",
            "ecritureImpossible": "La scrittura sul telefono è fallita. Ciò che è scaricato è conservato: riprendi.",
            "stockageIndisponible": "Il telefono non ha reso il suo spazio di archiviazione. Riprova; se insiste, riavvialo.",
            "annulee": "Scaricamento annullato. Ciò che è già scaricato è conservato.",
        },
        "demoIndisponible": "Lo scaricamento delle mappe non è disponibile durante la dimostrazione.",
        "a11y": {
            "bouton": "Scarica le mappe di tutto il percorso",
            "progression": "Scaricamento mappe: $pourcent %",
        },
    },
    "es": {
        "title": "Mapas sin conexión",
        "intro": "Una sola descarga: los mapas de todo el recorrido, para caminar sin cobertura.",
        "unSeulGeste": "Todo el recorrido de una vez, sin trozos que elegir.",
        "poids": "$mo MB por descargar",
        "poidsTotal": "Peso total del recorrido: $mo MB",
        "reprise": "$mo MB ya están en el teléfono: al reanudar solo se descargará el resto.",
        "telecharger": "DESCARGAR LOS MAPAS DEL RECORRIDO",
        "reprendre": "REANUDAR LA DESCARGA",
        "reessayer": "VOLVER A INTENTAR",
        "annuler": "CANCELAR",
        "supprimer": "ELIMINAR LOS MAPAS",
        "enCours": "$recus MB de $total MB",
        "verification": "Comprobación del mapa",
        "pretes": "Mapas listos sin conexión",
        "pretesPoids": "$mo MB en el teléfono",
        "libere": "Mapas eliminados, espacio liberado.",
        "supprimerTitre": "¿Eliminar los mapas?",
        "supprimerCorps": "Los mapas se retirarán del teléfono para liberar espacio. Podrás volver a descargarlos.",
        "supprimerAnnuler": "Cancelar",
        "supprimerConfirmer": "Eliminar",
        "horsWifiTitre": "¿$mo MB de tus datos móviles?",
        "horsWifiCorps": "No estás en Wi-Fi. Los mapas de un recorrido pueden pesar mucho en una tarifa móvil.",
        "horsWifiAttendre": "Esperar el Wi-Fi",
        "horsWifiContinuer": "Descargar igualmente",
        "refus": {
            "niveauInsuffisant": "Los mapas bajan cuando preparas el recorrido para caminarlo de verdad.",
            "sentierInconnu": "Este recorrido aún no está en tu teléfono. Descárgalo desde la lista de senderos.",
            "aucuneCartePubliee": "Todavía no hay mapa sin conexión publicado para este recorrido. El trazado sigue disponible.",
            "droitDeRealiserManquant": "Los mapas sin conexión forman parte del recorrido comprado.",
            "horsLigne": "Sin cobertura no se puede descargar un mapa. Conéctate y vuelve a intentarlo.",
            "stockageIndisponible": "El teléfono no ha respondido. Vuelve a intentarlo; si insiste, reinícialo.",
        },
        "echec": {
            "reseau": "Se ha cortado la conexión. Lo ya descargado se conserva: reanuda cuando quieras.",
            "empreinteInvalide": "El mapa recibido no coincide con el publicado: se ha descartado. Vuelve a intentarlo.",
            "tailleInattendue": "El mapa recibido está incompleto: se ha descartado. Vuelve a intentarlo.",
            "plusDePlace": "No queda espacio en el teléfono. Libera espacio y reanuda.",
            "ecritureImpossible": "La escritura en el teléfono ha fallado. Lo descargado se conserva: reanuda.",
            "stockageIndisponible": "El teléfono no ha entregado su almacenamiento. Vuelve a intentarlo; si insiste, reinícialo.",
            "annulee": "Descarga cancelada. Lo ya descargado se conserva.",
        },
        "demoIndisponible": "La descarga de los mapas no está disponible durante la demostración.",
        "a11y": {
            "bouton": "Descargar los mapas de todo el recorrido",
            "progression": "Descarga de mapas: $pourcent %",
        },
    },
}

HUB = {
    "fr": ("Cartes hors ligne", "Télécharger les cartes du circuit"),
    "en": ("Offline maps", "Download the maps for the route"),
    "de": ("Offline-Karten", "Karten der Route herunterladen"),
    "it": ("Mappe offline", "Scarica le mappe del percorso"),
    "es": ("Mapas sin conexión", "Descargar los mapas del recorrido"),
}


def renommer(dictionnaire, ancien, nouveau, valeur):
    """Remplace `ancien` par `nouveau` EN GARDANT SA PLACE dans l'ordre."""
    if ancien not in dictionnaire:
        return dictionnaire
    sortie = collections.OrderedDict()
    for cle, val in dictionnaire.items():
        if cle == ancien:
            sortie[nouveau] = valeur
        else:
            sortie[cle] = val
    return sortie


def main():
    for langue in ("fr", "en", "de", "it", "es"):
        chemin = os.path.join(BASE, "%s.i18n.json" % langue)
        with io.open(chemin, encoding="utf-8") as fichier:
            data = json.load(fichier, object_pairs_hook=collections.OrderedDict)

        data = renommer(data, "packs", "cartesHorsLigne", CARTES[langue])
        if "cartesHorsLigne" not in data:
            data["cartesHorsLigne"] = CARTES[langue]

        cartes_hub = data.get("hub", {}).get("cards")
        if cartes_hub is not None:
            titre, sous_titre = HUB[langue]
            cartes_hub = renommer(cartes_hub, "packs", "cartes", titre)
            cartes_hub = renommer(cartes_hub, "packsSub", "cartesSub", sous_titre)
            data["hub"]["cards"] = cartes_hub

        with io.open(chemin, "w", encoding="utf-8", newline="\n") as fichier:
            json.dump(data, fichier, ensure_ascii=False, indent=2)
            fichier.write("\n")
        print("ok %s" % langue)


if __name__ == "__main__":
    main()
