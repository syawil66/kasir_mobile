# AGENTS.md

## Project

Flutter cashier/POS app (`kasir_app`) backed by Firebase Auth + Cloud Firestore. Single Flutter app, no monorepo, no code generation, no assets, no CI workflows.

Entry point: `lib/main.dart` initializes Firebase, then runs `MyApp` with `initialRoute: /` (`SplashScreen`). The splash calls `AuthController.restoreSession()` and routes to the dashboard or login.

## Commands

```bash
flutter pub get
flutter run -d windows          # or -d chrome / an Android device
flutter analyze                 # keep at "No issues found!"
flutter test                    # unit tests: currency, model, diskon, laporan, tanggal
flutter build apk --debug       # use when Android/Gradle changes are involved

# Aturan Firestore (butuh Firebase CLI + Java untuk emulator)
firebase emulators:exec --only firestore --project demo-kasir "node tool/firestore_rules_test.js"
firebase deploy --only firestore        # rules + indexes
```

There is no `build_runner`, codegen, formatter config, or deployment script. Firestore rules and indexes are deployed together with `firebase deploy --only firestore` (requires Firebase CLI login).

## Branches

- Active development is on `syawil` (current branch). Remote is `syawil66/kasir_mobile`.
- `main` is the GitHub default but its `lib/main.dart` is still the Flutter counter demo; feature code lives on `syawil`. Don't treat `main` as the source of truth.
- `catatan_sistem_kasir_mobile.md` is an audit of an older commit; its UI notes are partially stale now that inventory and dashboard use Firestore.

## Architecture

- Feature-first: `lib/features/{auth,dashboard,inventory,pos}/{controllers,models,views}`. `pos` juga memuat `TransactionController` (riwayat, laporan, void) dan `auth` memuat `UserController` (kelola role/profil).
- Entry/routing: `lib/app/routes/app_routes.dart`; shared constants: `lib/app/constants`; helpers: `lib/shared/{utils,widgets}`.
- No state-management package. Controllers are plain classes instantiated inside widget state; screens are mostly one-file `StatefulWidget`s.
- `AuthController.currentUser` is a static, in-memory `UserModel?`, restored at startup from `FirebaseAuth.instance.currentUser` + `users/{uid}`. Role helpers: `AuthController.isAdmin`, `AuthController.isKasir`.

## RBAC (admin vs kasir)

- Roles come from `users/{uid}.role`; unknown/missing roles fall back to the kasir UI.
- `MainNavigationScreen` loads the session before building tabs and keeps tabs alive with `IndexedStack`. On resume it re-reads `users/{uid}` via `AuthController.refreshProfile()` so role changes by an admin take effect.
  - Admin: Dashboard, Kasir, Riwayat, Stok; lands on Dashboard.
  - Kasir: Kasir, Riwayat, Stok, Akun (limited dashboard); lands on POS.
- `HomeScreen`: admin sees today's omzet, transaction count, total products, low-stock count plus the low-stock product list (max 5), and the 5 most recent transactions. Kasir sees only profile info, today's transaction count, an admin-only notice, and logout. Admin cards and the low-stock list share one `products` stream; kasir gets an empty stream so no product listener is opened.
- Inventory: admin gets add (FAB) + edit/delete (delete icon on each list row and on the product detail screen, both behind an `AlertDialog` confirmation) + form access. Kasir gets a read-only list and a "Mode kasir" banner; `ProductFormScreen` renders an access-denied screen for non-admin.
- POS checkout/cart/discount is intentionally available to both roles.
- UI hiding is not security: `firestore.rules` is the actual enforcement layer.

## Firestore

