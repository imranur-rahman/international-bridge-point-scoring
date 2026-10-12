import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'help_texts.dart';

/// Shares which help overlay is open, so that only one is open at a time.
class HelpScope extends InheritedWidget {
  const HelpScope({super.key, required this.open, required super.child});

  final ValueNotifier<Object?> open;

  static ValueNotifier<Object?>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HelpScope>()?.open;

  @override
  bool updateShouldNotify(HelpScope oldWidget) => oldWidget.open != open;
}

/// A help button. A tap or a click shows an overlay next to the button; a
/// mouse pointer over it shows a short tooltip.
class HelpButton extends StatefulWidget {
  const HelpButton({
    super.key,
    required this.help,
    required this.id,
    this.standardDefault,
  });

  final HelpText help;

  /// The standard default of the value, shown in the overlay.
  final int? standardDefault;

  /// A unique id for this button inside its [HelpScope].
  final Object id;

  @override
  State<HelpButton> createState() => _HelpButtonState();
}

class _HelpButtonState extends State<HelpButton> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  ValueNotifier<Object?>? _open;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final open = HelpScope.of(context);
    if (open != _open) {
      _open?.removeListener(_sync);
      _open = open?..addListener(_sync);
    }
  }

  @override
  void dispose() {
    _open?.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    final shouldShow = _open?.value == widget.id;
    if (shouldShow && !_portal.isShowing) _portal.show();
    if (!shouldShow && _portal.isShowing) _portal.hide();
  }

  void _toggle() {
    final open = _open;
    if (open == null) {
      _portal.toggle();
      return;
    }
    open.value = open.value == widget.id ? null : widget.id;
  }

  void _close() {
    final open = _open;
    if (open == null) {
      _portal.hide();
    } else if (open.value == widget.id) {
      open.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final help = widget.help;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) {
          final width = MediaQuery.sizeOf(context).width;
          final scheme = Theme.of(context).colorScheme;
          final text = Theme.of(context).textTheme;
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  key: const Key('help-outside'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                ),
              ),
              CompositedTransformFollower(
                link: _link,
                targetAnchor: Alignment.bottomRight,
                followerAnchor: Alignment.topRight,
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.escape): _close,
                  },
                  child: Focus(
                    autofocus: true,
                    child: Material(
                      key: const Key('help-overlay'),
                      elevation: 6,
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: (width - 32).clamp(200, 340),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      help.title,
                                      style: text.titleSmall,
                                    ),
                                  ),
                                  IconButton(
                                    key: const Key('help-close'),
                                    tooltip: 'Close',
                                    icon: const Icon(Icons.close),
                                    onPressed: _close,
                                  ),
                                ],
                              ),
                              Text(help.meaning),
                              if (widget.standardDefault != null) ...[
                                const SizedBox(height: 8),
                                Text('Standard: ${widget.standardDefault}'),
                              ],
                              const SizedBox(height: 8),
                              Text(help.applies, style: text.bodySmall),
                              const SizedBox(height: 8),
                              Text(
                                'Example: ${help.example}',
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: Tooltip(
          message: help.short,
          waitDuration: const Duration(milliseconds: 400),
          triggerMode: TooltipTriggerMode.manual,
          child: IconButton(
            tooltip: null,
            icon: const Icon(Icons.info_outline),
            onPressed: _toggle,
          ),
        ),
      ),
    );
  }
}
