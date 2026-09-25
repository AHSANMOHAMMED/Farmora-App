import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/farmora_state.dart';
import '../../../../models/review_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';

class ReviewManagementScreen extends StatefulWidget {
  const ReviewManagementScreen({super.key});

  @override
  State<ReviewManagementScreen> createState() => _ReviewManagementScreenState();
}

class _ReviewManagementScreenState extends State<ReviewManagementScreen> {
  String _selectedFilter = 'all'; // all, pending, approved, rejected, low_rating

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final allReviews = state.reviews;

    final filteredReviews = allReviews.where((r) {
      if (_selectedFilter == 'pending') return r.status == ReviewStatus.pending;
      if (_selectedFilter == 'approved') return r.status == ReviewStatus.approved;
      if (_selectedFilter == 'rejected') return r.status == ReviewStatus.rejected;
      if (_selectedFilter == 'low_rating') return r.rating <= 2;
      return true;
    }).toList();

    final pendingCount = allReviews.where((r) => r.status == ReviewStatus.pending).length;
    final lowRatingCount = allReviews.where((r) => r.rating <= 2).length;
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.adminReviewsTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('all', l.adminReviewsFilterAll(allReviews.length)),
                const SizedBox(width: 8),
                _buildFilterChip('pending', l.adminReviewsFilterPending(pendingCount), badgeColor: Colors.orange),
                const SizedBox(width: 8),
                _buildFilterChip('approved', l.statusApproved),
                const SizedBox(width: 8),
                _buildFilterChip('rejected', l.adminReviewsFilterFlagged),
                const SizedBox(width: 8),
                _buildFilterChip('low_rating', l.adminReviewsFilterLowRating(lowRatingCount), badgeColor: Colors.red),
              ],
            ),
          ),
          const Divider(height: 1),

          // Review List
          Expanded(
            child: filteredReviews.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_outlined, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(l.adminReviewsEmpty, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredReviews.length,
                    itemBuilder: (ctx, index) {
                      final review = filteredReviews[index];
                      return _ReviewCard(review: review);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, {Color? badgeColor}) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: (badgeColor ?? AppColors.primary).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? (badgeColor ?? AppColors.primary) : AppColors.textPrimary,
        fontSize: 13,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = filterKey);
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final state = context.read<FarmoraState>();
    final l = context.l10n;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Reviewer, Subject, Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  radius: 20,
                  child: Text(
                    review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.adminReviewsReviewed(review.subjectName),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      if (review.orderNumber.isNotEmpty)
                        Text(
                          l.adminReviewsOrder(review.orderNumber),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                _buildStatusChip(review),
              ],
            ),

            const SizedBox(height: 10),

            // Star Rating
            Row(
              children: List.generate(5, (starIdx) {
                return Icon(
                  starIdx < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber.shade700,
                  size: 20,
                );
              }),
            ),

            const SizedBox(height: 8),

            // Comment Text
            Text(
              review.comment,
              style: const TextStyle(fontSize: 13, height: 1.35, color: AppColors.textPrimary),
            ),

            // Moderation Note
            if (review.moderationNote != null && review.moderationNote!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l.adminReviewsAdminNote(review.moderationNote!),
                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Action Buttons
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: Text(l.adminReviewsAddNote, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _showAddNoteDialog(context, review, state),
                ),
                const SizedBox(width: 4),
                if (review.status != ReviewStatus.approved)
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: Text(l.adminReviewsApprove, style: const TextStyle(fontSize: 12)),
                    onPressed: () async {
                      await state.moderateReview(
                        reviewId: review.id,
                        status: ReviewStatus.approved,
                        note: 'Approved by admin',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.adminReviewsApprovedSnack)),
                        );
                      }
                    },
                  ),
                if (review.status != ReviewStatus.rejected) ...[
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.flag_outlined, size: 16, color: Colors.orange),
                    label: Text(l.adminReviewsFlag, style: const TextStyle(fontSize: 12, color: Colors.orange)),
                    onPressed: () async {
                      await state.moderateReview(
                        reviewId: review.id,
                        status: ReviewStatus.rejected,
                        note: 'Flagged for content review',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.adminReviewsFlaggedSnack)),
                        );
                      }
                    },
                  ),
                ],
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  tooltip: l.adminReviewsDeleteTooltip,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l.adminReviewsDeleteTitle),
                        content: Text(l.adminReviewsDeleteMessage),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(l.commonDelete),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await state.deleteReview(reviewId: review.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.adminReviewsDeletedSnack)),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(Review review) {
    Color bg;
    Color fg;
    final text = review.getStatusDisplayName();

    switch (review.status) {
      case ReviewStatus.approved:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        break;
      case ReviewStatus.rejected:
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        break;
      case ReviewStatus.pending:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, Review review, FarmoraState state) {
    final ctrl = TextEditingController(text: review.moderationNote ?? '');
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.adminReviewsNoteTitle),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l.adminReviewsNoteHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonCancel)),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await state.moderateReview(
                reviewId: review.id,
                status: review.status,
                note: ctrl.text.trim(),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.adminReviewsNoteSaved)),
                );
              }
            },
            child: Text(l.adminReviewsSaveNote),
          ),
        ],
      ),
    );
  }
}
