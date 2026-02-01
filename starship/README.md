# Starship Prompt — konfigurasi repo ⭐

Ringkasan singkat

- **Tujuan:** Menyimpan konfigurasi Starship prompt yang dipakai dalam repositori ini.
- File utama: `starship/starship.toml` (konfigurasi) dan `starship/tokyo-night.toml` (tema contoh).

## Instalasi (macOS) 🍺

1. Install Starship:

```bash
brew install starship
```

2. Pasang ke shell Anda (contoh zsh):

```bash
# di ~/.zshrc
eval "$(starship init zsh)"
```

Untuk bash/fish gunakan `starship init bash` atau `starship init fish`.

## Menggunakan konfigurasi dari repo 🔧

Ada dua cara umum:

- Buat symlink ke lokasi konfigurasi default:

```bash
ln -s "$(pwd)/starship/starship.toml" "$HOME/.config/starship.toml"
```

- Atau set environment var untuk menunjuk file langsung:

```bash
export STARSHIP_CONFIG="$PWD/starship/starship.toml"
# lalu mulai ulang shell
```

> Catatan: `starship/tokyo-night.toml` adalah contoh tema yang dapat Anda salin atau gabungkan ke `starship.toml` sesuai kebutuhan.

## Contoh isi `starship.toml` (ringkas)

```toml
# contoh singkat
format = "[$all]($style)\n"
[dotnet]
format = "via [$symbol($version)]($style) "
```

Lihat `starship/starship.toml` untuk konfigurasi lengkap yang digunakan di repo.

## Test & debugging 🔍

- Cek versi starship:

```bash
starship --version
```

- Render prompt secara interaktif (preview):

```bash
STARSHIP_CONFIG="./starship/starship.toml" starship prompt
```

- Jika ada masalah parsing `Brewfile`/konfigurasi, ini bukan bagian Starship; laporkan issue dengan langkah reproduksi.

## Contributing / Perubahan ✨

- Ingin mengubah prompt atau tema? Buka PR yang menjelaskan perubahan dan cara mengetesnya (mis. screenshot atau perintah `starship prompt`).
- Pastikan perubahan bersih dan tidak mengandung kredensial.

---

## Contoh `~/.zshrc` (snippet) 🧩

Tambahkan baris ini ke `~/.zshrc` untuk menginisialisasi Starship dan menggunakan konfigurasi dari repo:

```bash
# Gunakan konfigurasi repo jika tersedia, fall back ke default
if [ -f "$HOME/.config/starship.toml" ]; then
  eval "$(starship init zsh)"
else
  # Optional: gunakan file repo saat sedang bekerja di repo
  export STARSHIP_CONFIG="$HOME/dotfiles/starship/starship.toml"
  eval "$(starship init zsh)"
fi
```

Untuk mengetes segera tanpa membuka shell baru:

```bash
STARSHIP_CONFIG="./starship/starship.toml" starship prompt
```

## Skrip instalasi otomatis `scripts/install-starship.sh` 🔧

Skrip ini membuat symlink dari `starship/starship.toml` di repo ke `$HOME/.config/starship.toml`.

Fitur:
- Opsi `--yes` untuk non-interactive (jawab otomatis ya ke prompt)
- Opsi `--force` untuk menimpa file/symlink yang sudah ada
- Opsi `--dry-run` untuk menampilkan apa yang akan dilakukan tanpa mengubah apa pun

Contoh penggunaan:

```bash
# Interaktif (akan minta konfirmasi jika file sudah ada)
./scripts/install-starship.sh

# Non-interaktif: setuju dan timpa jika perlu
./scripts/install-starship.sh --yes --force

# Cek tindakan tanpa mengubah file
./scripts/install-starship.sh --dry-run
```

Jika Anda mau, saya sudah buat skrip ini di `scripts/install-starship.sh` — jalankan dan laporkan jika perlu perubahan pada opsi atau perilaku.
