# -*- coding: utf-8 -*-
"""Patch the 5 Slang i18n JSON files with the full GR20-parity checklist tree.

Idempotent: overwrites the `checklist` subtree, `nav.checklist` and
`hub.cards.checklist`/`checklistSub` for each locale. Run:
    python tool/patch_checklist_i18n.py
Then regenerate Slang: dart run slang
"""
import io
import json
import os

I18N_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "i18n")

# --- Category names (12), parite GR20 ---------------------------------------
CATEGORIES = {
    "fr": {
        "carrying": "Sac & portage", "sleeping": "Couchage",
        "clothing": "Vetements", "cooking": "Cuisine",
        "foodWater": "Nourriture & Eau", "hygiene": "Hygiene",
        "firstAid": "Trousse de secours", "electronics": "Electronique",
        "women": "Femme", "men": "Homme", "misc": "Divers", "dog": "Chien",
    },
    "en": {
        "carrying": "Pack & carrying", "sleeping": "Sleeping",
        "clothing": "Clothing", "cooking": "Cooking",
        "foodWater": "Food & Water", "hygiene": "Hygiene",
        "firstAid": "First-aid kit", "electronics": "Electronics",
        "women": "Women", "men": "Men", "misc": "Miscellaneous", "dog": "Dog",
    },
    "de": {
        "carrying": "Rucksack & Tragen", "sleeping": "Schlafen",
        "clothing": "Kleidung", "cooking": "Kochen",
        "foodWater": "Essen & Wasser", "hygiene": "Hygiene",
        "firstAid": "Erste-Hilfe-Set", "electronics": "Elektronik",
        "women": "Frauen", "men": "Manner", "misc": "Sonstiges", "dog": "Hund",
    },
    "it": {
        "carrying": "Zaino & trasporto", "sleeping": "Riposo",
        "clothing": "Abbigliamento", "cooking": "Cucina",
        "foodWater": "Cibo & Acqua", "hygiene": "Igiene",
        "firstAid": "Kit di primo soccorso", "electronics": "Elettronica",
        "women": "Donna", "men": "Uomo", "misc": "Varie", "dog": "Cane",
    },
    "es": {
        "carrying": "Mochila & porte", "sleeping": "Descanso",
        "clothing": "Ropa", "cooking": "Cocina",
        "foodWater": "Comida & Agua", "hygiene": "Higiene",
        "firstAid": "Botiquin", "electronics": "Electronica",
        "women": "Mujer", "men": "Hombre", "misc": "Varios", "dog": "Perro",
    },
}

