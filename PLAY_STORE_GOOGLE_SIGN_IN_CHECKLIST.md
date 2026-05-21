# Play Store Google Sign-In Checklist

Google Sign-In can work in local release builds and fail only for Play Store installs when Firebase does not know the Play App Signing certificate fingerprints. Play re-signs uploaded builds, so the upload key and the installed Play Store key are different certificates.

## Android app

- Firebase project: `ecomapp-22701`
- Android package name: `com.bazariyo.avr`
- Android Firebase app id in `google-services.json`: `1:14234085234:android:3b0c54b9a3ae011ddd1feb`
- Local `DefaultFirebaseOptions.android.appId`: `1:14234085234:android:3b0c54b9a3ae011ddd1feb`

## Local upload certificate fingerprints

These were read from `upload_certificate.pem`:

- SHA-1: `17:02:5E:23:CE:94:46:2A:16:30:85:F8:C5:74:5D:BD:F8:EA:D1:9F`
- SHA-256: `BF:7B:24:BB:1F:64:7B:4B:79:44:AE:C0:80:A1:96:76:DE:78:33:79:A1:FC:6D:92:F2:ED:DC:F6:B3:97:B5:8F`

Add both to Firebase if they are not already present.

## Firebase fingerprints currently reported

These are the fingerprints currently shown in Firebase:

- SHA-1: `95:2D:20:F8:3E:D7:ED:5A:F1:61:C2:90:1C:93:FD:F0:63:DE:1A:B0`
- SHA-1: `17:02:5E:23:CE:94:46:2A:16:30:85:F8:C5:74:5D:BD:F8:EA:D1:9F`
- SHA-256: `F2:31:25:58:71:B2:B4:47:73:AC:3E:2C:68:10:12:D1:0A:DF:1F:C0:C1:3A:B1:DE:CC:59:E3:CE:4E:99:7F:DA`
- SHA-256: `BF:7B:24:BB:1F:64:7B:4B:79:44:AE:C0:80:A1:96:76:DE:78:33:79:A1:FC:6D:92:F2:ED:DC:F6:B3:97:B5:8F`

`17:02...` and `BF:7B...` match the local upload certificate. `95:2D...` and `F2:31...` should be the Play App Signing certificate pair; confirm they match **Play Console > Setup > App integrity > App signing key certificate**.

## Required Play Console fingerprints

1. Open Play Console.
2. Select the app.
3. Go to **Setup > App integrity > App signing**.
4. Copy both fingerprints from **App signing key certificate**:
   - SHA-1 certificate fingerprint
   - SHA-256 certificate fingerprint
5. In Firebase Console, open **Project settings > General > Your apps > Android app `com.bazariyo.avr`**.
6. Add both Play App Signing fingerprints.
7. Download the new `google-services.json`.
8. Replace `android/app/google-services.json`.
9. Rebuild and upload a new release to Play.

After the SHA fingerprints are registered, the downloaded `google-services.json` should include Android OAuth clients with `"client_type": 1` for `com.bazariyo.avr`, in addition to the web client with `"client_type": 3`.

## Verification

Run this after replacing `google-services.json`:

```powershell
Select-String -Path android\app\google-services.json -Pattern '"package_name": "com.bazariyo.avr"','"client_type": 1','"certificate_hash"'
```

The file should show the package name and at least one Android OAuth client entry with certificate hashes.
