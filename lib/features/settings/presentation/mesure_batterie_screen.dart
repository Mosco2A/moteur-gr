/// L'ECRAN DE MESURE BATTERIE (lot 671-01), cache : on n'y arrive QUE par un
/// appui long sur le numero de version des reglages. Aucune entree de menu,
/// aucun bouton visible ailleurs.
///
/// Quatre blocs, et rien d'autre : le choix du profil GPS, l'etat en lecture
/// seule (profil, batterie, journal et ses cinq dernieres lignes), le partage
/// du journal, et l'autorisation de compter les pas. Ni Demarrer, ni Arreter,
/// ni Effacer : le journal est ouvert et alimente par le suivi du trek.
///
/// TEXTE EN CLAIR, SANS CLE DE TRADUCTION, comme les ecrans voisins qui
/// portent deja leur francais dans le code (reglages, groupe) : c'est un ecran
/// technique et cache, lu par une seule personne pendant une mesure.
///
/// AUCUNE DEPENDANCE RESEAU NI FIREBASE : le journal ne quitte le telephone
/// que par la feuille de partage du systeme.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/analytics/screen_entry.dart';
import '../../../core/services/gps_cadence.dart';
import '../../../core/services/journal_de_mesure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../trek/trek_facade.dart'
    show MeasureBench, kLowBatteryThreshold, measureBenchProvider;

/// Les trois profils que l'ecran propose, dans l'ordre affiche.
const List<PositionProfile> kMeasureProfiles = [
  PositionProfile.map,
  PositionProfile.batteryFirst,
  PositionProfile.lowBattery,
];

// Le nom d'un profil pour un randonneur.
String _profileTitle(PositionProfile profile) => switch (profile) {
  PositionProfile.map => 'GPS continu actuel',
  PositionProfile.batteryFirst => 'Batterie d’abord',
  PositionProfile.lowBattery => 'Batterie basse',
  PositionProfile.stationary => 'Arrêt',
};

String _profileDetail(PositionProfile profile) => switch (profile) {
  PositionProfile.map => 'Le GPS suit chaque pas. C’est la référence.',
  PositionProfile.batteryFirst => 'Un point GPS toutes les trois minutes.',
  PositionProfile.lowBattery => 'Un point GPS tous les quarts d’heure.',
  PositionProfile.stationary => 'Pas proposé pour cette mesure.',
};

/// L'ecran cache du build de mesure batterie.
class MesureBatterieScreen extends ConsumerStatefulWidget {
  /// Un ecran sans parametre : tout se lit sur le telephone.
  const MesureBatterieScreen({super.key});

  @override
  ConsumerState<MesureBatterieScreen> createState() =>
      _MesureBatterieScreenState();
}

class _MesureBatterieScreenState extends ConsumerState<MesureBatterieScreen> {
  PositionProfile? _profile;
  int? _battery;
  MeasureJournalSnapshot? _journal;
  bool? _stepsAllowed;
  bool _stepsRefused = false;

  MeasureBench get _bench => ref.read(measureBenchProvider);

  @override
  void initState() {
    super.initState();
    observeScreenEntry(ref, ScreenBreadcrumb.mesureBatterie);
    _refresh();
    _settle(_bench.stepsAllowed(), (allowed) => _stepsAllowed = allowed);
  }

  /// Relit l'etat. Chaque lecture arrive a son rythme : une lecture lente
  /// n'en retient aucune autre.
  void _refresh() {
    _settle(_bench.readProfile(), (profile) => _profile = profile);
    _settle(_bench.readBattery(), (battery) => _battery = battery);
    _settle(_bench.journal.snapshot(), (journal) => _journal = journal);
  }

  void _settle<T>(Future<T> read, void Function(T value) apply) {
    unawaited(
      read.then((value) {
        if (mounted) setState(() => apply(value));
      }, onError: (Object _) {}),
    );
  }

