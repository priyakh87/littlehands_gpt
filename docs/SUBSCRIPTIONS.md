# Subscriptions setup (RevenueCat)

LittleHands Premium is sold through the App Store and Google Play, with
[RevenueCat](https://www.revenuecat.com) checking who is subscribed.
The app code is ready; these steps connect it to your store accounts.

## What is free and what is Premium

Defined in `lib/services/access_policy.dart`:

- **Free:** Level 1 of every activity, the first story, Animal Sounds.
- **Premium:** every other level and story.

Children never see a purchase prompt: Premium items show
"👑 Premium · ask a grown-up", and the paywall is only reachable after the
parent PIN (Apple Kids Category requirement).

## 1. Create the products in the stores

**App Store Connect** → your app → Monetization → Subscriptions:

1. Create a subscription group, e.g. `LittleHands Premium`.
2. Add the subscriptions, e.g. `littlehands_premium_monthly` and
   `littlehands_premium_yearly`, set prices, and add a free-trial
   introductory offer if you want one.
3. Fill in the localized name/description and review screenshot.
4. Agreements, Tax and Banking must be complete (Paid Apps agreement).

**Google Play Console** → your app → Monetize → Products → Subscriptions:

1. Create the same subscriptions with base plans (monthly / yearly) and,
   optionally, a free-trial offer.
2. Google Play needs an app uploaded to a testing track before products work.

## 2. Set up RevenueCat

1. Create a project and add an **iOS app** and an **Android app**
   (bundle ID / package name of LittleHands).
2. Connect the stores: App Store Connect API key / in-app purchase key for
   iOS, and a Google Play service account for Android (RevenueCat's
   dashboard walks you through both).
3. **Products:** import the store products.
4. **Entitlement:** create one called exactly `premium` and attach all
   Premium products to it.
5. **Offering:** make the `default` offering current, with packages
   `$rc_monthly` and `$rc_annual` (the yearly one is preselected and shown
   as "Best value" in the app).
6. Copy the **public SDK keys** (`appl_...` and `goog_...`) from
   Project settings → API keys. These public keys are meant to ship inside
   the app; never put a RevenueCat *secret* key in the app.

## 3. Run or build the app with the keys

```bash
flutter run \
  --dart-define=REVENUECAT_IOS_KEY=appl_xxx \
  --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx \
  --dart-define=TERMS_URL=https://your-site/terms \
  --dart-define=PRIVACY_URL=https://your-site/privacy
```

Use the same `--dart-define` flags for `flutter build ipa` /
`flutter build appbundle`. Without the RevenueCat keys the app still runs:
only free content is available and the paywall says subscriptions are not
available. In **debug builds only**, the paywall then shows a
"Developer: pretend Premium" switch for testing.

## 4. Test purchases

- **iOS:** sign in with a Sandbox tester (Settings → App Store → Sandbox
  Account) or use a StoreKit configuration file in Xcode.
- **Android:** add license testers in Play Console and install from the
  internal testing track.
- Check: subscribe, cancel, restore on a second device, and that Premium
  levels unlock without restarting.

## 5. Before submitting

- Terms of Use and Privacy Policy URLs set (Apple rejects paywalls without
  them).
- App Store privacy label and your privacy policy mention that purchases
  are processed by Apple/Google and RevenueCat (anonymous ID, purchase
  history; no name, email or ads).
- Kids Category: confirm against Apple's current guidelines that the
  paywall and external links are behind the parental gate (they are).
