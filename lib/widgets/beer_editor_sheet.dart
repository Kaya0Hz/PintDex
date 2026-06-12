import 'dart:io';

import 'package:beer_tracker/models/beer_entry.dart';
import 'package:beer_tracker/services/beer_repository.dart';
import 'package:beer_tracker/widgets/beer_bottle_rating.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BeerEditorSheet extends StatefulWidget {
  const BeerEditorSheet({super.key, required this.repository, this.initial});

  final BeerRepository repository;
  final BeerEntry? initial;

  @override
  State<BeerEditorSheet> createState() => _BeerEditorSheetState();
}

class _BeerEditorSheetState extends State<BeerEditorSheet> {
  late final TextEditingController _titleController;
  late BeerType _type;
  XFile? _image;
  int _sweetnessRating = 5;
  int _bitternessRating = 6;
  int _bodyRating = 6;
  int _acidityRating = 3;
  int _overallRating = 7;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    _type = widget.initial?.type ?? BeerType.ale;
    _sweetnessRating = widget.initial?.sweetnessRating ?? 5;
    _bitternessRating = widget.initial?.bitternessRating ?? 6;
    _bodyRating = widget.initial?.bodyRating ?? 6;
    _acidityRating = widget.initial?.acidityRating ?? 3;
    _overallRating = widget.initial?.overallRating ?? 7;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) return;

    final picked = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: 'Images',
          extensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
        ),
      ],
    );
    if (picked != null) {
      setState(() => _image = picked);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.repository.upsertBeer(
      existing: widget.initial,
      draft: BeerDraft(
        title: _titleController.text,
        type: _type,
        sweetnessRating: _sweetnessRating,
        bitternessRating: _bitternessRating,
        bodyRating: _bodyRating,
        acidityRating: _acidityRating,
        overallRating: _overallRating,
        image: _image,
      ),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final image = _image ?? (widget.initial?.imagePath.isNotEmpty == true ? XFile(widget.initial!.imagePath) : null);

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 5,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.initial == null ? 'Add beer' : 'Edit beer',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use the label photo as the visual title and rate the pour.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                _ImagePickerTile(
                  image: image,
                  onTap: _pickImage,
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Beer title',
                    hintText: 'Optional manual name',
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<BeerType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Beer type'),
                  items: BeerType.values
                      .where((type) => type != BeerType.all)
                      .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _type = value);
                    }
                  },
                ),
                const SizedBox(height: 18),
                _GuideTile(
                  title: 'Quick guide',
                  items: const [
                    'Sweetness: how sweet or caramel-like it tastes.',
                    'Bitterness: hop bite and dry finish.',
                    'Body: how thick, heavy, or full it feels.',
                    'Acidity: tart, bright, or tangy edge.',
                  ],
                ),
                const SizedBox(height: 18),
                _RatingEditor(label: 'Sweetness', value: _sweetnessRating, onChanged: (value) => setState(() => _sweetnessRating = value)),
                const SizedBox(height: 18),
                _RatingEditor(label: 'Bitterness', value: _bitternessRating, onChanged: (value) => setState(() => _bitternessRating = value)),
                const SizedBox(height: 18),
                _RatingEditor(label: 'Body', value: _bodyRating, onChanged: (value) => setState(() => _bodyRating = value)),
                const SizedBox(height: 18),
                _RatingEditor(label: 'Acidity', value: _acidityRating, onChanged: (value) => setState(() => _acidityRating = value)),
                const SizedBox(height: 18),
                _RatingEditor(label: 'Overall', value: _overallRating, onChanged: (value) => setState(() => _overallRating = value)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Saving...' : 'Save beer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingEditor extends StatelessWidget {
  const _RatingEditor({required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
          ),
          child: BeerBottleRating(value: value, onChanged: onChanged, size: 18, spacing: 2),
        ),
      ],
    );
  }
}

class _GuideTile extends StatelessWidget {
  const _GuideTile({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        collapsedIconColor: scheme.onSurfaceVariant,
        iconColor: scheme.onSurfaceVariant,
        title: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        subtitle: Text('Tap for quick meanings', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        children: [
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(item, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePickerTile extends StatelessWidget {
  const _ImagePickerTile({required this.image, required this.onTap});

  final XFile? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primaryContainer, scheme.secondaryContainer],
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: image == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sports_bar_rounded, size: 48, color: scheme.onPrimaryContainer),
                      const SizedBox(height: 12),
                      Text('Add a label photo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer)),
                      const SizedBox(height: 6),
                      Text('Capture on Android or pick a file on Linux', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer.withValues(alpha: 0.78))),
                    ],
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(image!.path), fit: BoxFit.cover),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.56)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Label photo selected',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const Icon(Icons.edit_rounded, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
