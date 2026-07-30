import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton ChangeNotifier that manages in-app subscriptions for Sleep Sounds.
/// Product IDs for Google Play & App Store:
/// - Monthly: sleepsounds_monthly_subs
/// - Yearly: sleepsounds_yearly_subs
class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  static const String idMonthly = 'sleepsounds_monthly_subs';
  static const String idYearly = 'sleepsounds_yearly_subs';
  static const String basePlanMonthly = 'sleepsounds-monthly-subs';
  static const String basePlanYearly = 'sleepsounds-yearly-subs';

  static const String _kIsPremiumKey = 'ss_is_premium';
  static const String _kPlanTypeKey = 'ss_plan_type';
  static const String _kExpiryDateKey = 'ss_expiry_date';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseStreamSub;
  Completer<bool>? _restoreCompleter;

  void Function(String message)? onPurchaseError;

  bool _isPremium = false;
  String _activePlan = 'none'; // 'monthly', 'yearly', or 'none'
  DateTime? _expiryDate;
  List<ProductDetails> _products = [];
  Set<String> _notFoundIDs = {};

  bool _isLoading = false;
  bool _isProductsLoading = false;
  bool _isPurchasePending = false;
  bool _initialized = false;

  bool get isPremium => _isPremium;
  String get activePlan => _activePlan;
  DateTime? get expiryDate => _expiryDate;
  List<ProductDetails> get products => _products;
  Set<String> get notFoundIDs => _notFoundIDs;
  bool get isLoading => _isLoading;
  bool get isProductsLoading => _isProductsLoading;
  bool get isPurchasePending => _isPurchasePending;

  ProductDetails? get monthlyProduct {
    try {
      return _products.firstWhere(
        (p) => p.id == idMonthly || p.id == basePlanMonthly,
      );
    } catch (_) {
      return null;
    }
  }

  ProductDetails? get yearlyProduct {
    try {
      return _products.firstWhere(
        (p) => p.id == idYearly || p.id == basePlanYearly,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _purchaseStreamSub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _purchaseStreamSub?.cancel(),
      onError: (error) => debugPrint('[SubscriptionService] Purchase stream error: $error'),
    );

    await _loadCachedStatus();
    await fetchProducts();

    // Auto-restore re-validation on app launch if not currently premium
    if (!_isPremium) {
      debugPrint('[SubscriptionService] Auto-checking active purchases on launch...');
      await restorePurchases();
    }
  }

  Future<void> _loadCachedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_kIsPremiumKey) ?? false;
    _activePlan = prefs.getString(_kPlanTypeKey) ?? 'none';
    final expiryStr = prefs.getString(_kExpiryDateKey);
    if (expiryStr != null) {
      _expiryDate = DateTime.tryParse(expiryStr);
      if (_expiryDate != null && DateTime.now().isAfter(_expiryDate!)) {
        // Expired
        _isPremium = false;
        _activePlan = 'none';
        await prefs.setBool(_kIsPremiumKey, false);
        await prefs.setString(_kPlanTypeKey, 'none');
      }
    }
    notifyListeners();
  }

  Future<void> _saveCachedStatus(bool isPrem, String plan, {DateTime? expiry}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsPremiumKey, isPrem);
    await prefs.setString(_kPlanTypeKey, plan);
    if (expiry != null) {
      await prefs.setString(_kExpiryDateKey, expiry.toIso8601String());
    } else {
      await prefs.remove(_kExpiryDateKey);
    }

    _isPremium = isPrem;
    _activePlan = plan;
    _expiryDate = expiry;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    _isProductsLoading = true;
    notifyListeners();
    try {
      final bool available = await _iap.isAvailable();
      if (!available) {
        debugPrint('[SubscriptionService] IAP not available on this device.');
        _notFoundIDs = {idMonthly, idYearly};
        return;
      }

      final Set<String> ids = {idMonthly, idYearly};
      debugPrint('[SubscriptionService] Querying product details for: $ids');
      final ProductDetailsResponse response = await _iap.queryProductDetails(ids);

      if (response.error != null) {
        debugPrint('[SubscriptionService] Product query error: ${response.error}');
      }

      _notFoundIDs = response.notFoundIDs.isNotEmpty ? response.notFoundIDs.toSet() : {};
      _products = response.productDetails;

      debugPrint('[SubscriptionService] Loaded ${_products.length} product(s).');
      for (final p in _products) {
        debugPrint('  • ${p.id} — ${p.title} — ${p.price}');
      }
    } catch (e) {
      debugPrint('[SubscriptionService] fetchProducts error: $e');
      _notFoundIDs = {idMonthly, idYearly};
    } finally {
      _isProductsLoading = false;
      notifyListeners();
    }
  }

  Future<void> buySubscription(ProductDetails product) async {
    _isPurchasePending = true;
    notifyListeners();

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _isPurchasePending = false;
      notifyListeners();
      debugPrint('[SubscriptionService] buySubscription error: $e');
      rethrow;
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    _setLoading(true);
    try {
      for (final purchase in purchaseDetailsList) {
        await _handleSinglePurchase(purchase);
      }
    } finally {
      _isPurchasePending = false;
      _setLoading(false);
      if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
        _restoreCompleter!.complete(_isPremium);
      }
    }
  }

  Future<void> _handleSinglePurchase(PurchaseDetails purchase) async {
    debugPrint('[SubscriptionService] Purchase status: ${purchase.productID} -> ${purchase.status}');

    switch (purchase.status) {
      case PurchaseStatus.error:
        final code = purchase.error?.code ?? '';
        final msg = purchase.error?.message ?? 'Unknown error';
        debugPrint('[SubscriptionService] Purchase error [$code]: $msg');
        onPurchaseError?.call(_friendlyErrorMessage(code, msg));
        break;

      case PurchaseStatus.canceled:
        debugPrint('[SubscriptionService] Purchase canceled by user.');
        break;

      case PurchaseStatus.pending:
        debugPrint('[SubscriptionService] Purchase pending.');
        break;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        final plan = (purchase.productID.contains('yearly')) ? 'yearly' : 'monthly';
        // Set expiry for 1 month or 1 year from now as client fallback estimate
        final duration = plan == 'yearly' ? const Duration(days: 365) : const Duration(days: 30);
        await _saveCachedStatus(true, plan, expiry: DateTime.now().add(duration));
        break;
    }

    if (purchase.pendingCompletePurchase) {
      try {
        await _iap.completePurchase(purchase);
        debugPrint('[SubscriptionService] completePurchase called for ${purchase.productID}');
      } catch (e) {
        debugPrint('[SubscriptionService] completePurchase error: $e');
      }
    }
  }

  Future<bool> restorePurchases() async {
    _setLoading(true);
    _restoreCompleter = Completer<bool>();
    try {
      await _iap.restorePurchases();
      // Wait for purchase stream to process restored items or timeout
      return await _restoreCompleter!.future.timeout(
        const Duration(seconds: 6),
        onTimeout: () => _isPremium,
      );
    } catch (e) {
      debugPrint('[SubscriptionService] restorePurchases error: $e');
      return _isPremium;
    } finally {
      _restoreCompleter = null;
      _setLoading(false);
    }
  }

  String _friendlyErrorMessage(String code, String rawMessage) {
    if (code.contains('itemAlreadyOwned') || rawMessage.toLowerCase().contains('already owned')) {
      return 'You already own this subscription. Tap "Restore Purchases" to restore it.';
    }
    if (rawMessage.toLowerCase().contains('network') || rawMessage.toLowerCase().contains('connect')) {
      return 'Network connection error. Please check your internet connection.';
    }
    return 'Purchase could not be completed. Please try again.';
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseStreamSub?.cancel();
    super.dispose();
  }
}
