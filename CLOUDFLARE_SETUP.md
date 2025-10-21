# 🌐 Cloudflare Domain Setup Guide

## ADIM 1: DNS Ayarları (5 dakika)

### Cloudflare Dashboard'a git:
1. https://dash.cloudflare.com açın
2. Domain'inizi seçin

### DNS Records ekle:

#### A Record (API için):
```
Type: A
Name: api
Content: 57.129.81.193
Proxy status: Proxied (🧡 turuncu bulut AÇIK)
TTL: Auto
```

#### A Record (Root domain - optional):
```
Type: A
Name: @ (root)
Content: 57.129.81.193
Proxy status: Proxied (🧡 turuncu bulut AÇIK)
TTL: Auto
```

### ✅ Nasıl anlarsın başarılı olduğunu:
- DNS kayıtları listede görünüyor
- Turuncu bulut (🧡) aktif (Proxied)
- Status: Active

---

## ADIM 2: SSL/TLS Ayarları (2 dakika)

### Cloudflare → SSL/TLS sekmesi:

1. **Overview** tab:
   ```
   SSL/TLS encryption mode: Full (strict)
   ```
   ⚠️ ÖNEMLI: "Flexible" değil, "Full (strict)" seç!

2. **Edge Certificates** tab:
   - Always Use HTTPS: ✅ ON
   - Minimum TLS Version: 1.2
   - Automatic HTTPS Rewrites: ✅ ON

### ✅ Nasıl anlarsın başarılı olduğunu:
- SSL/TLS mode: "Full (strict)"
- "Always Use HTTPS" aktif
- Cloudflare otomatik SSL sertifikası verdi (ücretsiz)

---

## ADIM 3: Backend Sunucuda Nginx Ayarları

### SSH ile sunucuya bağlan:
```bash
ssh root@57.129.81.193
```

### Nginx config dosyası oluştur:
```bash
sudo nano /etc/nginx/sites-available/braindumpster
```

### Şu config'i yapıştır:
```nginx
server {
    listen 80;
    server_name api.DOMAIN_ADI_BURAYA;  # Örnek: api.braindumpster.com

    # Cloudflare'den gelen istekleri kabul et
    real_ip_header CF-Connecting-IP;

    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # CORS headers (Flask'ta zaten var ama ekstra güvenlik)
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "Content-Type, Authorization";
    }

    # Health check endpoint
    location /api/health {
        proxy_pass http://127.0.0.1:5001/api/health;
        proxy_set_header Host $host;
    }

    # Apple webhook endpoint
    location /api/webhooks/apple {
        proxy_pass http://127.0.0.1:5001/api/webhooks/apple;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

### Nginx'i aktifleştir:
```bash
# Symlink oluştur
sudo ln -s /etc/nginx/sites-available/braindumpster /etc/nginx/sites-enabled/

# Test et
sudo nginx -t

# Restart et
sudo systemctl restart nginx

# Status kontrol
sudo systemctl status nginx
```

### ✅ Nasıl anlarsın başarılı olduğunu:
- `nginx -t` komutu "syntax is ok" ve "test is successful" döndü
- Nginx running

---

## ADIM 4: Test Et (2 dakika)

### DNS propagation kontrolü:
```bash
# Mac/Linux'ta:
nslookup api.DOMAIN_ADI_BURAYA

# Sonuç Cloudflare IP'lerinden biri olmalı (104.x.x.x veya benzer)
```

### HTTPS endpoint testi:
```bash
# Health check
curl https://api.DOMAIN_ADI_BURAYA/api/health

# Webhook test
curl https://api.DOMAIN_ADI_BURAYA/api/webhooks/test
```

### ✅ Beklenen sonuç:
```json
{
  "status": "healthy",
  "message": "Braindumpster API is running",
  ...
}
```

---

## ADIM 5: Backend Config Güncelle (1 dakika)

### config.py dosyasını güncelle:
```python
class ProductionConfig(Config):
    DEBUG = False
    CORS_ORIGINS = ['https://api.DOMAIN_ADI_BURAYA']
    # ... diğer ayarlar
```

### Restart:
```bash
sudo systemctl restart braindumpster
```

---

## ADIM 6: App Store Connect'e Webhook URL Ekle

Artık HTTPS URL'in hazır!

```
Production URL: https://api.DOMAIN_ADI_BURAYA/api/webhooks/apple
Sandbox URL: https://api.DOMAIN_ADI_BURAYA/api/webhooks/apple
```

Bu URL'i App Store Connect → App Information → App Store Server Notifications bölümüne ekle.

---

## 🔥 Cloudflare Avantajları:

✅ **Ücretsiz SSL** - Let's Encrypt kurmana gerek yok
✅ **DDoS Protection** - Cloudflare otomatik koruma sağlıyor
✅ **CDN** - Dünya çapında hızlı erişim
✅ **Caching** - API yanıtları cache'lenebilir
✅ **Analytics** - Trafik istatistikleri

---

## 🆘 SORUN ÇIKARSA:

### "502 Bad Gateway" hatası:
```bash
# Backend çalışıyor mu kontrol et
sudo systemctl status braindumpster

# Nginx loglarına bak
sudo tail -f /var/log/nginx/error.log
```

### "DNS_PROBE_FINISHED_NXDOMAIN":
- DNS kayıtlarını kontrol et
- 5-10 dakika bekle (propagation)
- `nslookup api.domain.com` ile test et

### Cloudflare SSL "Full (strict)" mode çalışmıyor:
- Nginx port 80'de çalışıyor olmalı
- Cloudflare "Flexible" mode'a geç (geçici)
- Backend'de SSL kurulumu gerekmez (Cloudflare halleder)

---

## 📊 ÖZET:

1. ✅ Cloudflare DNS → A record (api.domain.com → 57.129.81.193)
2. ✅ SSL/TLS mode → Full (strict) veya Full
3. ✅ Nginx config → Reverse proxy 5001'e
4. ✅ Test → curl https://api.domain.com/api/health
5. ✅ App Store Connect → HTTPS webhook URL ekle

**Toplam süre: ~15 dakika**

Başarılar! 🚀
