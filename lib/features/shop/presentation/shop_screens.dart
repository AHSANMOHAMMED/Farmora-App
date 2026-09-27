import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/utils/image_upload.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../models/product.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';
import '../../../services/shop_service.dart';
import '../../buyer/presentation/product_detail_screen.dart';

String boxFrequencyLabel(AppLocalizations l, BoxFrequency f) => switch (f) {
      BoxFrequency.weekly => l.shopWeekly,
      BoxFrequency.biweekly => l.shopBiweekly,
      BoxFrequency.monthly => l.shopMonthly,
    };

String subStatusLabel(AppLocalizations l, String s) => switch (s) {
      'paused' => l.shopStatusPaused,
      'cancelled' => l.shopStatusCancelled,
      _ => l.shopStatusActive,
    };

void _error(BuildContext context, Object e, String action) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(userMessage(e, action: action)),
    backgroundColor: AppColors.error,
  ));
}

Widget _center(String text) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.onSurfaceVariant)),
      ),
    );

// ── Wishlist heart ────────────────────────────────────────────

/// Heart toggle for a product (signed-in buyers).
class WishlistButton extends StatelessWidget {
  const WishlistButton({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final service = ShopService();
    return StreamBuilder<Set<String>>(
      stream: service.watchWishlistIds(),
      builder: (context, snap) {
        final saved = snap.data?.contains(productId) ?? false;
        return IconButton(
          tooltip: saved ? l.shopRemoveWishlist : l.shopAddWishlist,
          icon: Icon(saved ? Icons.favorite : Icons.favorite_border,
              color: saved ? Colors.red : AppColors.onSurface),
          onPressed: snap.hasData
              ? () => service
                  .toggleWishlist(productId, !saved)
                  .catchError((Object e) => _error(context, e, 'update the wishlist'))
              : null,
        );
      },
    );
  }
}

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final service = ShopService();
    return Scaffold(
      appBar: AppBar(title: Text(l.shopWishlist)),
      body: StreamBuilder<Set<String>>(
        stream: service.watchWishlistIds(),
        builder: (context, ids) {
          if (!ids.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ids.data!.isEmpty) return _center(l.shopWishlistEmpty);
          return FutureBuilder<List<Product>>(
            future: service.wishlistProducts(ids.data!),
            builder: (context, snap) {
              if (snap.hasError) return _center(userMessage(snap.error!));
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final p in snap.data!) _ProductTile(product: p),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 52,
              height: 52,
              child: (product.imagePath ?? '').isNotEmpty
                  ? SafeImage(path: product.imagePath!, fit: BoxFit.cover)
                  : const Icon(Icons.eco, color: AppColors.primary),
            ),
          ),
          title: Text(product.name),
          subtitle: Text(
              '${AppFormat.lkr(product.effectivePricePerUnit)} / ${product.unit} · ${product.location}'),
          trailing: WishlistButton(productId: product.id),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product))),
        ),
      );
}

// ── Farm store (buyer view) ───────────────────────────────────

class FarmStoreScreen extends StatelessWidget {
  const FarmStoreScreen({
    super.key,
    required this.farmerId,
    this.fallbackName = '',
  });

