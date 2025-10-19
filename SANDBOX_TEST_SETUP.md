# Sandbox Test Kurulumu

## Simulator'de StoreKit Test Yapma (iOS 18+)

### Adım 1: Simulator'de Ayarları Aç
1. Simulator'u çalıştır
2. **Settings** uygulamasını aç
3. **App Store** → **Sandbox Account** bölümüne git
4. Eğer hesap yoksa: **"Sign In with Apple ID"**

### Adım 2: App Store Connect'te Sandbox Test User Oluştur

1. **App Store Connect**'e git: https://appstoreconnect.apple.com
2. Sol menüden **Users and Access** → **Sandbox** sekmesine tıkla
3. **"+" (Add)** butonuna tıkla
4. Test kullanıcısı bilgilerini gir:
   - Email: test@example.com (gerçek olmayan bir email)
   - Password: En az 8 karakter, büyük harf, küçük harf, sayı
   - First Name: Test
   - Last Name: User
   - Country: Turkey (veya USA)
5. **Save** butonuna tıkla

### Adım 3: Simulator'de Sandbox Hesabı Ekle

1. Simulator → **Settings** → **App Store**
2. **Sandbox Account** altında **"Sign In"**
3. Oluşturduğun test email ve şifreyi gir
4. ✅ Başarılı! Artık sandbox test yapabilirsin

---

## Yöntem 2: Xcode'da StoreKit Configuration Kullan (Daha Kolay)

### Adım 1: Products.storekit'i Xcode Project'e Ekle

1. Xcode'da **Project Navigator**'ı aç (⌘+1)
2. **Products.storekit** dosyasını Finder'dan Xcode'a sürükle-bırak
3. Açılan dialogda:
   - ✅ **"Copy items if needed"** SEÇİLMESİN
   - ✅ **"Add to targets"** SEÇİLMESİN (sadece file reference)
   - ✅ **"Create folder references"**
4. **Add** butonuna tıkla

### Adım 2: Xcode Scheme'i Kontrol Et

1. Xcode'da üst menüden: **Product** → **Scheme** → **Edit Scheme...**
2. Sol tarafta **Run** seçeneğini seç
3. **Options** sekmesine git
4. **StoreKit Configuration** dropdown'ından **"Products"** seçeneğini seç
5. **Close** butonuna tıkla

### Adım 3: Test Et

1. **⌘ + Shift + K** (Clean Build)
2. **⌘ + R** (Run)
3. Settings → Upgrade to Premium
4. Bir plan seç ve satın al
5. ✅ Sandbox popup açılmalı!

---

## Sorun Giderme

### "Product not found" Hatası
- Xcode'u tamamen kapat ve tekrar aç
- Derived Data'yı temizle: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Products.storekit dosyasının scheme'de doğru tanımlı olduğundan emin ol

### "No active account" Hatası
- Simulator'de App Store sandbox account ekle (Yöntem 1)
- VEYA StoreKit Configuration kullan (Yöntem 2 - daha kolay)

### RevenueCat "Configuration Error"
- Normal! RevenueCat, App Store Connect'teki ürünleri bulamıyor
- Ürünler "Waiting for Review" durumunda
- Fallback UI devreye giriyor (hardcoded pricing)
- Native StoreKit satın alma çalışıyor

---

## Sonuç

StoreKit Configuration ile simulator'de **gerçek para ödemeden** test yapabilirsin!
