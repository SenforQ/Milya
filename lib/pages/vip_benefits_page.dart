import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/vip_service.dart';

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

class VipBenefitsPage extends StatefulWidget {
  const VipBenefitsPage({super.key});

  @override
  State<VipBenefitsPage> createState() => _VipBenefitsPageState();
}

class _VipBenefitsPageState extends State<VipBenefitsPage> {
  int _selectedIndex = 0;

  // 内购相关
  bool _isLoading = false;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  Map<String, ProductDetails> _products = {};
  int _retryCount = 0;
  static const int maxRetries = 3;

  final List<VipPackage> _vipPackages = [
    VipPackage(
      productId: 'MilyaWeekVIP',
      price: 12.99,
      period: 'Per week',
      total: 12.99,
    ),
    VipPackage(
      productId: 'MilyaMonthVIP',
      price: 49.99,
      period: 'Per week',
      total: 49.99,
    ),
  ];

  final List<VipBenefit> _benefits = [
    VipBenefit(
      icon: Icons.person,
      title: 'Unlimited avatar changes',
    ),
    VipBenefit(
      icon: Icons.block,
      title: 'Eliminate in-app advertising',
    ),
    VipBenefit(
      icon: Icons.visibility,
      title: 'Unlimited Avatar list views',
    ),
  ];

  @override
  void initState() {
    super.initState();
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
      final Set<String> kIds = _vipPackages.map((e) => e.productId).toSet();

      // 拉取商品信息
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

        // 激活VIP状态
        await VipService.activateVip(purchase.productID);

        if (mounted) {
          showCenterToast(context, 'VIP subscription activated successfully!');
          // 延迟一下再返回，让用户看到成功提示
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
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

  String _getDisplayPrice(VipPackage package) {
    final product = _products[package.productId];
    if (product != null) {
      // 使用App Store的货币符号和价格，去掉US前缀
      String price = product.price;
      if (price.startsWith('US')) {
        price = price.substring(2); // 移除"US"前缀，保留$符号和价格
      }
      return price;
    } else {
      // 使用预设价格，显示货币符号
      return '\$${package.price.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // 可滚动内容
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/bg_me_vip_20250625.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 240),
                        // 价格选项
                        Row(
                          children: [
                            for (int i = 0; i < _vipPackages.length; i++)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedIndex = i;
                                    });
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      right: i == 0 ? 16 : 0,
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: i == _selectedIndex
                                          ? Colors.transparent
                                          : const Color(0xFF2A2B3E),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: i == _selectedIndex
                                            ? Colors.white
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          _getDisplayPrice(_vipPackages[i]),
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _vipPackages[i].period,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Total ${_getDisplayPrice(_vipPackages[i])}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 50),

                        // 权益列表
                        ...List.generate(_benefits.length, (index) {
                          final benefit = _benefits[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              children: [
                                // 绿色勾选图标
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4CAF50),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // 权益文字
                                Expanded(
                                  child: Text(
                                    benefit.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 底部按钮区域
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Restore按钮
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            // 处理恢复购买
                            _handleRestore();
                          },
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      child: Text(
                        'Restore',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: _isLoading
                              ? Colors.grey
                              : const Color(0xFFFF9469),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Confirm按钮
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              // 处理确认购买
                              _handleConfirm();
                            },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isLoading
                                ? [Colors.grey, Colors.grey]
                                : [
                                    const Color(0xFFFFD2B5),
                                    const Color(0xFFFF9469),
                                  ],
                            begin: const Alignment(0, 0.5),
                            end: const Alignment(1, 0.5),
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'confirm',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF431400),
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

  void _handleConfirm() async {
    final selectedPackage = _vipPackages[_selectedIndex];

    if (!_isAvailable) {
      showCenterToast(context, 'Store is not available');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final product = _products[selectedPackage.productId];
      if (product == null) {
        throw Exception('Product not found');
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // 使用 buyNonConsumable 购买订阅
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      if (mounted) {
        showCenterToast(context, 'Purchase failed: ${e.toString()}');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleRestore() async {
    if (!_isAvailable) {
      showCenterToast(context, 'Store is not available');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 恢复购买
      await _inAppPurchase.restorePurchases();
      if (mounted) {
        showCenterToast(context, 'Checking for previous purchases...');
      }
    } catch (e) {
      if (mounted) {
        showCenterToast(context, 'Restore failed: ${e.toString()}');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class VipPackage {
  final String productId;
  final double price;
  final String period;
  final double total;

  VipPackage({
    required this.productId,
    required this.price,
    required this.period,
    required this.total,
  });
}

class VipBenefit {
  final IconData icon;
  final String title;

  VipBenefit({
    required this.icon,
    required this.title,
  });
}

class RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 15;

    canvas.drawCircle(center, radius, paint);

    // 绘制旋转的小圆点
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final angle = 0.0; // 可以添加动画
    final radians = angle * pi / 180;
    final dotX = center.dx + radius * 0.8 * cos(radians);
    final dotY = center.dy + radius * 0.8 * sin(radians);

    canvas.drawCircle(Offset(dotX, dotY), 4, dotPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
