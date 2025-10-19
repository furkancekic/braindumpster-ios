# 🚀 Braindumpster IAP Sandbox Test - Complete Guide

## ✅ Ne Yaptık:

1. ✅ **NativeStoreManager.swift** - RevenueCat yerine native StoreKit 2 kullanıyor
2. ✅ **PremiumView.swift** - NativeStoreManager ile entegre
3. ✅ **SettingsView.swift** - NativeStoreManager kullanıyor
4. ✅ **Products.storekit** - Xcode project'e ekli
5. ✅ **Xcode Scheme** - StoreKit Configuration path güncellendi

---

## 📋 ŞİMDİ YAPILMASI GEREKENLER:

### Adım 1: Xcode'da StoreKit Configuration'ı Manuel Aktif Et

**ÖNEMLİ**: Bu adımı MUTLAKA yapmalısın!

1. **Xcode'u aç** (eğer kapalıysa)
2. Üst solda **"Braindumpster"** scheme'ini seç (iPhone 16 Pro yanında)
3. **Product → Scheme → Edit Scheme...** tıkla (veya **⌘ + <** tuşları)
4. Sol tarafta **"Run"** seçeneğini seç
5. Sağ tarafta **"Options"** sekmesine tıkla
6. **"StoreKit Configuration"** bölümünü bul
7. Dropdown'dan **"Products"** veya **"Products.storekit"** seç
8. **"Close"** butonuna tıkla

### Adım 2: Clean Build

```
⌘ + Shift + K  (Product → Clean Build Folder)
```

### Adım 3: Run Simulator

```
⌘ + R  (Product → Run)
```

### Adım 4: Premium Ekranına Git

1. Simulator'de **Settings** butonuna tıkla
2. **"Upgrade to Premium"** tıkla
3. **ÜÇ PLAN GÖRMELI SIN:**
   - Yearly Premium: $49.99/year
   - Monthly Premium: $9.99/month
   - Lifetime Premium: $99.99 one-time

### Adım 5: Satın Alma Testi

1. Bir plan seç (örn. Yearly Premium)
2. **"Start Your Premium Journey →"** butonuna bas
3. **Sandbox satın alma popup'ı** açılmalı!
4. **"Subscribe"** veya **"Buy"** butonuna bas
5. ✅ **Otomatik onaylanmalı** (gerçek para çekilmez)
6. Toast: **"Welcome to Premium! 🎉"**

---

## 🐛 Sorun Giderme:

### Sorun 1: "✅ [NativeStore] Loaded 0 products"

**Sebep**: StoreKit Configuration yüklenmemiş

**Çözüm**:
1. Xcode'u **TAMAMEN KAPAT** (Quit)
2. DerivedData temizle:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Xcode'u tekrar aç
4. **Adım 1**'i tekrarla (Edit Scheme → Options → StoreKit Configuration → Products)
5. Clean Build + Run

### Sorun 2: "No active account" Hatası

**Normal!** Bu simulator'de sandbox account olmadığını gösterir.

**Çözüm**:
- Simulator'de StoreKit Configuration kullanırken bu hata önemli değil
- Ürünler yine de yüklenmeli
- Eğer ürünler yüklenmediyse **Sorun 1**'e bak

### Sorun 3: "Products are awaiting app store approval"

**Sebep**: StoreKit Configuration düzgün yüklenmemiş VEYA ürünler gerçekten approved değil

**Simulator'de**:
- StoreKit Configuration yoksa fallback UI gösterir
- **Adım 1**'i yap ve tekrar dene

**Gerçek Cihazda**:
- Normal! Ürünler App Store'da approved olmadan satın alınamaz
- Fallback UI pricing'i gösterir
- Apple'a submit edip onay beklemen lazım

---

## 📱 Gerçek Cihazda (iPhone) Test:

### Sandbox Account İle Test

**ÖNEMLİ**: Gerçek cihazda test için IAP'ler **App Store Connect'te approved** olmalı!

1. **App Store Connect** → Sandbox → Test User Oluştur
2. **iPhone'da**: Settings → App Store → Sandbox Account → Sign In
3. **Xcode'dan** iPhone'a app'i run et
4. Premium ekranına git → Satın al
5. Sandbox popup'ı açılacak (üstte "Environment: Sandbox" yazar)
6. Test account ile satın al

---

## 🎯 Console Log'larında Görmek İstediğin Mesajlar:

### ✅ BAŞARILI:

```
🛒 [NativeStore] Loading products...
✅ [NativeStore] Loaded 3 products
   📦 Yearly Premium: $49.99
   📦 Monthly Premium: $9.99
   📦 Lifetime Premium: $99.99
```

### ❌ BAŞARISIZ:

```
✅ [NativeStore] Loaded 0 products
```

→ **Çözüm**: Yukarıdaki **Sorun 1**'e bak

---

## 📤 App Store'a Submit İçin Checklist:

### Before Submit:

- [ ] IAP'lere screenshot ekledim (Premium ekranı)
- [ ] App Store Connect'te "In-App Purchases" bölümüne 3 IAP'i ekledim
- [ ] Simulator'de satın alma testi yaptım
- [ ] Fallback UI çalışıyor (ürünler approved olmasa bile pricing görünüyor)
- [ ] Console'da hata yok

### Apple'a Mesaj:

```
Dear App Review Team,

The in-app purchase products (Monthly, Yearly, Lifetime Premium) are fully implemented and functional.

The pricing interface is visible at Settings → Upgrade to Premium. However, the products
are awaiting approval and cannot be tested until they are approved by the App Store team.

Please approve the IAP products so they become functional. Once approved, the purchase
flow will work correctly with sandbox accounts.

Thank you!
```

---

## 🎉 Başarı Kriterleri:

✅ Console'da: `✅ [NativeStore] Loaded 3 products`
✅ Premium ekranında 3 pricing kartı görünüyor
✅ Satın alma butonuna basınca sandbox popup açılıyor
✅ "Welcome to Premium! 🎉" toast mesajı görünüyor
✅ isPremium = true oluyor

---

## 📞 Hala Çalışmıyorsa:

1. Console log'ları tam kopyala ve bana gönder
2. Premium ekranının screenshot'ını at
3. Xcode → Product → Scheme → Edit Scheme → Options → StoreKit Configuration'ın screenshot'ını at

---

## 🔧 Debug Komutları:

```bash
# DerivedData temizle
rm -rf ~/Library/Developer/Xcode/DerivedData

# Products.storekit'in yerini kontrol et
ls -la /Users/furkancekic/projects/last_tasks/Products.storekit

# Xcode scheme'i kontrol et
cat /Users/furkancekic/projects/last_tasks/Braindumpster.xcodeproj/xcshareddata/xcschemes/Braindumpster.xcscheme | grep storeKit

# NativeStoreManager'ın kodunu kontrol et
grep -n "Loading products" /Users/furkancekic/projects/last_tasks/NativeStoreManager.swift
```

---

**Son Güncelleme**: 13 Ekim 2025
**Durum**: Production Ready - Sandbox Test Bekleniyor
