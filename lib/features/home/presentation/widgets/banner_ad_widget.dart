import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    // Use test ad unit ID in debug mode, actual ad unit ID in release mode
    final adUnitId = kDebugMode
        ? 'ca-app-pub-3940256099942544/6300978111' // Test ad unit ID
        : 'ca-app-pub-7682628416837305/1425767502'; // AdMob guide ad unit ID

    debugPrint('Starting to load banner ad...');
    debugPrint('Using ad unit ID: $adUnitId');
    debugPrint('Debug mode: $kDebugMode');

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('Banner ad loaded successfully!');
          if (!mounted) return;
          setState(() {
            _isAdLoaded = true;
            _hasError = false;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint(
            'Banner ad failed to load: ${error.code} - ${error.message}',
          );
          debugPrint('Ad unit ID: $adUnitId');
          debugPrint('Response info: ${error.responseInfo}');
          debugPrint('Domain: ${error.domain}');
          ad.dispose();

          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isAdLoaded = false;
            _hasError = true;
            _errorMessage = '${error.code}: ${error.message}';
          });
        },
        onAdOpened: (Ad ad) {
          debugPrint('Banner ad opened');
        },
        onAdClosed: (Ad ad) {
          debugPrint('Banner ad closed');
        },
        onAdImpression: (Ad ad) {
          debugPrint('Banner ad impression recorded');
        },
      ),
    );

    _bannerAd?.load();
    debugPrint('Banner ad load() called');
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
    }

    if (_hasError) {
      if (kDebugMode) {
        return Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange),
            color: Colors.orange.withOpacity(0.1),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.orange, size: 16),
                const SizedBox(height: 2),
                Text(
                  'Ad failed to load',
                  style: TextStyle(fontSize: 10, color: Colors.orange),
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(fontSize: 8, color: Colors.orange),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        );
      }

      return const SizedBox.shrink();
    }

    return const SizedBox(
      height: 50,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