- Project `kasir-32a6b`. `lib/firebase_options.dart` is FlutterFire-generated; Android `google-services.json` lives in `android/app/`.
- `firebase.json` maps `firestore.rules` and `firestore.indexes.json`. Rules enforce:
  - `users/{uid}`: read owner or admin; create/update/delete admin only, validated by `isValidUser()` (`name` wajib, `role` hanya `admin`/`kasir`, `username` <= 50). Admin tidak boleh menurunkan role atau menghapus akunnya sendiri (anti-lockout).
  - `products/{id}`: read any signed-in user; create admin + `isValidProduct()` (nama 1..100, `price` > 0, `stock` int 0..1jt, `updatedAt == request.time`) + closed schema; update admin (validated) or a signed-in user changing only `stock` + `updatedAt` + `lastCheckoutId`, with `stock` an int `>= 0` that decreases by exactly the delta recorded in the referenced transaction; delete admin.
  - `transactions/{id}`: read admin or the owning cashier (`resource == null` is allowed so the pre-checkout idempotency read of a not-yet-existing nota does not fail for kasir; existing notas stay owner/admin only); create any signed-in user that passes `isValidTransactionCreate()` (closed schema via `keys().hasOnly()`, max 50 items, cashier identity, cash-only, discount mode/limit/consistency, totals, change, `createdAt == request.time`, `stockDeltas` matching `items`); update only via `isValidVoidUpdate()` (admin, sekali saja, hanya field `voided`/`voidedAt`/`voidedBy`); **delete is disabled** (`allow delete: if false`) karena menghapus nota tidak mengembalikan stok.
- `firestore.indexes.json` holds the composite index for the cashier summary query (`transactions`: `cashierId` ASC + `createdAt` ASC). Without it, `getTodaySummary()` for kasir fails with a "requires an index" error. `tool/firestore_rules_test.js` exercises the rules against the emulator (42 checks); run it before deploying rules.
- Collections:
  - `users/{uid}`: `username`, `name`, `role`
  - `products/{autoId}`: `name`, `category`, `price`, `stock`, `updatedAt`, `lastCheckoutId`
  - `transactions/{autoId}`: `items[]`, `stockDeltas{productId: qty}`, `subtotal`, `discount`, `discountMode`, `discountInput`, `finalTotal`, `cashPaid`, `changeAmount`, `paymentMethod`, `cashierId`, `cashierName`, `createdAt`, and after a void: `voided`, `voidedAt`, `voidedBy`
- Akun Firebase Authentication (email/password) tetap harus dibuat lewat Firebase Console atau Admin SDK; aplikasi hanya mengelola dokumen `users/{uid}` lewat `UserManagementScreen` (`/users`, khusus admin) — nama, username, role. Login mandiri/pendaftaran tidak disediakan.
- Password reset tersedia lewat tautan "Lupa password?" di `LoginScreen` → `AuthController.sendPasswordReset()` (Firebase Auth mengirim email reset).
- Android `INTERNET` permission is now in `android/app/src/main/AndroidManifest.xml` (release builds need it).
- macOS `FirebaseOptions` still reuses the iOS appId (FlutterFire output); untested on macOS.

## Current gaps / traps