  final String farmerId;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final service = ShopService();
    final isBuyer = context.select<FarmoraState, bool>(
        (s) => s.role.name == 'buyer' && s.currentUserId.isNotEmpty);
    return StreamBuilder<FarmStore?>(
      stream: service.watchStore(farmerId),
      builder: (context, storeSnap) {
        final store = storeSnap.data;
        final name = store?.farmName.isNotEmpty == true
            ? store!.farmName
            : fallbackName;
        return Scaffold(
          appBar: AppBar(title: Text(name)),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (store?.coverImageUrl != null)
                SizedBox(
                  height: 180,
                  child: SafeImage(path: store!.coverImageUrl!, fit: BoxFit.cover),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800)),
                    if ((store?.district ?? '').isNotEmpty)
                      Text(store!.district,
                          style: const TextStyle(
                              color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    Text(store?.story.isNotEmpty == true
                        ? store!.story
                        : l.shopNoStoryYet),
                    if (store?.certifications.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in store!.certifications)
                            Chip(
                              avatar: const Icon(Icons.verified, size: 16),
                              label: Text(c),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              StreamBuilder<List<SubscriptionBox>>(
                stream: service.farmerBoxes(farmerId),
                builder: (context, snap) {
                  final boxes = snap.data ?? const <SubscriptionBox>[];
                  if (boxes.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section(l.shopBoxes),
                      for (final b in boxes)
                        Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.inventory_2_outlined,
                                color: AppColors.primary),
                            title: Text(b.title),
                            subtitle: Text([
                              if (b.contents.isNotEmpty) b.contents,
                              '${boxFrequencyLabel(l, b.frequency)} · ${l.shopPerDelivery(AppFormat.lkr(b.price))}',
                            ].join('\n')),
                            isThreeLine: b.contents.isNotEmpty,
                            trailing: isBuyer
                                ? FilledButton.tonal(
                                    onPressed: () => _subscribe(context, b),
                                    child: Text(l.shopSubscribe),
                                  )
                                : null,
                          ),
                        ),
                    ],
                  );
                },
              ),
              _section(l.shopProducts),
              StreamBuilder<List<Product>>(
                stream: service.storeProducts(farmerId),
                builder: (context, snap) {
                  if (snap.hasError) return _center(userMessage(snap.error!));
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.data!.isEmpty) return _center(l.shopNoProducts);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(children: [
                      for (final p in snap.data!) _ProductTile(product: p),
                    ]),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      );

  Future<void> _subscribe(BuildContext context, SubscriptionBox box) async {
    final l = context.l10n;
    final address = TextEditingController(
        text: context.read<FarmoraState>().deliveryAddressDraft);
    var first = DateTime.now().add(const Duration(days: 2));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(box.title),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
                '${boxFrequencyLabel(l, box.frequency)} · ${l.shopPerDelivery(AppFormat.lkr(box.price))}'),
            const SizedBox(height: 12),
            TextField(
              controller: address,
              maxLines: 2,
              maxLength: 300,
              decoration: InputDecoration(
                  labelText: l.inpDeliveryAddress,
                  border: const OutlineInputBorder()),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.shopFirstDelivery),
              trailing: Text(AppFormat.date(first)),
              onTap: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: first,
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 45)),
                );
                if (d != null) setDialog(() => first = d);
              },
            ),
            Text(l.inpPayCod,
                style: const TextStyle(color: AppColors.onSurfaceVariant)),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.shopSubscribe)),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ShopService().subscribe(box, address.text, first);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.shopSubscribed)));
      }
    } catch (e) {
      if (context.mounted) _error(context, e, 'subscribe');
    }
  }
}

// ── Buyer subscriptions ───────────────────────────────────────

class MySubscriptionsScreen extends StatelessWidget {
  const MySubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final service = ShopService();
    return Scaffold(
      appBar: AppBar(title: Text(l.shopMySubscriptions)),
      body: StreamBuilder<List<BoxSubscription>>(
        stream: service.mySubscriptions(),
        builder: (context, snap) {
          if (snap.hasError) return _center(userMessage(snap.error!));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.data!.isEmpty) return _center(l.shopNoSubscriptions);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final s in snap.data!)
                _SubscriptionCard(
                  sub: s,
                  subtitle: s.farmerName,
                  actions: s.status == 'cancelled'
                      ? const []
                      : [
                          TextButton(
                            onPressed: () => service
                                .setSubscriptionStatus(
                                    s, s.status == 'active' ? 'paused' : 'active')
                                .catchError((Object e) =>
                                    _error(context, e, 'update the subscription')),
                            child: Text(s.status == 'active'
                                ? l.shopPause
                                : l.shopResume),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.error),
                            onPressed: () => service
                                .setSubscriptionStatus(s, 'cancelled')
                                .catchError((Object e) =>
                                    _error(context, e, 'cancel the subscription')),
                            child: Text(l.shopCancelSub),
                          ),
                        ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.sub,
    required this.subtitle,
    this.actions = const [],
  });

