// E5.19b — Widget Home Screen iOS (WidgetKit) — progression trek.
//
// Widget WidgetKit qui lit les donnees SharedPreferences (UserDefaults)
// ecrites par WidgetDataService (E5.19a Dart) et affiche
// la progression du trek en cours sur le Home Screen iOS.
//
// Donnees lues depuis UserDefaults (App Group shared container) :
// - widget_trek_trail_name
// - widget_trek_stage_name
// - widget_trek_stage_progress (0.0-1.0)
// - widget_trek_distance_remaining (metres)
// - widget_trek_eta_minutes
// - widget_trek_altitude (metres)
// - widget_trek_stage_index
// - widget_trek_total_stages
//
// Prerequis : App Group configure dans Xcode (ex: group.com.only1cent.g20App)
// Le widget sera ajoute au projet Xcode comme extension WidgetKit.

import WidgetKit
import SwiftUI

/// Donnees de progression trek pour le widget.
struct TrekProgressEntry: TimelineEntry {
    let date: Date
    let trailName: String
    let stageName: String
    let stageProgress: Double
    let distanceRemaining: Double
    let etaMinutes: Int
    let altitude: Double
    let stageIndex: Int
    let totalStages: Int

    /// Entree placeholder (widget pas encore configure).
    static var placeholder: TrekProgressEntry {
        TrekProgressEntry(
            date: Date(),
            trailName: "GR20",
            stageName: "Etape 3 - Haut Asco",
            stageProgress: 0.45,
            distanceRemaining: 5200,
            etaMinutes: 120,
            altitude: 1422,
            stageIndex: 3,
            totalStages: 16
        )
    }
}

/// Provider de timeline pour le widget trek.
///
/// Lit les donnees depuis UserDefaults (App Group) et
/// fournit les entrees au widget WidgetKit.
struct TrekProgressProvider: TimelineProvider {
    // App Group ID pour partage de donnees Flutter <-> Widget
    private let appGroupId = "group.com.only1cent.g20App"
    private let prefix = "flutter.widget_trek_"

    func placeholder(in context: Context) -> TrekProgressEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (TrekProgressEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TrekProgressEntry>) -> Void) {
        let entry = readEntry()
        // Rafraichir toutes les 5 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    /// Lit les donnees de progression depuis UserDefaults (App Group).
    private func readEntry() -> TrekProgressEntry {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            return .placeholder
        }

        return TrekProgressEntry(
            date: Date(),
            trailName: defaults.string(forKey: "\(prefix)trail_name") ?? "GR20",
            stageName: defaults.string(forKey: "\(prefix)stage_name") ?? "--",
            stageProgress: defaults.double(forKey: "\(prefix)stage_progress"),
            distanceRemaining: defaults.double(forKey: "\(prefix)distance_remaining"),
            etaMinutes: defaults.integer(forKey: "\(prefix)eta_minutes"),
            altitude: defaults.double(forKey: "\(prefix)altitude"),
            stageIndex: defaults.integer(forKey: "\(prefix)stage_index"),
            totalStages: defaults.integer(forKey: "\(prefix)total_stages")
        )
    }
}

/// Vue SwiftUI du widget trek progression.
///
/// Affiche le nom du trail, l'etape en cours, la progression,
/// la distance restante, l'ETA et l'altitude.
struct TrekWidgetEntryView: View {
    var entry: TrekProgressEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Titre trek
            Text(entry.trailName)
                .font(.headline)
                .foregroundColor(.white)

            // Etape en cours
            Text("\(entry.stageName) (\(entry.stageIndex)/\(entry.totalStages))")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))

            // Barre de progression
            ProgressView(value: entry.stageProgress)
                .tint(.green)

            // Stats
            HStack {
                Text("\(Int(entry.distanceRemaining / 1000)) km")
                    .font(.caption2)
                Spacer()
                Text("\(entry.etaMinutes) min")
                    .font(.caption2)
                Spacer()
                Text("\(Int(entry.altitude)) m")
                    .font(.caption2)
            }
            .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(red: 0.176, green: 0.314, blue: 0.086) // #2D5016
        }
    }
}

/// Definition du widget WidgetKit.
struct TrekWidget: Widget {
    let kind: String = "TrekWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TrekProgressProvider()) { entry in
            TrekWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Progression GR20")
        .description("Suivez votre progression sur le trek en temps reel.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
