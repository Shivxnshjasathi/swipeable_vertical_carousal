import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// 1. Import your new package
import 'package:swipeable_vertical_carousal/swipeable_vertical_carousal.dart';

// --- ALL YOUR ORIGINAL CLASSES ARE PASTED HERE ---

class ApiResponse {
  final List<BillCardModel> bills;
  final String title;
  final bool autoScrollEnabled;

  ApiResponse({
    required this.bills,
    required this.title,
    required this.autoScrollEnabled,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    try {
      var templateProps = json['template_properties'] ?? {};
      var body = templateProps['body'] ?? {};
      var childList = templateProps['child_list'] as List<dynamic>? ?? [];

      List<BillCardModel> parsedBills = childList
          .map((item) => BillCardModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return ApiResponse(
        bills: parsedBills,
        title: body['title'] ?? 'UPCOMING BILLS',
        autoScrollEnabled: body['auto_scroll_enabled'] ?? false,
      );
    } catch (e) {
      throw Exception('Failed to parse API response: $e');
    }
  }
}

class BillCardModel {
  final String title;
  final String subtitle;
  final String logoUrl;
  final String paymentAmount;
  final String ctaTitle;
  final String? footerText;
  final FlipperConfig? flipperConfig;

  BillCardModel({
    required this.title,
    required this.subtitle,
    required this.logoUrl,
    required this.paymentAmount,
    required this.ctaTitle,
    this.footerText,
    this.flipperConfig,
  });

  factory BillCardModel.fromJson(Map<String, dynamic> json) {
    var props = json['template_properties'] ?? {};
    var body = props['body'] ?? {};
    var ctas = props['ctas'] ?? {};
    var primaryCta = ctas['primary'] ?? {};

    return BillCardModel(
      title: body['title'] ?? 'No Title',
      subtitle: body['sub_title'] ?? '',
      logoUrl: body['logo']?['url'] ?? '',
      paymentAmount: body['payment_amount'] ?? '₹0',
      ctaTitle: primaryCta['title'] ?? 'Pay Now',
      footerText: body['footer_text'],
      flipperConfig: body['flipper_config'] != null
          ? FlipperConfig.fromJson(body['flipper_config'])
          : null,
    );
  }
}

class FlipperConfig {
  final List<String> items;
  final int flipDelay;

  FlipperConfig({required this.items, required this.flipDelay});

  factory FlipperConfig.fromJson(Map<String, dynamic> json) {
    var itemsList = (json['items'] as List<dynamic>? ?? [])
        .map((item) => (item['text'] ?? '') as String)
        .toList();

    return FlipperConfig(
      items: itemsList.isNotEmpty ? itemsList : [''],
      flipDelay: json['flip_delay'] ?? 2000,
    );
  }
}

class ApiService {
  final String _mock1Url = "https://your-api/1";
  final String _mock2Url = "https://your-api/2";

  Future<ApiResponse> fetchBills({int itemCount = 9}) async {
    final url = (itemCount <= 2) ? _mock1Url : _mock2Url;

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(decodedJson);
        return apiResponse;
      } else {
        throw Exception('Failed to load bills: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }
}

enum NotifierState { initial, loading, loaded, error }

class BillProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  ApiResponse? _apiResponse;
  ApiResponse? get apiResponse => _apiResponse;

  List<BillCardModel> get bills => _apiResponse?.bills ?? [];

  NotifierState _state = NotifierState.initial;
  NotifierState get state => _state;

  String _error = '';
  String get error => _error;

  Future<void> fetchBillsData({int itemCount = 9}) async {
    _setState(NotifierState.loading);
    try {
      _apiResponse = await _apiService.fetchBills(itemCount: itemCount);
      _setState(NotifierState.loaded);
    } catch (e) {
      _error = e.toString();
      _setState(NotifierState.error);
    }
  }

  void _setState(NotifierState state) {
    _state = state;
    notifyListeners();
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => BillProvider(),
      child: const BillsApp(),
    ),
  );
}

class BillsApp extends StatelessWidget {
  const BillsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bills UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
      ),
      home: const BillsScreen(),
    );
  }
}

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillProvider>().fetchBillsData(itemCount: 9);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Consumer<BillProvider>(
                builder: (context, provider, child) {
                  return HeaderRow(
                    title: provider.apiResponse?.title ?? 'UPCOMING BILLS',
                    count: provider.bills.length,
                  );
                },
              ),
              const SizedBox(height: 20),
              Consumer<BillProvider>(
                builder: (context, provider, child) {
                  switch (provider.state) {
                    case NotifierState.loading:
                    case NotifierState.initial:
                      return const SizedBox(
                        height: 250,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    case NotifierState.error:
                      return SizedBox(
                        height: 250,
                        child: Center(
                          child: Text(
                            'Failed to load bills.\n${provider.error}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    case NotifierState.loaded:
                      if (provider.bills.isEmpty) {
                        return const SizedBox(
                          height: 250,
                          child: Center(child: Text('No upcoming bills.')),
                        );
                      } else if (provider.bills.length > 2) {
                        
                        // *** THIS IS THE ONLY CHANGE ***
                        // We are now using your package widget
                        return StackedCardCarousel<BillCardModel>(
                          items: provider.bills,
                          cardHeight: 110.0, // You must provide the card height
                          autoScroll: provider.apiResponse!.autoScrollEnabled,
                          itemBuilder: (context, bill, index, visualPosition) {
                            // The builder just returns your original BillCard!
                            return BillCard(
                              bill: bill,
                              visualPosition: visualPosition,
                            );
                          },
                        );
                        // *** END OF CHANGE ***

                      } else {
                        return Column(
                          children: provider.bills
                              .map((bill) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12.0),
                                    child: BillCard(bill: bill, visualPosition: 0),
                                  ))
                              .toList(),
                        );
                      }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HeaderRow extends StatelessWidget {
  final String title;
  final int count;
  const HeaderRow({super.key, required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$title ($count)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
            letterSpacing: 0.3,
          ),
        ),
        Text(
          'view all >',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}

// *** IMPORTANT: The old `BillsCarousel` widget is DELETED ***
// It is now replaced by the `StackedCardCarousel` from your package.

class BillCard extends StatelessWidget {
  final BillCardModel bill;
  final int visualPosition;

  const BillCard({
    super.key,
    required this.bill,
    this.visualPosition = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110.0,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: (visualPosition <= 1)
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  spreadRadius: 0,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.network(
            bill.logoUrl,
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.credit_card,
                size: 32,
                color: Colors.grey,
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  bill.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  bill.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  bill.ctaTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              CardFooter(
                footerText: bill.footerText,
                flipperConfig: bill.flipperConfig,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CardFooter extends StatelessWidget {
  final String? footerText;
  final FlipperConfig? flipperConfig;

  const CardFooter({super.key, this.footerText, this.flipperConfig});

  @override
  Widget build(BuildContext context) {
    if (flipperConfig != null && flipperConfig!.items.isNotEmpty) {
      return FlipperWidget(config: flipperConfig!);
    } else if (footerText != null) {
      return Text(
        footerText!.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.3,
        ),
      );
    }
    return const SizedBox(height: 12);
  }
}

class FlipperWidget extends StatefulWidget {
  final FlipperConfig config;
  const FlipperWidget({super.key, required this.config});

  @override
  State<FlipperWidget> createState() => _FlipperWidgetState();
}

class _FlipperWidgetState extends State<FlipperWidget> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.config.items.length > 1) {
      _timer = Timer.periodic(
        Duration(milliseconds: widget.config.flipDelay),
        (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.config.items.length;
          });
        },
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Text(
        widget.config.items[_currentIndex].toUpperCase(),
        key: ValueKey<int>(_currentIndex),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
