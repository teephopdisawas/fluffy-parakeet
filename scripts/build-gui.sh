#!/bin/bash
# NASBox GUI Builder
# Sets up the lightweight web-based management interface

set -e

ROOTFS_DIR=${1:-"build/rootfs"}

echo "Building NASBox GUI..."

# Create GUI directories
mkdir -p "$ROOTFS_DIR/var/www/nasbox"
mkdir -p "$ROOTFS_DIR/etc/nginx/conf.d"

# Copy GUI files
cp -r gui/* "$ROOTFS_DIR/var/www/nasbox/"

# Create nginx configuration for GUI
cat > "$ROOTFS_DIR/etc/nginx/conf.d/nasbox.conf" << 'EOF'
server {
    listen 8080;
    listen [::]:8080;
    server_name _;
    
    root /var/www/nasbox;
    index index.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # GUI static files
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # API proxy
    location /api/ {
        proxy_pass http://127.0.0.1:8081/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_cache_bypass $http_upgrade;
    }
    
    # WebSocket support for real-time updates
    location /ws {
        proxy_pass http://127.0.0.1:8081/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
    }
    
    # Static assets caching
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
}
EOF

# Create GUI service
cat > "$ROOTFS_DIR/etc/init.d/nasbox-gui" << 'EOF'
#!/sbin/openrc-run

name="NASBox GUI"
description="NASBox Web Management Interface"

command="/usr/sbin/nginx"
command_args="-c /etc/nginx/nginx.conf"
pidfile="/var/run/nginx.pid"

depend() {
    need net
    after nasbox-api
}

start_pre() {
    checkpath --directory --mode 0755 /var/www/nasbox
    checkpath --directory --mode 0755 /var/log/nginx
}
EOF
chmod +x "$ROOTFS_DIR/etc/init.d/nasbox-gui"

# Create API backend service (Python-based)
cat > "$ROOTFS_DIR/usr/local/bin/nasbox-api" << 'APIEOF'
#!/usr/bin/env python3
"""
NASBox API Backend
Provides REST API for the management GUI

Security Note: This API uses subprocess for system commands but only with
predefined arguments - no user input is passed to shell commands.
"""

import json
import os
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

class NASBoxAPI(BaseHTTPRequestHandler):
    """Simple API handler for NASBox management
    
    Security: All subprocess calls use fixed command arguments.
    No user input is interpolated into shell commands.
    """
    
    def _set_headers(self, status=200, content_type='application/json'):
        self.send_response(status)
        self.send_header('Content-Type', content_type)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
    
    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        
        if path == '/system/stats':
            self._get_system_stats()
        elif path == '/services':
            self._get_services()
        elif path == '/storage/pools':
            self._get_storage_pools()
        elif path == '/storage/disks':
            self._get_disks()
        elif path == '/docker/containers':
            self._get_containers()
        else:
            self._set_headers(404)
            self.wfile.write(json.dumps({'error': 'Not found'}).encode())
    
    def _get_system_stats(self):
        """Get system statistics"""
        stats = {
            'cpu': self._get_cpu_usage(),
            'memory': self._get_memory_usage(),
            'storage': self._get_storage_usage(),
            'uptime': self._get_uptime()
        }
        self._set_headers()
        self.wfile.write(json.dumps(stats).encode())
    
    def _get_cpu_usage(self):
        try:
            with open('/proc/loadavg', 'r') as f:
                load = float(f.read().split()[0])
            cpu_count = os.cpu_count() or 1
            return min(100, int(load / cpu_count * 100))
        except:
            return 0
    
    def _get_memory_usage(self):
        try:
            with open('/proc/meminfo', 'r') as f:
                lines = f.readlines()
            mem = {}
            for line in lines:
                parts = line.split(':')
                if len(parts) == 2:
                    key = parts[0].strip()
                    value = int(parts[1].strip().split()[0])
                    mem[key] = value
            total = mem.get('MemTotal', 1)
            available = mem.get('MemAvailable', 0)
            used = total - available
            return int(used / total * 100)
        except:
            return 0
    
    def _get_storage_usage(self):
        try:
            stat = os.statvfs('/mnt/storage')
            total = stat.f_blocks * stat.f_frsize
            free = stat.f_bfree * stat.f_frsize
            used = total - free
            return int(used / total * 100) if total > 0 else 0
        except:
            return 0
    
    def _get_uptime(self):
        try:
            with open('/proc/uptime', 'r') as f:
                uptime_seconds = float(f.read().split()[0])
            days = int(uptime_seconds // 86400)
            hours = int((uptime_seconds % 86400) // 3600)
            return f"{days} days, {hours} hours"
        except:
            return "Unknown"
    
    def _get_services(self):
        """Get service statuses"""
        services = ['samba', 'nfs', 'docker', 'ssh', 'nginx']
        status = []
        for svc in services:
            running = self._check_service(svc)
            status.append({'name': svc, 'running': running})
        self._set_headers()
        self.wfile.write(json.dumps(status).encode())
    
    def _check_service(self, name):
        try:
            result = subprocess.run(['rc-service', name, 'status'], 
                                  capture_output=True, timeout=5)
            return result.returncode == 0
        except:
            return False
    
    def _get_storage_pools(self):
        """Get storage pool information"""
        pools = []
        # Check for ZFS pools
        try:
            result = subprocess.run(['zpool', 'list', '-H', '-o', 'name,size,alloc,free,health'],
                                  capture_output=True, text=True, timeout=10)
            for line in result.stdout.strip().split('\n'):
                if line:
                    parts = line.split('\t')
                    if len(parts) >= 5:
                        pools.append({
                            'name': parts[0],
                            'type': 'ZFS',
                            'size': parts[1],
                            'used': parts[2],
                            'free': parts[3],
                            'health': parts[4]
                        })
        except:
            pass
        
        self._set_headers()
        self.wfile.write(json.dumps(pools).encode())
    
    def _get_disks(self):
        """Get disk information"""
        disks = []
        try:
            result = subprocess.run(['lsblk', '-d', '-o', 'NAME,SIZE,TYPE,MODEL', '-J'],
                                  capture_output=True, text=True, timeout=10)
            data = json.loads(result.stdout)
            for device in data.get('blockdevices', []):
                if device.get('type') == 'disk':
                    disks.append({
                        'name': f"/dev/{device['name']}",
                        'size': device.get('size', 'Unknown'),
                        'model': device.get('model', 'Unknown')
                    })
        except:
            pass
        
        self._set_headers()
        self.wfile.write(json.dumps(disks).encode())
    
    def _get_containers(self):
        """Get Docker container information"""
        containers = []
        try:
            result = subprocess.run(['docker', 'ps', '--format', '{{json .}}'],
                                  capture_output=True, text=True, timeout=10)
            for line in result.stdout.strip().split('\n'):
                if line:
                    containers.append(json.loads(line))
        except:
            pass
        
        self._set_headers()
        self.wfile.write(json.dumps(containers).encode())

def run(port=8081):
    server = HTTPServer(('127.0.0.1', port), NASBoxAPI)
    print(f"NASBox API running on port {port}")
    server.serve_forever()

if __name__ == '__main__':
    run()
APIEOF
chmod +x "$ROOTFS_DIR/usr/local/bin/nasbox-api"

# Create API service
cat > "$ROOTFS_DIR/etc/init.d/nasbox-api" << 'EOF'
#!/sbin/openrc-run

name="NASBox API"
description="NASBox REST API Backend"

command="/usr/local/bin/nasbox-api"
command_background="yes"
pidfile="/var/run/nasbox-api.pid"
output_log="/var/log/nasbox/api.log"
error_log="/var/log/nasbox/api-error.log"

depend() {
    need net docker
}
EOF
chmod +x "$ROOTFS_DIR/etc/init.d/nasbox-api"

echo "GUI build complete"
