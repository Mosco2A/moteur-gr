"""DESSINE DES TUILES RASTER (PNG) DEPUIS DES TUILES VECTORIELLES OSM.

CE QUE FAIT CE FICHIER, ET POURQUOI IL EXISTE. La carte de StepWays lit un
`.mbtiles` RASTER (`flutter_map_mbtiles` 1.0.4 -> `MbTilesTileProvider` ->
paquet `mbtiles` 0.4.2 : une image par tuile). Personne ne vend ni ne donne un
tel fichier pour la Corse sans condition : le telechargement en masse de
`tile.openstreetmap.org` est INTERDIT par la politique d usage d OSM, et les
loueurs interdisent la redistribution du fichier. La decision du lot 608 est donc
de FABRIQUER les tuiles depuis un extrait OpenStreetMap — ODbL, oeuvre produite,
attribution seule obligation.

Fabriquer du raster depuis un `.osm.pbf` demande un moteur de rendu. Aucun
n existe sur la machine de fabrication (ni mapnik, ni GDAL, ni docker, ni QGIS ;
mesure du 30/09). La chaine retenue coupe le probleme en deux :

  1. PLANETILER (Java, officiel, deja utilise par OpenMapTiles) transforme
     l extrait OSM en tuiles VECTORIELLES de schema OpenMapTiles. Il fait tout le
     travail difficile : assemblage du trait de cote, multipolygones d eau,
     generalisation par niveau de zoom, choix des objets a garder.
  2. CE FICHIER dessine ces tuiles vectorielles en PNG avec Pillow, puis les
     range dans un `.mbtiles` raster.

POURQUOI UN DESSIN A NOUS PLUTOT QU UN NAVIGATEUR SANS TETE. La voie habituelle
(MapLibre GL JS dans un Chromium sans tete) exige un navigateur, WebGL logiciel,
un jeu de glyphes et un jeu de sprites servis en local : quatre dependances de
plus, toutes fragiles sur Windows, pour un rendu qu on ne maitrise pas mieux.
Pillow et Python suffisent, et le style vit dans un seul fichier lisible.

LE STYLE N EST PAS COPIE. Les couleurs et les epaisseurs ci-dessous sont
choisies pour la RANDONNEE : fond clair, bois lisibles, sentiers et chemins
tires en trait tirete brun, sommets nommes avec leur altitude. Aucune feuille de
style d un tiers n est reprise.

SOURCES (gravees avant production, regle 6178) :
  * Planetiler — https://github.com/onthegomap/planetiler (Apache-2.0)
  * Schema OpenMapTiles (noms de couches, `class`, `subclass`, `rank`) —
    https://openmaptiles.org/schema/
  * Specification MBTiles 1.3 (table `tiles`, `tile_row` en TMS, `metadata`) —
    https://github.com/mapbox/mbtiles-spec/blob/master/1.3/spec.md
  * ODbL 1.0, oeuvre produite et attribution —
    https://www.openstreetmap.org/copyright
  * Noto Sans, licence SIL OFL 1.1 — https://github.com/google/fonts

L AXE Y DES TUILES : `tile_row` DE LA TABLE EST EN TMS (origine en bas), pendant
que le monde entier compte en XYZ (origine en haut). La conversion est faite ICI,
a l ecriture comme a la lecture, et elle est verifiee : `flutter_map_mbtiles`
calcule `tmsY = (1 << z) - 1 - y` avant d interroger la base — si on ecrivait en
XYZ, la carte du randonneur serait retournee.
"""

from __future__ import annotations

import gzip
import io
import math
import sqlite3
import time
from dataclasses import dataclass

from PIL import Image, ImageDraw, ImageFont

import mvt

TAILLE_TUILE = 256

# ---------------------------------------------------------------------------
# LE STYLE
# ---------------------------------------------------------------------------

FOND = (242, 239, 232)

