Place your splash image and icon files here.

Required files:

- splash_logo.png — The splash logo used by flutter_native_splash. Recommended source size: 1200x1200 or 1024x1024 PNG.

Instructions:

1. Add your splash image at: assets/images/splash_logo.png
2. Generate Android mipmap folders (mipmap-mdpi, mipmap-hdpi, ...), then copy them into android/app/src/main/res/ to replace the default Flutter launcher icons.

After you add `splash_logo.png`, run:

    dart run flutter_native_splash:create

Notes:
- Do a full rebuild (not hot reload) to see native splash and icon changes:

    flutter clean; flutter run