  final BoxSubscription sub;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(sub.boxTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Chip(label: Text(subStatusLabel(l, sub.status))),
            ]),
            Text(subtitle,
                style: const TextStyle(color: AppColors.onSurfaceVariant)),
            Text(
                '${boxFrequencyLabel(l, sub.frequency)} · ${l.shopPerDelivery(AppFormat.lkr(sub.priceMinor / 100))}'),
            if (sub.status == 'active' && sub.nextDeliveryAt != null)
              Text(l.shopNextDelivery(AppFormat.date(sub.nextDeliveryAt!)),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(l.shopDeliveries('${sub.deliveriesCount}'),
                style: const TextStyle(fontSize: 12)),
            if (actions.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(spacing: 8, children: actions),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Farmer: store editor, boxes and subscribers ───────────────

class MyFarmStoreScreen extends StatefulWidget {
  const MyFarmStoreScreen({super.key});

  @override
  State<MyFarmStoreScreen> createState() => _MyFarmStoreScreenState();
}

class _MyFarmStoreScreenState extends State<MyFarmStoreScreen>
    with SingleTickerProviderStateMixin {
  final _service = ShopService();
  late final _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final uid = context.read<FarmoraState>().currentUserId;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.shopMyStore),
        actions: [
          IconButton(
            tooltip: l.shopVisitStore,
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FarmStoreScreen(farmerId: uid))),
          ),
        ],
        bottom: TabBar(controller: _tabs, tabs: [
          Tab(text: l.shopStory),
          Tab(text: l.shopBoxes),
          Tab(text: l.shopSubscribers),
        ]),
      ),
      body: TabBarView(controller: _tabs, children: [
        _StoreEditor(service: _service, farmerId: uid),
        _BoxesManager(service: _service, farmerId: uid),
        _SubscribersList(service: _service),
      ]),
    );
  }
}

class _StoreEditor extends StatefulWidget {
  const _StoreEditor({required this.service, required this.farmerId});

  final ShopService service;
  final String farmerId;

  @override
  State<_StoreEditor> createState() => _StoreEditorState();
}

class _StoreEditorState extends State<_StoreEditor> {
  final _name = TextEditingController();
  final _story = TextEditingController();
  final _district = TextEditingController();
  final _certs = TextEditingController();
  String? _coverUrl;
  PickedImage? _cover;
  bool _loaded = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<FarmoraState>();
    widget.service.watchStore(widget.farmerId).first.then((store) {
      if (!mounted) return;
      setState(() {
        _name.text = store?.farmName ?? state.farmName;
        _story.text = store?.story ?? '';
        _district.text = store?.district ?? state.district;
        _certs.text = (store?.certifications ?? const []).join(', ');
        _coverUrl = store?.coverImageUrl;
        _loaded = true;
      });
    }).catchError((Object _) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _story, _district, _certs]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      var cover = _coverUrl;
      if (_cover != null) {
        cover = (await FirestoreService().uploadProductImage(_cover!)).url;
      }
      await widget.service.saveStore(
        farmName: _name.text,
        story: _story.text,
        district: _district.text,
        certifications: _certs.text.split(','),
        coverImageUrl: cover,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.save)));
      }
    } catch (e) {
      if (mounted) _error(context, e, 'save the store');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GestureDetector(
          onTap: () async {
            final img = await ImagePickerHelper().pickOne();
            if (img != null) setState(() => _cover = img);
          },
          child: Container(
            height: 150,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _cover != null
                ? Image.memory(_cover!.bytes, fit: BoxFit.cover)
                : _coverUrl != null
                    ? SafeImage(path: _coverUrl!, fit: BoxFit.cover)
                    : Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.add_a_photo_outlined),
                        Text(l.shopCoverPhoto),
                      ])),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
            controller: _name,
            maxLength: 80,
            decoration: InputDecoration(
                labelText: l.shopFarmName, border: const OutlineInputBorder())),
        TextField(
            controller: _district,
            maxLength: 60,
            decoration: InputDecoration(
                labelText: l.supDistrict, border: const OutlineInputBorder())),
        TextField(
            controller: _story,
            maxLength: 2000,
            maxLines: 6,
            decoration: InputDecoration(
                labelText: l.shopStory, border: const OutlineInputBorder())),
        TextField(
            controller: _certs,
            decoration: InputDecoration(
                labelText: l.shopCertifications,
                border: const OutlineInputBorder())),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(l.save),
        ),
      ],
    );
  }
}

