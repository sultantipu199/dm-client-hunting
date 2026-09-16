import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

/// Modal dialog displaying blacklisted contacts protected by the Wrong-Contact Guard.
class BlacklistGuardDialog extends StatelessWidget {
  const BlacklistGuardDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        borderColor: AppTheme.sunsetCoral.withOpacity(0.4),
        child: ValueListenableBuilder<Box<String>>(
          valueListenable: StorageService.blacklistBox.listenable(),
          builder: (context, box, _) {
            final keys = box.keys.toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_rounded, color: AppTheme.sunsetCoral, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Blacklist Contact Guard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.cleanAlabaster,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.subduedSilver, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Numbers automatically saved to prevent re-contacting recipients who requested removal or wrong contact.',
                  style: TextStyle(fontSize: 12, color: AppTheme.subduedSilver),
                ),
                const SizedBox(height: 14),
                if (keys.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    alignment: Alignment.center,
                    child: const Text(
                      'No contacts blacklisted yet. All channels clear.',
                      style: TextStyle(fontSize: 13, color: AppTheme.mutedSlate),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: keys.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: AppTheme.borderNeonSubtle,
                        height: 1,
                      ),
                      itemBuilder: (context, idx) {
                        final phone = keys[idx].toString();
                        final reason = box.get(phone) ?? 'Wrong contact';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.sunsetCoral.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.block_rounded,
                                  size: 14,
                                  color: AppTheme.sunsetCoral,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '+$phone',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.cleanAlabaster,
                                      ),
                                    ),
                                    Text(
                                      reason,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.mutedSlate,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 16, color: AppTheme.mutedSlate),
                                onPressed: () async {
                                  await box.delete(phone);
                                  HapticFeedback.lightImpact();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
