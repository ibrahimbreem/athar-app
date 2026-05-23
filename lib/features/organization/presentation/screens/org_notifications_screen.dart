import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/notification_model.dart';
import '../../../../services/firestore_service.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final _orgNotificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return FirestoreService().getNotifications(user.id);
});

class OrgNotificationsScreen extends ConsumerWidget {
  const OrgNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(_orgNotificationsProvider);
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notifications),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: user == null
                ? null
                : () =>
                    FirestoreService().markAllNotificationsRead(user.id),
            child: const Text(AppStrings.markAllRead),
          ),
        ],
      ),
      body: notifs.when(
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.notifications_none_rounded,
                title: AppStrings.noNotifications,
                description: AppStrings.noNotificationsDesc,
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final n = list[i];
                  final isDark = theme.brightness == Brightness.dark;
                  final isUnread = !n.isRead;

                  return GestureDetector(
                    onTap: () =>
                        FirestoreService().markNotificationRead(n.id),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isUnread
                            ? (isDark
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.primaryContainer
                                    .withValues(alpha: 0.5))
                            : (isDark
                                ? AppColors.surfaceDark
                                : AppColors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isUnread
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : (isDark
                                  ? const Color(0xFF2D3748)
                                  : AppColors.grey100),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isUnread
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : AppColors.grey100,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(n.typeIcon,
                                  style: const TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(
                                    fontWeight: isUnread
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(n.body,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(height: 1.5)),
                                const SizedBox(height: 5),
                                Text(
                                  _timeAgo(n.createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey400,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }
}