# --- Item names (84 + swimsuit override), parite GR20 -----------------------
ITEMS = {
    "backpack": {"fr": "Sac a dos 35-45L", "en": "Backpack 35-45L", "de": "Rucksack 35-45L", "it": "Zaino 35-45L", "es": "Mochila 35-45L"},
    "rainCover": {"fr": "Housse de pluie sac", "en": "Backpack rain cover", "de": "Rucksack-Regenhulle", "it": "Coprizaino antipioggia", "es": "Funda de lluvia mochila"},
    "dryBags": {"fr": "Sacs etanches (dry bags)", "en": "Dry bags", "de": "Packsacke (dry bags)", "it": "Sacche stagne (dry bags)", "es": "Bolsas estancas (dry bags)"},
    "sleepingBag": {"fr": "Sac de couchage (0-5C)", "en": "Sleeping bag (0-5C)", "de": "Schlafsack (0-5C)", "it": "Sacco a pelo (0-5C)", "es": "Saco de dormir (0-5C)"},
    "sleepingPad": {"fr": "Matelas / tapis de sol", "en": "Sleeping pad / mat", "de": "Isomatte / Unterlage", "it": "Materassino / stuoia", "es": "Esterilla / colchoneta"},
    "sleepingLiner": {"fr": "Drap de sac / sac a viande", "en": "Sleeping bag liner", "de": "Huttenschlafsack / Inlett", "it": "Lenzuolo per sacco a pelo", "es": "Sabana saco / funda"},
    "pillow": {"fr": "Oreiller gonflable", "en": "Inflatable pillow", "de": "Aufblasbares Kissen", "it": "Cuscino gonfiabile", "es": "Almohada hinchable"},
    "hikingPants": {"fr": "Pantalon de rando", "en": "Hiking trousers", "de": "Wanderhose", "it": "Pantaloni da trekking", "es": "Pantalon de senderismo"},
    "rainPants": {"fr": "Pantalon de pluie", "en": "Rain trousers", "de": "Regenhose", "it": "Pantaloni antipioggia", "es": "Pantalon de lluvia"},
    "shorts": {"fr": "Short", "en": "Shorts", "de": "Shorts", "it": "Pantaloncini", "es": "Pantalon corto"},
    "techTshirt": {"fr": "T-shirt technique", "en": "Technical T-shirt", "de": "Funktions-T-Shirt", "it": "Maglietta tecnica", "es": "Camiseta tecnica"},
    "fleece": {"fr": "Polaire / doudoune legere", "en": "Fleece / light down", "de": "Fleece / leichte Daune", "it": "Pile / piumino leggero", "es": "Forro polar / plumas ligero"},
    "rainJacket": {"fr": "Veste impermeable Gore-Tex", "en": "Waterproof jacket Gore-Tex", "de": "Regenjacke Gore-Tex", "it": "Giacca impermeabile Gore-Tex", "es": "Chaqueta impermeable Gore-Tex"},
    "underwear": {"fr": "Sous-vetement", "en": "Underwear", "de": "Unterwasche", "it": "Biancheria intima", "es": "Ropa interior"},
    "hikingSocks": {"fr": "Chaussettes de rando", "en": "Hiking socks", "de": "Wandersocken", "it": "Calze da trekking", "es": "Calcetines de senderismo"},
    "gaiters": {"fr": "Guetres", "en": "Gaiters", "de": "Gamaschen", "it": "Ghette", "es": "Polainas"},
    "hat": {"fr": "Chapeau / casquette", "en": "Hat / cap", "de": "Hut / Kappe", "it": "Cappello / berretto", "es": "Sombrero / gorra"},
    "beanie": {"fr": "Bonnet", "en": "Beanie", "de": "Mutze", "it": "Berretto di lana", "es": "Gorro"},
    "buff": {"fr": "Buff / tour de cou", "en": "Buff / neck gaiter", "de": "Buff / Halstuch", "it": "Buff / scaldacollo", "es": "Buff / braga de cuello"},
    "lightGloves": {"fr": "Gants legers", "en": "Light gloves", "de": "Leichte Handschuhe", "it": "Guanti leggeri", "es": "Guantes ligeros"},
    "hikingBoots": {"fr": "Chaussures de rando (portees)", "en": "Hiking boots (worn)", "de": "Wanderschuhe (getragen)", "it": "Scarponi (indossati)", "es": "Botas de senderismo (puestas)"},
    "campSandals": {"fr": "Sandales de bivouac", "en": "Camp sandals", "de": "Camp-Sandalen", "it": "Sandali da bivacco", "es": "Sandalias de vivac"},
    "stove": {"fr": "Rechaud (PocketRocket)", "en": "Stove (PocketRocket)", "de": "Kocher (PocketRocket)", "it": "Fornello (PocketRocket)", "es": "Hornillo (PocketRocket)"},
    "gasCanister": {"fr": "Cartouche gaz", "en": "Gas canister", "de": "Gaskartusche", "it": "Cartuccia gas", "es": "Cartucho de gas"},
    "cookpot": {"fr": "Popote / gamelle", "en": "Cookpot / mess tin", "de": "Kochtopf / Geschirr", "it": "Pentolino / gavetta", "es": "Olla / cazuela"},
    "cutlery": {"fr": "Couverts (cuillere, couteau)", "en": "Cutlery (spoon, knife)", "de": "Besteck (Loffel, Messer)", "it": "Posate (cucchiaio, coltello)", "es": "Cubiertos (cuchara, cuchillo)"},
    "waterBottle": {"fr": "Gourde / poche a eau 2L", "en": "Water bottle / bladder 2L", "de": "Trinkflasche / Blase 2L", "it": "Borraccia / sacca 2L", "es": "Cantimplora / bolsa 2L"},
    "knife": {"fr": "Couteau pliant", "en": "Folding knife", "de": "Klappmesser", "it": "Coltello pieghevole", "es": "Navaja plegable"},
    "lighter": {"fr": "Briquet", "en": "Lighter", "de": "Feuerzeug", "it": "Accendino", "es": "Mechero"},
    "energyBars": {"fr": "Barre energetique", "en": "Energy bar", "de": "Energieriegel", "it": "Barretta energetica", "es": "Barrita energetica"},
    "driedFruits": {"fr": "Fruits secs", "en": "Dried fruits", "de": "Trockenfruchte", "it": "Frutta secca", "es": "Frutos secos"},
    "freezeDriedMeal": {"fr": "Repas lyophilise", "en": "Freeze-dried meal", "de": "Gefriergetrocknete Mahlzeit", "it": "Pasto liofilizzato", "es": "Comida liofilizada"},
    "waterPurification": {"fr": "Pastilles purification eau", "en": "Water purification tablets", "de": "Wasser-Entkeimungstabletten", "it": "Pastiglie depurazione acqua", "es": "Pastillas potabilizadoras"},
    "electrolytes": {"fr": "Electrolytes", "en": "Electrolytes", "de": "Elektrolyte", "it": "Elettroliti", "es": "Electrolitos"},
    "carriedWater": {"fr": "Eau transportee (1L = 1000g)", "en": "Carried water (1L = 1000g)", "de": "Getragenes Wasser (1L = 1000g)", "it": "Acqua trasportata (1L = 1000g)", "es": "Agua transportada (1L = 1000g)"},
    "soap": {"fr": "Savon biodegradable", "en": "Biodegradable soap", "de": "Biologisch abbaubare Seife", "it": "Sapone biodegradabile", "es": "Jabon biodegradable"},
    "toothbrush": {"fr": "Brosse a dents", "en": "Toothbrush", "de": "Zahnburste", "it": "Spazzolino da denti", "es": "Cepillo de dientes"},
    "toothpaste": {"fr": "Dentifrice", "en": "Toothpaste", "de": "Zahnpasta", "it": "Dentifricio", "es": "Pasta de dientes"},
    "microfiberTowel": {"fr": "Serviette microfibre", "en": "Microfiber towel", "de": "Mikrofaser-Handtuch", "it": "Asciugamano in microfibra", "es": "Toalla de microfibra"},
    "toiletPaper": {"fr": "Papier toilette", "en": "Toilet paper", "de": "Toilettenpapier", "it": "Carta igienica", "es": "Papel higienico"},
    "trashBag": {"fr": "Sac poubelle", "en": "Trash bag", "de": "Mullbeutel", "it": "Sacco della spazzatura", "es": "Bolsa de basura"},
    "antiChafingCream": {"fr": "Creme anti-frottements", "en": "Anti-chafing cream", "de": "Anti-Scheuer-Creme", "it": "Crema anti-sfregamento", "es": "Crema antirozaduras"},
    "earplugs": {"fr": "Boules Quies", "en": "Earplugs", "de": "Ohrstopsel", "it": "Tappi per orecchie", "es": "Tapones para oidos"},
    "bandages": {"fr": "Pansements assortis", "en": "Assorted plasters", "de": "Sortierte Pflaster", "it": "Cerotti assortiti", "es": "Tiritas surtidas"},
    "sterileCompresses": {"fr": "Compresses steriles", "en": "Sterile compresses", "de": "Sterile Kompressen", "it": "Compresse sterili", "es": "Compresas esteriles"},
    "elasticBandage": {"fr": "Bande elastique", "en": "Elastic bandage", "de": "Elastische Binde", "it": "Benda elastica", "es": "Venda elastica"},
    "disinfectant": {"fr": "Desinfectant (50ml)", "en": "Disinfectant (50ml)", "de": "Desinfektionsmittel (50ml)", "it": "Disinfettante (50ml)", "es": "Desinfectante (50ml)"},
    "painkillers": {"fr": "Doliprane / Ibuprofene", "en": "Paracetamol / Ibuprofen", "de": "Paracetamol / Ibuprofen", "it": "Paracetamolo / Ibuprofene", "es": "Paracetamol / Ibuprofeno"},
    "sunscreen": {"fr": "Creme solaire SPF50", "en": "Sunscreen SPF50", "de": "Sonnencreme SPF50", "it": "Crema solare SPF50", "es": "Crema solar SPF50"},
    "lipBalm": {"fr": "Stick a levres SPF30", "en": "Lip balm SPF30", "de": "Lippenbalsam SPF30", "it": "Burrocacao SPF30", "es": "Barra labial SPF30"},
    "emergencyBlanket": {"fr": "Couverture de survie", "en": "Emergency blanket", "de": "Rettungsdecke", "it": "Coperta di sopravvivenza", "es": "Manta de supervivencia"},
    "tickRemover": {"fr": "Tire-tiques", "en": "Tick remover", "de": "Zeckenzange", "it": "Leva-zecche", "es": "Extractor de garrapatas"},
    "whistle": {"fr": "Sifflet de secours", "en": "Emergency whistle", "de": "Notfallpfeife", "it": "Fischietto di emergenza", "es": "Silbato de emergencia"},
    "strapping": {"fr": "Elastoplaste / strapping", "en": "Strapping tape", "de": "Tapeverband / Strapping", "it": "Cerotto elastico / strapping", "es": "Esparadrapo / strapping"},
    "eyeDrops": {"fr": "Collyre", "en": "Eye drops", "de": "Augentropfen", "it": "Collirio", "es": "Colirio"},
    "antiDiarrheal": {"fr": "Anti-diarrheique", "en": "Anti-diarrheal", "de": "Durchfallmittel", "it": "Antidiarroico", "es": "Antidiarreico"},
    "antihistamine": {"fr": "Antihistaminique", "en": "Antihistamine", "de": "Antihistaminikum", "it": "Antistaminico", "es": "Antihistaminico"},
    "kneeTape": {"fr": "Tape genoux", "en": "Knee tape", "de": "Knie-Tape", "it": "Tape per ginocchia", "es": "Tape para rodillas"},
    "phone": {"fr": "Telephone", "en": "Phone", "de": "Telefon", "it": "Telefono", "es": "Telefono"},
    "powerBank": {"fr": "Batterie externe 20000mAh", "en": "Power bank 20000mAh", "de": "Powerbank 20000mAh", "it": "Power bank 20000mAh", "es": "Bateria externa 20000mAh"},
    "usbCable": {"fr": "Cable USB", "en": "USB cable", "de": "USB-Kabel", "it": "Cavo USB", "es": "Cable USB"},
    "headlamp": {"fr": "Lampe frontale", "en": "Headlamp", "de": "Stirnlampe", "it": "Lampada frontale", "es": "Linterna frontal"},
    "spareBatteries": {"fr": "Piles de rechange", "en": "Spare batteries", "de": "Ersatzbatterien", "it": "Batterie di ricambio", "es": "Pilas de repuesto"},
    "periodProtection": {"fr": "Protections periodiques", "en": "Period protection", "de": "Periodenschutz", "it": "Protezioni mestruali", "es": "Proteccion menstrual"},
    "sportsBra": {"fr": "Brassiere sport", "en": "Sports bra", "de": "Sport-BH", "it": "Reggiseno sportivo", "es": "Sujetador deportivo"},
    "intimateWipes": {"fr": "Lingettes intimes", "en": "Intimate wipes", "de": "Intimtucher", "it": "Salviette intime", "es": "Toallitas intimas"},
    "peeCloth": {"fr": "Pee-cloth", "en": "Pee cloth", "de": "Pee-Cloth", "it": "Pee-cloth", "es": "Pee-cloth"},
    "razor": {"fr": "Rasoir", "en": "Razor", "de": "Rasierer", "it": "Rasoio", "es": "Maquinilla de afeitar"},
    "techBoxers": {"fr": "Calecons tech", "en": "Tech boxers", "de": "Funktions-Boxershorts", "it": "Boxer tecnici", "es": "Boxers tecnicos"},
    "hikingPoles": {"fr": "Batons de marche (portes)", "en": "Trekking poles (carried)", "de": "Wanderstocke (getragen)", "it": "Bastoncini da trekking (portati)", "es": "Bastones de marcha (llevados)"},
    "sunglasses": {"fr": "Lunettes de soleil", "en": "Sunglasses", "de": "Sonnenbrille", "it": "Occhiali da sole", "es": "Gafas de sol"},
    "trailMap": {"fr": "Carte IGN / topo", "en": "Map / topo guide", "de": "Karte / Topo-Guide", "it": "Cartina / guida topo", "es": "Mapa / guia topo"},
    "spareLaces": {"fr": "Lacets de rechange", "en": "Spare laces", "de": "Ersatzschnursenkel", "it": "Lacci di ricambio", "es": "Cordones de repuesto"},
    "needleThread": {"fr": "Fil + aiguille", "en": "Needle + thread", "de": "Nadel + Faden", "it": "Ago + filo", "es": "Aguja + hilo"},
    "ductTape": {"fr": "Ruban adhesif", "en": "Duct tape", "de": "Klebeband", "it": "Nastro adesivo", "es": "Cinta adhesiva"},
    "ziplocBags": {"fr": "Sacs ziploc", "en": "Ziploc bags", "de": "Ziploc-Beutel", "it": "Sacchetti ziploc", "es": "Bolsas ziploc"},
    "cord": {"fr": "Cordelle", "en": "Cord", "de": "Schnur", "it": "Cordino", "es": "Cordel"},
    "cash": {"fr": "Argent liquide", "en": "Cash", "de": "Bargeld", "it": "Contanti", "es": "Dinero en efectivo"},
    "dogBowl": {"fr": "Gamelle pliable", "en": "Foldable bowl", "de": "Faltbarer Napf", "it": "Ciotola pieghevole", "es": "Comedero plegable"},
    "dogLeash": {"fr": "Laisse", "en": "Leash", "de": "Leine", "it": "Guinzaglio", "es": "Correa"},
    "dogKibble": {"fr": "Croquettes (ration/jour)", "en": "Kibble (ration/day)", "de": "Trockenfutter (Ration/Tag)", "it": "Crocchette (razione/giorno)", "es": "Pienso (racion/dia)"},
    "dogBooties": {"fr": "Bottines protection", "en": "Protective booties", "de": "Schutzstiefel", "it": "Scarpine protettive", "es": "Botines de proteccion"},
    "dogVaccineBook": {"fr": "Carnet de vaccins", "en": "Vaccine record", "de": "Impfpass", "it": "Libretto vaccinazioni", "es": "Cartilla de vacunas"},
    "dogPoopBags": {"fr": "Sacs a dejections", "en": "Poop bags", "de": "Kotbeutel", "it": "Sacchetti igienici", "es": "Bolsas para excrementos"},
    "swimsuit": {"fr": "Maillot de bain", "en": "Swimsuit", "de": "Badeanzug", "it": "Costume da bagno", "es": "Banador"},
}

