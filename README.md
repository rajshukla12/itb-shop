# iTechBuilders Shop — Flutter App (Android + iOS)

Ek hi code se Android aur iOS dono ke liye shopping app. Aapki existing
itechbuilders.com site ke **mobile JSON API** se connect hoti hai.

## Features
- Home: banner slider, categories, featured products
- Categories → sub-categories → products (infinite scroll, sort by price/new)
- Search (live)
- Product detail: image gallery, price/MRP/discount, description, related
- Cart (device par save, offline bhi rehta hai)
- Login / Register (aapke `manage_signup` customers)
- Checkout → Cash on Delivery order (admin `app_orders` table me aata hai)
- My Orders, Call/WhatsApp to order

---

## STEP 1 — Server par API file (ek hi file)
`api/Api.php` ko site me daalo:
```
application/controllers/Api.php
```
(zip me `server/Api.php` diya hai — isko wahan copy karo.)

Test karo browser me:
```
https://www.itechbuilders.com/index.php/api/ping
```
`{"status":"success",...}` aaye to API ready. (Pretty URL on hai to `/api/ping` bhi chalega.)
Pehli call par app ke liye do table (`app_orders`, `app_order_items`) apne aap ban jaati hain — aur kuch nahi badalta.

## STEP 2 — App ka base URL set karo
`lib/config.dart` me:
```dart
static const String apiBase = 'https://www.itechbuilders.com/index.php/api';
static const String supportPhone = '+9199XXXXXXXX'; // Call/WhatsApp number
```
(Agar site me index.php hidden hai to `.../api` use kar sakte ho.)

## STEP 3 — App build karo
Flutter install hona chahiye (https://docs.flutter.dev/get-started/install). Phir:

```bash
# is folder me android/ios platform files generate karo
flutter create --org com.itechbuilders --project-name itb_shop .

# (create ne pubspec/lib overwrite kar diya ho to zip wali pubspec.yaml aur lib/ wapas daal do)

flutter pub get
flutter run          # phone/emulator par chala kar dekho
```

### Android APK (install/share ke liye)
```bash
flutter build apk --release
# file: build/app/outputs/flutter-apk/app-release.apk
```
Play Store ke liye: `flutter build appbundle`.

### iOS (Mac + Xcode zaroori)
```bash
flutter build ios --release
# phir Xcode se signing + App Store / TestFlight
```

## Zaroori settings (release ke liye)
- **Android internet permission** — `android/app/src/main/AndroidManifest.xml` me
  `<manifest>` ke andar (agar na ho):
  ```xml
  <uses-permission android:name="android.permission.INTERNET"/>
  ```
- **App ka naam** — Android: `AndroidManifest.xml` me `android:label="iTechBuilders"`.
  iOS: `ios/Runner/Info.plist` me `CFBundleDisplayName`.
- **App icon** — `flutter_launcher_icons` package se laga sakte ho (baad me).
- API HTTPS par hai isliye iOS ATS ki extra setting nahi chahiye.

## Notes
- Cart app me local hai; checkout par order server ko jaata hai (COD).
- Payment gateway (Razorpay/PayU) abhi nahi hai — order "confirmation call" flow par hai.
  Chahein to baad me gateway add kar denge.
- Categories/products wahi dikhte hain jo site par **active** (status=1) hain.

---

# APK kaise banwayein (bina kuch install kiye — cloud me free)

Is environment me APK compile nahi ho sakta (Google/Android servers block hain),
isliye ye project me **auto-build** laga diya hai — GitHub par daalte hi APK ban jaata hai.

## Tarika A — GitHub Actions (recommended, free)
1. https://github.com par free account banao → **New repository** (private bhi chalega).
2. Is folder (`itb_shop`) ko us repo me daal do:
   - Git aata hai to:
     ```bash
     cd itb_shop
     git init && git add . && git commit -m "itb shop app"
     git branch -M main
     git remote add origin https://github.com/<tumhara-user>/<repo>.git
     git push -u origin main
     ```
   - Ya GitHub website par "uploading an existing file" se saari files drag-drop kar do.
3. Repo me upar **Actions** tab kholo → "Build Android APK" run apne aap chalega
   (~5–8 min). Green tick aane par us run ko kholo →
   niche **Artifacts** me **app-release-apk** download karo → andar `app-release.apk`.
4. Wo APK Android phone me install kar lo (Settings me "unknown sources" allow karna pad sakta hai).

> Base URL yaad se `lib/config.dart` me sahi kar lena push karne se pehle.

## Tarika B — Codemagic (bina YAML, click-based)
1. https://codemagic.io par GitHub se login → apni repo select karo.
2. Flutter project detect ho jayega → **Start build** (Android APK).
3. Build ke baad APK download link mil jayega.

## Tarika C — Apne computer par (agar Flutter install karna ho)
```bash
flutter create --platforms=android,ios --org com.itechbuilders --project-name itb_shop .
flutter pub get
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

iOS ki .ipa sirf Mac + Xcode par banti hai (Apple ka rule).