TEINTES_LANDCOVER = {
    "wood": (198, 221, 186),
    "grass": (215, 231, 202),
    "farmland": (238, 240, 211),
    "rock": (226, 222, 214),
    "sand": (245, 234, 199),
    "wetland": (208, 226, 220),
    "ice": (238, 246, 250),
}

TEINTES_LANDUSE = {
    "residential": (232, 228, 221),
    "industrial": (233, 224, 229),
    "commercial": (238, 228, 226),
    "retail": (240, 226, 222),
    "cemetery": (204, 217, 195),
    "school": (233, 229, 214),
    "university": (233, 229, 214),
    "hospital": (240, 226, 226),
    "quarry": (221, 216, 209),
    "military": (232, 222, 214),
    "pitch": (208, 229, 200),
    "stadium": (208, 229, 200),
}

EAU = (163, 204, 226)
EAU_BORD = (137, 181, 208)
PARC_BORD = (150, 190, 140)
BATI = (213, 204, 194)
BATI_BORD = (194, 182, 170)
RAIL = (146, 146, 146)

# Chaque route : (couleur de remplissage, couleur de gaine, largeur de reference
# a z13 en pixels finaux, tirets ou None).
ROUTES = {
    "motorway": ((232, 146, 106), (198, 108, 78), 2.2, None),
    "trunk": ((247, 178, 138), (206, 138, 100), 2.0, None),
    "primary": ((252, 213, 163), (203, 160, 110), 1.8, None),
    "secondary": ((247, 249, 190), (186, 189, 132), 1.5, None),
    "tertiary": ((255, 255, 255), (186, 186, 186), 1.3, None),
    "minor": ((255, 255, 255), (194, 194, 194), 1.0, None),
    "service": ((255, 255, 255), (203, 203, 203), 0.8, None),
    "track": ((176, 138, 96), None, 0.9, (5.0, 3.0)),
    "path": ((150, 104, 72), None, 0.8, (3.5, 2.5)),
    "raceway": ((255, 255, 255), (194, 194, 194), 0.9, None),
}

# Ordre de dessin : du moins important au plus important. Une route majeure doit
# passer PAR-DESSUS une piste, jamais l inverse.
ORDRE_ROUTES = [
    "path",
    "track",
    "service",
    "minor",
    "raceway",
    "tertiary",
    "secondary",
    "primary",
    "trunk",
    "motorway",
]

# Depuis quel zoom une classe de route apparait. Planetiler filtre deja
# beaucoup ; ce second filtre evite une carte illisible a z12-13, ou une piste
# dessinee a 0,4 pixel ne fait que salir l image.
ZOOM_MINI_ROUTES = {
    "path": 14,
    "track": 13,
    "service": 14,
    "minor": 12,
    "raceway": 14,
    "tertiary": 11,
    "secondary": 10,
    "primary": 10,
    "trunk": 10,
    "motorway": 10,
}

# Depuis quel zoom le nom d un lieu s affiche, et a quelle taille (pixels finaux).
LIEUX = {
    "city": (10, 13.0, True),
    "town": (10, 11.5, True),
    "island": (11, 9.5, False),
    "village": (12, 10.0, False),
    "suburb": (13, 9.5, False),
    "hamlet": (13, 8.5, False),
    "neighbourhood": (14, 8.5, False),
    "isolated_dwelling": (15, 8.0, False),
}

TEXTE = (60, 56, 52)
TEXTE_EAU = (60, 110, 150)
HALO = (255, 255, 255)
SOMMET = (120, 96, 72)


def _largeur(reference: float, zoom: int) -> float:
    """Largeur d un trait a [zoom], depuis sa largeur de reference a z13.

    Une largeur constante donnerait une toile d araignee a z15 et une bouillie a
    z11. Le facteur 1,45 par niveau suit la densite : deux fois plus de detail
    par niveau, un trait un peu plus fin que double.
    """
    return max(0.7, reference * (1.45 ** (zoom - 13)))


# ---------------------------------------------------------------------------
# LE DESSIN
# ---------------------------------------------------------------------------


