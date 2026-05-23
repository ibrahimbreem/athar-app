import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../models/donor_request_model.dart';
import '../../../../models/notification_model.dart';
import '../../../../services/firestore_service.dart';
import '../providers/org_provider.dart';

class OrgRequestsScreen extends ConsumerWidget {
  const OrgRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(orgRequestsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات المتابعة'),
        centerTitle: true,
      ),
      body: requests.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, size: 72, color: AppColors.grey300),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد طلبات متابعة حتى الآن',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: AppColors.grey500),
                  ),
                ],
              ),
            );
          }

          final pending = list.where((r) => r.status == RequestStatus.pending).toList();
          final others = list.where((r) => r.status != RequestStatus.pending).toList();
          final sorted = [...pending, ...others];

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _RequestCard(
              key: ValueKey(sorted[i].id),
              request: sorted[i],
              index: i,
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

// ─── Request Card ─────────────────────────────────────────────────────────────

class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({
    super.key,
    required this.request,
    required this.index,
  });
  final DonorRequestModel request;
  final int index;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _expanded = false;
  bool _isLoading = false;

  Future<void> _approve() async {
    final confirm = await context.showConfirmDialog(
      title: 'قبول الطلب',
      message: 'هل تريد قبول طلب متابعة ${widget.request.donorName} لحالة "${widget.request.campaignTitle}"؟',
      confirmText: 'قبول',
    );
    if (confirm != true) return;
    await _doUpdate(RequestStatus.approved, null);
  }

  Future<void> _reject() async {
    String? note;
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المتبرع: ${widget.request.donorName}'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'سبب الرفض (اختياري)...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('رفض', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    note = ctrl.text.trim().isEmpty ? null : ctrl.text.trim();
    await _doUpdate(RequestStatus.rejected, note);
  }

  Future<void> _doUpdate(RequestStatus status, String? note) async {
    setState(() => _isLoading = true);
    try {
      await FirestoreService().updateRequestStatus(widget.request.id, status, note);

      if (status == RequestStatus.approved) {
        await FirestoreService().incrementFollowersCount(widget.request.campaignId);
      }

      final isApproved = status == RequestStatus.approved;
      await FirestoreService().sendInAppNotification(
        userId: widget.request.donorId,
        title: isApproved ? 'تمت الموافقة على طلبك ✅' : 'تحديث بشأن طلبك',
        body: isApproved
            ? 'تمت الموافقة على متابعتك لحالة "${widget.request.campaignTitle}"'
            : 'تم رفض طلب متابعتك لحالة "${widget.request.campaignTitle}"'
                '${note != null ? ': $note' : ''}',
        type: isApproved
            ? NotificationType.requestApproved
            : NotificationType.general,
        campaignId: widget.request.campaignId,
        requestId: widget.request.id,
      );

      if (mounted) {
        context.showSuccessSnackBar(
          isApproved ? 'تمت الموافقة على الطلب' : 'تم رفض الطلب',
        );
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final req = widget.request;
    final isPending = req.status == RequestStatus.pending;

    final Color statusColor;
    switch (req.status) {
      case RequestStatus.approved:
        statusColor = AppColors.success;
        break;
      case RequestStatus.rejected:
        statusColor = AppColors.error;
        break;
      case RequestStatus.reviewed:
        statusColor = AppColors.info;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? AppColors.warning.withValues(alpha: 0.4)
              : (isDark ? const Color(0xFF2D3748) : AppColors.grey100),
        ),
      ),
      child: Column(
        children: [
          // ─── Header row ────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: statusColor.withValues(alpha: 0.15),
                    child: Text(
                      req.donorName.isNotEmpty ? req.donorName[0] : 'م',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.donorName,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          req.campaignTitle,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: req.status, color: statusColor),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.grey400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ─── Expanded details ──────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (req.donorPhone != null)
                    _InfoRow(Icons.phone_outlined, 'الهاتف', req.donorPhone!),
                  if (req.donorEmail != null)
                    _InfoRow(Icons.email_outlined, 'البريد', req.donorEmail!),
                  _InfoRow(Icons.access_time_rounded, 'التاريخ',
                      _timeAgo(req.createdAt)),

                  if (req.message != null && req.message!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('رسالة المتبرع',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.backgroundDark
                            : AppColors.grey50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        req.message!,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ),
                  ],

                  if (req.organizationNote != null &&
                      req.organizationNote!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoRow(Icons.note_outlined, 'ملاحظتك',
                        req.organizationNote!),
                  ],

                  // Action buttons for pending requests
                  if (isPending) ...[
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _approve,
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('قبول'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 44),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _reject,
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: const Text('رفض'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                minimumSize: const Size(0, 44),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 60))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.08, end: 0);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});
  final RequestStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  String get _label {
    switch (status) {
      case RequestStatus.pending:
        return 'قيد المراجعة';
      case RequestStatus.approved:
        return 'مقبول';
      case RequestStatus.rejected:
        return 'مرفوض';
      case RequestStatus.reviewed:
        return 'تمت المراجعة';
    }
  }
}
