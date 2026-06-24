import 'package:flutter/material.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_themes.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedPlanIndex = 1; // Default to Yearly (index 1)

  void _showSubscriptionSuccess() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemes.borderRadiusCard),
            side: const BorderSide(color: AppColors.borderLight, width: 1),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.primaryCyan,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Unlock Successful!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thank you for upgrading! Enjoy ultimate sleep sounds.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop(); // Close Dialog
                  Navigator.of(context).pop(); // Go back to Profile Screen
                },
                child: Container(
                  height: 44,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      AppThemes.borderRadiusButton,
                    ),
                    gradient: AppColors.primaryButtonGradient,
                  ),
                  child: const Center(
                    child: Text(
                      'Awesome',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Free Premium',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppThemes.paddingScreen,
            vertical: 4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Badge/Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryCyan, AppColors.primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryCyan.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(
                      text: 'Unlock ',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: 'Premium',
                      style: TextStyle(color: AppColors.primaryCyan),
                    ),
                    TextSpan(
                      text: ' Sounds',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              const Text(
                'Deeper sleep with our full library, ad-free.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 18),

              // Benefits Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight, width: 1),
                ),
                child: Column(
                  children: [
                    _buildBenefitRow(
                      icon: Icons.shield_outlined,
                      title: 'Unlimited Sound Library',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(
                        color: AppColors.borderLight.withValues(alpha: 0.5),
                        height: 1,
                      ),
                    ),
                    _buildBenefitRow(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Exclusive Premium Ambience',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(
                        color: AppColors.borderLight.withValues(alpha: 0.5),
                        height: 1,
                      ),
                    ),
                    _buildBenefitRow(
                      icon: Icons.notifications_none_outlined,
                      title: 'Ad-Free Listening',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Plans Selection Row
              Row(
                children: [
                  Expanded(
                    child: _buildPlanCard(
                      index: 0,
                      title: 'Monthly',
                      price: '\$2.99/mo',
                      period: 'Per month',
                      isSelected: _selectedPlanIndex == 0,
                      onTap: () {
                        setState(() {
                          _selectedPlanIndex = 0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPlanCard(
                      index: 1,
                      title: 'Yearly',
                      price: '\$2.99',
                      period: 'Save 50%',
                      isSelected: _selectedPlanIndex == 1,
                      onTap: () {
                        setState(() {
                          _selectedPlanIndex = 1;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Button
              GestureDetector(
                onTap: _showSubscriptionSuccess,
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      AppThemes.borderRadiusButton,
                    ),
                    gradient: AppColors.primaryButtonGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryCyan.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Start Free Trial',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow({required IconData icon, required String title}) {
    return Row(
      children: [
        // Icon Box
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryCyan, size: 22),
        ),
        const SizedBox(width: 16),

        // Text
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Green Checkmark
        const Icon(Icons.check_rounded, color: Colors.tealAccent, size: 22),
      ],
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String title,
    required String price,
    required String period,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color textColor = isSelected ? Colors.black : Colors.white;
    final Color subTextColor = isSelected
        ? Colors.black.withValues(alpha: 0.6)
        : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.primaryCyan, AppColors.primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppColors.cardColor,
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.borderLight,
            width: isSelected ? 0 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: subTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              price,
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              period,
              style: TextStyle(
                color: subTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
