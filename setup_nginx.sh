#!/bin/bash

echo "🚀 Setting up Nginx for braindumpster.io..."
echo ""

# Nginx kurulu mu kontrol et
if ! command -v nginx &> /dev/null; then
    echo "📦 Installing Nginx..."
    sudo apt update
    sudo apt install -y nginx
else
    echo "✅ Nginx already installed"
fi

echo ""
echo "📝 Creating Nginx configuration..."

# Config dosyası oluştur
sudo tee /etc/nginx/sites-available/braindumpster > /dev/null <<'EOF'
server {
    listen 80;
    server_name api.braindumpster.io braindumpster.io www.braindumpster.io;

    # Cloudflare real IP
    real_ip_header CF-Connecting-IP;
    set_real_ip_from 103.21.244.0/22;
    set_real_ip_from 103.22.200.0/22;
    set_real_ip_from 103.31.4.0/22;
    set_real_ip_from 104.16.0.0/13;
    set_real_ip_from 104.24.0.0/14;
    set_real_ip_from 108.162.192.0/18;
    set_real_ip_from 131.0.72.0/22;
    set_real_ip_from 141.101.64.0/18;
    set_real_ip_from 162.158.0.0/15;
    set_real_ip_from 172.64.0.0/13;
    set_real_ip_from 173.245.48.0/20;
    set_real_ip_from 188.114.96.0/20;
    set_real_ip_from 190.93.240.0/20;
    set_real_ip_from 197.234.240.0/22;
    set_real_ip_from 198.41.128.0/17;

    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $server_name;

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    access_log /var/log/nginx/braindumpster_access.log;
    error_log /var/log/nginx/braindumpster_error.log;
}
EOF

echo "✅ Configuration file created"
echo ""

# Symlink oluştur
if [ ! -L /etc/nginx/sites-enabled/braindumpster ]; then
    echo "🔗 Creating symlink..."
    sudo ln -s /etc/nginx/sites-available/braindumpster /etc/nginx/sites-enabled/
    echo "✅ Symlink created"
else
    echo "✅ Symlink already exists"
fi

echo ""
echo "🧪 Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Configuration is valid!"
    echo ""
    echo "🔄 Restarting Nginx..."
    sudo systemctl restart nginx

    echo ""
    echo "📊 Nginx status:"
    sudo systemctl status nginx --no-pager | head -10

    echo ""
    echo "✅ Setup complete!"
    echo ""
    echo "🧪 Test your endpoints:"
    echo "   curl http://api.braindumpster.io/api/health"
    echo "   curl https://api.braindumpster.io/api/health"
else
    echo ""
    echo "❌ Configuration test failed!"
    echo "Please check the error messages above."
fi