- POS is wired to Firestore through `PosController`: the product grid comes from `InventoryController`, cart/discount state lives in `PosController`, and `PaymentDialog` is cash-only (`paymentMethod` is always `'Tunai'`; QRIS was removed). Discounts support nominal Rupiah and percentage modes. Checkout runs a Firestore transaction that re-reads each product, rejects price drift and insufficient stock, decrements stock, and writes to `transactions`, so the dashboard metrics update after a sale. Admin and kasir share the same POS flow.
- Checkout is idempotent per cart via `CheckoutKey` (`lib/features/pos/controllers/pos_controller.dart`): the transaction ID is reused until the cart or discount changes. If a retry finds that ID already committed, it only succeeds when the stored `cashierId` and `finalTotal` match. An **ambiguous** failure (network/timeout, commit status unknown) marks the key `unresolved`, so cart edits no longer regenerate the ID — a retry either replays idempotently (same total) or fails with `_DuplicateCheckoutException`, which clears the cart to prevent a double note. Validation failures (`_CheckoutValidationException`) never mark the key unresolved, so a fixed cart gets a fresh ID.
- Every product stock decrement must carry `lastCheckoutId` pointing at a transaction created in the same commit, and that transaction's `stockDeltas` must match the decrement exactly. Rules use `getAfter()`, so stock can no longer be reduced without a transaction.
- Discount percentages must be written as `(subtotal * input) / 100.0` in rules: Firestore integer division makes `10 / 100` equal `0`.
- Nota dibatalkan (void) lewat `TransactionController.voidTransaction()` dari tab **Riwayat** (admin): stok dikembalikan per item, lalu `voided`/`voidedAt`/`voidedBy` di-set. Void kedua ditolak di dalam Firestore transaction dan oleh rules. `SalesReport`, `getTodaySummary()`, dan `topProducts()` mengabaikan nota void.
- Riwayat transaksi memakai `TransactionController.getTransactions()` dengan filter `start`/`end` (end eksklusif) dan `limit` 100. Query kasir (`cashierId` + `createdAt`) memakai composite index; filter tambahan `createdAt` untuk admin adalah single-field index bawaan.
- `TransactionHistoryScreen` menghitung laporan dari snapshot yang sudah dimuat (maks 100 nota). Untuk toko dengan > 100 nota per rentang, angka laporan hanya mencakup 100 nota terbaru.
- `TransactionController.voidTransaction()` mengembalikan stok berdasarkan `items[].quantity` dan mengembalikan `VoidResult`. Jika dokumen produk sudah dihapus admin, item tersebut dilewati dan namanya dilaporkan di `skippedProducts` (ditampilkan sebagai peringatan di UI), karena stok produk yang sudah tidak ada tidak punya tempat untuk dikembalikan.
- Struk (`ReceiptScreen`) ditampilkan otomatis setelah checkout lewat `PosController.lastCheckout`, dan bisa dibuka ulang dari tab Riwayat atau daftar "Aktivitas Terakhir" di dashboard.
- `shared/utils/date_formatter.dart` menyediakan format tanggal Indonesia (`formatDate`, `formatDateTime`, `formatTime`, `startOfDay`).
- `AppRoutes.pos` dan `AppRoutes.inventory` bypass the bottom-nav shell and its role ordering. Prefer navigating through `MainNavigationScreen`.
- `ProductModel.toMap()` embeds `FieldValue.serverTimestamp()`, so it is not a plain serializable map.
- Editing a product pre-fills price with `toStringAsFixed(0)`, so fractional prices are rounded in the form.
- The product update rule allows non-admin users to change only `stock` + `updatedAt` + `lastCheckoutId`, and stock may only decrease while staying `>= 0` and matching the transaction's `stockDeltas`.
- Discount amounts are rounded to whole rupiah then clamped to the subtotal (`discountAmount`), so fractional legacy prices cannot push the discount above the subtotal.
- `getTodaySummary()` sekarang membungkus query dalam `StreamController` dan menjadwalkan `Timer` ke tengah malam berikutnya, lalu berlangganan ulang dengan `startOfDay` baru. Sesi yang dibiarkan terbuka melewati tengah malam otomatis menghitung hari yang benar.
- Empty/unused files: `lib/shared/widgets/product_card.dart` (POS memakai `lib/features/pos/views/widgets/product_card.dart`).
- `AppColor`/`AppTextStyles` are blue-themed and barely used; screens hardcode the pastel pink/lavender palette per file. Match the per-screen palette when editing UI.
- `test/widget_test.dart` is unit-test only; `test/transaction_report_test.dart` covers `SalesReport`, `topProducts`, `TransactionModel.voided`, `DateFormatter`, and the receipt widget; `test/checkout_key_test.dart` covers `CheckoutKey` (idempotency) and `VoidResult`. There is no end-to-end/widget test of the checkout flow against Firestore.
- Belum bisa dikerjakan dari klien (butuh Admin SDK / Cloud Functions): membuat akun Firebase Auth dari dalam aplikasi, dan verifikasi harga per item di rules (rules tidak bisa melakukan loop pada list). Harga tetap diverifikasi di Firestore transaction pada `PosController`.

## Conventions

- UI copy and most identifiers are Indonesian (`currentUser`, `products`); class names are English. Keep user-facing messages in Indonesian.
- Low-stock means `stock <= 5` in `inventory_screen.dart`, `product_detail_screen.dart`, and `home_screen.dart` (twice: count card and list); update all of them together.
- Product categories come from `lib/app/constants/product_categories.dart` (`Sembako`, `Minuman`, `Snack`, `Lainnya`). `ProductCategories.withExisting()` appends a legacy category so older products stay editable; the POS category chips are still derived from live product data.
- Currency formatting is split: `CurrencyFormatter.formatRupiah` and a local `formatPrice` regex duplicated in the inventory screens.
- Dashboard "today" starts at local midnight (`DateTime(now.year, now.month, now.day)`); transactions without `createdAt` are excluded from the query.
