# AGENTS.md

## Project

Flutter cashier/POS app (`kasir_app`) backed by Firebase Auth + Cloud Firestore. Single Flutter app, no monorepo, no code generation, no assets, no CI workflows.

Entry point: `lib/main.dart` initializes Firebase, then runs `MyApp` with `initialRoute: /` (`SplashScreen`). The splash calls `AuthController.restoreSession()` and routes to the dashboard or login.

## Commands

```bash
flutter pub get
flutter run -d windows          # or -d chrome / an Android device
flutter analyze                 # keep at "No issues found!"
flutter test                    # 2 unit tests for currency + UserModel
flutter build apk --debug       # use when Android/Gradle changes are involved
```

There is no `build_runner`, codegen, formatter config, or deployment script. Firestore rules are deployed separately with `firebase deploy --only firestore:rules` (requires Firebase CLI login).

## Branches

- Active development is on `syawil` (current branch). Remote is `syawil66/kasir_mobile`.
- `main` is the GitHub default but its `lib/main.dart` is still the Flutter counter demo; feature code lives on `syawil`. Don't treat `main` as the source of truth.
- `catatan_sistem_kasir_mobile.md` is an audit of an older commit; its UI notes are partially stale now that inventory and dashboard use Firestore.

## Architecture

- Feature-first: `lib/features/{auth,dashboard,inventory,pos}/{controllers,models,views}`.
- Entry/routing: `lib/app/routes/app_routes.dart`; shared constants: `lib/app/constants`; helpers: `lib/shared/{utils,widgets}`.
- No state-management package. Controllers are plain classes instantiated inside widget state; screens are mostly one-file `StatefulWidget`s.
- `AuthController.currentUser` is a static, in-memory `UserModel?`, restored at startup from `FirebaseAuth.instance.currentUser` + `users/{uid}`. Role helpers: `AuthController.isAdmin`, `AuthController.isKasir`.

## RBAC (admin vs kasir)

- Roles come from `users/{uid}.role`; unknown/missing roles fall back to the kasir UI.
- `MainNavigationScreen` loads the session before building tabs and keeps tabs alive with `IndexedStack`.
  - Admin: Dashboard, Kasir, Stok; lands on Dashboard.
  - Kasir: Kasir, Stok, Akun (limited dashboard); lands on POS.
- `HomeScreen`: admin sees today's omzet, transaction count, low-stock count, and the 5 most recent transactions. Kasir sees only profile info, today's transaction count, an admin-only notice, and logout.
- Inventory: admin gets add (FAB) + edit/delete (product detail) + form access. Kasir gets a read-only list and a "Mode kasir" banner; `ProductFormScreen` renders an access-denied screen for non-admin.
- POS checkout/cart/discount is intentionally available to both roles.
- UI hiding is not security: `firestore.rules` is the actual enforcement layer.

## Firestore

- Project `kasir-32a6b`. `lib/firebase_options.dart` is FlutterFire-generated; Android `google-services.json` lives in `android/app/`.
- `firebase.json` maps `firestore.rules`; rules enforce:
  - `users/{uid}`: read owner or admin; write admin only.
  - `products/{id}`: read any signed-in user; create/delete admin; update admin, or any signed-in user changing only `stock` + `updatedAt` with `stock` an int `>= 0`.
  - `transactions/{id}`: read/create any signed-in user; update/delete admin.
- Collections:
  - `users/{uid}`: `username`, `name`, `role`
  - `products/{autoId}`: `name`, `category`, `price`, `stock`, `updatedAt`
  - `transactions/{autoId}`: `items[]`, `subtotal`, `discount`, `finalTotal`, `cashPaid`, `changeAmount`, `paymentMethod`, `cashierId`, `cashierName`, `createdAt`
- There is no UI or seed script for creating users/admin accounts; they must exist in Firestore before login works.
- Android `INTERNET` permission is now in `android/app/src/main/AndroidManifest.xml` (release builds need it).
- macOS `FirebaseOptions` still reuses the iOS appId (FlutterFire output); untested on macOS.

## Current gaps / traps

- POS is wired to Firestore through `PosController`: the product grid comes from `InventoryController`, cart/discount state lives in `PosController`, and `PaymentDialog` supports Tunai and QRIS. Checkout runs a Firestore transaction that decrements stock and writes to `transactions`, so the dashboard metrics update after a sale. Admin and kasir share the same POS flow.
- `AppRoutes.pos` and `AppRoutes.inventory` bypass the bottom-nav shell and its role ordering. Prefer navigating through `MainNavigationScreen`.
- `ProductModel.toMap()` embeds `FieldValue.serverTimestamp()`, so it is not a plain serializable map.
- Editing a product pre-fills price with `toStringAsFixed(0)`, so fractional prices are rounded in the form.
- The product update rule allows non-admin users to change only `stock` + `updatedAt`, and stock may only decrease (`<=` current value) while staying `>= 0`.
- Empty/unused files: `lib/features/pos/views/receipt_screen.dart`, `lib/shared/utils/date_formatter.dart`, `lib/shared/widgets/product_card.dart`.
- `AppColor`/`AppTextStyles` are blue-themed and barely used; screens hardcode the pastel pink/lavender palette per file. Match the per-screen palette when editing UI.
- `test/widget_test.dart` is now unit-test only; there is no widget/integration test coverage.

## Conventions

- UI copy and most identifiers are Indonesian (`currentUser`, `products`); class names are English. Keep user-facing messages in Indonesian.
- Low-stock means `stock <= 5` in `inventory_screen.dart`, `product_detail_screen.dart`, and `home_screen.dart`; update all three together.
- Currency formatting is split: `CurrencyFormatter.formatRupiah` and a local `formatPrice` regex duplicated in the inventory screens.
- Dashboard "today" starts at local midnight (`DateTime(now.year, now.month, now.day)`); transactions without `createdAt` are excluded from the query.
