import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../models/language.dart';
import '../../providers/language_provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(languageProvider.tr('select_language')),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: AppLanguages.all.length,
            itemBuilder: (context, index) {
              final language = AppLanguages.all[index];
              final isSelected = languageProvider.currentLanguage == language;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isSelected ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected
                      ? BorderSide(color: AppColors.primary, width: 2)
                      : BorderSide.none,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        language.flag,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  title: Text(
                    language.nativeName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 18,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    language.name,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.7)
                          : AppColors.textSecondary,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 28,
                        )
                      : const Icon(
                          Icons.radio_button_unchecked,
                          color: AppColors.textHint,
                        ),
                  onTap: () async {
                    if (!isSelected) {
                      await languageProvider.changeLanguage(language);

                      // Show success message
                      Get.snackbar(
                        languageProvider.tr('success'),
                        languageProvider.tr('updated_successfully'),
                        backgroundColor: AppColors.success,
                        colorText: AppColors.textWhite,
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
