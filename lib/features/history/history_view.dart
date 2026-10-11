import 'package:flutter/material.dart';

import '../../models/translation_entry.dart';
import 'bloc/history_bloc.dart';
import 'bloc/history_state.dart';

/// Displays the translation history: a list of entries with per-row delete and
/// a "clear all" action. Purely presentational — it reads from [HistoryBloc].
class HistoryView extends StatefulWidget {
  final HistoryBloc bloc;

  const HistoryView({super.key, required this.bloc});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  @override
  void initState() {
    super.initState();
    widget.bloc.load();
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
          'This permanently deletes every saved translation. '
          'It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await widget.bloc.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HistoryState>(
      stream: widget.bloc.stateStream,
      initialData: widget.bloc.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const HistoryInitial();

        return Scaffold(
          appBar: AppBar(
            title: const Text('History'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: widget.bloc.load,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Clear all',
                onPressed: state is HistoryLoaded && !state.isEmpty
                    ? _confirmClear
                    : null,
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
            ],
          ),
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(HistoryState state) {
    return switch (state) {
      HistoryInitial() ||
      HistoryLoading() => const Center(child: CircularProgressIndicator()),
      HistoryFailure(:final message) => _MessageState(
        icon: Icons.error_outline,
        title: 'Could not load history',
        message: message,
      ),
      HistoryLoaded(:final entries) =>
        entries.isEmpty
            ? const _MessageState(
                icon: Icons.history,
                title: 'No history yet',
                message: 'Translations you make will appear here.',
              )
            : ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _HistoryTile(
                    entry: entry,
                    onDelete: () => widget.bloc.delete(entry.id),
                  );
                },
              ),
    };
  }
}

class _HistoryTile extends StatelessWidget {
  final TranslationEntry entry;
  final VoidCallback onDelete;

  const _HistoryTile({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      isThreeLine: true,
      title: Text(
        entry.originalText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          // The translated text may be Persian (RTL), so force the direction
          // of just this run to keep mixed content readable.
          Text(
            entry.translatedText,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.sourceLanguage.toUpperCase()} → '
            '${entry.targetLanguage.toUpperCase()} · '
            '${_formatTimestamp(entry.createdAt)}',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
      trailing: IconButton(
        tooltip: 'Delete',
        onPressed: onDelete,
        icon: const Icon(Icons.close),
      ),
    );
  }

  static String _formatTimestamp(DateTime timestamp) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${timestamp.year}-${two(timestamp.month)}-${two(timestamp.day)} '
        '${two(timestamp.hour)}:${two(timestamp.minute)}';
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
