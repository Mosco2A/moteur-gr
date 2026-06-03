// E5.19b — Widget Home Screen Android — progression trek.
//
// Widget AppWidgetProvider qui lit les donnees SharedPreferences
// ecrites par WidgetDataService (E5.19a Dart) et affiche
// la progression du trek en cours sur le Home Screen Android.
//
// Donnees lues depuis SharedPreferences (FlutterSharedPreferences) :
// - flutter.widget_trek_trail_name
// - flutter.widget_trek_stage_name
// - flutter.widget_trek_stage_progress (0.0-1.0)
// - flutter.widget_trek_distance_remaining (metres)
// - flutter.widget_trek_eta_minutes
// - flutter.widget_trek_altitude (metres)
// - flutter.widget_trek_stage_index
// - flutter.widget_trek_total_stages
//
// Layout : widget_trek_progress.xml (a creer dans res/layout/)
// Config : widget_trek_info.xml (a creer dans res/xml/)

package com.only1cent.moteur_gr

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews

/// Widget Android Home Screen pour la progression trek.
///
/// Lit les donnees de progression depuis SharedPreferences
/// (ecrites par le code Dart via WidgetDataService) et
/// met a jour l'affichage du widget sur le Home Screen.
class TrekWidget : AppWidgetProvider() {

    companion object {
        // Prefixe Flutter SharedPreferences
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val PREFIX = "flutter.widget_trek_"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, prefs)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        prefs: SharedPreferences
    ) {
        // Lire les donnees trek depuis SharedPreferences
        val trailName = prefs.getString("${PREFIX}trail_name", "Trek") ?: "Trek"
        val stageName = prefs.getString("${PREFIX}stage_name", "--") ?: "--"
        val stageProgress = prefs.getFloat("${PREFIX}stage_progress", 0f)
        val distanceRemaining = prefs.getFloat("${PREFIX}distance_remaining", 0f)
        val etaMinutes = prefs.getInt("${PREFIX}eta_minutes", 0)
        val altitude = prefs.getFloat("${PREFIX}altitude", 0f)
        val stageIndex = prefs.getInt("${PREFIX}stage_index", 0)
        val totalStages = prefs.getInt("${PREFIX}total_stages", 0)

        // Placeholder : RemoteViews sera connecte au layout XML
        // quand les ressources Android seront creees.
        // Pour l'instant, le widget lit les donnees mais n'a pas
        // de layout XML associe. Le layout sera :
        //
        // - Nom du trail (trailName)
        // - Etape en cours (stageName) — "Etape 3/16"
        // - Barre de progression (stageProgress %)
        // - Distance restante + ETA
        // - Altitude actuelle

        // TODO: Creer res/layout/widget_trek_progress.xml
        // TODO: Creer res/xml/widget_trek_info.xml
        // TODO: Connecter RemoteViews au layout
        //
        // val views = RemoteViews(context.packageName, R.layout.widget_trek_progress)
        // views.setTextViewText(R.id.trail_name, trailName)
        // views.setTextViewText(R.id.stage_name, "$stageName ($stageIndex/$totalStages)")
        // views.setProgressBar(R.id.progress_bar, 100, (stageProgress * 100).toInt(), false)
        // views.setTextViewText(R.id.distance_remaining, "${(distanceRemaining / 1000).toInt()} km")
        // views.setTextViewText(R.id.eta, "${etaMinutes} min")
        // views.setTextViewText(R.id.altitude, "${altitude.toInt()} m")
        // appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    override fun onEnabled(context: Context) {
        // Premier widget ajoute au Home Screen
    }

    override fun onDisabled(context: Context) {
        // Dernier widget retire du Home Screen
    }
}