  Future<void> _choose(PositionProfile profile) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _bench.chooseProfile(profile);
      if (!mounted) return;
      setState(() => _profile = profile);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Profil choisi : ${_profileTitle(profile)}. '
            'Il s’applique tout de suite, sans arrêter la randonnée.',
          ),
        ),
      );
    } on Object {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Le profil n’a pas pu être enregistré. Réessayez.'),
        ),
      );
    }
    _refresh();
  }

  Future<void> _share() async {
    final messenger = ScaffoldMessenger.of(context);
    final journal = await _bench.journal.snapshot();
    if (!mounted) return;
    setState(() => _journal = journal);
    if (!journal.exists) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Le journal n’existe pas encore : il commence au démarrage '
            'du suivi d’une randonnée.',
          ),
        ),
      );
      return;
    }
    try {
      await Share.shareXFiles([
        XFile(journal.path, mimeType: 'text/plain'),
      ], subject: 'Journal de mesure batterie');
    } on Object {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Aucune application ne peut recevoir le journal.'),
        ),
      );
    }
  }

  Future<void> _askSteps() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Compter vos pas'),
        content: const Text(
          'Pendant la mesure, StepWays compte vos pas pour connaître la '
          'longueur de votre foulée. Le téléphone va vous demander '
          'l’autorisation « activité physique ». Vous pouvez refuser : la '
          'mesure continue sans les pas.',
        ),
        actions: [
          AppButton(
            label: 'Plus tard',
            variant: AppButtonVariant.text,
            isFullWidth: false,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppButton(
            label: 'Continuer',
            isFullWidth: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    bool granted;
    try {
      granted = await _bench.requestSteps();
    } on Object {
      granted = false;
    }
    if (!mounted) return;
    setState(() {
      _stepsAllowed = granted;
      _stepsRefused = !granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const AppHeader(title: 'Mesure batterie'),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        children: [
          _title(theme, 'Profil GPS'),
          AppCard(padding: EdgeInsets.zero, child: _profiles()),
          const SizedBox(height: AppTheme.spacingLg),
          _title(theme, 'État'),
          AppCard(child: _state(theme)),
          const SizedBox(height: AppTheme.spacingLg),
          _title(theme, 'Partager le journal'),
          AppButton(
            key: const ValueKey('mesure-partager'),
            label: 'Partager le journal',
            onPressed: _share,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _title(theme, 'Comptage des pas'),
          _steps(theme),
        ],
      ),
    );
  }

  Widget _title(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
    child: Text(text, style: theme.textTheme.titleMedium),
  );

  Widget _profiles() => RadioGroup<PositionProfile>(
    groupValue: _profile,
    onChanged: (profile) {
      if (profile != null) unawaited(_choose(profile));
    },
    child: Column(
      children: [
        for (final profile in kMeasureProfiles)
          ListTile(
            key: ValueKey('mesure-profil-${profile.name}'),
            leading: Radio<PositionProfile>(value: profile),
            title: Text(_profileTitle(profile)),
            subtitle: Text(_profileDetail(profile)),
            onTap: () => unawaited(_choose(profile)),
          ),
      ],
    ),
  );

  Widget _state(ThemeData theme) {
    final journal = _journal;
    final battery = _battery;
    final low = battery != null && battery < kLowBatteryThreshold;
    final lines = <String>[
      'Profil en vigueur : '
          '${_profile == null ? '…' : _profileTitle(_profile!)}',
      'Batterie : ${battery == null ? '…' : '$battery %'}'
          '${low ? ' (batterie basse)' : ''}',
      'Fichier : $kMeasureJournalFileName',
      if (journal == null)
        'Lecture du journal…'
      else if (!journal.exists)
        'Le journal n’existe pas encore : il commence au démarrage du suivi '
            'd’une randonnée.'
      else
        'Lignes écrites : ${journal.lineCount}',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
            child: Text(line),
          ),
        if (journal != null && journal.lastLines.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingSm),
          Text('Dernières lignes :', style: theme.textTheme.labelLarge),
          for (final line in journal.lastLines)
            Text(
              line,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
        ],
      ],
    );
  }

  Widget _steps(ThemeData theme) {
    final allowed = _stepsAllowed;
    final String phrase;
    if (allowed == true) {
      phrase = 'Le comptage des pas est autorisé : le journal note vos pas.';
    } else if (_stepsRefused) {
      phrase =
          'Sans cette autorisation, le journal s’écrit sans les pas '
          '(un tiret dans la colonne). La mesure continue normalement.';
    } else {
      phrase =
          'Pour la mesure, StepWays peut compter vos pas et en déduire la '
          'longueur de votre foulée. Rien ne quitte le téléphone.';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(phrase),
        const SizedBox(height: AppTheme.spacingSm),
        AppButton(
          key: const ValueKey('mesure-autoriser-pas'),
          label: switch (allowed) {
            true => 'Comptage des pas autorisé',
            _ when _stepsRefused => 'Autorisation refusée',
            null => 'Vérification de l’autorisation…',
            false => 'Autoriser le comptage des pas',
          },
          variant: AppButtonVariant.outline,
          // Accordee, refusee ou en cours de lecture : rien a redemander.
          onPressed: allowed == false && !_stepsRefused ? _askSteps : null,
        ),
      ],
    );
  }
}
