import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/coins_service.dart';

// 充值项常量
class GoldProduct {
  final String productId;
  final int coins;
  final int bonusCoins;
  final String priceText; // 预设价格文本

  GoldProduct({
    required this.productId,
    required this.coins,
    required this.bonusCoins,
    required this.priceText,
  });
}

final List<GoldProduct> kGoldProducts = [
  GoldProduct(
      productId: 'Milya', coins: 32, bonusCoins: 0, priceText: '\$0.99'),
  GoldProduct(
      productId: 'Milya2', coins: 96, bonusCoins: 0, priceText: '\$2.99'),
  GoldProduct(
      productId: 'Milya5', coins: 189, bonusCoins: 0, priceText: '\$5.99'),
  GoldProduct(
      productId: 'Milya9', coins: 299, bonusCoins: 60, priceText: '\$9.99'),
  GoldProduct(
      productId: 'Milya19', coins: 599, bonusCoins: 130, priceText: '\$19.99'),
  GoldProduct(
      productId: 'Milya49', coins: 1599, bonusCoins: 270, priceText: '\$49.99'),
  GoldProduct(
      productId: 'Milya99', coins: 3199, bonusCoins: 600, priceText: '\$99.99'),
  GoldProduct(
      productId: 'Milya159',
      coins: 5099,
      bonusCoins: 900,
      priceText: '\$159.99'),
  GoldProduct(
      productId: 'Milya239',
      coins: 7959,
      bonusCoins: 1100,
      priceText: '\$239.99'),
];

const String kGoldBalanceKey = 'gold_coins_balance';

// 居中自动消失提示
Future<void> showCenterToast(BuildContext context, String message,
    {int milliseconds = 1800}) async {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, anim1, anim2) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return FadeTransition(opacity: anim1, child: child);
    },
  );
  await Future.delayed(Duration(milliseconds: milliseconds));
  if (Navigator.of(context, rootNavigator: true).canPop()) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

Future<void> fetchAndCacheIAPProducts(
    InAppPurchase iap, Set<String> productIds) async {
  final response = await iap.queryProductDetails(productIds);
  if (response.error == null && response.productDetails.isNotEmpty) {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> productList = response.productDetails
        .map((p) => {
              'id': p.id,
              'title': p.title,
              'description': p.description,
              'price': p.price,
              'currencySymbol': p.currencySymbol,
              'rawPrice': p.rawPrice,
              'currencyCode': p.currencyCode,
            })
        .toList();
    await prefs.setString('iap_product_cache', jsonEncode(productList));
  }
}