WEIGHT = {
    "fr": {"title": "Poids du sac", "total": "Poids total", "bodyWeight": "Poids corporel :", "ratio": "Ratio sac / corps", "perItem": "Poids par article", "edit": "Modifier le poids", "grams": "g", "kilograms": "kg", "adviceUltraLight": "Sac ultra-leger — ideal pour le trek", "adviceLight": "Sac ultra-leger — ideal pour le trek", "adviceOk": "Sac bien equilibre", "adviceHeavy": "Correct mais lourd — envisagez d'alleger", "adviceTooHeavy": "Attention genoux ! Allegez le sac", "adviceDanger": "Danger blessure — allegez absolument !", "itemWeight": "Poids de l'article", "cancel": "Annuler", "save": "Enregistrer", "gaugeUltraLight": "Ultra-leger, parfait !", "gaugeOk": "Bien, sac equilibre", "gaugeHeavy": "Correct mais lourd", "gaugeWarn": "Attention genoux !", "gaugeDanger": "Danger blessure !", "percentOfWeight": "{pct}% du poids", "gaugeObjective": "Objectif max : < 15% en refuge, < 20% en autonomie", "itemsChecked": "{checked} / {total} articles coches"},
    "en": {"title": "Backpack weight", "total": "Total weight", "bodyWeight": "Body weight:", "ratio": "Pack / body ratio", "perItem": "Weight per item", "edit": "Edit weight", "grams": "g", "kilograms": "kg", "adviceUltraLight": "Ultra-light pack — ideal for trekking", "adviceLight": "Ultra-light pack — ideal for trekking", "adviceOk": "Well-balanced pack", "adviceHeavy": "OK but heavy — consider lightening", "adviceTooHeavy": "Mind your knees! Lighten the pack", "adviceDanger": "Injury risk — lighten it now!", "itemWeight": "Item weight", "cancel": "Cancel", "save": "Save", "gaugeUltraLight": "Ultra-light, perfect!", "gaugeOk": "Good, balanced pack", "gaugeHeavy": "OK but heavy", "gaugeWarn": "Mind your knees!", "gaugeDanger": "Injury risk!", "percentOfWeight": "{pct}% of body weight", "gaugeObjective": "Max target: < 15% in huts, < 20% self-supported", "itemsChecked": "{checked} / {total} items checked"},
    "de": {"title": "Rucksackgewicht", "total": "Gesamtgewicht", "bodyWeight": "Korpergewicht:", "ratio": "Rucksack / Korper", "perItem": "Gewicht pro Artikel", "edit": "Gewicht andern", "grams": "g", "kilograms": "kg", "adviceUltraLight": "Ultraleichter Rucksack — ideal furs Trekking", "adviceLight": "Ultraleichter Rucksack — ideal furs Trekking", "adviceOk": "Gut ausbalancierter Rucksack", "adviceHeavy": "OK aber schwer — erwage zu erleichtern", "adviceTooHeavy": "Achtung Knie! Rucksack erleichtern", "adviceDanger": "Verletzungsgefahr — jetzt erleichtern!", "itemWeight": "Artikelgewicht", "cancel": "Abbrechen", "save": "Speichern", "gaugeUltraLight": "Ultraleicht, perfekt!", "gaugeOk": "Gut, ausbalanciert", "gaugeHeavy": "OK aber schwer", "gaugeWarn": "Achtung Knie!", "gaugeDanger": "Verletzungsgefahr!", "percentOfWeight": "{pct}% des Korpergewichts", "gaugeObjective": "Max. Ziel: < 15% in Hutten, < 20% autark", "itemsChecked": "{checked} / {total} Artikel angehakt"},
    "it": {"title": "Peso dello zaino", "total": "Peso totale", "bodyWeight": "Peso corporeo:", "ratio": "Rapporto zaino / corpo", "perItem": "Peso per articolo", "edit": "Modifica il peso", "grams": "g", "kilograms": "kg", "adviceUltraLight": "Zaino ultraleggero — ideale per il trekking", "adviceLight": "Zaino ultraleggero — ideale per il trekking", "adviceOk": "Zaino ben bilanciato", "adviceHeavy": "Discreto ma pesante — valuta di alleggerire", "adviceTooHeavy": "Attenzione ginocchia! Alleggerisci lo zaino", "adviceDanger": "Rischio infortunio — alleggerisci subito!", "itemWeight": "Peso dell'articolo", "cancel": "Annulla", "save": "Salva", "gaugeUltraLight": "Ultraleggero, perfetto!", "gaugeOk": "Bene, bilanciato", "gaugeHeavy": "Discreto ma pesante", "gaugeWarn": "Attenzione ginocchia!", "gaugeDanger": "Rischio infortunio!", "percentOfWeight": "{pct}% del peso corporeo", "gaugeObjective": "Obiettivo max: < 15% in rifugio, < 20% in autonomia", "itemsChecked": "{checked} / {total} articoli spuntati"},
    "es": {"title": "Peso de la mochila", "total": "Peso total", "bodyWeight": "Peso corporal:", "ratio": "Ratio mochila / cuerpo", "perItem": "Peso por articulo", "edit": "Editar el peso", "grams": "g", "kilograms": "kg", "adviceUltraLight": "Mochila ultraligera — ideal para el trekking", "adviceLight": "Mochila ultraligera — ideal para el trekking", "adviceOk": "Mochila bien equilibrada", "adviceHeavy": "Correcto pero pesado — considera aligerar", "adviceTooHeavy": "Cuidado rodillas! Aligera la mochila", "adviceDanger": "Riesgo de lesion — aligera ya!", "itemWeight": "Peso del articulo", "cancel": "Cancelar", "save": "Guardar", "gaugeUltraLight": "Ultraligero, perfecto!", "gaugeOk": "Bien, equilibrado", "gaugeHeavy": "Correcto pero pesado", "gaugeWarn": "Cuidado rodillas!", "gaugeDanger": "Riesgo de lesion!", "percentOfWeight": "{pct}% del peso corporal", "gaugeObjective": "Objetivo max: < 15% en refugio, < 20% en autonomia", "itemsChecked": "{checked} / {total} articulos marcados"},
}

