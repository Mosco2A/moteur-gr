package com.only1cent.moteur_gr

import io.flutter.embedding.android.FlutterFragmentActivity

// Le plugin `health` exige une ComponentActivity (FlutterFragmentActivity)
// au lieu de la FlutterActivity par defaut, sans quoi il signale une
// "plugin health unhealthy" au demarrage. FlutterFragmentActivity herite de
// FragmentActivity (donc ComponentActivity) et reste 100% compatible Flutter.
class MainActivity : FlutterFragmentActivity()