@dataclass
class _Etiquette:
    """Un texte a poser, et la place qu il prend."""

    x: float
    y: float
    texte: str
    taille: float
    gras: bool
    couleur: tuple
    ordre: float


class Rendeur:
    """Dessine les tuiles raster d une emprise, par metatuiles.

    POURQUOI DES METATUILES, ET CE N EST PAS UNE OPTIMISATION. Une tuile dessinee
    seule coupe tout ce qui la depasse : un nom de village a cheval sur deux
    tuiles apparaitrait tronque des deux cotes, et une route perdrait sa jointure
    au bord. On dessine donc un carre de [cote] tuiles ENTOURE d une couronne
    d une tuile, puis on decoupe le centre : chaque pixel livre a ete dessine avec
    ses voisins sous les yeux.
    """

    def __init__(
        self,
        chemin_vecteur: str,
        police: str,
        cote: int = 4,
        surechantillon: int = 2,
    ) -> None:
        self._base = sqlite3.connect(chemin_vecteur)
        self._cote = cote
        self._s = surechantillon
        self._police = police
        self._cache_polices: dict[tuple[float, bool], ImageFont.FreeTypeFont] = {}

    def fermer(self) -> None:
        self._base.close()

    # -- lecture du vectoriel ------------------------------------------------

    def _tuile_vecteur(self, z: int, x: int, y: int):
        ligne_tms = (1 << z) - 1 - y
        r = self._base.execute(
            "SELECT tile_data FROM tiles WHERE zoom_level=? AND tile_column=? AND tile_row=?",
            (z, x, ligne_tms),
        ).fetchone()
        if r is None:
            return None
        donnees = r[0]
        if donnees[:2] == b"\x1f\x8b":
            donnees = gzip.decompress(donnees)
        return mvt.lire_tuile(donnees)

    def _fonte(self, taille: float, gras: bool) -> ImageFont.FreeTypeFont:
        cle = (round(taille, 1), gras)
        if cle not in self._cache_polices:
            fonte = ImageFont.truetype(self._police, int(round(taille)))
            if gras:
                try:
                    fonte.set_variation_by_name("Bold")
                except Exception:  # pragma: no cover - police statique
                    pass
            self._cache_polices[cle] = fonte
        return self._cache_polices[cle]

    # -- une metatuile -------------------------------------------------------

    def dessiner_metatuile(self, z: int, x0: int, y0: int, nx: int, ny: int):
        """Dessine le carre de tuiles [x0..x0+nx-1] x [y0..y0+ny-1] au zoom [z].

        Rend un dictionnaire (x, y) -> image PNG en octets.
        """
        s = self._s
        cote_px = TAILLE_TUILE * s
        # Fenetre elargie d une tuile de chaque cote (la couronne).
        fx0, fy0 = x0 - 1, y0 - 1
        fnx, fny = nx + 2, ny + 2
        largeur, hauteur = fnx * cote_px, fny * cote_px

        toile = Image.new("RGB", (largeur, hauteur), FOND)
        dessin = ImageDraw.Draw(toile)

        # Chargement des tuiles vectorielles de la fenetre, une seule fois.
        tuiles = {}
        maxi = 1 << z
        for tx in range(fx0, fx0 + fnx):
            for ty in range(fy0, fy0 + fny):
                if tx < 0 or ty < 0 or tx >= maxi or ty >= maxi:
                    continue
                couches = self._tuile_vecteur(z, tx, ty)
                if couches is not None:
                    tuiles[(tx, ty)] = couches

        def points(objet_parties, tx, ty, etendue):
            """Coordonnees de la tuile (tx, ty) vers la toile."""
            ox = (tx - fx0) * cote_px
            oy = (ty - fy0) * cote_px
            facteur = cote_px / etendue
            return [
                [(ox + px * facteur, oy + py * facteur) for px, py in partie]
                for partie in objet_parties
            ]

        etiquettes: list[_Etiquette] = []

        # 1. Couvertures du sol, puis usages du sol.
        for nom_couche, teintes in (("landcover", TEINTES_LANDCOVER), ("landuse", TEINTES_LANDUSE)):
            for classe, couleur in teintes.items():
                masque = None
                for (tx, ty), couches in tuiles.items():
                    couche = couches.get(nom_couche)
                    if couche is None:
                        continue
                    for objet in couche.objets:
                        if objet.type != mvt.POLYGONE or objet.attributs.get("class") != classe:
                            continue
                        if masque is None:
                            masque = Image.new("L", (largeur, hauteur), 0)
                            dm = ImageDraw.Draw(masque)
                        self._poser_polygone(dm, points(objet.parties, tx, ty, couche.etendue))
                if masque is not None:
                    toile.paste(couleur, mask=masque)

        # 2. LES ESPACES PROTEGES NE SONT PAS DESSINES, ET C EST UNE MESURE, PAS UN
        #    OUBLI. Un essai de rendu du 30/09 les a tires en contour : le parc
        #    naturel regional de Corse couvre presque toute l emprise, et chaque
        #    tuile vectorielle n en porte que le MORCEAU DECOUPE A SES BORDS. Le
        #    contour dessinait donc le rectangle de decoupe — une grille de traits
        #    verts en travers de la carte, qui n existe nulle part sur le terrain.
        #    Un aplat, lui, verdirait tout et cacherait les bois. La limite d un
        #    parc ne sert pas a marcher : elle sort.

        # 3. L eau : surfaces puis cours d eau.
        masque_eau = None
        for (tx, ty), couches in tuiles.items():
            couche = couches.get("water")
            if couche is None:
                continue
            for objet in couche.objets:
                if objet.type != mvt.POLYGONE:
                    continue
                if objet.attributs.get("class") == "swimming_pool" and z < 15:
                    continue
                if masque_eau is None:
                    masque_eau = Image.new("L", (largeur, hauteur), 0)
                    dme = ImageDraw.Draw(masque_eau)
                self._poser_polygone(dme, points(objet.parties, tx, ty, couche.etendue))
        if masque_eau is not None:
            toile.paste(EAU, mask=masque_eau)
            bord = Image.new("L", (largeur, hauteur), 0)
            db = ImageDraw.Draw(bord)
            for (tx, ty), couches in tuiles.items():
                couche = couches.get("water")
                if couche is None:
                    continue
                for objet in couche.objets:
                    if objet.type != mvt.POLYGONE:
                        continue
                    for anneau in points(objet.parties, tx, ty, couche.etendue):
                        if len(anneau) > 1:
                            db.line(anneau, fill=255, width=max(1, int(0.9 * s)))
            toile.paste(EAU_BORD, mask=bord)

        for (tx, ty), couches in tuiles.items():
            couche = couches.get("waterway")
            if couche is None:
                continue
            for objet in couche.objets:
                if objet.type != mvt.LIGNE:
                    continue
                classe = objet.attributs.get("class")
                if classe in ("river", "canal"):
                    reference = 1.6
                elif classe == "stream":
                    if z < 13:
                        continue
                    reference = 1.0
                else:
                    if z < 14:
                        continue
                    reference = 0.8
                largeur_trait = max(1, int(round(_largeur(reference, z) * s)))
                for ligne in points(objet.parties, tx, ty, couche.etendue):
                    if len(ligne) > 1:
                        dessin.line(ligne, fill=EAU_BORD, width=largeur_trait, joint="curve")

        # 4. Pistes d aerodrome (l aerodrome de Corte-Tavignano, et Ajaccio au bord).
        for (tx, ty), couches in tuiles.items():
            couche = couches.get("aeroway")
            if couche is None:
                continue
            for objet in couche.objets:
                classe = objet.attributs.get("class")
                if objet.type == mvt.POLYGONE and classe in ("aerodrome", "apron"):
                    masque = Image.new("L", (largeur, hauteur), 0)
                    self._poser_polygone(
                        ImageDraw.Draw(masque), points(objet.parties, tx, ty, couche.etendue)
                    )
                    toile.paste((226, 222, 226), mask=masque)
                elif objet.type == mvt.LIGNE and classe in ("runway", "taxiway"):
                    ref = 3.0 if classe == "runway" else 1.0
                    for ligne in points(objet.parties, tx, ty, couche.etendue):
                        if len(ligne) > 1:
                            dessin.line(
                                ligne,
                                fill=(200, 196, 200),
                                width=max(1, int(round(_largeur(ref, z) * s))),
                                joint="curve",
                            )

        # 5. Le bati, a partir de z14 seulement (Planetiler ne le sort pas avant).
        if z >= 14:
            masque_bati = None
            for (tx, ty), couches in tuiles.items():
                couche = couches.get("building")
                if couche is None:
                    continue
                for objet in couche.objets:
                    if objet.type != mvt.POLYGONE:
                        continue
                    if masque_bati is None:
                        masque_bati = Image.new("L", (largeur, hauteur), 0)
                        dmb = ImageDraw.Draw(masque_bati)
                    self._poser_polygone(dmb, points(objet.parties, tx, ty, couche.etendue))
            if masque_bati is not None:
                toile.paste(BATI, mask=masque_bati)

        # 6. Les routes : gaine d abord, remplissage ensuite, classe par classe.
        #    Deux passes par classe, sinon la gaine d une route recouvrirait le
        #    remplissage de la precedente et la carte serait grise.
        for classe in ORDRE_ROUTES:
            if z < ZOOM_MINI_ROUTES.get(classe, 0):
                continue
            remplissage, gaine, reference, tirets = ROUTES[classe]
            largeur_trait = _largeur(reference, z) * s
            lignes: list[list[tuple[float, float]]] = []
            for (tx, ty), couches in tuiles.items():
                couche = couches.get("transportation")
                if couche is None:
                    continue
                for objet in couche.objets:
                    if objet.type != mvt.LIGNE or objet.attributs.get("class") != classe:
                        continue
                    lignes.extend(points(objet.parties, tx, ty, couche.etendue))
            if not lignes:
                continue
            if gaine is not None and largeur_trait >= 1.6:
                epaisseur = max(1, int(round(largeur_trait + 1.4 * s)))
                for ligne in lignes:
                    if len(ligne) > 1:
                        dessin.line(ligne, fill=gaine, width=epaisseur, joint="curve")
            epaisseur = max(1, int(round(largeur_trait)))
            for ligne in lignes:
                if len(ligne) < 2:
                    continue
                if tirets is None:
                    dessin.line(ligne, fill=remplissage, width=epaisseur, joint="curve")
                else:
                    for segment in _tirets(ligne, tirets[0] * s, tirets[1] * s):
                        dessin.line(segment, fill=remplissage, width=epaisseur)

        # 7. Le rail, au-dessus des routes mineures.
        if z >= 11:
            for (tx, ty), couches in tuiles.items():
                couche = couches.get("transportation")
                if couche is None:
                    continue
                for objet in couche.objets:
                    if objet.type != mvt.LIGNE or objet.attributs.get("class") != "rail":
                        continue
                    for ligne in points(objet.parties, tx, ty, couche.etendue):
                        if len(ligne) > 1:
                            dessin.line(
                                ligne,
                                fill=RAIL,
                                width=max(1, int(round(_largeur(1.1, z) * s))),
                                joint="curve",
                            )

        # 8. Les sommets : un point qui compte en randonnee, avec son altitude.
        if z >= 12:
            for (tx, ty), couches in tuiles.items():
                couche = couches.get("mountain_peak")
                if couche is None:
                    continue
                for objet in couche.objets:
                    if objet.type != mvt.POINT:
                        continue
                    if objet.attributs.get("class") not in ("peak", "volcano"):
                        continue
                    rang = objet.attributs.get("rank") or 9
                    if z == 12 and rang > 1:
                        continue
                    if z == 13 and rang > 3:
                        continue
                    nom = _nom(objet.attributs)
                    altitude = objet.attributs.get("ele")
                    for partie in points(objet.parties, tx, ty, couche.etendue):
                        px, py = partie[0]
                        cote_triangle = 2.6 * s
                        dessin.polygon(
                            [
                                (px, py - cote_triangle),
                                (px - cote_triangle, py + cote_triangle * 0.7),
                                (px + cote_triangle, py + cote_triangle * 0.7),
                            ],
                            fill=SOMMET,
                        )
                        if nom:
                            libelle = nom
                            if altitude is not None and z >= 13:
                                libelle = f"{nom} {int(float(altitude))} m"
                            etiquettes.append(
                                _Etiquette(
                                    px,
                                    py + 4.2 * s,
                                    libelle,
                                    8.5,
                                    False,
                                    SOMMET,
                                    2.0 + float(rang),
                                )
                            )

        # 9. Les noms de lieux et de lacs.
        for (tx, ty), couches in tuiles.items():
            couche = couches.get("place")
            if couche is not None:
                for objet in couche.objets:
                    if objet.type != mvt.POINT:
                        continue
                    reglage = LIEUX.get(str(objet.attributs.get("class")))
                    if reglage is None or z < reglage[0]:
                        continue
                    nom = _nom(objet.attributs)
                    if not nom:
                        continue
                    for partie in points(objet.parties, tx, ty, couche.etendue):
                        px, py = partie[0]
                        etiquettes.append(
                            _Etiquette(px, py, nom, reglage[1], reglage[2], TEXTE, reglage[1] * -1)
                        )
            couche = couches.get("water_name")
            if couche is not None and z >= 13:
                for objet in couche.objets:
                    nom = _nom(objet.attributs)
                    if not nom:
                        continue
                    for partie in points(objet.parties, tx, ty, couche.etendue):
                        px, py = partie[0]
                        etiquettes.append(_Etiquette(px, py, nom, 9.0, False, TEXTE_EAU, 5.0))

        self._poser_etiquettes(dessin, etiquettes)

        # 10. Decoupe : on ne garde que le centre, la couronne a fait son travail.
        images: dict[tuple[int, int], bytes] = {}
        for ix in range(nx):
            for iy in range(ny):
                gx = (ix + 1) * cote_px
                gy = (iy + 1) * cote_px
                morceau = toile.crop((gx, gy, gx + cote_px, gy + cote_px))
                if s != 1:
                    morceau = morceau.resize(
                        (TAILLE_TUILE, TAILLE_TUILE), Image.Resampling.LANCZOS
                    )
                # PNG A PALETTE : LE POIDS QUI VOYAGE SUR LE FORFAIT DU RANDONNEUR.
                # Une carte n a pas 16 millions de couleurs, elle en a une
                # trentaine plus l anticrenelage. Mesure du 30/09 : 44 Ko la tuile
                # en couleurs vraies, 13 Ko a palette de 256 — meme image a l oeil,
                # trois fois moins a telecharger sur des milliers de tuiles.
                morceau = morceau.quantize(colors=256, method=Image.Quantize.MEDIANCUT)
                tampon = io.BytesIO()
                morceau.save(tampon, format="PNG", optimize=True)
                images[(x0 + ix, y0 + iy)] = tampon.getvalue()
        return images

    @staticmethod
    def _poser_polygone(dessin_masque: ImageDraw.ImageDraw, anneaux) -> None:
        """Pose un polygone SUR UN MASQUE, trous compris.

        Pillow ne sait pas remplir un polygone troue. On dessine donc les anneaux
        exterieurs a 255 puis les trous a 0 dans un masque, et l appelant colle
        la couleur au travers. Sans cela une ile dans un lac serait bleue, et un
        lac dans une ile serait vert.
        """
        exterieurs = []
        trous = []
        for anneau in anneaux:
            if len(anneau) < 4:
                continue
            (trous if mvt.aire_signee(anneau) < 0 else exterieurs).append(anneau)
        for anneau in exterieurs:
            dessin_masque.polygon(anneau, fill=255)
        for anneau in trous:
            dessin_masque.polygon(anneau, fill=0)

    def _poser_etiquettes(self, dessin: ImageDraw.ImageDraw, etiquettes) -> None:
        """Pose les textes, du plus important au moins important, sans chevauchement.

        L ORDRE EST FIXE ET REPRODUCTIBLE (importance, puis position, puis texte)
        pour qu une metatuile et sa voisine prennent la MEME decision sur une
        etiquette qu elles voient toutes les deux.
        """
        etiquettes.sort(key=lambda e: (e.ordre, round(e.y, 1), round(e.x, 1), e.texte))
        occupes: list[tuple[float, float, float, float]] = []
        for e in etiquettes:
            fonte = self._fonte(e.taille * self._s, e.gras)
            boite = dessin.textbbox((e.x, e.y), e.texte, font=fonte, anchor="ma")
            marge = 1.5 * self._s
            candidat = (boite[0] - marge, boite[1] - marge, boite[2] + marge, boite[3] + marge)
            if any(_chevauche(candidat, pris) for pris in occupes):
                continue
            occupes.append(candidat)
            dessin.text(
                (e.x, e.y),
                e.texte,
                font=fonte,
                fill=e.couleur,
                anchor="ma",
                stroke_width=max(1, int(1.4 * self._s)),
                stroke_fill=HALO,
            )


