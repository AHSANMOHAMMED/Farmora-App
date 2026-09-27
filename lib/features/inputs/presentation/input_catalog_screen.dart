import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../models/farm_input.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/input_market_service.dart';
import 'inputs_l10n.dart';
import 'my_input_orders_screen.dart';

/// Farmer: browse supplier inputs by category and buy or book them.
class InputCatalogScreen extends StatefulWidget {
  const InputCatalogScreen({super.key});

  @override
  State<InputCatalogScreen> createState() => _InputCatalogScreenState();
}

class _InputCatalogScreenState extends State<InputCatalogScreen> {
  final _service = InputMarketService();
  InputCategory? _category;
  late Stream<List<FarmInput>> _stream = _service.catalog();

  void _select(InputCategory? c) => setState(() {
        _category = c;
        _stream = _service.catalog(category: c);
      });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l.inpTitle),
        actions: [
          IconButton(
            tooltip: l.inpMyOrders,
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const MyInputOrdersScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _chip(l.inpCatAll, null),
                for (final c in InputCategory.values)
                  _chip(inputCategoryLabel(l, c), c),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<FarmInput>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text(userMessage(snap.error!)));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data!;
                if (items.isEmpty) return Center(child: Text(l.inpEmpty));
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _InputCard(
                    input: items[i],
                    onTap: () => _order(items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, InputCategory? c) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _category == c,
          onSelected: (_) => _select(c),
        ),
      );

  Future<void> _order(FarmInput input) async {
    if (!input.inStock) return;
    final placed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OrderSheet(input: input, service: _service),
    );
    if (placed == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.inpOrderPlaced)));
    }
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({required this.input, required this.onTap});

  final FarmInput input;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: input.inStock ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: input.imageUrl != null
                      ? SafeImage(path: input.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          child: Icon(inputCategoryIcon(input.category),
                              color: AppColors.primary, size: 32),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(input.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      [
                        l.inpBy(input.supplierName),
                        if (input.district.isNotEmpty) input.district,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Text(inputPriceLabel(l, input),
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                    Text(
                      !input.inStock
                          ? l.inpOutOfStock
                          : input.isRental
                              ? l.inpMachinesFree('${input.stock}')
                              : l.inpInStock('${input.stock}', input.unit),
                      style: TextStyle(
                          fontSize: 12,
                          color: input.inStock
                              ? AppColors.onSurfaceVariant
                              : AppColors.error),
                    ),
                  ],
                ),
              ),
              if (input.inStock)
                FilledButton.tonal(
                  onPressed: onTap,
                  child: Text(input.isRental ? l.inpBook : l.inpBuy),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSheet extends StatefulWidget {
  const _OrderSheet({required this.input, required this.service});

  final FarmInput input;
  final InputMarketService service;

  @override
  State<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<_OrderSheet> {
  int _qty = 1;
  int _days = 1;
  DateTime _start = DateTime.now().add(const Duration(days: 1));
  late final _address = TextEditingController(
      text: context.read<FarmoraState>().deliveryAddressDraft);
  bool _busy = false;
  bool _payLater = false;
  String? _error;

  FarmInput get input => widget.input;

  int get _totalMinor =>
      input.priceMinor * _qty * (input.isRental ? _days : 1);

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.placeOrder(
        input: input,
        quantity: _qty,
        deliveryAddress: _address.text,
        days: input.isRental ? _days : null,
        startDate: input.isRental ? _start : null,
        payLater: _payLater,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = userMessage(e, action: 'place the order');
        });
      }
    }
  }

  Widget _stepper(String label, int value, int max, ValueChanged<int> set) =>
      Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            tooltip: '$label −',
            onPressed: value > 1 ? () => set(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 40,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          IconButton(
            tooltip: '$label +',
            onPressed: value < max ? () => set(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(input.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(inputPriceLabel(l, input),
                style: const TextStyle(color: AppColors.primary)),
            const SizedBox(height: 12),
            _stepper(l.inpQuantity, _qty, input.stock,
                (v) => setState(() => _qty = v)),
            if (input.isRental) ...[
              _stepper(l.inpDays, _days, 60, (v) => setState(() => _days = v)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.inpStartDate),
                trailing: Text(AppFormat.date(_start),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _start,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 180)),
                  );
                  if (picked != null) setState(() => _start = picked);
                },
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _address,
              maxLines: 2,
              maxLength: 300,
              inputFormatters: [LengthLimitingTextInputFormatter(300)],
              decoration: InputDecoration(
                labelText: l.inpDeliveryAddress,
                border: const OutlineInputBorder(),
              ),
            ),
            Text(l.inpTotal(AppFormat.lkr(_totalMinor / 100)),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.inpPayLater),
              subtitle: Text(_payLater ? l.inpPayLaterHint : l.inpPayCod),
              value: _payLater,
              onChanged: (v) => setState(() => _payLater = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.inpPlaceOrder),
            ),
          ],
        ),
      ),
    );
  }
}
