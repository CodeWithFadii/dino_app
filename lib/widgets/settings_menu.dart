import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../iap_service.dart';
import '/game/dino_run.dart';
import '/widgets/main_menu.dart';

class SettingsMenu extends StatefulWidget {
  static const id = 'SettingsMenu';
  final DinoRun game;

  const SettingsMenu(this.game, {super.key});

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  bool _isLoading = true;
  final Map<String, bool> _isPurchasing = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    await InAppPurchaseService.instance.init();
    setState(() => _isLoading = false);
  }

  void _showPurchaseDialog(
      BuildContext context, String name, int coins, String price, ProductDetails product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withAlpha(200),
          title: Text(
            'Purchase $name',
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
          content: Text(
            'Get $coins coins for $price',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            _isPurchasing[product.id] ?? false
                ? const CircularProgressIndicator(color: Colors.amber)
                : ElevatedButton(
                    onPressed: () async {
                      setState(() => _isPurchasing[product.id] = true);
                      final success = await InAppPurchaseService.instance.buy(product);
                      setState(() => _isPurchasing[product.id] = false);
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Purchase',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.game.settings,
      child: Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.black.withAlpha(100),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 50),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            widget.game.overlays.remove(SettingsMenu.id);
                            if (widget.game.settingsReturnToOverlay != null) {
                              widget.game.overlays.add(widget.game.settingsReturnToOverlay!);
                              widget.game.settingsReturnToOverlay = null;
                            } else {
                              widget.game.overlays.add(MainMenu.id);
                            }
                          },
                          child: const Icon(Icons.arrow_back_ios_rounded,
                              color: Colors.white, size: 30),
                        ),
                        const Text(
                          'Purchase Coins',
                          style: TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextButton(onPressed: null, child: SizedBox()),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Product List or Loading
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                        : Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: _getSortedProductWidgets(),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _getSortedProductWidgets() {
    final sortedProducts = InAppPurchaseService.instance.products.toList()
      ..sort((a, b) => _getCoinsForProduct(a.id).compareTo(_getCoinsForProduct(b.id)));

    return sortedProducts.map((product) {
      final coins = _getCoinsForProduct(product.id);
      final price = product.price;
      final displayName = _trimNameAfterPack(product.title);
      return _buildPurchaseOption(
        context,
        displayName,
        coins,
        price,
        product,
      );
    }).toList();
  }

  String _trimNameAfterPack(String title) {
    final packIndex = title.toLowerCase().indexOf('pack');
    if (packIndex != -1) {
      return title.substring(0, packIndex + 4).trim();
    }
    return title;
  }

  Widget _buildPurchaseOption(
    BuildContext context,
    String name,
    int coins,
    String price,
    ProductDetails product,
  ) {
    return Card(
      color: Colors.amber.withAlpha(100),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ListTile(
        leading: const Icon(Icons.monetization_on, color: Colors.amber, size: 30),
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$coins coins - $price',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        trailing: _isPurchasing[product.id] ?? false
            ? const CircularProgressIndicator(color: Colors.amber)
            : ElevatedButton(
                onPressed: () => _showPurchaseDialog(context, name, coins, price, product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  'Buy',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }

  int _getCoinsForProduct(String productId) {
    switch (productId) {
      case 'starter':
        return 100;
      case 'small':
        return 200;
      case 'medium':
        return 300;
      case 'large':
        return 400;
      case 'mega':
        return 500;
      default:
        return 0;
    }
  }
}
