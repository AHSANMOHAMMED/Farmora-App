import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/utils/image_upload.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../models/farm_input.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';
import '../../../services/input_market_service.dart';
import 'inputs_l10n.dart';
import 'my_input_orders_screen.dart';

/// Supplier home: listing and order counts with shortcuts.
class SupplierDashboardScreen extends StatelessWidget {
  const SupplierDashboardScreen({
    super.key,
    required this.onOpenListings,
    required this.onOpenOrders,
  });

  final VoidCallback onOpenListings;
  final VoidCallback onOpenOrders;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final service = InputMarketService();
    final name = context.select<FarmoraState, String>((s) => s.displayName);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l.supDashboardTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(name,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          StreamBuilder<List<FarmInput>>(
            stream: service.myListings(),
            builder: (context, snap) => _Stat(
              icon: Icons.inventory_2_outlined,
              label: l.supActiveListings,
              value: '${(snap.data ?? const []).where((i) => i.active).length}',
              onTap: onOpenListings,
            ),
          ),
          StreamBuilder<List<InputOrder>>(
            stream: service.supplierOrders(limit: 200),
            builder: (context, snap) {
              final orders = snap.data ?? const <InputOrder>[];
              final pending = orders
                  .where((o) => o.status == InputOrderStatus.pending)
                  .length;
              final done = orders
                  .where((o) =>
                      o.status == InputOrderStatus.delivered ||
                      o.status == InputOrderStatus.returned)
                  .fold<int>(0, (sum, o) => sum + o.totalMinor);
              return Column(children: [
                _Stat(
                  icon: Icons.pending_actions_outlined,
                  label: l.supPendingOrders,
                  value: '$pending',
                  onTap: onOpenOrders,
                ),
                _Stat(
                  icon: Icons.payments_outlined,
                  label: l.supCompletedSales,
                  value: AppFormat.lkr(done / 100),
                  onTap: onOpenOrders,
                ),
              ]);
            },
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(label),
          trailing: Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          onTap: onTap,
        ),
      );
}

/// Supplier: own listings with add, edit, hide and delete.
class SupplierListingsScreen extends StatefulWidget {
  const SupplierListingsScreen({super.key});

  @override
  State<SupplierListingsScreen> createState() => _SupplierListingsScreenState();
}

class _SupplierListingsScreenState extends State<SupplierListingsScreen> {
  final _service = InputMarketService();
  late final _stream = _service.myListings();

