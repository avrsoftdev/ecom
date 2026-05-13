import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidgetTest extends StatefulWidget {
  const BannerAdWidgetTest({super.key});

  @override
  State<BannerAdWidgetTest> createState() => _BannerAdWidgetTestState();
}

class _BannerAdWidgetTestState extends State<BannerAdWidgetTest> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    debugPrint('Starting to load TEST banner ad...');
    
    _bannerAd = BannerAd(
      // Test ad unit ID for Android banner
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('TEST Banner ad loaded successfully!');
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('TEST Banner ad failed to load: ${error.code} - ${error.message}');
          debugPrint('Response info: ${error.responseInfo}');
          ad.dispose();
        },
        onAdOpened: (Ad ad) {
          debugPrint('TEST Banner ad opened');
        },
        onAdClosed: (Ad ad) {
          debugPrint('TEST Banner ad closed');
        },
        onAdImpression: (Ad ad) {
          debugPrint('TEST Banner ad impression recorded');
        },
      ),
    );

    _bannerAd?.load();
    debugPrint('TEST Banner ad load() called');
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      return Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          color: Colors.red.withOpacity(0.1),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
              ),
              SizedBox(height: 4),
              Text(
                'Loading Test Ad',
                style: TextStyle(fontSize: 10, color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
