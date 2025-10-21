# 🚀 App Store Connect Setup Guide

## Bu dosyayı kullanarak App Store Connect'te gerekli ayarları yap

---

## ADIM 1: Webhook URL Ayarla (3 dakika)

### Nereye gideceksin:
1. **App Store Connect** aç: https://appstoreconnect.apple.com
2. **My Apps** → **Braindumpster** seç
3. Sol menüden **App Information** tıkla
4. Aşağı scroll et → **App Store Server Notifications** bölümünü bul

### Ne yapacaksın:
```
Production Server URL Notification Version: V2 seç
Production URL: http://57.129.81.193:5001/api/webhooks/apple
Sandbox URL: http://57.129.81.193:5001/api/webhooks/apple
```

### Tıkla:
- **Save** butonu (sağ üstte)

### ✅ Nasıl anlarsın başarılı olduğunu:
- URL'ler kaydedildi
- "Saved successfully" gibi mesaj göründü

---

## ADIM 2: Billing Grace Period Aktifle (2 dakika)

⚠️ **ÖNEMLİ**: Billing Grace Period artık APP SEVİYESİNDE ayarlanıyor (her subscription için ayrı değil!)

### Nereye gideceksin:
1. **App Store Connect** → **Apps** → **Braindumpster** seç
2. Sol sidebar'dan **Subscriptions** tıkla
3. **Billing Grace Period** bölümünü bul (sayfanın üst kısmında)
4. **Set Up Billing Grace Period** butonuna tıkla (eğer hiç setup edilmediyse)
   VEYA
   **Edit** butonuna tıkla (eğer daha önce setup edildiyse)

### Ne yapacaksın:
```
Duration: 16 days seç
  (3, 16, veya 28 gün seçenekleri var)

Renewal Types: All Renewals seç
  (Tüm renewals için geçerli olacak)

Server Environments: Production and Sandbox Environment seç
  (Her iki environment için aktif olacak)
```

### Tıkla:
- **Save** butonu

### ✅ Nasıl anlarsın başarılı olduğunu:
- Billing Grace Period section'da "16 days" görünüyor
- "All Renewals" yazıyor
- "Production and Sandbox Environment" seçili
- Tüm subscriptions (Yearly, Monthly, Lifetime) için otomatik uygulanmış olacak

### 💡 NOT:
- Değişiklikler 24 saat içinde aktif olur
- Bu ayar APP seviyesinde olduğu için TÜM subscription products için geçerli
- Ayrı ayrı her product için ayarlamana gerek YOK

---

## ADIM 3: Sandbox Test Account Oluştur (2 dakika)

### Nereye gideceksin:
1. **App Store Connect** → **Users and Access**
2. Üstteki tabs'dan **Sandbox** tıkla
3. **Sandbox Testers** altında **+** (Create) butonu

### Ne yapacaksın:
```
First Name: Brain
Last Name: Tester
Email: braindumpster-sandbox@test.com
         (Gerçek email olmamalı! Apple fake email kabul eder)
Password: TestBrain2025!
Confirm Password: TestBrain2025!
Date of Birth: 01/01/1990
Country or Region: United States
```

### Tıkla:
- **Create** butonu

### ✅ Nasıl anlarsın başarılı olduğunu:
- Listede "braindumpster-sandbox@test.com" görünüyor
- Status: Active

---

## ADIM 4: Sandbox Test Yap (İsteğe Bağlı - 5 dakika)

### iPhone'da:
1. **Settings** → **App Store** → Sign Out (eğer giriş yaptıysan)
2. **Settings** → **Developer** → **Sandbox Apple Account**
   - Email: braindumpster-sandbox@test.com
   - Password: TestBrain2025!
3. **Braindumpster** uygulamasını aç
4. **Premium** → **Yearly** seç → **Subscribe** tıkla
5. Sandbox hesapla giriş yap
6. Purchase confirm et

### ✅ Nasıl anlarsın başarılı olduğunu:
- Console log'da "Backend verification successful" görünüyor
- Premium unlock oldu
- Settings'te "Premium Member" badge var

---

## ADIM 5: Build Info Kontrol Et

### Xcode'da:
1. **Braindumpster** project dosyasını seç
2. **Targets** → **Braindumpster** → **General** tab
3. **Identity** bölümünü kontrol et:
   ```
   Version: 1.0
   Build: 11
   ```

### ✅ Eğer farklıysa:
- Version ve Build'i düzelt
- Save (⌘S)

---

## ADIM 6: Archive & Upload (10 dakika)

### Xcode'da:
1. **Product** → **Clean Build Folder** (⇧⌘K)
2. Cihaz seçimini **Any iOS Device (arm64)** yap (simulator değil!)
3. **Product** → **Archive**
4. Bekle... (2-3 dakika)
5. Organizer açılacak
6. **Distribute App** tıkla
7. **App Store Connect** seç → **Next**
8. **Upload** seç → **Next**
9. **Automatically manage signing** seç → **Next**
10. Review bilgileri → **Upload**
11. Bekle... (5-10 dakika upload için)

### ✅ Nasıl anlarsın başarılı olduğunu:
- "Upload Successful" mesajı
- Email gelecek (1-2 dakika sonra)

---

## ADIM 7: Submit for Review

### App Store Connect'te:
1. **My Apps** → **Braindumpster**
2. **App Store** tab → **iOS App** altında **1.0 Prepare for Submission**
3. Build seç (방금 upload ettiğin)
4. **Version Information** doldur (eğer boşsa)
5. **App Review Information** bölümünde:
   ```
   Notes: APP_REVIEW_NOTES.md dosyasındaki metni yapıştır
   ```
6. **Export Compliance:**
   - "No, this app does not use encryption"
   (Sadece HTTPS kullanıyoruz, ek encryption yok)

### Tıkla:
- **Submit for Review** (sağ üstte)

### ✅ Nasıl anlarsın başarılı olduğunu:
- Status: "Waiting for Review"
- Email gelecek: "Your app is in review"

---

## 📊 ÖZET - YAPILACAKLAR LİSTESİ

- [ ] Webhook URL ayarla (3 dk)
- [ ] Billing Grace Period aktifle (2 dk)
- [ ] Sandbox test account oluştur (2 dk)
- [ ] Sandbox test yap (optional - 5 dk)
- [ ] Build info kontrol et (1 dk)
- [ ] Archive & Upload (10 dk)
- [ ] Submit for Review (3 dk)

**TOPLAM SÜRE: ~25 dakika**

---

## 🆘 SORUN ÇIKARSA

### Webhook URL kaydedilmiyor:
- URL doğru mu kontrol et: http://57.129.81.193:5001/api/webhooks/apple
- V2 seçili mi?
- Save'e bastın mı?

### Billing Grace Period toggle yok:
- Subscription product olmalı (non-consumable değil)
- Eğer yoksa, atlayabilirsin (optional feature)

### Sandbox account oluşturmuyor:
- Email unique olmalı
- Daha önce kullanılmamış olmalı
- Farklı email dene: braindumpster-test2@sandbox.com

### Archive yapamıyorum:
- Cihaz "Any iOS Device" olmalı (simulator değil!)
- Signing certificates hazır mı kontrol et
- Clean build folder yap (⇧⌘K)

### Upload başarısız:
- Internet bağlantını kontrol et
- Xcode'u restart et
- Tekrar dene

---

## 📞 DESTEK

Takılırsan:
1. Bu dosyayı oku
2. Error mesajını kopyala
3. Bana gönder

**Başarılar! 🚀**
