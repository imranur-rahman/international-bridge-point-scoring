import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';
import '../../scoring/scoring.dart';
import 'providers.dart';
import 'theme.dart';

/// Text with colored suit symbols. Every suit symbol in the app goes
/// through this widget, so that the suit color setting applies everywhere.
class SuitText extends ConsumerWidget {
  const SuitText(this.text, {super.key, this.style, this.textAlign});

  /// Builds the text of a contract, for example "4♠X".
  SuitText.contract(Contract contract, {Key? key, TextStyle? style})
    : this(contract.toString(), key: key, style: style);

  SuitText.bid(Bid bid, {Key? key, TextStyle? style})
    : this(bid.toString(), key: key, style: style);

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  static const Map<String, Strain> _symbols = {
    '♣': Strain.clubs,
    '♦': Strain.diamonds,
    '♥': Strain.hearts,
    '♠': Strain.spades,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(displayProvider.select((d) => d.suitColors));
    final brightness = Theme.of(context).brightness;
    final baseSize =
        DefaultTextStyle.of(context).style.merge(style).fontSize ?? 14;
    final spans = <TextSpan>[];
    final buffer = StringBuffer();
    void flush() {
      if (buffer.isNotEmpty) {
        spans.add(TextSpan(text: buffer.toString()));
        buffer.clear();
      }
    }

    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      final strain = _symbols[ch];
      if (strain == null) {
        buffer.write(ch);
      } else {
        flush();
        spans.add(
          TextSpan(
            text: ch,
            style: TextStyle(
              fontFamily: suitFontFamily,
              fontSize: baseSize * suitScale,
              color: strainColor(strain, brightness, setting),
            ),
          ),
        );
      }
    }
    flush();
    return Text.rich(
      TextSpan(children: spans),
      style: style,
      textAlign: textAlign,
    );
  }
}

/// The bundled font that draws the suit symbols as text. Some platforms
/// otherwise draw them with a color emoji font that ignores the text color.
const String suitFontFamily = 'SuitSymbols';

/// The size of a suit symbol relative to the text around it.
const double suitScale = 1.3;

/// Centers the content at most 600 logical pixels wide, with a 16 pixel
/// side gutter.
class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.child, this.maxWidth = 600});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: child,
      ),
    ),
  );
}

/// A scrollable page body inside a [PageFrame].
class ScrollPage extends StatelessWidget {
  const ScrollPage({super.key, required this.children, this.maxWidth = 600});

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: PageFrame(
      maxWidth: maxWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// Shows "vulnerable" or "not vulnerable" for a side.
class VulnerabilityLabel extends StatelessWidget {
  const VulnerabilityLabel({
    super.key,
    required this.name,
    required this.vulnerable,
  });

  final String name;
  final bool vulnerable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          vulnerable ? Icons.warning_amber_rounded : Icons.shield_outlined,
          size: 20,
          color: vulnerable ? scheme.error : scheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text('$name: ${vulnerable ? 'vulnerable' : 'not vulnerable'}'),
        ),
      ],
    );
  }
}

/// Asks the user to confirm an action. Returns true on confirm.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showError(BuildContext context, String? message) {
  if (message == null) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// "+200" or "−50" style text.
String signed(int points) => points >= 0 ? '+$points' : '−${-points}';

/// The label of a score item for the breakdown.
String componentLabel(ScoreComponent c) => c.label;
