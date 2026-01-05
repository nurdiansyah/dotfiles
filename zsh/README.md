# ZSH Configuration

Modern zsh configuration untuk dotfiles dengan profile switching & integration dengan Neovim.

## 📁 Struktur

```
zsh/
├── .zshrc           # Main zsh config (sourced by ~/.zshrc)
├── .zsh_profile     # Environment setup
└── install.sh       # Setup script untuk link ke home directory
```

## 🎯 Fitur Utama

### 1. **Profile Switching untuk Neovim**
Dengan Neovim yang sudah di-update ke fzf-lua, blink.cmp, dan conform, zsh sekarang support quick profile switching:

```bash
nvim_profile javascript    # Set JavaScript profile
nvim_profile java          # Set Java profile  
nvim_profile devops        # Set DevOps profile
nvim_profile_show          # Show current profile
```

Profile disimpan di `~/.config/nvim/state/profile` dan Neovim membacanya untuk load plugin yang sesuai.

### 2. **Format Files dengan Conform**
Quick formatter untuk files:

```bash
nvim_format file.js file.ts    # Format files dengan conform
```

### 3. **FZF Integration**
Auto-configured dengan default options:
- `--height 40%` - Height 40% dari terminal
- `--reverse` - Show results di bawah
- `--border` - Add border
- Default command: `fd` dengan hidden files support

### 4. **Shell Shortcuts**

**Neovim:**
```bash
v                           # nvim
vi                          # nvim
vim                         # nvim
nvimrc                      # nvim ~/.config/nvim
nvimsync                    # cd to nvim in dotfiles
nvim_format <file>          # Format file with conform
```

**Git:**
```bash
g                           # git
ga                          # git add
gc                          # git commit
gp                          # git push
gpl                         # git pull
gst                         # git status
glog                        # git log oneline
gbr                         # git branch
```

**Kubernetes:**
```bash
k                           # kubectl
kg                          # kubectl get
kd                          # kubectl describe
kl                          # kubectl logs
kgp                         # kubectl get pods
kgs                         # kubectl get svc
kgn                         # kubectl get nodes
```

**Directory:**
```bash
ll                          # ls -lah
dots                        # cd ~/dotfiles
proj                        # cd ~/projects
reload                      # source ~/.zshrc
```

### 5. **Node.js & Package Managers**
```bash
npm-global                  # List global npm packages
pnpm-global                 # List global pnpm packages
```

## 📋 Environment Variables

### Diatur di `.zshrc`
- `EDITOR=nvim` - Default editor
- `FZF_DEFAULT_OPTS` - FZF options
- `FZF_DEFAULT_COMMAND` - FZF search command

### Diatur di `.zsh_profile`
- `TZ=Asia/Jakarta` - Timezone
- `NODE_OPTIONS=--max_old_space_size=4096` - Node memory limit
- `HOMEBREW_NO_AUTO_UPDATE=true` - Disable auto brew updates

## 🚀 Installation

```bash
cd ~/dotfiles/home/zsh
bash install.sh
```

Script akan:
1. ✅ Backup existing files ke `~/.dotfiles_backup_*`
2. ✅ Copy `.zshrc` ke `~/.zshrc`
3. ✅ Copy `.zsh_profile` ke `~/.zsh_profile`
4. ✅ Symlink `nvim/` ke `~/.config/nvim`
5. ✅ Create `~/.config/nvim/state/` untuk profile switching
6. ✅ Set permissions

## 📦 Plugin Management

### Oh-My-Zsh Plugins (aktif)
- `git` - Git aliases & functions
- `kustomize` - Kustomize completion
- `kubectl` - Kubectl completion

### Shell Plugins (auto-loaded)
- **zsh-autosuggestions** - Command suggestions saat ketik
- **fzf** - Fuzzy finder CLI
- **mcfly** - Reverse history search (opsional)
- **rush.js** - Rush CLI completion
- **pnpm** - pnpm CLI completion

## 🔧 Configuration Files

### `.zshrc`
Main config dengan:
- Oh-My-Zsh setup
- Theme (sobole)
- Aliases & functions
- Plugin sourcing
- Profile switching untuk Neovim

### `.zsh_profile`
Environment variables:
- Language & locale
- Node.js paths
- Python venv
- PostgreSQL, Perl, Java paths
- Tools configuration

## 🎨 Integration dengan Neovim

Neovim sekarang bisa detect profile dari `.config/nvim/state/profile` dan load plugins sesuai:

```lua
-- In Neovim
local ok_state, state = pcall(require, "utils.state")
if ok_state then
  if state.mode == "javascript" then
    -- Load JavaScript plugins
  elseif state.mode == "java" then
    -- Load Java plugins
  elseif state.mode == "devops" then
    -- Load DevOps plugins
  end
end
```

Set profile dari terminal:
```bash
nvim_profile javascript    # Langsung reload di Nvim
```

## 💡 Pro Tips

1. **Local Overrides:** Buat `~/.zsh_local` atau `~/.zsh_profile_local` untuk machine-specific config
2. **Token Security:** Simpan tokens di `~/.zsh_tokens` (gitignore) bukan di zshrc
3. **Backup:** Script auto-backup existing files sebelum symlink
4. **Reload:** Gunakan `reload` alias untuk quick reload config tanpa exit shell

## 🔄 Update

Untuk update zsh config dari dotfiles:
```bash
# Copy latest dari dotfiles
cp ~/dotfiles/home/zsh/.zshrc ~/.zshrc
cp ~/dotfiles/home/zsh/.zsh_profile ~/.zsh_profile

# Reload
reload
```

## 📚 Referensi

- [Oh-My-Zsh](https://ohmyz.sh/)
- [FZF](https://github.com/junegunn/fzf)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