SCREEN = {
    "fr": {"title": "Materiel & Sac", "requirementRequired": "Obligatoire", "addItem": "Ajouter un item", "addItemTitle": "Ajouter un item", "fieldName": "Nom", "fieldWeightGrams": "Poids (grammes)", "add": "Ajouter", "editWeightTitle": "Modifier le poids", "editCustomTitle": "Modifier l'item custom", "modify": "Modifier", "delete": "Supprimer", "deleteItemTitle": "Supprimer cet article ?", "deleteItemBody": "L'article \"{name}\" sera definitivement supprime.", "requiredWarnTitle": "Equipement obligatoire", "requiredWarnBody": "Cet equipement est obligatoire pour la securite (inspire reglementation UTMB). Voulez-vous vraiment le retirer ?", "keep": "Garder", "removeAnyway": "Retirer quand meme", "reduceQuantity": "Reduire quantite", "increaseQuantity": "Augmenter quantite", "addToShoppingList": "Ajouter a la liste de courses", "removeFromShoppingList": "Retirer de la liste", "help": "Aide", "shoppingListTitle": "Liste de courses", "shoppingListEmpty": "Votre liste de courses est vide. Ajoutez des items avec le bouton panier.", "shoppingToBuy": "A acheter", "shoppingPurchased": "Deja achete", "share": "PARTAGER", "infoTitle": "Materiel & Sac", "infoCheckTitle": "Cocher les items", "infoCheckBody": "Cochez ce que vous emportez — le poids se recalcule en haut.", "infoRequiredTitle": "Obligatoires", "infoRequiredBody": "Items avec cadenas = reglementation (sifflet, lampe, couverture survie).", "infoGaugeTitle": "Jauge poids", "infoGaugeBody": "Objectif : sac < 15% de votre poids. Vert = OK, Orange = attention, Rouge = trop lourd.", "infoAddTitle": "Ajouter", "infoAddBody": "Bouton + en bas de chaque categorie pour vos propres items.", "infoValidateBody": "Validez quand votre sac est pret — un check apparaitra sur l'accueil.", "infoUnderstood": "Compris !", "prepTitle": "Preparation du sac", "prepCounter": "{prepared} / {total} items prepares", "prepAllReady": "Tout est pret ! Bon trek", "preDepartureTitle": "Checklist avant depart", "preDepartureCounter": "{checked}/{total} verifies", "preDep1": "Verifier la meteo des prochains jours", "preDep2": "Charger telephone + batterie externe", "preDep3": "Prevenir un proche de votre itineraire", "preDep4": "Verifier que le sac est bien ferme et etanche", "preDep5": "Remplir les gourdes (minimum 2L)", "preDep6": "Appliquer creme solaire et anti-frottements", "preDep7": "Verifier les lacets et le serrage des chaussures", "preDep8": "Telecharger les cartes offline", "bagOk": "SAC OK — PRET A PARTIR", "validateBag": "VALIDER MON SAC", "cancelValidation": "ANNULER LA VALIDATION", "shoppingListButton": "LISTE D'ACHAT", "shareGroup": "PARTAGER AVEC LE GROUPE", "exportList": "EXPORTER LA LISTE", "bagValidTitle": "Sac valide", "bagValidBody": "Tous les {total} equipements obligatoires sont dans votre sac.\n\nPoids total : {weight} kg ({pct}% du poids corporel)\n\nEtes-vous certain que votre sac est pret ?", "checkAgain": "Verifier encore", "yesBagOk": "Oui, sac OK", "bagValidatedSnack": "Sac valide !", "validationCancelledSnack": "Validation du sac annulee — vous pouvez modifier votre materiel.", "missingTitle": "Equipement manquant", "missingBody": "{checked}/{total} equipements obligatoires coches.", "missingList": "Il manque :", "understood": "Compris", "validateAnyway": "Valider quand meme", "bagValidatedMissingSnack": "Sac valide (avec items manquants) !", "shareGroupHint": "Rejoignez un groupe pour partager votre checklist."},
    "en": {"title": "Gear & Pack", "requirementRequired": "Required", "addItem": "Add an item", "addItemTitle": "Add an item", "fieldName": "Name", "fieldWeightGrams": "Weight (grams)", "add": "Add", "editWeightTitle": "Edit weight", "editCustomTitle": "Edit custom item", "modify": "Edit", "delete": "Delete", "deleteItemTitle": "Delete this item?", "deleteItemBody": "The item \"{name}\" will be permanently deleted.", "requiredWarnTitle": "Required gear", "requiredWarnBody": "This gear is required for safety (inspired by UTMB rules). Do you really want to remove it?", "keep": "Keep", "removeAnyway": "Remove anyway", "reduceQuantity": "Decrease quantity", "increaseQuantity": "Increase quantity", "addToShoppingList": "Add to shopping list", "removeFromShoppingList": "Remove from list", "help": "Help", "shoppingListTitle": "Shopping list", "shoppingListEmpty": "Your shopping list is empty. Add items with the cart button.", "shoppingToBuy": "To buy", "shoppingPurchased": "Already bought", "share": "SHARE", "infoTitle": "Gear & Pack", "infoCheckTitle": "Check items", "infoCheckBody": "Check what you take — the weight recalculates at the top.", "infoRequiredTitle": "Required", "infoRequiredBody": "Items with a lock = regulation (whistle, lamp, emergency blanket).", "infoGaugeTitle": "Weight gauge", "infoGaugeBody": "Target: pack < 15% of your weight. Green = OK, Orange = careful, Red = too heavy.", "infoAddTitle": "Add", "infoAddBody": "The + button at the bottom of each category for your own items.", "infoValidateBody": "Validate when your pack is ready — a check appears on the home screen.", "infoUnderstood": "Got it!", "prepTitle": "Pack preparation", "prepCounter": "{prepared} / {total} items packed", "prepAllReady": "All set! Enjoy your trek", "preDepartureTitle": "Pre-departure checklist", "preDepartureCounter": "{checked}/{total} checked", "preDep1": "Check the weather for the coming days", "preDep2": "Charge phone + power bank", "preDep3": "Tell a relative about your itinerary", "preDep4": "Check the pack is well closed and waterproof", "preDep5": "Fill the water bottles (minimum 2L)", "preDep6": "Apply sunscreen and anti-chafing cream", "preDep7": "Check laces and boot tightness", "preDep8": "Download the offline maps", "bagOk": "PACK OK — READY TO GO", "validateBag": "VALIDATE MY PACK", "cancelValidation": "CANCEL VALIDATION", "shoppingListButton": "SHOPPING LIST", "shareGroup": "SHARE WITH THE GROUP", "exportList": "EXPORT THE LIST", "bagValidTitle": "Pack validated", "bagValidBody": "All {total} required items are in your pack.\n\nTotal weight: {weight} kg ({pct}% of body weight)\n\nAre you sure your pack is ready?", "checkAgain": "Check again", "yesBagOk": "Yes, pack OK", "bagValidatedSnack": "Pack validated!", "validationCancelledSnack": "Pack validation cancelled — you can edit your gear.", "missingTitle": "Missing gear", "missingBody": "{checked}/{total} required items checked.", "missingList": "Missing:", "understood": "Got it", "validateAnyway": "Validate anyway", "bagValidatedMissingSnack": "Pack validated (with missing items)!", "shareGroupHint": "Join a group to share your checklist."},
    "de": {"title": "Ausrustung & Rucksack", "requirementRequired": "Pflicht", "addItem": "Artikel hinzufugen", "addItemTitle": "Artikel hinzufugen", "fieldName": "Name", "fieldWeightGrams": "Gewicht (Gramm)", "add": "Hinzufugen", "editWeightTitle": "Gewicht andern", "editCustomTitle": "Eigenen Artikel bearbeiten", "modify": "Bearbeiten", "delete": "Loschen", "deleteItemTitle": "Diesen Artikel loschen?", "deleteItemBody": "Der Artikel \"{name}\" wird endgultig geloscht.", "requiredWarnTitle": "Pflichtausrustung", "requiredWarnBody": "Diese Ausrustung ist aus Sicherheitsgrunden Pflicht (angelehnt an UTMB-Regeln). Wirklich entfernen?", "keep": "Behalten", "removeAnyway": "Trotzdem entfernen", "reduceQuantity": "Menge verringern", "increaseQuantity": "Menge erhohen", "addToShoppingList": "Zur Einkaufsliste hinzufugen", "removeFromShoppingList": "Von der Liste entfernen", "help": "Hilfe", "shoppingListTitle": "Einkaufsliste", "shoppingListEmpty": "Deine Einkaufsliste ist leer. Fuge Artikel mit dem Warenkorb-Button hinzu.", "shoppingToBuy": "Zu kaufen", "shoppingPurchased": "Bereits gekauft", "share": "TEILEN", "infoTitle": "Ausrustung & Rucksack", "infoCheckTitle": "Artikel anhaken", "infoCheckBody": "Hake an, was du mitnimmst — das Gewicht wird oben neu berechnet.", "infoRequiredTitle": "Pflicht", "infoRequiredBody": "Artikel mit Schloss = Vorschrift (Pfeife, Lampe, Rettungsdecke).", "infoGaugeTitle": "Gewichtsanzeige", "infoGaugeBody": "Ziel: Rucksack < 15% deines Gewichts. Grun = OK, Orange = Achtung, Rot = zu schwer.", "infoAddTitle": "Hinzufugen", "infoAddBody": "Der +-Button unten in jeder Kategorie fur eigene Artikel.", "infoValidateBody": "Bestatige, wenn dein Rucksack fertig ist — ein Haken erscheint auf der Startseite.", "infoUnderstood": "Verstanden!", "prepTitle": "Rucksack packen", "prepCounter": "{prepared} / {total} Artikel gepackt", "prepAllReady": "Alles bereit! Gute Tour", "preDepartureTitle": "Checkliste vor dem Start", "preDepartureCounter": "{checked}/{total} gepruft", "preDep1": "Wetter der nachsten Tage prufen", "preDep2": "Telefon + Powerbank laden", "preDep3": "Eine nahestehende Person uber die Route informieren", "preDep4": "Prufen, dass der Rucksack gut geschlossen und wasserdicht ist", "preDep5": "Trinkflaschen fullen (mindestens 2L)", "preDep6": "Sonnencreme und Anti-Scheuer-Creme auftragen", "preDep7": "Schnursenkel und Schuhsitz prufen", "preDep8": "Offline-Karten herunterladen", "bagOk": "RUCKSACK OK — STARTBEREIT", "validateBag": "RUCKSACK BESTATIGEN", "cancelValidation": "BESTATIGUNG AUFHEBEN", "shoppingListButton": "EINKAUFSLISTE", "shareGroup": "MIT DER GRUPPE TEILEN", "exportList": "LISTE EXPORTIEREN", "bagValidTitle": "Rucksack bestatigt", "bagValidBody": "Alle {total} Pflichtartikel sind im Rucksack.\n\nGesamtgewicht: {weight} kg ({pct}% des Korpergewichts)\n\nBist du sicher, dass dein Rucksack fertig ist?", "checkAgain": "Nochmal prufen", "yesBagOk": "Ja, Rucksack OK", "bagValidatedSnack": "Rucksack bestatigt!", "validationCancelledSnack": "Bestatigung aufgehoben — du kannst deine Ausrustung andern.", "missingTitle": "Fehlende Ausrustung", "missingBody": "{checked}/{total} Pflichtartikel angehakt.", "missingList": "Es fehlt:", "understood": "Verstanden", "validateAnyway": "Trotzdem bestatigen", "bagValidatedMissingSnack": "Rucksack bestatigt (mit fehlenden Artikeln)!", "shareGroupHint": "Tritt einer Gruppe bei, um deine Checkliste zu teilen."},
    "it": {"title": "Attrezzatura & Zaino", "requirementRequired": "Obbligatorio", "addItem": "Aggiungi un articolo", "addItemTitle": "Aggiungi un articolo", "fieldName": "Nome", "fieldWeightGrams": "Peso (grammi)", "add": "Aggiungi", "editWeightTitle": "Modifica il peso", "editCustomTitle": "Modifica articolo personalizzato", "modify": "Modifica", "delete": "Elimina", "deleteItemTitle": "Eliminare questo articolo?", "deleteItemBody": "L'articolo \"{name}\" sara eliminato definitivamente.", "requiredWarnTitle": "Attrezzatura obbligatoria", "requiredWarnBody": "Questa attrezzatura e obbligatoria per la sicurezza (ispirata al regolamento UTMB). Vuoi davvero rimuoverla?", "keep": "Mantieni", "removeAnyway": "Rimuovi comunque", "reduceQuantity": "Riduci quantita", "increaseQuantity": "Aumenta quantita", "addToShoppingList": "Aggiungi alla lista della spesa", "removeFromShoppingList": "Rimuovi dalla lista", "help": "Aiuto", "shoppingListTitle": "Lista della spesa", "shoppingListEmpty": "La tua lista della spesa e vuota. Aggiungi articoli con il pulsante carrello.", "shoppingToBuy": "Da comprare", "shoppingPurchased": "Gia comprato", "share": "CONDIVIDI", "infoTitle": "Attrezzatura & Zaino", "infoCheckTitle": "Spunta gli articoli", "infoCheckBody": "Spunta cio che porti — il peso si ricalcola in alto.", "infoRequiredTitle": "Obbligatori", "infoRequiredBody": "Articoli con lucchetto = regolamento (fischietto, lampada, coperta di sopravvivenza).", "infoGaugeTitle": "Indicatore peso", "infoGaugeBody": "Obiettivo: zaino < 15% del tuo peso. Verde = OK, Arancione = attenzione, Rosso = troppo pesante.", "infoAddTitle": "Aggiungi", "infoAddBody": "Il pulsante + in fondo a ogni categoria per i tuoi articoli.", "infoValidateBody": "Conferma quando lo zaino e pronto — un segno di spunta appare sulla home.", "infoUnderstood": "Capito!", "prepTitle": "Preparazione dello zaino", "prepCounter": "{prepared} / {total} articoli preparati", "prepAllReady": "Tutto pronto! Buon trekking", "preDepartureTitle": "Checklist prima della partenza", "preDepartureCounter": "{checked}/{total} verificati", "preDep1": "Controllare il meteo dei prossimi giorni", "preDep2": "Caricare telefono + power bank", "preDep3": "Avvisare una persona cara del tuo itinerario", "preDep4": "Verificare che lo zaino sia ben chiuso e impermeabile", "preDep5": "Riempire le borracce (minimo 2L)", "preDep6": "Applicare crema solare e anti-sfregamento", "preDep7": "Controllare lacci e serraggio degli scarponi", "preDep8": "Scaricare le mappe offline", "bagOk": "ZAINO OK — PRONTO A PARTIRE", "validateBag": "CONFERMA IL MIO ZAINO", "cancelValidation": "ANNULLA LA CONFERMA", "shoppingListButton": "LISTA DELLA SPESA", "shareGroup": "CONDIVIDI CON IL GRUPPO", "exportList": "ESPORTA LA LISTA", "bagValidTitle": "Zaino confermato", "bagValidBody": "Tutti i {total} articoli obbligatori sono nello zaino.\n\nPeso totale: {weight} kg ({pct}% del peso corporeo)\n\nSei sicuro che lo zaino sia pronto?", "checkAgain": "Controlla ancora", "yesBagOk": "Si, zaino OK", "bagValidatedSnack": "Zaino confermato!", "validationCancelledSnack": "Conferma annullata — puoi modificare la tua attrezzatura.", "missingTitle": "Attrezzatura mancante", "missingBody": "{checked}/{total} articoli obbligatori spuntati.", "missingList": "Manca:", "understood": "Capito", "validateAnyway": "Conferma comunque", "bagValidatedMissingSnack": "Zaino confermato (con articoli mancanti)!", "shareGroupHint": "Unisciti a un gruppo per condividere la tua checklist."},
    "es": {"title": "Equipo & Mochila", "requirementRequired": "Obligatorio", "addItem": "Anadir un articulo", "addItemTitle": "Anadir un articulo", "fieldName": "Nombre", "fieldWeightGrams": "Peso (gramos)", "add": "Anadir", "editWeightTitle": "Editar el peso", "editCustomTitle": "Editar articulo personalizado", "modify": "Editar", "delete": "Eliminar", "deleteItemTitle": "Eliminar este articulo?", "deleteItemBody": "El articulo \"{name}\" se eliminara definitivamente.", "requiredWarnTitle": "Equipo obligatorio", "requiredWarnBody": "Este equipo es obligatorio por seguridad (inspirado en el reglamento UTMB). Seguro que quieres quitarlo?", "keep": "Mantener", "removeAnyway": "Quitar de todos modos", "reduceQuantity": "Reducir cantidad", "increaseQuantity": "Aumentar cantidad", "addToShoppingList": "Anadir a la lista de la compra", "removeFromShoppingList": "Quitar de la lista", "help": "Ayuda", "shoppingListTitle": "Lista de la compra", "shoppingListEmpty": "Tu lista de la compra esta vacia. Anade articulos con el boton del carrito.", "shoppingToBuy": "Por comprar", "shoppingPurchased": "Ya comprado", "share": "COMPARTIR", "infoTitle": "Equipo & Mochila", "infoCheckTitle": "Marca los articulos", "infoCheckBody": "Marca lo que llevas — el peso se recalcula arriba.", "infoRequiredTitle": "Obligatorios", "infoRequiredBody": "Articulos con candado = reglamento (silbato, linterna, manta de supervivencia).", "infoGaugeTitle": "Indicador de peso", "infoGaugeBody": "Objetivo: mochila < 15% de tu peso. Verde = OK, Naranja = cuidado, Rojo = demasiado pesado.", "infoAddTitle": "Anadir", "infoAddBody": "El boton + al final de cada categoria para tus propios articulos.", "infoValidateBody": "Valida cuando tu mochila este lista — aparecera una marca en el inicio.", "infoUnderstood": "Entendido!", "prepTitle": "Preparacion de la mochila", "prepCounter": "{prepared} / {total} articulos preparados", "prepAllReady": "Todo listo! Buen trek", "preDepartureTitle": "Checklist antes de salir", "preDepartureCounter": "{checked}/{total} verificados", "preDep1": "Comprobar el tiempo de los proximos dias", "preDep2": "Cargar telefono + bateria externa", "preDep3": "Avisar a un allegado de tu itinerario", "preDep4": "Comprobar que la mochila este bien cerrada y estanca", "preDep5": "Llenar las cantimploras (minimo 2L)", "preDep6": "Aplicar crema solar y antirozaduras", "preDep7": "Comprobar los cordones y el ajuste de las botas", "preDep8": "Descargar los mapas offline", "bagOk": "MOCHILA OK — LISTA PARA SALIR", "validateBag": "VALIDAR MI MOCHILA", "cancelValidation": "ANULAR LA VALIDACION", "shoppingListButton": "LISTA DE COMPRA", "shareGroup": "COMPARTIR CON EL GRUPO", "exportList": "EXPORTAR LA LISTA", "bagValidTitle": "Mochila validada", "bagValidBody": "Los {total} articulos obligatorios estan en tu mochila.\n\nPeso total: {weight} kg ({pct}% del peso corporal)\n\nSeguro que tu mochila esta lista?", "checkAgain": "Comprobar de nuevo", "yesBagOk": "Si, mochila OK", "bagValidatedSnack": "Mochila validada!", "validationCancelledSnack": "Validacion anulada — puedes modificar tu equipo.", "missingTitle": "Equipo faltante", "missingBody": "{checked}/{total} articulos obligatorios marcados.", "missingList": "Falta:", "understood": "Entendido", "validateAnyway": "Validar de todos modos", "bagValidatedMissingSnack": "Mochila validada (con articulos faltantes)!", "shareGroupHint": "Unete a un grupo para compartir tu checklist."},
}

