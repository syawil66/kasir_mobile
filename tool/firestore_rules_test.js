#!/usr/bin/env node
// Smoke test firestore.rules terhadap Firebase Emulator.
//
// Jalankan dari root repo:
//   firebase emulators:exec --only firestore --project demo-kasir "node tool/firestore_rules_test.js"
//
// Tidak butuh dependency npm: memakai REST API emulator + JWT unsigned.

const PROJECT = process.env.GCLOUD_PROJECT || 'demo-kasir';
const HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
const BASE = `http://${HOST}/v1/projects/${PROJECT}/databases/(default)/documents`;
const OWNER = 'owner';

let failures = 0;

function b64url(value) {
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}

function tokenFor(uid) {
  const now = Math.floor(Date.now() / 1000);
  return (
    `${b64url({ alg: 'none', typ: 'JWT' })}.` +
    `${b64url({ sub: uid, user_id: uid, aud: PROJECT, iat: now, exp: now + 3600 })}.`
  );
}

function value(input) {
  if (typeof input === 'string') return { stringValue: input };
  if (typeof input === 'boolean') return { booleanValue: input };
  if (Number.isInteger(input)) return { integerValue: String(input) };
  if (typeof input === 'number') return { doubleValue: input };
  if (Array.isArray(input)) {
    return { arrayValue: { values: input.map(value) } };
  }
  return { mapValue: { fields: fields(input) } };
}

function fields(map) {
  const out = {};
  for (const [key, item] of Object.entries(map)) {
    if (item === undefined) continue;
    out[key] = value(item);
  }
  return out;
}

function docName(path) {
  return `projects/${PROJECT}/databases/(default)/documents/${path}`;
}

function updateWrite(path, data, options = {}) {
  const write = { update: { name: docName(path), fields: fields(data) } };
  const mask = [...Object.keys(data), ...(options.transforms || [])];
  if (mask.length > 0) write.updateMask = { fieldPaths: mask };
  if (options.transforms && options.transforms.length > 0) {
    write.updateTransforms = options.transforms.map((fieldPath) => ({
      fieldPath,
      setToServerValue: 'REQUEST_TIME',
    }));
  }
  if (options.exists !== undefined) {
    write.currentDocument = { exists: options.exists };
  }
  return write;
}

function deleteWrite(path) {
  return { delete: docName(path) };
}

async function commit(writes, token) {
  const response = await fetch(`${BASE}:commit`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ writes }),
  });
  if (response.status !== 200) {
    await response.text();
  }
  return response.status;
}

async function getDoc(path, token) {
  const headers = token ? { Authorization: `Bearer ${token}` } : {};
  const response = await fetch(`${BASE}/${path}`, { headers });
  await response.text();
  return response.status;
}

// Query/list (bukan get dokumen tunggal), dipakai untuk memastikan aturan baca
// tidak terbuka hanya karena guard `resource == null` pada dokumen tunggal.
async function runQuery(structuredQuery, token) {
  const response = await fetch(`${BASE}:runQuery`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ structuredQuery }),
  });
  await response.text();
  return response.status;
}

