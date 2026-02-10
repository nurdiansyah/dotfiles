# Scripts (smoke tests & helpers)

Ringkasan singkat dari skrip kecil dan smoke-tests yang ada di `scripts/`.

## Tes yang tersedia ✅

- `./scripts/test_zsh_znap_smoke.sh` — smoke-test non-destruktif untuk helper
  `zsh_znap_install_plugins`.
  - Aman untuk dijalankan di CI: tidak melakukan operasi jaringan, menggunakan stub `znap`.
  - Jalankan: `./scripts/test_zsh_znap_smoke.sh`

- `./scripts/test_kanata_smoke.sh` — pemeriksaan cepat untuk instalasi Kanata
  (user-level checks). Untuk pemeriksaan driver/daemon jalankan dengan `--full` (membutuhkan sudo):
  - Jalankan: `./scripts/test_kanata_smoke.sh` atau `./scripts/test_kanata_smoke.sh --full`

## Pedoman

- Skrip disimpan di `scripts/` dan sebaiknya bersifat non-destruktif, mudah dijalankan, dan
  memiliki opsi `--help`/`-h` bila relevan.
- Jika ingin menambahkan skrip baru, sertakan `--help` dan buat smoke-test kecil bila
  memungkinkan untuk memudahkan integrasi CI.

## Catatan CI 🧪

- Tes seperti `test_zsh_znap_smoke.sh` cocok untuk ditambahkan ke workflow CI karena tidak
  bergantung pada jaringan dan tidak mengubah sistem. Untuk memanfaatkan ini di CI,
  tambahkan langkah yang menjalankan skrip tersebut dan periksa kode keluaran (0 = OK).
