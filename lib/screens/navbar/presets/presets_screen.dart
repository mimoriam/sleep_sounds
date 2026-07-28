import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/mix_preset.dart';
import '../../../models/sound_model.dart';
import '../../../providers/audio_provider.dart';
import '../../../providers/presets_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_themes.dart';
import '../../../utils/page_transitions.dart';
import '../home/widgets/sound_playing.dart';

class PresetsScreen extends StatelessWidget {
  const PresetsScreen({super.key});

  void _showSaveMixDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _SaveMixDialog(),
    );
  }

  void _applyPreset(BuildContext context, MixPreset preset) {
    HapticFeedback.mediumImpact();
    final audio = context.read<AudioProvider>();
    final mainSound = SoundRegistry.getByIdOrNull(preset.mainSoundId) ??
        SoundRegistry.allSounds.first;

    final List<({SoundType sound, double volume})> layerTuples = [];
    int skippedLayers = 0;
    for (final l in preset.layers) {
      final s = SoundRegistry.getByIdOrNull(l.soundId);
      if (s != null) {
        layerTuples.add((sound: s, volume: l.volume));
      } else {
        skippedLayers++;
      }
    }

    audio.loadPreset(
      mainSound: mainSound,
      layers: layerTuples,
      masterVolume: preset.masterVolume,
    );

    if (skippedLayers > 0 && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Loaded preset (skipped $skippedLayers missing sound layer(s))',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    Navigator.push(
      context,
      SlideUpFadeRoute(page: SoundPlaying(sound: mainSound)),
    );
  }

  void _showOptionsSheet(BuildContext context, MixPreset preset) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.play_circle_fill, color: AppColors.primaryCyan),
              title: Text('Play "${preset.name}"', style: TextStyle(color: AppColors.text(context))),
              onTap: () {
                Navigator.pop(ctx);
                _applyPreset(context, preset);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.white70),
              title: Text('Rename Preset', style: TextStyle(color: AppColors.text(context))),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(context, preset);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.errorRed),
              title: const Text('Delete Preset', style: TextStyle(color: AppColors.errorRed)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirmation(context, preset);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, MixPreset preset) {
    showDialog(
      context: context,
      builder: (ctx) => _RenamePresetDialog(preset: preset),
    );
  }

  void _showDeleteConfirmation(BuildContext context, MixPreset preset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Preset?', style: TextStyle(color: AppColors.text(context))),
        content: Text(
          'Are you sure you want to delete "${preset.name}"? This cannot be undone.',
          style: TextStyle(color: AppColors.textMuted(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<PresetsProvider>().deletePreset(preset.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final presetsProvider = context.watch<PresetsProvider>();
    final presets = presetsProvider.presets;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryCyan,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.bookmark_add_rounded),
        label: const Text('Save Current Mix', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showSaveMixDialog(context),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppThemes.paddingScreen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Saved Mix Presets',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Save your favorite ambient layer combinations',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted(context),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: presets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 64,
                              color: AppColors.textMuted(context),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No saved presets yet',
                              style: TextStyle(
                                color: AppColors.text(context),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Combine sounds together using "Add Sound Layer" on the player screen, then tap "Save Current Mix" below.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textMuted(context),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: presets.length,
                        itemBuilder: (context, index) {
                          final preset = presets[index];
                          final mainSound = SoundRegistry.getByIdOrNull(preset.mainSoundId) ??
                              SoundRegistry.allSounds.first;
                          final layerCount = preset.layers.length;

                          // UI #2: Wrap with Dismissible for swipe-to-delete
                          return Dismissible(
                            key: Key(preset.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.card(context),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  title: Text('Delete Preset?',
                                      style: TextStyle(color: AppColors.text(context))),
                                  content: Text(
                                    'Delete "${preset.name}"? This cannot be undone.',
                                    style:
                                        TextStyle(color: AppColors.textMuted(context)),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text('Cancel',
                                          style: TextStyle(
                                              color: AppColors.textMuted(context))),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.errorRed,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete',
                                          style:
                                              TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                              return result ?? false;
                            },
                            onDismissed: (_) {
                              context
                                  .read<PresetsProvider>()
                                  .deletePreset(preset.id);
                            },
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.errorRed,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.card(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.border(context),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryCyan.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    mainSound.icon,
                                    color: AppColors.primaryCyan,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  preset.name,
                                  style: TextStyle(
                                    color: AppColors.text(context),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  'Main: ${mainSound.title} • $layerCount layer(s)',
                                  style: TextStyle(
                                    color: AppColors.textMuted(context),
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.more_vert_rounded,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () =>
                                          _showOptionsSheet(context, preset),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.play_circle_fill_rounded,
                                        color: AppColors.primaryCyan,
                                        size: 32,
                                      ),
                                      onPressed: () =>
                                          _applyPreset(context, preset),
                                    ),
                                  ],
                                ),
                                onTap: () => _applyPreset(context, preset),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveMixDialog extends StatefulWidget {
  const _SaveMixDialog();

  @override
  State<_SaveMixDialog> createState() => _SaveMixDialogState();
}

class _SaveMixDialogState extends State<_SaveMixDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final audio = context.read<AudioProvider>();
    _controller = TextEditingController(
      text: 'My ${audio.currentSound.title} Mix',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.read<AudioProvider>();
    final presets = context.read<PresetsProvider>();

    return AlertDialog(
      backgroundColor: AppColors.card(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Save Current Mix',
        style: TextStyle(color: AppColors.text(context)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Main sound: ${audio.currentSound.title}',
              style: TextStyle(color: AppColors.textMuted(context), fontSize: 13),
            ),
            if (audio.soundLayers.isNotEmpty)
              Text(
                'Layers: ${audio.soundLayers.map((l) => l.soundType.title).join(", ")}',
                style: const TextStyle(color: AppColors.primaryCyan, fontSize: 13),
              )
            else
              Text(
                'No additional layers added',
                style: TextStyle(color: AppColors.textMuted(context), fontSize: 12),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(color: AppColors.text(context)),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Preset Name',
                hintText: 'e.g. Cozy Rain Night',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(context))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryCyan,
            foregroundColor: Colors.black,
          ),
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () async {
                  final name = _controller.text.trim();
                  final layers = audio.soundLayers
                      .map((l) => LayerConfig(
                            soundId: l.soundType.id,
                            volume: l.volume,
                          ))
                      .toList();

                  final cardColor = AppColors.card(context);
                  final textColor = AppColors.text(context);

                  final success = await presets.savePreset(
                    name: name,
                    mainSoundId: audio.currentSound.id,
                    layers: layers,
                    masterVolume: audio.masterVolume,
                  );

                  if (context.mounted) Navigator.pop(context);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Saved preset "$name"'
                              : 'Failed to save preset (Limit reached)',
                          style: TextStyle(color: textColor),
                        ),
                        backgroundColor: cardColor,
                      ),
                    );
                  }
                },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _RenamePresetDialog extends StatefulWidget {
  final MixPreset preset;

  const _RenamePresetDialog({required this.preset});

  @override
  State<_RenamePresetDialog> createState() => _RenamePresetDialogState();
}

class _RenamePresetDialogState extends State<_RenamePresetDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.preset.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card(context),
      title: Text('Rename Preset', style: TextStyle(color: AppColors.text(context))),
      content: SingleChildScrollView(
        child: TextField(
          controller: _controller,
          autofocus: true,
          style: TextStyle(color: AppColors.text(context)),
          onChanged: (_) => setState(() {}),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(context))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryCyan,
            foregroundColor: Colors.black,
          ),
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () {
                  context
                      .read<PresetsProvider>()
                      .renamePreset(widget.preset.id, _controller.text.trim());
                  Navigator.pop(context);
                },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