Future<List<Map<String, dynamic>>?> getCachedIAPProducts() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonStr = prefs.getString('iap_product_cache');
  if (jsonStr == null) return null;
  final List<dynamic> list = jsonDecode(jsonStr);
  return list.cast<Map<String, dynamic>>();
}

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double _goldCoins = 100.00;
  int _selectedIndex = -1;

  // 内购相关
  bool _isLoading = false;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  Map<String, ProductDetails> _products = {};
  int _retryCount = 0;
  static const int maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _loadGoldCoins();
    _checkConnectivityAndInit();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivityAndInit() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) {
        showCenterToast(context,
            'No internet connection. Please check your network settings.');
      }
      return;
    }
    await _initIAP();
  }

  Future<void> _initIAP() async {
    try {
      final available = await _inAppPurchase.isAvailable();
      if (!mounted) return;
      setState(() {
        _isAvailable = available;
      });
      if (!available) {
        if (mounted) {
          showCenterToast(context, 'In-App Purchase not available');
        }
        return;
      }

      // 获取所有产品ID
      final Set<String> kIds = kGoldProducts.map((e) => e.productId).toSet();

      // 先尝试从缓存获取
      final cachedProducts = await getCachedIAPProducts();
      if (cachedProducts != null && mounted) {
        setState(() {
          _products = {
            for (var p in cachedProducts)
              p['id']: ProductDetails(
                id: p['id'],
                title: p['title'],
                description: p['description'],
                price: p['price'],
                rawPrice: p['rawPrice'],
                currencySymbol: p['currencySymbol'],
                currencyCode: p['currencyCode'] ?? 'USD',
              )
          };
        });
      }

      // 拉取最新商品信息
      final response = await _inAppPurchase.queryProductDetails(kIds);

      if (response.error != null) {
        if (_retryCount < maxRetries) {
          _retryCount++;
          await Future.delayed(const Duration(seconds: 2));
          await _initIAP();
          return;
        }
        if (mounted) {
          showCenterToast(
              context, 'Failed to load products: ${response.error!.message}');
        }
      }

      if (mounted) {
        setState(() {
          _products = {for (var p in response.productDetails) p.id: p};
        });
      }

      // 缓存商品信息
      await fetchAndCacheIAPProducts(_inAppPurchase, kIds);

      // 监听购买流
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () {
          _subscription?.cancel();
        },
        onError: (e) {
          if (mounted) {
            showCenterToast(context, 'Purchase error: ${e.toString()}');
          }
        },
      );
    } catch (e) {
      if (_retryCount < maxRetries) {
        _retryCount++;
        await Future.delayed(const Duration(seconds: 2));
        await _initIAP();
      } else {
        if (mounted) {
          showCenterToast(context,
              'Failed to initialize in-app purchases. Please try again later.');
        }
      }
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _inAppPurchase.completePurchase(purchase);
        // 根据产品ID更新余额
        final product = _products[purchase.productID];
        if (product != null) {
          int coins = _getCoinsForProduct(purchase.productID);
          await _updateBalance(coins);
          if (mounted) {
            showCenterToast(context, 'Successfully purchased $coins coins!');
          }
        }
      } else if (purchase.status == PurchaseStatus.error) {
        if (mounted) {
          showCenterToast(
              context, 'Purchase failed: ${purchase.error?.message ?? ''}');
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        if (mounted) {
          showCenterToast(context, 'Purchase canceled.');
        }
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _getCoinsForProduct(String productId) {
    final goldProduct = kGoldProducts.firstWhere(
      (p) => p.productId == productId,
      orElse: () =>
          GoldProduct(productId: '', coins: 0, bonusCoins: 0, priceText: ''),
    );
    return goldProduct.coins + goldProduct.bonusCoins;
  }

  Future<void> _loadGoldCoins() async {
    final coins = await CoinsService.getCoins();
    setState(() {
      _goldCoins = coins;
    });
  }

  Future<void> _updateBalance(int amount) async {
    final newCoins = await CoinsService.addCoins(amount.toDouble());
    setState(() {
      _goldCoins = newCoins;
    });
  }

  Future<void> _onPurchase() async {
    if (_selectedIndex >= 0) {
      final item = kGoldProducts[_selectedIndex];

      if (!_isAvailable) {
        showCenterToast(context, 'Store is not available');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final product = _products[item.productId];
        if (product == null) {
          throw Exception('Product not found');
        }

        final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: product,
        );

        await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      } catch (e) {
        if (mounted) {
          showCenterToast(context, 'Purchase failed: ${e.toString()}');
        }
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCoinsInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'About Gold Coins',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gold coins are used for premium features in our app:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'AI Jewelry Expert consultations: Each message costs 6 coins',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'This is a paid consumption service',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'New users receive 100 coins as a welcome gift!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Got it',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getDisplayPrice(GoldProduct package) {
    final product = _products[package.productId];
    if (product != null) {
      return product.price;
    } else {
      return package.priceText; // 使用预设价格
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_wallet_nor_20250625.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // 顶部导航栏
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 金币余额卡片
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Stack(
                      children: [
                        // 背景图片 - 直接充满区域，高度自适应
                        Image.asset(
                          'assets/images/bg_wallet_gold_20250625.png',
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 120,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.orange, Colors.deepOrange],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            );
                          },
                        ),
                        // 文字内容
                        Positioned(
                          left: 24,
                          top: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'My gold coins',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFFFDAA8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _goldCoins.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: Color(0xFFFFDAA8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 右上角感叹号按钮
                        Positioned(
                          right: 16,
                          top: 16,
                          child: GestureDetector(
                            onTap: _showCoinsInfoDialog,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFDAA8),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Color(0xFFFFDAA8),
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 购买选项网格
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: kGoldProducts.length,
                        itemBuilder: (context, index) {
                          final item = kGoldProducts[index];
                          final isSelected = _selectedIndex == index;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.orange
                                      : Colors.white.withValues(alpha: 0.2),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _getDisplayPrice(item),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.orange
                                          : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${item.coins + item.bonusCoins} gold',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isSelected
                                          ? Colors.orange.withValues(alpha: 0.9)
                                          : Colors.grey[300],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // 购买按钮
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: GestureDetector(
                        onTap: (_selectedIndex >= 0 && !_isLoading)
                            ? _onPurchase
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: (_selectedIndex >= 0 && !_isLoading)
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD2B5),
                                      Color(0xFFFF9469),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.grey[600]!,
                                      Colors.grey[600]!,
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF431400)),
                                    strokeWidth: 3,
                                  )
                                : Text(
                                    _selectedIndex >= 0
                                        ? 'Purchase'
                                        : 'Select a package',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF431400),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