  void _open([FarmInput? input]) => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => InputListingFormScreen(input: input)));

  Future<void> _delete(FarmInput input) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.supDeleteConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteListing(input.id);
    } catch (e) {
      if (mounted) _snack(userMessage(e, action: 'delete the listing'));
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: AppColors.error));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l.supListings)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _open,
        icon: const Icon(Icons.add),
        label: Text(l.supAddListing),
      ),
      body: StreamBuilder<List<FarmInput>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(userMessage(snap.error!)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.supNoListings, textAlign: TextAlign.center),
            ));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final input = items[i];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(inputCategoryIcon(input.category),
                        color: AppColors.primary),
                  ),
                  title: Text(input.name),
                  subtitle: Text([
                    inputPriceLabel(l, input),
                    input.isRental
                        ? l.inpMachinesFree('${input.stock}')
                        : l.inpInStock('${input.stock}', input.unit),
                    input.active ? l.supVisible : l.supHidden,
                  ].join(' · ')),
                  onTap: () => _open(input),
                  trailing: IconButton(
                    tooltip: l.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(input),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Add or edit one supplier listing.
class InputListingFormScreen extends StatefulWidget {
  const InputListingFormScreen({super.key, this.input});

  final FarmInput? input;

  @override
  State<InputListingFormScreen> createState() => _InputListingFormScreenState();
}

class _InputListingFormScreenState extends State<InputListingFormScreen> {
  final _form = GlobalKey<FormState>();
  final _service = InputMarketService();
  late final _name = TextEditingController(text: widget.input?.name);
  late final _price = TextEditingController(
      text: widget.input == null ? '' : '${widget.input!.priceMinor ~/ 100}');
  late final _unit = TextEditingController(text: widget.input?.unit ?? 'kg');
  late final _stock =
      TextEditingController(text: widget.input == null ? '' : '${widget.input!.stock}');
  late final _district = TextEditingController(
      text: widget.input?.district ??
          context.read<FarmoraState>().district);
  late final _description =
      TextEditingController(text: widget.input?.description);
  late InputCategory _category = widget.input?.category ?? InputCategory.seeds;
  late bool _rental = widget.input?.isRental ?? false;
  late bool _active = widget.input?.active ?? true;
  PickedImage? _photo;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _price, _unit, _stock, _district, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _positive(String? v) {
    final n = int.tryParse((v ?? '').trim());
    return n == null || n < 0 ? context.l10n.supInvalidNumber : null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      var imageUrl = widget.input?.imageUrl;
      if (_photo != null) {
        imageUrl = (await FirestoreService().uploadProductImage(_photo!)).url;
      }
      final price = int.parse(_price.text.trim()) * 100;
      final stock = int.parse(_stock.text.trim());
      if (widget.input == null) {
        await _service.createListing(
          name: _name.text,
          category: _category,
          isRental: _rental,
          priceMinor: price,
          unit: _unit.text,
          stock: stock,
          description: _description.text,
          district: _district.text,
          imageUrl: imageUrl,
        );
      } else {
        await _service.updateListing(
          widget.input!.id,
          name: _name.text,
          category: _category,
          isRental: _rental,
          priceMinor: price,
          unit: _unit.text,
          stock: stock,
          description: _description.text,
          district: _district.text,
          imageUrl: imageUrl,
          active: _active,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(userMessage(e, action: 'save the listing')),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  InputDecoration _dec(String label) =>
      InputDecoration(labelText: label, border: const OutlineInputBorder());

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final digits = [FilteringTextInputFormatter.digitsOnly];
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.input == null ? l.supAddListing : l.supEditListing)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _busy
                  ? null
                  : () async {
                      final img = await ImagePickerHelper().pickOne();
                      if (img != null) setState(() => _photo = img);
                    },
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: _photo != null
                    ? Image.memory(_photo!.bytes, fit: BoxFit.cover)
                    : widget.input?.imageUrl != null
                        ? SafeImage(
                            path: widget.input!.imageUrl!, fit: BoxFit.cover)
                        : Center(
                            child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_a_photo_outlined),
                              Text(l.supAddPhoto),
                            ],
                          )),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              maxLength: 120,
              decoration: _dec(l.supName),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l.requiredField : null,
            ),
            DropdownButtonFormField<InputCategory>(
              initialValue: _category,
              decoration: _dec(l.supCategory),
              items: [
                for (final c in InputCategory.values)
                  DropdownMenuItem(
                      value: c, child: Text(inputCategoryLabel(l, c))),
              ],
              onChanged: (c) => setState(() {
                _category = c ?? _category;
                if (_category == InputCategory.machinery) _rental = true;
              }),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.supForRent),
              value: _rental,
              onChanged: (v) => setState(() => _rental = v),
            ),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  decoration: _dec(l.supPrice),
                  validator: (v) =>
                      _positive(v) ?? (int.parse(v!.trim()) == 0 ? l.supInvalidNumber : null),
                ),
              ),
              if (!_rental) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unit,
                    maxLength: 20,
                    decoration: _dec(l.supUnit),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? l.requiredField : null,
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stock,
              keyboardType: TextInputType.number,
              inputFormatters: digits,
              decoration: _dec(_rental ? l.supMachines : l.supStock),
              validator: _positive,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _district,
              maxLength: 60,
              decoration: _dec(l.supDistrict),
            ),
            TextFormField(
              controller: _description,
              maxLines: 4,
              maxLength: 2000,
              decoration: _dec(l.supDescription),
            ),
            if (widget.input != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.supVisible),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}

/// Supplier: incoming purchases and bookings with the next action.
class SupplierOrdersScreen extends StatefulWidget {
  const SupplierOrdersScreen({super.key});

  @override
  State<SupplierOrdersScreen> createState() => _SupplierOrdersScreenState();
}

class _SupplierOrdersScreenState extends State<SupplierOrdersScreen> {
  final _service = InputMarketService();
  late final _stream = _service.supplierOrders();
  final Set<String> _busy = {};

  Future<void> _move(InputOrder o, String next) async {
    setState(() => _busy.add(o.id));
    try {
      await _service.transition(o, next);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(userMessage(e, action: 'update the order')),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(o.id));
    }
  }

  String _nextLabel(AppLocalizations l, String next) => switch (next) {
        InputOrderStatus.dispatched => l.supMarkDispatched,
        InputOrderStatus.delivered => l.supMarkDelivered,
        InputOrderStatus.inUse => l.supMarkInUse,
        InputOrderStatus.returned => l.supMarkReturned,
        _ => next,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l.homeNavOrders)),
      body: StreamBuilder<List<InputOrder>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(userMessage(snap.error!)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snap.data!;
          if (orders.isEmpty) return Center(child: Text(l.supNoOrders));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final o = orders[i];
              final busy = _busy.contains(o.id);
              final next =
                  InputOrderStatus.nextFor(o.status, rental: o.isRental);
              return InputOrderCard(
                order: o,
                subtitle: l.supOrderFrom(o.farmerName),
                actions: [
                  if (o.status == InputOrderStatus.pending) ...[
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => _move(o, InputOrderStatus.rejected),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.error),
                      child: Text(l.reject),
                    ),
                    FilledButton(
                      onPressed: busy
                          ? null
                          : () => _move(o, InputOrderStatus.confirmed),
                      child: Text(l.confirm),
                    ),
                  ] else if (next != null)
                    FilledButton.tonal(
                      onPressed: busy ? null : () => _move(o, next),
                      child: Text(_nextLabel(l, next)),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