def _chevauche(a, b) -> bool:
    return not (a[2] < b[0] or b[2] < a[0] or a[3] < b[1] or b[3] < a[1])


def _nom(attributs: dict) -> str:
    """Le nom a afficher : le francais s il existe, sinon le nom local.

    Le corse (`name:co`) est le nom local de beaucoup de sommets ; `name` porte
    deja la valeur locale, et `name:fr` la traduction quand elle existe. On prend
    `name:fr` en premier parce que l application parle francais par defaut, et on
    n invente jamais une translitteration.
    """
    for cle in ("name:fr", "name", "name:latin", "name_int", "name:en"):
        valeur = attributs.get(cle)
        if isinstance(valeur, str) and valeur.strip():
            return valeur.strip()
    return ""


def _tirets(ligne, longueur_trait: float, longueur_vide: float):
    """Coupe une polyligne en segments pour obtenir un trait tirete.

    Pillow ne sait pas dessiner un trait tirete. Les sentiers et les chemins en
    ont besoin : c est ce qui les distingue d une petite route sur une carte de
    randonnee, et cette distinction compte quand on choisit par ou passer.
    """
    segments = []
    courant = []
    reste = longueur_trait
    trace = True
    for i in range(len(ligne) - 1):
        x1, y1 = ligne[i]
        x2, y2 = ligne[i + 1]
        distance = math.hypot(x2 - x1, y2 - y1)
        if distance <= 0:
            continue
        position = 0.0
        while position < distance:
            pas = min(reste, distance - position)
            xa = x1 + (x2 - x1) * (position / distance)
            ya = y1 + (y2 - y1) * (position / distance)
            xb = x1 + (x2 - x1) * ((position + pas) / distance)
            yb = y1 + (y2 - y1) * ((position + pas) / distance)
            if trace:
                if not courant:
                    courant.append((xa, ya))
                courant.append((xb, yb))
            position += pas
            reste -= pas
            if reste <= 1e-9:
                if trace and courant:
                    segments.append(courant)
                    courant = []
                trace = not trace
                reste = longueur_trait if trace else longueur_vide
    if courant:
        segments.append(courant)
    return segments


