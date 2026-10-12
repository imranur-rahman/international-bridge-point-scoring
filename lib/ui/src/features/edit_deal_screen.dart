import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../scoring/scoring.dart';
import '../../../session/session.dart';
import '../providers.dart';
import '../widgets.dart';
import 'deal_screen.dart';

class EditDealScreen extends ConsumerStatefulWidget {
  const EditDealScreen({super.key, required this.index});

  final int index;

  @override
  ConsumerState<EditDealScreen> createState() => _EditDealScreenState();
}

class _EditDealScreenState extends ConsumerState<EditDealScreen> {
  late bool passedOut;
  late ContractInput contract;
  int? tricks;
  Honors? honors;

  @override
  void initState() {
    super.initState();
    final record = ref.read(sessionProvider)!.records[widget.index];
    final r = record.result;
    passedOut = r == null;
    contract = r == null
        ? const ContractInput()
        : ContractInput.from(r.contract);
    tricks = r?.tricksTaken;
    honors = r?.honors;
  }

  DealResult? buildResult(SessionState s) {
    final c = contract.toContract();
    if (c == null || tricks == null) return null;
    final honorsOn = s.settings.components.honors;
    final h = honors;
    if (honorsOn && (h == null || h.holding.suit != c.strain.isSuit)) {
      return null;
    }
    return DealResult(
      contract: c,
      tricksTaken: tricks!,
      honors: honorsOn ? h : null,
    );
  }

  Future<void> preview(SessionState s) async {
    final result = passedOut ? null : buildResult(s);
    final p = s.settings.players;
    final preview = SessionController.previewEdit(s, widget.index, result);
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('edit-preview'),
        title: const Text('Effect of this edit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Table(
                children: [
                  const TableRow(
                    children: [Text(''), Text('Before'), Text('After')],
                  ),
                  for (final side in Side.values)
                    TableRow(
                      children: [
                        Text(p.partnershipName(side)),
                        Text('${preview.totalsBefore[side]}'),
                        Text(
                          '${preview.totalsAfter[side]}',
                          key: Key('after-${side.name}'),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (preview.changedDeals.isEmpty)
                const Text('No later deal changes.')
              else ...[
                const Text('Changed later deals:'),
                for (final c in preview.changedDeals)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _describeChange(c, p),
                      key: Key('changed-${c.index + 1}'),
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('cancel-edit'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('save-edit'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save edit'),
          ),
        ],
      ),
    );
    if (save != true || !mounted) return;
    final error = await ref
        .read(sessionProvider.notifier)
        .send(EditDeal(widget.index, result));
    if (!mounted) return;
    if (error != null) {
      showError(context, error);
    } else {
      Navigator.of(context).pop();
    }
  }

  static String _describeChange(ChangedDeal c, Players p) {
    final parts = <String>[];
    for (final side in Side.values) {
      final b = c.vulnerabilityBefore.of(side);
      final a = c.vulnerabilityAfter.of(side);
      if (a != b) {
        parts.add(
          '${p.partnershipName(side)} now ${a ? 'vulnerable' : 'not vulnerable'}',
        );
      }
      if (c.pointsBefore[side] != c.pointsAfter[side]) {
        parts.add(
          '${p.partnershipName(side)} ${c.pointsBefore[side]} → '
          '${c.pointsAfter[side]}',
        );
      }
    }
    return 'Deal ${c.index + 1}: ${parts.join('; ')}';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider);
    if (s == null || widget.index >= s.records.length) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This deal does not exist.')),
      );
    }
    final p = s.settings.players;
    final record = s.records[widget.index];
    final c = contract.toContract();
    final canSave = passedOut || buildResult(s) != null;
    ContractInput copy({
      int? level,
      Strain? strain,
      Doubling? doubling,
      Seat? declarer,
    }) => ContractInput(
      level: level ?? contract.level,
      strain: strain ?? contract.strain,
      doubling: doubling ?? contract.doubling,
      declarer: declarer ?? contract.declarer,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit deal ${widget.index + 1}'),
        actions: [
          TextButton(
            key: const Key('preview-edit'),
            onPressed: canSave ? () => preview(s) : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ScrollPage(
        children: [
          Text('Dealer: ${p.nameOf(record.dealer)} (fixed)'),
          CheckboxListTile(
            key: const Key('edit-passed-out'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Passed out'),
            value: passedOut,
            onChanged: (v) => setState(() => passedOut = v!),
          ),
          if (record.auction != null || record.auctionEdited)
            const Text(
              'A change of the contract replaces the recorded auction.',
            ),
          if (!passedOut) ...[
            const SectionTitle('Contract'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var l = 1; l <= 7; l++)
                  ChoiceChip(
                    key: Key('edit-level-$l'),
                    label: Text('$l'),
                    selected: contract.level == l,
                    onSelected: (_) => setState(() {
                      contract = copy(level: l);
                      tricks = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final st in Strain.values)
                  ChoiceChip(
                    key: Key('edit-strain-${st.name}'),
                    label: SuitText(st.symbol),
                    selected: contract.strain == st,
                    onSelected: (_) => setState(() {
                      contract = copy(strain: st);
                      if (honors != null && honors!.holding.suit != st.isSuit) {
                        honors = null;
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in Doubling.values)
                  ChoiceChip(
                    key: Key('edit-doubling-${d.name}'),
                    label: Text(switch (d) {
                      Doubling.none => 'Undoubled',
                      Doubling.doubled => 'Doubled',
                      Doubling.redoubled => 'Redoubled',
                    }),
                    selected: contract.doubling == d,
                    onSelected: (_) =>
                        setState(() => contract = copy(doubling: d)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final seat in Seat.values)
                  ChoiceChip(
                    key: Key('edit-declarer-${seat.name}'),
                    label: Text(p.nameOf(seat)),
                    selected: contract.declarer == seat,
                    onSelected: (_) =>
                        setState(() => contract = copy(declarer: seat)),
                  ),
              ],
            ),
            if (contract.level != null) ...[
              const SectionTitle('Result'),
              ResultPicker(
                key: ValueKey('edit-result-${contract.level}'),
                level: contract.level!,
                selected: tricks,
                onSelected: (t) => setState(() => tricks = t),
              ),
            ],
            if (s.settings.components.honors && c != null) ...[
              const SectionTitle('Honors'),
              HonorsPicker(
                key: ValueKey('edit-honors-${c.strain.isSuit}'),
                strain: c.strain,
                players: p,
                values: s.settings.values,
                honors: honors,
                onChanged: (h) => setState(() => honors = h),
              ),
            ],
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('preview-edit-bottom'),
            onPressed: canSave ? () => preview(s) : null,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
