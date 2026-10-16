# Les couchages a moins de 30 minutes du GR20 qui ne sont pas des fins d etape

Tache 838. Socle : la trace de la tache 837 (9128 points, 183.584 km).

- Source : OpenStreetMap, relation 12484370, licence ODbL
- Modele de terrain : EU-DEM (resolution 25 m)
- Modele de temps de marche EMPLOYE DANS LE TABLEAU : Naismith simplifiee de l application StepWays (lib/core/models/stage_duration.dart : kWalkingKmPerHour = 4.0, kWalkingElevationMPerHour = 400.0) : duree = distance / 4 km/h + denivele positif / 400 m/h ; le denivele negatif ne compte pas
- Second modele de l application, calcule a cote : Naismith raffinee de l application StepWays (lib/features/trek/domain/eta_service.dart : defaultFlatPaceMps = 1.1 m/s, ascentSecondsPerMetre = 3600/600, descentSecondsPerMetre = 10/6) : duree = distance / 1,1 m/s + montee x 6 s/m + descente x 1,67 s/m ; la descente COUTE
- Couloir interroge : 3000 m autour de la trace ; itineraire plafonne a 6000 m de marche
- Seuil de Christophe : 30 minutes DANS CHAQUE SENS

| PK | Nom | Type | Lits | Aller | Retour | D+ aller | D+ retour | Chemin trace | OSM | Statut |
|---|---|---|---|---|---|---|---|---|---|---|
| 0.00 | Bel horizon | hotel | inconnu | 1 min | 1 min | 0 m | 4 m | oui | node/7139293435 | deja fin d etape (depart) |
| 0.00 | Calenzana Camping/Gite d'étape | camping | inconnu | 11 min | 18 min | 2 m | 52 m | oui | way/236843104 | tete de sentier, pas une nuit de plus |
| 0.00 | À l'Ombre du Clocher | chambre d hotes | inconnu | 2 min | 4 min | 0 m | 11 m | oui | node/6431373876 | deja fin d etape (depart) |
| 0.19 | A Casa di paese | meuble | inconnu | 41 min | 34 min | 75 m | 31 m | oui | way/649533712 | au-dela du seuil |
| 0.19 | Gîte d'Étape municipal | auberge | inconnu | 9 min | 17 min | 0 m | 50 m | oui | node/2409034852 | tete de sentier, pas une nuit de plus |
| 0.29 | A Flatta | hotel | inconnu | 1h08 | 49 min | 157 m | 33 m | oui | way/303873183 | au-dela du seuil |
| 11.35 | Refuge | refuge de montagne | inconnu | 0 min | 0 min | 1 m | 0 m | oui | node/12955341201 | deja fin d etape (fin E1) |
| 11.46 | (sans nom dans OpenStreetMap) | abri | inconnu | 2 min | 5 min | 0 m | 19 m | oui | way/1083328604 | deja fin d etape (fin E1) |
| 11.46 | Bivouac de l'Ortu di u Piobbu | camping | inconnu | 2 min | 6 min | 0 m | 21 m | oui | way/237852713 | deja fin d etape (fin E1) |
| 18.62 | Bivouac de Carozzu | camping | inconnu | 0 min | 0 min | 0 m | 2 m | oui | way/237852708 | deja fin d etape (fin E2) |
| 18.68 | Refuge de Carozzu | refuge de montagne | inconnu | 0 min | 0 min | 0 m | 2 m | oui | node/4355620103 | deja fin d etape (fin E2) |
| 18.68 | Refuge de Carozzu | refuge de montagne | 36 lits | 0 min | 0 min | 0 m | 0 m | oui | way/237852703 | deja fin d etape (fin E2) |
| 18.83 | (sans nom dans OpenStreetMap) | abri | inconnu | 1 min | 3 min | 0 m | 14 m | oui | node/4460382850 | deja fin d etape (fin E2) |
| 18.83 | (sans nom dans OpenStreetMap) | abri | inconnu | 2 min | 10 min | 0 m | 48 m | oui | node/13069064777 | NOUVELLE NUIT — un lit au lieu du dortoir |
| 23.59 | Bivouac Haut-Asco | camping | inconnu | 0 min | 0 min | 1 m | 0 m | oui | way/437755712 | deja fin d etape (fin E3) |
| 23.59 | Refuge d'Ascu-Stagnu | refuge de montagne | 32 lits | 1 min | 0 min | 2 m | 0 m | oui | way/118990828 | deja fin d etape (fin E3) |
| 23.70 | Hôtel Restaurant le Chalet | hotel | inconnu | 0 min | 0 min | 0 m | 1 m | oui | way/118908103 | deja fin d etape (fin E3) |
| 24.78 | Camping Monte Cinto | camping | inconnu | 1h00 | 1h57 | 1 m | 378 m | oui | way/977371192 | au-dela du seuil |
| 28.62 | Bergerie de Pulella | bergerie | inconnu | 1h14 | 3h26 | 95 m | 974 m | oui | node/8791280953 | nomme, aucun couchage declare dans OSM |
| 32.02 | Bivouac de Tighiettu | camping | inconnu | 3 min | 2 min | 6 m | 0 m | oui | way/437755707 | deja fin d etape (fin E4) |
| 32.02 | Refuge | refuge de montagne | inconnu | 3 min | 2 min | 8 m | 0 m | oui | node/12955341301 | deja fin d etape (fin E4) |
| 32.02 | Refuge de Tighiettu | refuge de montagne | 36 lits | 4 min | 2 min | 13 m | 0 m | oui | way/437755706 | deja fin d etape (fin E4) |
| 33.17 | Bergerie de Ballone | refuge de montagne | inconnu | 0 min | 1 min | 0 m | 3 m | oui | way/631221944 | NOUVELLE NUIT — coupure de jour nouvelle |
| 33.17 | Bergerie de Tilarba (en ruine) | refuge de montagne | inconnu | 1h10 | 39 min | 261 m | 59 m | oui | node/440374694 | au-dela du seuil |
| 38.29 | Bivouac de Ciottulu di i Mori | camping | inconnu | 0 min | 1 min | 0 m | 6 m | oui | way/437752735 | deja fin d etape (fin E5) |
| 38.37 | Refuge de Ciottulu di i Mori | refuge de montagne | 30 lits | 0 min | 1 min | 0 m | 3 m | oui | way/437752736 | deja fin d etape (fin E5) |
| 40.53 | Bergerie de Tula | bergerie | inconnu | 10 min | 6 min | 30 m | 5 m | oui | node/6722771018 | nomme, aucun couchage declare dans OSM |
| 41.73 | Bergeries de Mazza | bergerie | inconnu | 1h58 | 2h44 | 342 m | 644 m | oui | node/12040145159 | nomme, aucun couchage declare dans OSM |
| 41.73 | Refuge de Puscaghia | refuge de montagne | 15 lits | 1h42 | 2h55 | 236 m | 723 m | oui | way/686967384 | au-dela du seuil |
| 43.49 | Bergeries de Radule | camping | 150 lits | 0 min | 2 min | 0 m | 12 m | oui | node/1935629269 | NOUVELLE NUIT — coupure de jour nouvelle |
| 43.67 | (sans nom dans OpenStreetMap) | refuge non garde | inconnu | 0 min | 0 min | 0 m | 0 m | oui | node/13699902838 | NOUVELLE NUIT — coupure de jour nouvelle |
| 46.77 | Castel De Vergio | refuge de montagne | inconnu | 1 min | 2 min | 0 m | 4 m | oui | way/89697304 | NOUVELLE NUIT — coupure de jour nouvelle |
| 46.77 | Hôtel Castel De Vergio | hotel | 29 lits | 2 min | 2 min | 1 m | 0 m | oui | way/89697301 | NOUVELLE NUIT — coupure de jour nouvelle |
| 46.87 | Castel de Vergio | camping | inconnu | 1 min | 1 min | 2 m | 0 m | oui | way/122022686 | NOUVELLE NUIT — coupure de jour nouvelle |
| 50.47 | AS Niolu | camping | inconnu | 59 min | 1h41 | 12 m | 293 m | oui | node/4958296223 | au-dela du seuil |
| 51.10 | Bergerie d'Albia | bergerie | inconnu | 1h18 | 1h27 | 156 m | 218 m | oui | way/791176718 | nomme, aucun couchage declare dans OSM |
| 56.43 | Bergerie de Colga | refuge non garde | 4 lits | 26 min | 1h17 | 11 m | 352 m | oui | way/307613194 | au-dela du seuil |
| 58.46 | Bergerie des Inzecche | bergerie | inconnu | 1 min | 1 min | 4 m | 0 m | oui | node/4438820139 | nomme, aucun couchage declare dans OSM |
| 58.79 | Bergerie de Ceppu | bergerie | inconnu | 51 min | 1h09 | 26 m | 147 m | oui | node/4957117944 | nomme, aucun couchage declare dans OSM |
| 58.79 | Bergerie ruinée de Ceppu | abri | inconnu | 51 min | 1h09 | 26 m | 148 m | oui | node/8431492473 | au-dela du seuil |
| 61.34 | Bergeries de Vaccaghia | refuge de montagne | inconnu | 0 min | 0 min | 1 m | 0 m | oui | way/297487399 | NOUVELLE NUIT — coupure de jour nouvelle |
| 61.35 | Bivouac de Vaccaghja | camping | inconnu | 3 min | 2 min | 8 m | 0 m | oui | way/437737341 | NOUVELLE NUIT — coupure de jour nouvelle |
| 61.41 | Bergerie de Tramizzole | bergerie | inconnu | 37 min | 1h01 | 14 m | 177 m | oui | way/469986174 | nomme, aucun couchage declare dans OSM |
| 62.64 | Bergerie de Lenze | bergerie | inconnu | 24 min | 17 min | 45 m | 1 m | oui | node/6238729298 | nomme, aucun couchage declare dans OSM |
| 62.64 | Bergerie de Lenze | abri | inconnu | 24 min | 18 min | 45 m | 1 m | oui | way/639198828 | NOUVELLE NUIT — un lit au lieu du dortoir |
| 63.24 | Bergerie de l'Izzola | bergerie | inconnu | 1h00 | 1h46 | 32 m | 340 m | oui | way/121496555 | nomme, aucun couchage declare dans OSM |
| 63.40 | Refuge de Manganu | refuge de montagne | 31 lits | 0 min | 0 min | 0 m | 1 m | oui | way/297485752 | deja fin d etape (fin E6) |
| 63.40 | (sans nom dans OpenStreetMap) | camping | inconnu | 1 min | 0 min | 2 m | 0 m | oui | node/11028460199 | deja fin d etape (fin E6) |
| 67.01 | (sans nom dans OpenStreetMap) | abri | inconnu | 22 min | 1h13 | 0 m | 340 m | oui | way/121296733 | au-dela du seuil |
| 67.01 | Bergerie de Grotelle | bergerie | inconnu | 1h01 | 2h47 | 3 m | 715 m | oui | node/6238290539 | nomme, aucun couchage declare dans OSM |
| 67.01 | Bergerie de Grotelle | bergerie | inconnu | 56 min | 2h39 | 0 m | 686 m | oui | way/121296707 | nomme, aucun couchage declare dans OSM |
| 67.01 | Bergerie de Melo | bergerie | inconnu | 43 min | 2h08 | 0 m | 566 m | oui | way/121296708 | nomme, aucun couchage declare dans OSM |
| 67.01 | Bergerie du Melo | bergerie | inconnu | 44 min | 2h09 | 1 m | 567 m | oui | node/11136735853 | nomme, aucun couchage declare dans OSM |
| 71.76 | Abri Helbronner | abri | inconnu | 2h29 | 46 min | 714 m | 22 m | oui | way/629272829 | au-dela du seuil |
| 71.76 | Bergeries de Muraccioli | bergerie | inconnu | 36 min | 1h07 | 46 m | 252 m | oui | node/6734702625 | nomme, aucun couchage declare dans OSM |
| 71.76 | Bivouac de Petra Piana | camping | inconnu | 1 min | 3 min | 2 m | 12 m | oui | way/437735563 | deja fin d etape (fin E7) |
| 71.76 | Refuge de Petra Piana | refuge de montagne | 25 lits | 1 min | 5 min | 0 m | 26 m | oui | way/297484188 | deja fin d etape (fin E7) |
| 72.64 | Bergeries de Gialgo | bergerie | inconnu | 0 min | 0 min | 0 m | 0 m | oui | node/6286907738 | nomme, aucun couchage declare dans OSM |
| 73.50 | Bergeries de Gialghello | bergerie | inconnu | 57 min | 1h04 | 141 m | 185 m | oui | node/6286830713 | nomme, aucun couchage declare dans OSM |
| 77.90 | Bergerie de Tolla | bergerie | inconnu | 1 min | 1 min | 0 m | 0 m | oui | node/5703388155 | nomme, aucun couchage declare dans OSM |
| 77.90 | Bergerie de Tolla | camping | inconnu | 1 min | 1 min | 0 m | 0 m | oui | way/120874153 | NOUVELLE NUIT — coupure de jour nouvelle |
| 77.93 | Bergerie de Tolla | camping | 20 lits | 1 min | 1 min | 1 m | 0 m | oui | node/4438888372 | NOUVELLE NUIT — coupure de jour nouvelle |
| 81.57 | Bivouac de l'Onda | camping | inconnu | 0 min | 1 min | 0 m | 5 m | oui | way/437735560 | deja fin d etape (fin E8) |
| 81.60 | Refuge de l'Onda | refuge de montagne | 16 lits | 1 min | 1 min | 2 m | 2 m | oui | way/297483737 | deja fin d etape (fin E8) |
| 81.74 | Refuge de L'Onda | refuge de montagne | inconnu | 0 min | 1 min | 0 m | 3 m | oui | way/437735561 | deja fin d etape (fin E8) |
| 87.37 | Bergeries de Porteto | bergerie | inconnu | 4 min | 5 min | 0 m | 8 m | oui | node/6167087145 | nomme, aucun couchage declare dans OSM |
| 88.75 | Bergerie des Pozzi | abri | 8 lits | 1h06 | 36 min | 236 m | 39 m | oui | way/444726168 | au-dela du seuil |
| 88.75 | Bergeries des Pozzi | bergerie | inconnu | 1h08 | 37 min | 249 m | 37 m | oui | node/794865468 | nomme, aucun couchage declare dans OSM |
| 89.16 | Aire de bivouac La Halte Du Prince | camping | inconnu | 23 min | 17 min | 45 m | 6 m | oui | way/446641114 | NOUVELLE NUIT — coupure de jour nouvelle |
| 89.16 | Gite d'Étape Monte d'Oro | auberge | inconnu | 27 min | 20 min | 55 m | 5 m | oui | way/130854308 | NOUVELLE NUIT — coupure de jour nouvelle |
| 89.16 | Hôtel Monte d'Oro | hotel | inconnu | 26 min | 19 min | 54 m | 5 m | oui | way/130854309 | NOUVELLE NUIT — coupure de jour nouvelle |
| 89.16 | La Halte du Prince | auberge | 40 lits | 22 min | 16 min | 46 m | 5 m | oui | node/4438941956 | NOUVELLE NUIT — coupure de jour nouvelle |
| 91.80 | L'Alzarella | auberge | 16 lits | 4 min | 6 min | 0 m | 16 m | oui | node/6506235954 | deja fin d etape (fin E9) |
| 91.80 | L'Alzarella | camping | inconnu | 4 min | 6 min | 0 m | 17 m | oui | way/352050543 | deja fin d etape (fin E9) |
| 91.80 | Le Vizzavona | hotel | inconnu | 4 min | 6 min | 0 m | 12 m | oui | way/692948737 | deja fin d etape (fin E9) |
| 91.99 | Camping Le Soleil | camping | inconnu | 1h13 | 1h39 | 44 m | 220 m | oui | way/130735372 | au-dela du seuil |
| 91.99 | Casa Alta | chambre d hotes | inconnu | 13 min | 16 min | 12 m | 34 m | oui | way/222198640 | NOUVELLE NUIT — un lit au lieu du dortoir |
| 91.99 | Chez Pierrot | chambre d hotes | inconnu | 1h00 | 1h24 | 32 m | 194 m | oui | node/14061007701 | au-dela du seuil |
| 91.99 | Hôtel - Restaurant de la Gare | hotel | inconnu | 4 min | 11 min | 0 m | 46 m | oui | way/692948715 | deja fin d etape (fin E9) |
| 91.99 | U Castellu | hotel | inconnu | 3 min | 2 min | 4 m | 0 m | oui | way/692948728 | NOUVELLE NUIT — un lit au lieu du dortoir |
| 93.27 | Cabane de Tattone | abri | inconnu | 1h43 | 1h29 | 217 m | 128 m | oui | node/10578185198 | au-dela du seuil |
| 97.87 | Bivouac de Bocca Palmente | camping | inconnu | 0 min | 0 min | 1 m | 0 m | oui | way/1344508783 | NOUVELLE NUIT — coupure de jour nouvelle |
| 98.44 | Bergerie d'Alzeta | bergerie | inconnu | 1 min | 0 min | 7 m | 0 m | oui | way/352354188 | nomme, aucun couchage declare dans OSM |
| 98.44 | Bergeries d'Alzeta | camping | inconnu | 1 min | 0 min | 3 m | 0 m | oui | node/8871451503 | NOUVELLE NUIT — coupure de jour nouvelle |
| 100.39 | Bergeries de Cardo | bergerie | inconnu | 7 min | 17 min | 0 m | 66 m | oui | node/5911825059 | nomme, aucun couchage declare dans OSM |
| 100.39 | Bergeries de Pezzo | bergerie | inconnu | 1h16 | 2h27 | 46 m | 516 m | oui | node/8871451494 | nomme, aucun couchage declare dans OSM |
| 103.87 | Bergerie de Scarpacceghje | bergerie | inconnu | 2 min | 0 min | 7 m | 0 m | oui | way/352354191 | nomme, aucun couchage declare dans OSM |
| 103.87 | Bergeries de Scarpaccedié | camping | inconnu | 2 min | 1 min | 10 m | 0 m | oui | node/5911859788 | NOUVELLE NUIT — coupure de jour nouvelle |
| 105.71 | Refuge d'E Capanelle | refuge de montagne | 16 lits | 3 min | 1 min | 14 m | 0 m | oui | way/305575039 | deja fin d etape (fin E10) |
| 105.75 | Bivouac de Capanelle | camping | inconnu | 1 min | 0 min | 8 m | 0 m | oui | node/6545047285 | deja fin d etape (fin E10) |
| 105.79 | Gite U Fugone | restauration | inconnu | 0 min | 0 min | 0 m | 0 m | oui | node/5003636922 | deja fin d etape (fin E10) |
| 105.79 | Gite U Fugone | auberge | inconnu | 1 min | 0 min | 6 m | 0 m | oui | way/305567810 | deja fin d etape (fin E10) |
| 106.77 | Bergeries de Traggette | bergerie | inconnu | 2 min | 1 min | 8 m | 0 m | oui | node/3583959628 | nomme, aucun couchage declare dans OSM |
| 113.99 | Bergerie de Gialgone | refuge de montagne | inconnu | 4 min | 2 min | 14 m | 0 m | oui | node/4394676189 | NOUVELLE NUIT — coupure de jour nouvelle |
| 115.66 | (sans nom dans OpenStreetMap) | refuge non garde | inconnu | 1h45 | 51 min | 384 m | 23 m | oui | way/89826702 | au-dela du seuil |
| 115.66 | Bergerie des Pozzi | abri | 8 lits | 1h13 | 26 min | 311 m | 0 m | oui | way/89921551 | au-dela du seuil |
| 115.66 | Bivouac des Pozzi | camping | inconnu | 1h13 | 26 min | 310 m | 0 m | oui | way/437562772 | au-dela du seuil |
| 118.66 | Bivouac Col de Verde | camping | inconnu | 1 min | 1 min | 0 m | 5 m | oui | way/437562771 | NOUVELLE NUIT — coupure de jour nouvelle |
| 118.66 | Relais San Petru di Verde | refuge de montagne | 50 lits | 0 min | 0 min | 0 m | 1 m | oui | way/352675138 | NOUVELLE NUIT — coupure de jour nouvelle |
| 123.48 | Bivouac de Prati | camping | inconnu | 0 min | 1 min | 0 m | 4 m | oui | way/437551969 | deja fin d etape (fin E11) |
| 123.48 | Refuge de Prati | refuge de montagne | 32 lits | 0 min | 0 min | 1 m | 0 m | oui | way/96438686 | deja fin d etape (fin E11) |
| 129.26 | Bergerie de la Scanciatella | bergerie | inconnu | 38 min | 1h28 | 20 m | 356 m | oui | node/5312089075 | nomme, aucun couchage declare dans OSM |
| 129.26 | Gîte d'étape de Catastaghju | auberge | inconnu | 1h11 | 3h36 | 9 m | 972 m | oui | way/539005968 | au-dela du seuil |
| 129.26 | Refuge Laparo | refuge non garde | 6 lits | 10 min | 28 min | 5 m | 126 m | oui | way/907378832 | NOUVELLE NUIT — coupure de jour nouvelle |
| 133.09 | Bergerie de Bianca | refuge non garde | 4 lits | 37 min | 1h54 | 0 m | 511 m | oui | way/536622447 | au-dela du seuil |
| 134.36 | Bivouac d'Usciolu | camping | inconnu | 1 min | 2 min | 0 m | 7 m | oui | way/437549979 | deja fin d etape (fin E12) |
| 134.37 | Refuge d'Usciolu | refuge de montagne | 31 lits | 0 min | 0 min | 1 m | 0 m | oui | way/353265114 | deja fin d etape (fin E12) |
| 134.66 | Gîte d'étape Bella Vista | auberge | inconnu | 1h15 | 3h48 | 9 m | 1029 m | oui | node/1379768801 | au-dela du seuil |
| 134.66 | gîte Paulette Renucci | hotel | inconnu | 1h21 | 3h54 | 12 m | 1035 m | oui | node/13913935801 | au-dela du seuil |
| 140.84 | A Funtana - Chez Blanche | chambre d hotes | inconnu | 1h11 | 2h49 | 8 m | 664 m | oui | node/1329784993 | au-dela du seuil |
| 140.84 | Hôtel du tourisme | hotel | inconnu | 1h14 | 2h53 | 10 m | 672 m | oui | node/1282830173 | au-dela du seuil |
| 143.52 | Bergeries de Basseta | refuge de montagne | inconnu | 1 min | 1 min | 0 m | 5 m | oui | way/353421104 | NOUVELLE NUIT — coupure de jour nouvelle |
| 145.24 | Refuge de Matalza | refuge de montagne | inconnu | 1 min | 1 min | 0 m | 1 m | oui | way/353448449 | NOUVELLE NUIT — coupure de jour nouvelle |
| 145.61 | Bergeries d'Alluccia | bergerie | inconnu | 56 min | 40 min | 135 m | 31 m | oui | node/14127803091 | nomme, aucun couchage declare dans OSM |
| 145.61 | Bergeries de Frauletu | bergerie | inconnu | 50 min | 31 min | 127 m | 2 m | oui | node/14127800665 | nomme, aucun couchage declare dans OSM |
| 148.23 | Bergerie I Croci | refuge de montagne | inconnu | 0 min | 0 min | 0 m | 2 m | oui | way/263889051 | NOUVELLE NUIT — coupure de jour nouvelle |
| 148.24 | Bergeries des Cavallara | bergerie | inconnu | 25 min | 26 min | 23 m | 27 m | oui | node/14127800382 | nomme, aucun couchage declare dans OSM |
| 151.47 | Bergeries de Chiralbella | bergerie | inconnu | 21 min | 42 min | 0 m | 140 m | oui | node/5315168065 | nomme, aucun couchage declare dans OSM |
| 155.10 | Bergerie d'Asinau | refuge de montagne | 20 lits | 5 min | 18 min | 0 m | 87 m | oui | way/353640451 | NOUVELLE NUIT — un lit au lieu du dortoir |
| 155.10 | Bivouac d'Asinau | camping | inconnu | 1 min | 3 min | 0 m | 11 m | oui | way/437545324 | deja fin d etape (fin E13) |
| 155.10 | Refuge d'Asinau | refuge non garde | inconnu | 2 min | 2 min | 6 m | 10 m | oui | way/353634247 | deja fin d etape (fin E13) |
| 165.43 | (sans nom dans OpenStreetMap) | abri | inconnu | 34 min | 8 min | 175 m | 0 m | oui | node/3018297906 | au-dela du seuil |
| 165.81 | Les Aiguilles de Bavella | hotel | inconnu | 0 min | 1 min | 0 m | 4 m | oui | way/129769113 | deja fin d etape (fin E15) |
| 166.08 | Auberge du col de la Bavella | hotel | inconnu | 0 min | 1 min | 0 m | 6 m | oui | way/354652886 | NOUVELLE NUIT — un lit au lieu du dortoir |
| 166.08 | Le Refuge | restauration | inconnu | 1 min | 3 min | 0 m | 10 m | oui | way/354652884 | nomme, aucun couchage declare dans OSM |
| 170.37 | Refuge d'i Paliri | refuge de montagne | 22 lits | 0 min | 0 min | 1 m | 0 m | oui | way/354661509 | deja fin d etape (fin E14) |
| 170.46 | Bivouac de Paliri | camping | inconnu | 0 min | 0 min | 0 m | 0 m | oui | way/437544876 | deja fin d etape (fin E14) |
| 183.58 | (sans nom dans OpenStreetMap) | abri | inconnu | 1h46 | 1h39 | 271 m | 226 m | oui | node/9705373263 | au-dela du seuil |
| 183.58 | (sans nom dans OpenStreetMap) | abri | inconnu | 1 min | 2 min | 0 m | 4 m | oui | node/14070227101 | tete de sentier, pas une nuit de plus |
| 183.58 | Gite d'Étape La Tonnelle | camping | inconnu | 8 min | 12 min | 0 m | 29 m | oui | node/8829309175 | tete de sentier, pas une nuit de plus |
| 183.58 | Gite d'Étape La Tonnelle | auberge | inconnu | 7 min | 11 min | 0 m | 28 m | oui | way/222119845 | tete de sentier, pas une nuit de plus |
| - | Bergerie Coltu | bergerie | inconnu | - | - | - | - | NON | node/5872355787 | sans chemin trace |
| - | Bergerie de Giovannaccia | bergerie | inconnu | - | - | - | - | NON | node/6238729332 | sans chemin trace |
| - | Bergerie de Livru | refuge non garde | inconnu | - | - | - | - | NON | node/12864075537 | sans chemin trace |
| - | Bergerie de Manica | bergerie | inconnu | - | - | - | - | NON | node/6311680325 | sans chemin trace |
| - | Bergerie de Paratelle | bergerie | inconnu | - | - | - | - | NON | node/6238729345 | sans chemin trace |
| - | Bergerie de Petra Tilleri | bergerie | inconnu | - | - | - | - | NON | node/8791248011 | sans chemin trace |
| - | Bergeries de Betulliccia | bergerie | inconnu | - | - | - | - | NON | node/6167087117 | sans chemin trace |
| - | Bergeries de Biciancola | bergerie | inconnu | - | - | - | - | NON | node/6536327885 | sans chemin trace |
| - | Bergeries de Gialicatapiano | bergerie | inconnu | - | - | - | - | NON | node/5885476886 | sans chemin trace |
| - | Bergeries de Matone | bergerie | inconnu | - | - | - | - | NON | node/12964981822 | sans chemin trace |
| - | Bergeries de Monte Lati | bergerie | inconnu | - | - | - | - | NON | node/6536308284 | sans chemin trace |
| - | Bergeries de Rimugeto | bergerie | inconnu | - | - | - | - | NON | node/11952287332 | sans chemin trace |
| - | Chalet Manuella | gite | inconnu | - | - | - | - | NON | node/9250999322 | sans chemin trace |
| - | Chalet U Renosu | gite | inconnu | - | - | - | - | NON | node/9250999321 | sans chemin trace |
| - | Gîte de Cavu | gite | inconnu | - | - | - | - | NON | node/9250999323 | sans chemin trace |
| - | bergerie ciutare | abri | inconnu | - | - | - | - | NON | way/367967630 | sans chemin trace |

