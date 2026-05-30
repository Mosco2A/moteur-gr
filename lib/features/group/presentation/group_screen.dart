import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/group_member.dart';
import '../providers/group_provider.dart';
import '../services/group_tracking_service.dart';
import '../widgets/member_position_card.dart';

/// Ecran de gestion du groupe de localisation partagee.
class GroupScreen extends ConsumerStatefulWidget {
  const GroupScreen({super.key, required this.trailId});
  final String trailId;
  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends ConsumerState<GroupScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() { _codeController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final groupCode = ref.watch(groupCodeProvider);
    final membersAsync = ref.watch(groupMembersProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Groupe'), actions: [
        if (groupCode != null) IconButton(icon: const Icon(Icons.exit_to_app),
          tooltip: 'Quitter le groupe', onPressed: _leaveGroup),
      ]),
      body: groupCode == null ? _buildJoinOrCreate(theme)
          : _buildGroupView(theme, groupCode, membersAsync),
    );
  }

  Widget _buildJoinOrCreate(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Localisation partagee', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppTheme.spacingSm),
        Text('Partagez votre position avec votre groupe de randonnee.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.grisGranite)),
        const SizedBox(height: AppTheme.spacingXl),
        ElevatedButton.icon(onPressed: _isLoading ? null : _createGroup,
          icon: _isLoading ? const SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.group_add),
          label: const Text('Creer un groupe')),
        const SizedBox(height: AppTheme.spacingLg),
        Row(children: [const Expanded(child: Divider()),
          Padding(padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
            child: Text('ou', style: theme.textTheme.bodySmall)),
          const Expanded(child: Divider())]),
        const SizedBox(height: AppTheme.spacingLg),
        Text('Code du groupe', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppTheme.spacingSm),
        TextField(controller: _codeController, textCapitalization: TextCapitalization.characters,
          maxLength: 6, decoration: const InputDecoration(hintText: 'Ex: ABC123', counterText: ''),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), UpperCaseTextFormatter()]),
        const SizedBox(height: AppTheme.spacingSm),
        OutlinedButton.icon(onPressed: _isLoading ? null : _joinGroup,
          icon: const Icon(Icons.login), label: const Text('Rejoindre')),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: AppTheme.spacingBase),
          child: Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.rougeUrgence),
            textAlign: TextAlign.center)),
      ]),
    );
  }

  Widget _buildGroupView(ThemeData theme, String groupCode, AsyncValue<List<GroupMember>> membersAsync) {
    final watcherCount = ref.watch(watcherCountProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Card(child: Padding(padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Code du groupe', style: theme.textTheme.labelMedium),
              const SizedBox(height: AppTheme.spacingXs),
              Text(groupCode, style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold, letterSpacing: 4)),
            ])),
            IconButton(icon: const Icon(Icons.copy), tooltip: 'Copier le code', onPressed: () {
              Clipboard.setData(ClipboardData(text: groupCode));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copie')));
            }),
          ]))),
        const SizedBox(height: AppTheme.spacingSm),
        if (watcherCount >= 2) Container(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(color: AppTheme.orangeDifficile.withAlpha(30),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard)),
          child: Text('Limite de 2 mateurs gratuits atteinte',
            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.orangeDifficile),
            textAlign: TextAlign.center)),
        const SizedBox(height: AppTheme.spacingBase),
        Text('Membres', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppTheme.spacingSm),
        membersAsync.when(
          data: (members) {
            if (members.isEmpty) return const Center(child: Padding(
              padding: EdgeInsets.all(AppTheme.spacingLg), child: Text('Aucun membre')));
            return Column(children: members.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              child: MemberPositionCard(member: m))).toList());
          },
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(AppTheme.spacingLg), child: CircularProgressIndicator())),
          error: (e, _) => Center(child: Text('Erreur chargement membres',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.rougeUrgence))),
        ),
      ]),
    );
  }

  Future<void> _createGroup() async {
    setState(() { _isLoading = true; _error = null; });
    final user = ref.read(authStateProvider);
    if (user == null) { setState(() { _isLoading = false; _error = 'Connexion requise'; }); return; }
    final service = ref.read(groupTrackingServiceProvider);
    final code = await service.createGroup(widget.trailId, uid: user.uid);
    if (code != null) ref.read(groupCodeProvider.notifier).set(code);
    else setState(() => _error = 'Impossible de creer le groupe');
    setState(() => _isLoading = false);
  }

  Future<void> _joinGroup() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) { setState(() => _error = 'Le code doit contenir 6 caracteres'); return; }
    setState(() { _isLoading = true; _error = null; });
    final user = ref.read(authStateProvider);
    if (user == null) { setState(() { _isLoading = false; _error = 'Connexion requise'; }); return; }
    final service = ref.read(groupTrackingServiceProvider);
    final joined = await service.joinGroup(code, uid: user.uid, displayName: user.displayName);
    if (joined) { ref.read(groupCodeProvider.notifier).set(code); _codeController.clear(); }
    else setState(() => _error = 'Groupe introuvable ou erreur');
    setState(() => _isLoading = false);
  }

  Future<void> _leaveGroup() async {
    final service = ref.read(groupTrackingServiceProvider);
    await service.leaveGroup();
    ref.read(groupCodeProvider.notifier).set(null);
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}