HUB_SUB = {
    "fr": "Preparez votre sac a dos",
    "en": "Prepare your backpack",
    "de": "Bereite deinen Rucksack vor",
    "it": "Prepara il tuo zaino",
    "es": "Prepara tu mochila",
}
NAV_TITLE = {loc: SCREEN[loc]["title"] for loc in SCREEN}
LOCALES = ["fr", "en", "de", "it", "es"]


def build_checklist_subtree(loc, existing):
    ck = dict(existing) if isinstance(existing, dict) else {}
    ck["title"] = SCREEN[loc]["title"]
    ck.setdefault("subtitle", HUB_SUB[loc])
    ck["categories"] = CATEGORIES[loc]
    ck["items"] = {k: v[loc] for k, v in ITEMS.items()}
    ck["weight"] = WEIGHT[loc]
    ck["ui"] = SCREEN[loc]
    return ck


def main():
    for loc in LOCALES:
        path = os.path.join(I18N_DIR, "%s.i18n.json" % loc)
        with io.open(path, encoding="utf-8") as f:
            data = json.load(f)
        data["checklist"] = build_checklist_subtree(loc, data.get("checklist", {}))
        data.setdefault("nav", {})
        data["nav"]["checklist"] = NAV_TITLE[loc]
        data.setdefault("hub", {}).setdefault("cards", {})
        data["hub"]["cards"]["checklist"] = NAV_TITLE[loc]
        data["hub"]["cards"]["checklistSub"] = HUB_SUB[loc]
        with io.open(path, "w", encoding="utf-8") as f:
            f.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
        print("patched", loc, "items=%d" % len(ITEMS))


if __name__ == "__main__":
    main()
