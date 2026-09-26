import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/farmer_header.dart';
import '../../../core/widgets/harvest_video_player.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../models/product.dart';
import '../../../providers/farmora_state.dart';
import 'add_product_screen.dart';
import 'farmer_l10n.dart';

class FarmerProductsScreen extends StatefulWidget {
  const FarmerProductsScreen({super.key});

  @override
  State<FarmerProductsScreen> createState() => _FarmerProductsScreenState();
}

class _FarmerProductsScreenState extends State<FarmerProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final products = state.filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: FarmerHeader(title: context.l10n.farmerProductsTitle),
      body: Stack(
        children: [
          SingleChildScrollView(
            // Stitch: bg-tertiary outer container, white cards
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Search Bar & Filter Button
                // Stitch: flex items-center justify-between mb-sm mt-xs
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          // Stitch: bg-surface rounded-full shadow
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(9999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => state.setSearchQuery(val),
                          decoration: InputDecoration(
                            hintText: context.l10n.farmerProductsSearchHint,
                            hintStyle: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              color: AppColors.onSurfaceVariant
                                  .withValues(alpha: 0.70),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.onSurfaceVariant,
                              size: 22,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      state.setSearchQuery('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Stitch: w-touch-target h-touch-target rounded-full bg-surface shadow
                    InkWell(
                      onTap: () => _showFilterDialog(context, state),
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.filter_list,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Active filter badge
                if (state.selectedCategory != 'All')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Chip(
                      label: Text(context.l10n.farmerProductsCategoryChip(
                          farmerCategoryLabel(
                              state.selectedCategory, context.l10n))),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => state.setSelectedCategory('All'),
                      backgroundColor: AppColors.surfaceContainerHigh,
                    ),
                  ),

                // 2. Product List
                if (products.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: AppColors.outlineVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.emptyState,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          if (state.currentUserId.isNotEmpty &&
                              !state.profileLoaded) ...[
                            const SizedBox(height: 16),
                            const CircularProgressIndicator(),
                            const SizedBox(height: 8),
                            Text(context.l10n.loading),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildProductCard(context, state, product);
                    },
                  ),
              ],
            ),
          ),

          // 3. FAB - Stitch: fixed bottom-24 right-4 w-14 h-14 bg-primary-container rounded-[16px]
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddProductScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimary,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    FarmoraState state,
    Product product,
  ) {
    final isEmpty = product.isEmpty;

    return InkWell(
      onTap: () => _showProductActionsModal(context, state, product),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        // Stitch: out-of-stock card = opacity-75 grayscale-[20%]
        opacity: isEmpty ? 0.75 : 1.0,
        child: Container(
          // Stitch: bg-surface rounded-[16px] p-md shadow-[0_4px_12px_rgba(0,0,0,0.05)]
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Stitch: w-20 h-20 rounded-lg overflow-hidden
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child:
                      product.imagePath != null && product.imagePath!.isNotEmpty
                          ? SafeImage(
                              path: product.imagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildFallbackThumbnail(product),
                            )
                          : _buildFallbackThumbnail(product),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Status chip row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Stitch: Active = bg-[#E3F2FD] text-[#0D47A1], Empty = bg-[#EEEEEE] text-[#424242]
                        _buildStatusPill(context, product.status, isEmpty),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Stitch: Organic • 50 kg available
                    Text(
                      '${product.isOrganic ? context.l10n.farmerOrganic : context.l10n.farmerConventional} • ${farmerProductQuantityText(product, context.l10n)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.hasVideo || product.hasQrCode) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (product.hasVideo) ...[
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => Scaffold(
                                      appBar: AppBar(
                                          title: Text(context.l10n.farmerProductsVideoTitle(product.name))),
                                      body: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: HarvestVideoPlayer(
                                            videoUrl: product.videoUrl!),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.videocam,
                                      size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    farmerHarvestStatusLabel(
                                        product.harvestStatus, context.l10n),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (product.hasQrCode)
                            InkWell(
                              onTap: () => _showProductQrDialog(
                                  context, product, product.qrCode!),
                              borderRadius: BorderRadius.circular(4),
                              child: Tooltip(
                                message: 'View Packing QR',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.qr_code_2,
                                          size: 14, color: AppColors.primary),
                                      SizedBox(width: 3),
                                      Text(
                                        'QR',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Price - Stitch: strikethrough + muted if empty
                    Text(
                      farmerProductPriceText(product, context.l10n),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isEmpty
                            ? AppColors.onSurfaceVariant
                            : AppColors.primary,
                        decoration: isEmpty ? TextDecoration.lineThrough : null,
                        decorationColor:
                            AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Stitch exact status chip colors
  Widget _buildStatusPill(BuildContext context, String status, bool isEmpty) {
    final Color bgColor;
    final Color textColor;

    if (isEmpty) {
      // Stitch: bg-[#EEEEEE] text-[#424242]
      bgColor = const Color(0xFFEEEEEE);
      textColor = const Color(0xFF424242);
    } else {
      // Stitch: bg-[#E3F2FD] text-[#0D47A1]
      bgColor = const Color(0xFFE3F2FD);
      textColor = const Color(0xFF0D47A1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        statusLabel(status, context.l10n).toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildFallbackThumbnail(Product product) {
    final emojiText = product.emoji.length > 2
        ? product.emoji.characters.first
        : product.emoji;
    return Container(
      color: product.color,
      child: Center(
        child: Text(
          emojiText,
          style: const TextStyle(fontSize: 36),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, FarmoraState state) {
    final categories = [
      'All',
      'Vegetables',
      'Fruits',
      'Grains',
      'Dairy',
      'Herbs'
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ctx.l10n.farmerProductsFilterByCategory,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = state.selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(farmerCategoryLabel(cat, ctx.l10n)),
                    selected: isSelected,
                    selectedColor: AppColors.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        state.setSelectedCategory(cat);
                        Navigator.of(ctx).pop();
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProductActionsModal(
      BuildContext context, FarmoraState state, Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final l = ctx.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  '${farmerProductPriceText(product, l)} • ${farmerProductQuantityText(product, l)}',
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.videocam_outlined,
                      color: AppColors.primary),
                  title: Text(
                    product.hasVideo
                        ? l.farmerProductsReplaceVideo
                        : l.farmerProductsUploadVideo,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    product.hasVideo
                        ? l.farmerProductsVideoStatus(
                            farmerHarvestStatusLabel(product.harvestStatus, l))
                        : l.farmerProductsVideoHint,
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _uploadHarvestVideo(context, state, product);
                  },
                ),
                if (product.hasVideo)
                  ListTile(
                    leading: const Icon(Icons.play_circle_outline, color: AppColors.primary),
                    title: Text(l.farmerProductsPreviewVideo,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                                title: Text(l.farmerProductsVideoTitle(product.name))),
                            body: Padding(
                              padding: const EdgeInsets.all(16),
                              child: HarvestVideoPlayer(
                                  videoUrl: product.videoUrl!),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                if (product.hasVideo)
                  ListTile(
                    leading: const Icon(Icons.videocam_off_outlined,
                        color: AppColors.error),
                    title: const Text('Delete harvest video',
                        style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await _deleteHarvestVideo(context, state, product);
                    },
                  ),
                if (product.hasQrCode)
                  ListTile(
                    leading: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                    title: const Text('View packing QR code',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('View & copy high-resolution QR for packaging'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showProductQrDialog(context, product, product.qrCode!);
                    },
                  ),
                ListTile(
                  leading:
                      const Icon(Icons.qr_code_2, color: AppColors.primary),
                  title: Text(
                    product.hasQrCode
                        ? l.farmerProductsRefreshQr
                        : l.farmerProductsGenerateQr,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(l.farmerProductsQrHint),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    try {
                      final payload =
                          await state.generateQrForProduct(product.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            payload == null
                                ? l.farmerProductsQrFailed
                                : l.farmerProductsQrReady,
                          ),
                        ),
                      );
                      if (payload != null && context.mounted) {
                        _showProductQrDialog(context, product, payload);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  l.farmerProductsQrError(userMessage(e,
                                      action: 'generate the QR code')))),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Icon(
                    product.isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    product.isActive
                        ? l.farmerProductsMarkOutOfStock
                        : l.farmerProductsMarkInStock,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    try {
                      await state.toggleProductStock(product.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text(l.farmerProductsStockUpdated(product.name))));
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Could not update listing: ${userMessage(error, action: 'update the listing')}')));
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.onSurface,
                  ),
                  title: Text(
                    l.farmerProductsEditListing,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AddProductScreen(existingProduct: product),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline, color: AppColors.error),
                  title: Text(
                    l.farmerProductsRemoveListing,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    try {
                      await state.deleteProduct(product.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.farmerProductsDeleted(product.name))));
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Could not remove listing: ${userMessage(error, action: 'remove the listing')}')));
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadHarvestVideo(
    BuildContext context,
    FarmoraState state,
    Product product,
  ) async {
    final picker = ImagePicker();
    var dialogShown = false;
    try {
      final file = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
      if (file == null) return;
      if (!context.mounted) return;
      dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final bytes = await file.readAsBytes();
      final result = await state.uploadHarvestVideo(
        productId: product.id,
        bytes: bytes,
        fileName: file.name,
      );
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dialog
      dialogShown = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result == null
              ? context.l10n.farmerProductsVideoUploadFailed
              : context.l10n.farmerProductsVideoUploaded(product.name)),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        if (dialogShown) Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.l10n.farmerProductsVideoUploadFailedReason(
                  userMessage(e, action: 'upload the harvest video')))),
        );
      }
    }
  }

  Future<void> _deleteHarvestVideo(
    BuildContext context,
    FarmoraState state,
    Product product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete harvest video?'),
        content: Text(
            'Buyers will no longer see the harvest video for ${product.name}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await state.deleteHarvestVideo(product);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harvest video deleted.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                userMessage(e, action: 'delete the harvest video'))),
      );
    }
  }

  void _showProductQrDialog(
      BuildContext context, Product product, String payload) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.qr_code_2, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: payload,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  payload,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Attach this QR code to crates or packaging. Handlers and buyers can scan to track harvest batch provenance.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: payload));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('QR Code data copied to clipboard!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy Data'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