## Le total

- Couchages releves dans le couloir : 147 (104 declares par OpenStreetMap, 43 nommes sans etiquette de couchage)
- Avec un chemin trace jusqu a eux : 131 ; SANS chemin trace : 16
- Deja des fins d etape : 41
- **Nouvelles nuits possibles : 23**
  - dont coupures de jour NOUVELLES : 15
  - dont un lit a la place du dortoir au meme endroit : 6
  - dont des tetes de sentier (Calenzana, Conca) : 2

## Les nouveaux endroits de couchage, un par un

| PK | Ce que ca ouvre | Fin d etape la plus proche | Ecart PK | Couchages | Lits | Aller | Retour |
|---|---|---|---|---|---|---|---|
| 0.00 | une tete de sentier, pas une nuit sur le sentier | Calenzana | 0.00 km | Calenzana Camping/Gite d'étape + Gîte d'Étape municipal | inconnu | 9 min | 17 min |
| 18.83 | un vrai lit a la place du dortoir, au meme endroit du sentier | Refuge de Carozzu | 0.15 km | (sans nom dans OpenStreetMap) | inconnu | 2 min | 10 min |
| 33.17 | une coupure de jour NOUVELLE | Refuge de Tighjettu | 1.17 km | Bergerie de Ballone | inconnu | 0 min | 1 min |
| 43.49 | une coupure de jour NOUVELLE | Refuge de Ciottulu di i Mori | 5.12 km | Bergeries de Radule + (sans nom dans OpenStreetMap) | 150 | 0 min | 0 min |
| 46.77 | une coupure de jour NOUVELLE | Refuge de Ciottulu di i Mori | 8.40 km | Castel De Vergio + Hôtel Castel De Vergio + Castel de Vergio | 29 | 1 min | 1 min |
| 61.34 | une coupure de jour NOUVELLE | Refuge de Manganu | 2.06 km | Bergeries de Vaccaghia + Bivouac de Vaccaghja | inconnu | 0 min | 0 min |
| 62.64 | un vrai lit a la place du dortoir, au meme endroit du sentier | Refuge de Manganu | 0.76 km | Bergerie de Lenze | inconnu | 24 min | 18 min |
| 77.90 | une coupure de jour NOUVELLE | Refuge de l'Onda | 3.69 km | Bergerie de Tolla + Bergerie de Tolla | 20 | 1 min | 1 min |
| 89.16 | une coupure de jour NOUVELLE | Gare de Vizzavona | 2.63 km | Aire de bivouac La Halte Du Prince + Gite d'Étape Monte d'Oro + Hôtel Monte d'Oro + La Halte du Prince | 40 | 22 min | 16 min |
| 91.99 | un vrai lit a la place du dortoir, au meme endroit du sentier | Gare de Vizzavona | 0.19 km | Casa Alta | inconnu | 13 min | 16 min |
| 91.99 | un vrai lit a la place du dortoir, au meme endroit du sentier | Gare de Vizzavona | 0.19 km | U Castellu | inconnu | 3 min | 2 min |
| 97.87 | une coupure de jour NOUVELLE | Gare de Vizzavona | 6.07 km | Bivouac de Bocca Palmente | inconnu | 0 min | 0 min |
| 98.44 | une coupure de jour NOUVELLE | Gare de Vizzavona | 6.65 km | Bergeries d'Alzeta | inconnu | 1 min | 0 min |
| 103.87 | une coupure de jour NOUVELLE | Refuge d'E Capanelle | 1.88 km | Bergeries de Scarpaccedié | inconnu | 2 min | 1 min |
| 113.99 | une coupure de jour NOUVELLE | Refuge d'E Capanelle | 8.24 km | Bergerie de Gialgone | inconnu | 4 min | 2 min |
| 118.66 | une coupure de jour NOUVELLE | Refuge de Prati | 4.82 km | Bivouac Col de Verde + Relais San Petru di Verde | 50 | 0 min | 0 min |
| 129.26 | une coupure de jour NOUVELLE | Refuge d'Usciolu | 5.11 km | Refuge Laparo | 6 | 10 min | 28 min |
| 143.52 | une coupure de jour NOUVELLE | Refuge d'Usciolu | 9.15 km | Bergeries de Basseta | inconnu | 1 min | 1 min |
| 145.24 | une coupure de jour NOUVELLE | Refuge d'Asinau | 9.85 km | Refuge de Matalza | inconnu | 1 min | 1 min |
| 148.24 | une coupure de jour NOUVELLE | Refuge d'Asinau | 6.86 km | Bergerie I Croci | inconnu | 0 min | 0 min |
| 155.10 | un vrai lit a la place du dortoir, au meme endroit du sentier | Refuge d'Asinau | 0.00 km | Bergerie d'Asinau | 20 | 5 min | 18 min |
| 166.08 | un vrai lit a la place du dortoir, au meme endroit du sentier | Col de Bavella | 0.23 km | Auberge du col de la Bavella | inconnu | 0 min | 1 min |
| 183.58 | une tete de sentier, pas une nuit sur le sentier | Conca | 0.00 km | (sans nom dans OpenStreetMap) + Gite d'Étape La Tonnelle + Gite d'Étape La Tonnelle | inconnu | 1 min | 2 min |

## Les deux modeles de l application, et ou ils se contredisent

| Nom | PK | Decoupage aller/retour | Heure d arrivee aller/retour | Qui passe |
|---|---|---|---|---|
| (sans nom dans OpenStreetMap) | 165.43 | 34 min / 8 min | 25 min / 13 min | heure d arrivee |
