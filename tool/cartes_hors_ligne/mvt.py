"""LECTURE D UNE TUILE VECTORIELLE MAPBOX (MVT v2), SANS DEPENDANCE.

POURQUOI CE FICHIER EXISTE. La chaine de fabrication des cartes hors ligne de
StepWays part d un extrait OpenStreetMap, le transforme en tuiles VECTORIELLES
avec Planetiler (Java), puis DESSINE ces tuiles en PNG pour les ranger dans un
`.mbtiles` RASTER — le seul format que la carte de l application sait lire
(`flutter_map_mbtiles` -> `MbTilesTileProvider`).

Le maillon « lire le vectoriel » a besoin d un decodeur protobuf. La machine de
fabrication n a ni `protobuf`, ni `mapbox_vector_tile`, ni compilateur C : le
decodeur est donc ecrit ici, en Python pur. Ce n est pas un choix d elegance,
c est la seule facon d avoir une chaine REPRODUCTIBLE sans demander a Christophe
d installer quoi que ce soit.

SOURCES (gravees avant d ecrire, regle 6178) :
  * Specification Mapbox Vector Tile 2.1 —
    https://github.com/mapbox/vector-tile-spec/blob/master/2.1/README.md
    (numeros de champs, commandes de geometrie MoveTo=1 / LineTo=2 / ClosePath=7,
    encodage en zigzag des parametres, sens des anneaux : exterieur horaire).
  * Encodage protobuf (varint, zigzag, types de fil) —
    https://protobuf.dev/programming-guides/encoding/

CE QUE CE DECODEUR NE FAIT PAS. Il ne valide pas la tuile et n ecrit rien : il
LIT ce que Planetiler a produit, sur la machine de fabrication, hors du
telephone. Une tuile illisible fait lever — c est voulu : une carte a trous ne
doit pas se fabriquer en silence.
"""

from __future__ import annotations

from dataclasses import dataclass, field

# Types de geometrie de la specification (champ 3 d une Feature).
INCONNU = 0
POINT = 1
LIGNE = 2
POLYGONE = 3


def _varint(buf: bytes, i: int) -> tuple[int, int]:
    """Lit un varint a la position [i]. Rend (valeur, position suivante)."""
    resultat = 0
    decalage = 0
    while True:
        octet = buf[i]
        i += 1
        resultat |= (octet & 0x7F) << decalage
        if not octet & 0x80:
            return resultat, i
        decalage += 7


def _zigzag(valeur: int) -> int:
    """Decodage zigzag : les parametres de geometrie sont signes."""
    return (valeur >> 1) ^ (-(valeur & 1))


def _champs(buf: bytes, debut: int, fin: int):
    """Parcourt les champs protobuf de [debut] a [fin].

    Rend (numero_de_champ, type_de_fil, charge) ou la charge est un entier pour
    les varints et un couple (debut, fin) pour les champs a longueur prefixee.
    """
    i = debut
    while i < fin:
        cle, i = _varint(buf, i)
        champ, fil = cle >> 3, cle & 7
        if fil == 0:  # varint
            valeur, i = _varint(buf, i)
            yield champ, fil, valeur
        elif fil == 2:  # longueur prefixee
            longueur, i = _varint(buf, i)
            yield champ, fil, (i, i + longueur)
            i += longueur
        elif fil == 5:  # 32 bits
            yield champ, fil, (i, i + 4)
            i += 4
        elif fil == 1:  # 64 bits
            yield champ, fil, (i, i + 8)
            i += 8
        else:  # pragma: no cover - groupes protobuf, absents de MVT
            raise ValueError(f"type de fil protobuf inattendu : {fil}")


def _paquet_de_varints(buf: bytes, debut: int, fin: int) -> list[int]:
    valeurs: list[int] = []
    i = debut
    while i < fin:
        valeur, i = _varint(buf, i)
        valeurs.append(valeur)
    return valeurs


def _valeur(buf: bytes, debut: int, fin: int):
    """Une `Value` de la specification : une seule des sept variantes est posee."""
    import struct

    for champ, fil, charge in _champs(buf, debut, fin):
        if champ == 1 and fil == 2:  # string
            d, f = charge
            return buf[d:f].decode("utf-8", "replace")
        if champ == 2 and fil == 5:  # float
            d, f = charge
            return struct.unpack("<f", buf[d:f])[0]
        if champ == 3 and fil == 1:  # double
            d, f = charge
            return struct.unpack("<d", buf[d:f])[0]
        if champ == 4 and fil == 0:  # int64
            return charge if charge < (1 << 63) else charge - (1 << 64)
        if champ == 5 and fil == 0:  # uint64
            return charge
        if champ == 6 and fil == 0:  # sint64
            return _zigzag(charge)
        if champ == 7 and fil == 0:  # bool
            return bool(charge)
    return None


@dataclass
class Objet:
    """Un objet d une tuile : son type, ses attributs, sa geometrie brute."""

    type: int
    attributs: dict
    # Pour un POINT : une liste de points. Pour une LIGNE : une liste de lignes.
    # Pour un POLYGONE : une liste d anneaux, dans l ordre du fichier (un
    # anneau exterieur est suivi de ses trous).
    parties: list[list[tuple[float, float]]] = field(default_factory=list)


