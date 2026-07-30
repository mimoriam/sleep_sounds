import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/subscription_service.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_themes.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedPlanIndex = 1; // Default to Yearly (index 1)
  bool _isRestoring = false;
  SubscriptionService? _service;
  bool _wasPremium = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _service = context.read<SubscriptionService>();
      _wasPremium = _service?.isPremium ?? false;
      _service?.addListener(_onSubscriptionChanged);
      _service?.onPurchaseError = (msg) {
        if (!mounted || msg.isEmpty) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.cardColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      };
    });
  }

  void _onSubscriptionChanged() {
    if (!mounted || _service == null) return;
    final isPrem = _service!.isPremium;
    if (!_wasPremium && isPrem) {
      _wasPremium = true;
      _showSubscriptionSuccess();
    }
  }

  @override
  void dispose() {
    if (_service != null) {
      _service!.removeListener(_onSubscriptionChanged);
      _service!.onPurchaseError = null;
    }
    super.dispose();
  }

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
                  Navigator.of(context).pop(); // Go back
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

  Future<void> _handleBuy(SubscriptionService service) async {
    final monthly = service.monthlyProduct;
    final yearly = service.yearlyProduct;

    final targetProduct = _selectedPlanIndex == 0 ? monthly : yearly;

    if (targetProduct != null) {
      try {
        await service.buySubscription(targetProduct);
      } catch (e) {
        debugPrint('[PremiumScreen] buy error: $e');
      }
    } else {
      // Fallback if product details haven't arrived from store yet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connecting to store... Please try again in a moment.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      service.fetchProducts();
    }
  }

  Future<void> _handleRestore(SubscriptionService service) async {
    setState(() => _isRestoring = true);
    final restored = await service.restorePurchases();
    if (mounted) {
      setState(() => _isRestoring = false);
      if (restored) {
        _showSubscriptionSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active subscriptions found to restore.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SubscriptionService>();
    final isPremium = service.isPremium;
    final monthly = service.monthlyProduct;
    final yearly = service.yearlyProduct;

    final monthlyPriceStr = monthly?.price ?? '\$2.99';
    final yearlyPriceStr = yearly?.price ?? '\$19.99';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isPremium ? 'Premium Pass' : 'Unlock Premium',
          style: const TextStyle(
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
                child: Center(
                  child: Icon(
                    isPremium ? Icons.workspace_premium_rounded : Icons.workspace_premium_outlined,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (isPremium) ...[
                const Text(
                  'Premium Active ✓',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryCyan,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You have unlocked all sleep music & relaxation sounds!\nPlan: ${service.activePlan.toUpperCase()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
              ] else ...[
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
              ],

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
                      title: 'Full 26+ Sound Library Unlocked',
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
                      title: 'Sleep Music & Relaxation Categories',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(
                        color: AppColors.borderLight.withValues(alpha: 0.5),
                        height: 1,
                      ),
                    ),
                    _buildBenefitRow(
                      icon: Icons.music_note_rounded,
                      title: 'Unlimited Layer Combinations',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (!isPremium) ...[
                // Plans Selection Row
                Row(
                  children: [
                    Expanded(
                      child: _buildPlanCard(
                        index: 0,
                        title: 'Monthly',
                        price: monthlyPriceStr,
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
                        price: yearlyPriceStr,
                        period: 'Save 45%',
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
                  onTap: service.isPurchasePending ? null : () => _handleBuy(service),
                  child: Container(
                    width: double.infinity,
                    height: 48,
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
                    child: Center(
                      child: service.isPurchasePending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Upgrade Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Restore Purchases button
              TextButton(
                onPressed: _isRestoring ? null : () => _handleRestore(service),
                child: _isRestoring
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: AppColors.primaryCyan, strokeWidth: 2),
                      )
                    : const Text(
                        'Restore Purchases',
                        style: TextStyle(
                          color: AppColors.primaryCyan,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow({required IconData icon, required String title}) {
    return Row(
      children: [
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
                fontSize: 22,
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