function check(name, actual, expected) {
  const ok = actual === expected;
  if (!ok) failures += 1;
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name} (${actual}, expected ${expected})`);
}

const KASIR1 = tokenFor('kasir1');
const KASIR2 = tokenFor('kasir2');
const ADMIN = tokenFor('admin1');

function transactionData(overrides = {}) {
  return {
    items: [
      {
        productId: 'p1',
        productName: 'Kopi Susu',
        priceAtPurchase: 10000,
        quantity: 2,
        totalPrice: 20000,
      },
    ],
    stockDeltas: { p1: 2 },
    subtotal: 20000,
    discount: 0,
    discountMode: 'nominal',
    discountInput: 0,
    finalTotal: 20000,
    cashPaid: 50000,
    changeAmount: 30000,
    paymentMethod: 'Tunai',
    cashierId: 'kasir1',
    cashierName: 'Kasir Satu',
    ...overrides,
  };
}

function transactionWrite(id, overrides = {}) {
  return updateWrite(`transactions/${id}`, transactionData(overrides), {
    transforms: ['createdAt'],
  });
}

function stockWrite(productId, stock, checkoutId, exists = true) {
  const data = { stock };
  if (checkoutId !== null) data.lastCheckoutId = checkoutId;
  return updateWrite(`products/${productId}`, data, {
    transforms: ['updatedAt'],
    exists,
  });
}

async function seed() {
  const products = {};
  for (const id of ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8']) {
    products[id] = updateWrite(`products/${id}`, {
      name: `Produk ${id}`,
      category: 'Minuman',
      price: 10000,
      stock: 10,
    });
  }

  const status = await commit(
    [
      updateWrite('users/admin1', { username: 'admin', name: 'Admin', role: 'admin' }),
      updateWrite('users/kasir1', {
        username: 'kasir1',
        name: 'Kasir Satu',
        role: 'kasir',
      }),
      updateWrite('users/kasir2', {
        username: 'kasir2',
        name: 'Kasir Dua',
        role: 'kasir',
      }),
      ...Object.values(products),
    ],
    OWNER,
  );

  if (status !== 200) {
    throw new Error(`Gagal seed data emulator (status ${status})`);
  }
}

async function main() {
  await seed();

  // --- Autentikasi dasar -------------------------------------------------
  check('anonymous read products ditolak', await getDoc('products/p1', null), 403);
  check('kasir read products diizinkan', await getDoc('products/p1', KASIR1), 200);
  check('kasir read profil sendiri', await getDoc('users/kasir1', KASIR1), 200);
  check('kasir read profil lain ditolak', await getDoc('users/kasir2', KASIR1), 403);
  check('admin read profil kasir', await getDoc('users/kasir1', ADMIN), 200);

  // --- Checkout atomik yang sah -----------------------------------------
  check(
    'checkout valid (transaksi + stok dalam satu commit)',
    await commit([transactionWrite('tx-ok'), stockWrite('p1', 8, 'tx-ok')], KASIR1),
    200,
  );

  check(
    'checkout diskon persen 10% valid',
    await commit(
      [
        transactionWrite('tx-percent', {
          items: [
            {
              productId: 'p2',
              productName: 'Produk p2',
              priceAtPurchase: 10000,
              quantity: 2,
              totalPrice: 20000,
            },
          ],
          stockDeltas: { p2: 2 },
          subtotal: 20000,
          discount: 2000,
          discountMode: 'percentage',
          discountInput: 10,
          finalTotal: 18000,
          cashPaid: 20000,
          changeAmount: 2000,
        }),
        stockWrite('p2', 8, 'tx-percent'),
      ],
      KASIR1,
    ),
    200,
  );

  check(
    'checkout diskon 100% dengan bayar 0 valid',
    await commit(
      [
        transactionWrite('tx-free', {
          items: [
            {
              productId: 'p3',
              productName: 'Produk p3',
              priceAtPurchase: 10000,
              quantity: 2,
              totalPrice: 20000,
            },
          ],
          stockDeltas: { p3: 2 },
          discount: 20000,
          discountInput: 20000,
          finalTotal: 0,
          cashPaid: 0,
          changeAmount: 0,
        }),
        stockWrite('p3', 8, 'tx-free'),
      ],
      KASIR1,
    ),
    200,
  );

  // --- Pengurangan stok tanpa transaksi ---------------------------------
  check(
    'stok turun tanpa transaksi ditolak',
    await commit([stockWrite('p4', 8, 'tx-missing')], KASIR1),
    403,
  );

  check(
    'stok turun tanpa lastCheckoutId ditolak',
    await commit([stockWrite('p4', 8, null)], KASIR1),
    403,
  );

  check(
    'stok turun memakai transaksi kasir lain ditolak',
    await commit([stockWrite('p4', 8, 'tx-ok')], KASIR2),
    403,
  );

  check(
    'delta stok tidak cocok dengan transaksi ditolak',
    await commit([transactionWrite('tx-mismatch'), stockWrite('p5', 7, 'tx-mismatch')], KASIR1),
    403,
  );

  check(
    'stok naik lewat jalur kasir ditolak',
    await commit(
      [transactionWrite('tx-up'), stockWrite('p5', 12, 'tx-up')],
      KASIR1,
    ),
    403,
  );

  // --- Validasi nominal transaksi ---------------------------------------
  check(
    'finalTotal tidak konsisten ditolak',
    await commit([transactionWrite('tx-bad-total', { finalTotal: 19900 })], KASIR1),
    403,
  );

  check(
    'discountInput persen di atas 100 ditolak',
    await commit(
      [
        transactionWrite('tx-bad-percent', {
          discount: 20000,
          discountMode: 'percentage',
          discountInput: 150,
          finalTotal: 0,
          cashPaid: 0,
          changeAmount: 0,
        }),
      ],
      KASIR1,
    ),
    403,
  );

  check(
    'discount tidak konsisten dengan discountInput ditolak',
    await commit(
      [
        transactionWrite('tx-bad-discount', {
          discount: 5000,
          discountMode: 'percentage',
          discountInput: 10,
          finalTotal: 15000,
          cashPaid: 20000,
          changeAmount: 5000,
        }),
      ],
      KASIR1,
    ),
    403,
  );

  check(
    'cashierName kosong ditolak',
    await commit([transactionWrite('tx-no-name', { cashierName: '' })], KASIR1),
    403,
  );

  check(
    'transaksi atas nama kasir lain ditolak',
    await commit([transactionWrite('tx-other', { cashierId: 'kasir2' })], KASIR1),
    403,
  );

  check(
    'kembalian tidak konsisten ditolak',
    await commit([transactionWrite('tx-bad-change', { changeAmount: 100 })], KASIR1),
    403,
  );

  // --- Hak baca transaksi ------------------------------------------------
  check('kasir baca transaksi sendiri', await getDoc('transactions/tx-ok', KASIR1), 200);
  check('kasir lain baca transaksi ditolak', await getDoc('transactions/tx-ok', KASIR2), 403);
  check('admin baca transaksi kasir', await getDoc('transactions/tx-ok', ADMIN), 200);

  // Cek idempotency di PosController membaca dokumen transaksi yang BELUM ADA
  // sebelum checkout. Dokumen tidak ada berarti `resource == null`, jadi aturan
  // baca tidak boleh langsung menyentuh `resource.data`.
  check(
    'kasir baca transaksi yang belum ada (cek idempotency) diizinkan',
    await getDoc('transactions/tx-belum-ada', KASIR1),
    404,
  );
  check(
    'admin baca transaksi yang belum ada diizinkan',
    await getDoc('transactions/tx-belum-ada', ADMIN),
    404,
  );
  check(
    'kasir list semua transaksi ditolak',
    await runQuery({ from: [{ collectionId: 'transactions' }] }, KASIR1),
    403,
  );
  check(
    'kasir list transaksi miliknya sendiri diizinkan',
    await runQuery(
      {
        from: [{ collectionId: 'transactions' }],
        where: {
          fieldFilter: {
            field: { fieldPath: 'cashierId' },
            op: 'EQUAL',
            value: { stringValue: 'kasir1' },
          },
        },
      },
      KASIR1,
    ),
    200,
  );

  // --- Jalur admin -------------------------------------------------------
  check(
    'admin bebas update produk',
    await commit(
      [updateWrite('products/p6', { stock: 25 }, { transforms: ['updatedAt'], exists: true })],
      ADMIN,
    ),
    200,
  );

  // --- Validasi skema produk --------------------------------------------
  check(
    'admin buat produk valid',
    await commit(
      [
        updateWrite(
          'products/p9',
          { name: 'Produk Baru', category: 'Snack', price: 5000, stock: 3 },
          { transforms: ['updatedAt'], exists: false },
        ),
      ],
      ADMIN,
    ),
    200,
  );

  check(
    'admin buat produk nama kosong ditolak',
    await commit(
      [
        updateWrite(
          'products/p10',
          { name: '', category: 'Snack', price: 5000, stock: 3 },
          { transforms: ['updatedAt'], exists: false },
        ),
      ],
      ADMIN,
    ),
    403,
  );

  check(
    'admin buat produk harga negatif ditolak',
    await commit(
      [
        updateWrite(
          'products/p10',
          { name: 'Produk Rusak', category: 'Snack', price: -1, stock: 3 },
          { transforms: ['updatedAt'], exists: false },
        ),
      ],
      ADMIN,
    ),
    403,
  );

  check(
    'kasir buat produk ditolak',
    await commit(
      [
        updateWrite(
          'products/p10',
          { name: 'Produk Kasir', category: 'Snack', price: 5000, stock: 3 },
          { transforms: ['updatedAt'], exists: false },
        ),
      ],
      KASIR1,
    ),
    403,
  );

  check(
    'kasir ubah harga produk ditolak',
    await commit(
      [updateWrite('products/p1', { price: 1 }, { transforms: ['updatedAt'], exists: true })],
      KASIR1,
    ),
    403,
  );

  check(
    'admin stok negatif ditolak',
    await commit(
      [updateWrite('products/p7', { stock: -1 }, { transforms: ['updatedAt'], exists: true })],
      ADMIN,
    ),
    403,
  );

  // --- Validasi koleksi pengguna ----------------------------------------
  check(
    'admin ubah role kasir jadi admin',
    await commit([updateWrite('users/kasir2', { role: 'admin' })], ADMIN),
    200,
  );

  check(
    'role tidak dikenal ditolak',
    await commit([updateWrite('users/kasir2', { role: 'owner' })], ADMIN),
    403,
  );

  check(
    'kasir ubah role sendiri ditolak',
    await commit([updateWrite('users/kasir1', { role: 'admin' })], KASIR1),
    403,
  );

  check(
    'admin turunkan role sendiri ditolak',
    await commit([updateWrite('users/admin1', { role: 'kasir' })], ADMIN),
    403,
  );

  // --- Pembatalan nota (void) -------------------------------------------
  check(
    'admin batalkan nota',
    await commit(
      [
        updateWrite(
          'transactions/tx-ok',
          { voided: true, voidedBy: 'admin1' },
          { transforms: ['voidedAt'], exists: true },
        ),
      ],
      ADMIN,
    ),
    200,
  );

  check(
    'pembatalan kedua ditolak',
    await commit(
      [
        updateWrite(
          'transactions/tx-ok',
          { voided: true, voidedBy: 'admin1' },
          { transforms: ['voidedAt'], exists: true },
        ),
      ],
      ADMIN,
    ),
    403,
  );

  check(
    'kasir batalkan nota ditolak',
    await commit(
      [
        updateWrite(
          'transactions/tx-percent',
          { voided: true, voidedBy: 'kasir1' },
          { transforms: ['voidedAt'], exists: true },
        ),
      ],
      KASIR1,
    ),
    403,
  );

  check(
    'hapus nota ditolak',
    await commit([deleteWrite('transactions/tx-percent')], ADMIN),
    403,
  );

  console.log(failures === 0 ? '\nSemua pemeriksaan rules lulus.' : `\n${failures} pemeriksaan GAGAL.`);
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