@dataclass
class Couche:
    """Une couche de la tuile (`water`, `transportation`, `place`...)."""

    nom: str
    etendue: int
    objets: list[Objet] = field(default_factory=list)


def _geometrie(commandes: list[int], type_geom: int) -> list[list[tuple[float, float]]]:
    """Traduit les commandes de la specification en listes de points.

    Les coordonnees restent dans l unite de la tuile (0..etendue), l appelant
    fait la mise a l echelle : c est lui qui sait a quelle taille il dessine.
    """
    parties: list[list[tuple[float, float]]] = []
    courante: list[tuple[float, float]] = []
    x = y = 0
    i = 0
    n = len(commandes)
    while i < n:
        entete = commandes[i]
        i += 1
        identifiant, nombre = entete & 7, entete >> 3
        if identifiant == 1:  # MoveTo
            for _ in range(nombre):
                x += _zigzag(commandes[i])
                y += _zigzag(commandes[i + 1])
                i += 2
                if courante:
                    parties.append(courante)
                courante = [(float(x), float(y))]
            if type_geom == POINT and courante:
                # Un multipoint pose un MoveTo par point : chacun est une partie.
                parties.append(courante)
                courante = []
        elif identifiant == 2:  # LineTo
            for _ in range(nombre):
                x += _zigzag(commandes[i])
                y += _zigzag(commandes[i + 1])
                i += 2
                courante.append((float(x), float(y)))
        elif identifiant == 7:  # ClosePath
            if courante:
                courante.append(courante[0])
                parties.append(courante)
                courante = []
        else:  # pragma: no cover
            raise ValueError(f"commande de geometrie inconnue : {identifiant}")
    if courante:
        parties.append(courante)
    return parties


def lire_tuile(donnees: bytes) -> dict[str, Couche]:
    """Decode une tuile MVT et rend ses couches, par nom."""
    couches: dict[str, Couche] = {}
    for champ, fil, charge in _champs(donnees, 0, len(donnees)):
        if champ != 3 or fil != 2:
            continue
        debut, fin = charge
        couche = _lire_couche(donnees, debut, fin)
        couches[couche.nom] = couche
    return couches


def _lire_couche(buf: bytes, debut: int, fin: int) -> Couche:
    nom = ""
    etendue = 4096
    cles: list[str] = []
    valeurs: list = []
    objets_bruts: list[tuple[int, int]] = []

    for champ, fil, charge in _champs(buf, debut, fin):
        if champ == 1 and fil == 2:
            d, f = charge
            nom = buf[d:f].decode("utf-8", "replace")
        elif champ == 2 and fil == 2:
            objets_bruts.append(charge)
        elif champ == 3 and fil == 2:
            d, f = charge
            cles.append(buf[d:f].decode("utf-8", "replace"))
        elif champ == 4 and fil == 2:
            d, f = charge
            valeurs.append(_valeur(buf, d, f))
        elif champ == 5 and fil == 0:
            etendue = charge

    couche = Couche(nom=nom, etendue=etendue)
    for d, f in objets_bruts:
        couche.objets.append(_lire_objet(buf, d, f, cles, valeurs))
    return couche


def _lire_objet(buf: bytes, debut: int, fin: int, cles: list[str], valeurs: list) -> Objet:
    type_geom = INCONNU
    etiquettes: list[int] = []
    commandes: list[int] = []

    for champ, fil, charge in _champs(buf, debut, fin):
        if champ == 2 and fil == 2:
            d, f = charge
            etiquettes.extend(_paquet_de_varints(buf, d, f))
        elif champ == 2 and fil == 0:
            etiquettes.append(charge)
        elif champ == 3 and fil == 0:
            type_geom = charge
        elif champ == 4 and fil == 2:
            d, f = charge
            commandes.extend(_paquet_de_varints(buf, d, f))
        elif champ == 4 and fil == 0:
            commandes.append(charge)

    attributs: dict = {}
    for i in range(0, len(etiquettes) - 1, 2):
        indice_cle, indice_valeur = etiquettes[i], etiquettes[i + 1]
        if indice_cle < len(cles) and indice_valeur < len(valeurs):
            attributs[cles[indice_cle]] = valeurs[indice_valeur]

    return Objet(type=type_geom, attributs=attributs, parties=_geometrie(commandes, type_geom))


def aire_signee(anneau: list[tuple[float, float]]) -> float:
    """Aire signee d un anneau, formule du lacet.

    EN COORDONNEES D ECRAN (y VERS LE BAS), UN ANNEAU EXTERIEUR EST HORAIRE et
    son aire signee est POSITIVE ; un trou est anti-horaire, donc negatif. C est
    la regle de la specification 2.1 (§4.3.3.3), et c est elle qui permet de
    distinguer un lac d une ile DANS le lac sans rien deviner.
    """
    total = 0.0
    for i in range(len(anneau) - 1):
        x1, y1 = anneau[i]
        x2, y2 = anneau[i + 1]
        total += x1 * y2 - x2 * y1
    return total / 2.0