# ---------------------------------------------------------------------------
# L ECRITURE DU .mbtiles RASTER
# ---------------------------------------------------------------------------


def tuiles_de_l_emprise(ouest: float, sud: float, est: float, nord: float, zoom: int):
    """Bornes de tuiles XYZ couvrant l emprise a [zoom]."""

    def xy(lon: float, lat: float):
        n = 1 << zoom
        x = int((lon + 180.0) / 360.0 * n)
        lat = max(min(lat, 85.05112878), -85.05112878)
        rad = math.radians(lat)
        y = int((1.0 - math.log(math.tan(rad) + 1.0 / math.cos(rad)) / math.pi) / 2.0 * n)
        return max(0, min(n - 1, x)), max(0, min(n - 1, y))

    x0, y1 = xy(ouest, sud)
    x1, y0 = xy(est, nord)
    return x0, y0, x1, y1


def fabriquer(
    chemin_vecteur: str,
    chemin_sortie: str,
    emprise: tuple[float, float, float, float],
    zoom_mini: int,
    zoom_maxi: int,
    police: str,
    nom: str,
    description: str,
    cote_metatuile: int = 4,
    surechantillon: int = 2,
    journal=print,
) -> dict:
    """Dessine toutes les tuiles et ecrit le `.mbtiles` raster. Rend un bilan."""
    ouest, sud, est, nord = emprise
    rendeur = Rendeur(chemin_vecteur, police, cote=cote_metatuile, surechantillon=surechantillon)

    sortie = sqlite3.connect(chemin_sortie)
    sortie.executescript(
        """
        PRAGMA journal_mode=DELETE;
        CREATE TABLE metadata (name text, value text);
        CREATE TABLE tiles (
            zoom_level integer, tile_column integer, tile_row integer, tile_data blob);
        CREATE UNIQUE INDEX tiles_index ON tiles (zoom_level, tile_column, tile_row);
        """
    )

    total = 0
    octets = 0
    debut = time.time()
    for zoom in range(zoom_mini, zoom_maxi + 1):
        x0, y0, x1, y1 = tuiles_de_l_emprise(ouest, sud, est, nord, zoom)
        pour_ce_zoom = 0
        for mx in range(x0, x1 + 1, cote_metatuile):
            for my in range(y0, y1 + 1, cote_metatuile):
                nx = min(cote_metatuile, x1 - mx + 1)
                ny = min(cote_metatuile, y1 - my + 1)
                images = rendeur.dessiner_metatuile(zoom, mx, my, nx, ny)
                lignes = []
                for (tx, ty), png in images.items():
                    lignes.append((zoom, tx, (1 << zoom) - 1 - ty, png))
                    octets += len(png)
                sortie.executemany(
                    "INSERT OR REPLACE INTO tiles (zoom_level, tile_column, tile_row, tile_data)"
                    " VALUES (?,?,?,?)",
                    lignes,
                )
                pour_ce_zoom += len(lignes)
        sortie.commit()
        total += pour_ce_zoom
        journal(
            f"  z{zoom} : {pour_ce_zoom} tuiles ({octets / 1e6:.1f} Mo cumules,"
            f" {time.time() - debut:.0f} s)"
        )

    centre_lon = (ouest + est) / 2
    centre_lat = (sud + nord) / 2
    meta = {
        "name": nom,
        "description": description,
        "format": "png",
        "type": "baselayer",
        "version": "1",
        "minzoom": str(zoom_mini),
        "maxzoom": str(zoom_maxi),
        "bounds": f"{ouest:.6f},{sud:.6f},{est:.6f},{nord:.6f}",
        "center": f"{centre_lon:.6f},{centre_lat:.6f},{zoom_maxi - 2}",
        "attribution": "© OpenStreetMap contributors (ODbL)",
    }
    sortie.executemany("INSERT INTO metadata (name, value) VALUES (?,?)", list(meta.items()))
    sortie.commit()
    sortie.execute("VACUUM")
    sortie.close()
    rendeur.fermer()
    return {"tuiles": total, "octets_png": octets, "secondes": time.time() - debut}