class _BoxesManager extends StatelessWidget {
  const _BoxesManager({required this.service, required this.farmerId});

  final ShopService service;
  final String farmerId;

  Future<void> _edit(BuildContext context, [SubscriptionBox? box]) async {
    final l = context.l10n;
    final title = TextEditingController(text: box?.title);
    final contents = TextEditingController(text: box?.contents);
    final price = TextEditingController(
        text: box == null ? '' : '${box.priceMinor ~/ 100}');
    var freq = box?.frequency ?? BoxFrequency.weekly;
    var active = box?.active ?? true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(box == null ? l.shopAddBox : box.title),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: title,
                  maxLength: 100,
                  decoration: InputDecoration(labelText: l.shopBoxName)),
              TextField(
                  controller: contents,
                  maxLength: 1000,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: l.shopBoxContents)),
              TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: l.supPrice)),
              DropdownButtonFormField<BoxFrequency>(
                initialValue: freq,
                decoration: InputDecoration(labelText: l.shopFrequency),
                items: [
                  for (final f in BoxFrequency.values)
                    DropdownMenuItem(
                        value: f, child: Text(boxFrequencyLabel(l, f))),
                ],
                onChanged: (v) => setDialog(() => freq = v ?? freq),
              ),
              if (box != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.supVisible),
                  value: active,
                  onChanged: (v) => setDialog(() => active = v),
                ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.save)),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await service.saveBox(
        id: box?.id,
        title: title.text,
        contents: contents.text,
        priceMinor: (int.tryParse(price.text) ?? 0) * 100,
        frequency: freq,
        active: active,
      );
    } catch (e) {
      if (context.mounted) _error(context, e, 'save the box');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-box',
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add),
        label: Text(l.shopAddBox),
      ),
      body: StreamBuilder<List<SubscriptionBox>>(
        stream: service.farmerBoxes(farmerId, activeOnly: false),
        builder: (context, snap) {
          if (snap.hasError) return _center(userMessage(snap.error!));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.data!.isEmpty) return _center(l.shopNoBoxes);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              for (final b in snap.data!)
                Card(
                  child: ListTile(
                    title: Text(b.title),
                    subtitle: Text(
                        '${boxFrequencyLabel(l, b.frequency)} · ${l.shopPerDelivery(AppFormat.lkr(b.price))} · ${b.active ? l.supVisible : l.supHidden}'),
                    onTap: () => _edit(context, b),
                    trailing: IconButton(
                      tooltip: l.delete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => service
                          .deleteBox(b.id)
                          .catchError((Object e) => _error(context, e, 'delete the box')),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SubscribersList extends StatelessWidget {
  const _SubscribersList({required this.service});

  final ShopService service;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<List<BoxSubscription>>(
      stream: service.subscribers(),
      builder: (context, snap) {
        if (snap.hasError) return _center(userMessage(snap.error!));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.data!.isEmpty) return _center(l.shopNoSubscribers);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final s in snap.data!)
              _SubscriptionCard(
                sub: s,
                subtitle: '${s.buyerName} · ${s.deliveryAddress}',
                actions: [
                  if (s.status == 'active')
                    FilledButton.tonal(
                      onPressed: () => service
                          .markBoxDelivered(s)
                          .catchError((Object e) => _error(context, e, 'record the delivery')),
                      child: Text(l.shopMarkDelivered),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
