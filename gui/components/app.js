/**
 * NASBox GUI - Main Application JavaScript
 * Lightweight management interface for NAS
 */

class NASBoxApp {
    constructor() {
        this.currentPage = 'dashboard';
        this.theme = localStorage.getItem('nasbox-theme') || 'dark';
        this.apiBase = '/api/v1';
        this.init();
    }

    init() {
        this.applyTheme(this.theme);
        this.bindEvents();
        this.startSystemMonitoring();
        this.loadPage(this.currentPage);
    }

    // Theme Management
    applyTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
        const themeToggle = document.getElementById('themeToggle');
        if (themeToggle) {
            themeToggle.textContent = theme === 'dark' ? '☀️' : '🌙';
        }
        localStorage.setItem('nasbox-theme', theme);
    }

    toggleTheme() {
        this.theme = this.theme === 'dark' ? 'light' : 'dark';
        this.applyTheme(this.theme);
    }

    // Event Bindings
    bindEvents() {
        // Theme toggle
        const themeToggle = document.getElementById('themeToggle');
        if (themeToggle) {
            themeToggle.addEventListener('click', () => this.toggleTheme());
        }

        // Mobile menu toggle
        const menuToggle = document.getElementById('menuToggle');
        const sidebar = document.getElementById('sidebar');
        if (menuToggle && sidebar) {
            menuToggle.addEventListener('click', () => {
                sidebar.classList.toggle('open');
            });
        }

        // Navigation
        const navItems = document.querySelectorAll('.nav-item');
        navItems.forEach(item => {
            item.addEventListener('click', () => {
                const page = item.dataset.page;
                this.navigateTo(page);
            });
        });

        // Service buttons
        document.querySelectorAll('.service-item .btn-small').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const serviceName = e.target.closest('.service-item').querySelector('.service-name').textContent;
                const action = e.target.textContent.toLowerCase();
                this.controlService(serviceName, action);
            });
        });
    }

    // Navigation
    navigateTo(page) {
        // Update active state
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
            if (item.dataset.page === page) {
                item.classList.add('active');
            }
        });

        // Update title
        const pageTitle = document.getElementById('pageTitle');
        if (pageTitle) {
            pageTitle.textContent = page.charAt(0).toUpperCase() + page.slice(1);
        }

        // Close mobile menu
        const sidebar = document.getElementById('sidebar');
        if (sidebar) {
            sidebar.classList.remove('open');
        }

        this.currentPage = page;
        this.loadPage(page);
    }

    // Page Loading
    async loadPage(page) {
        const content = document.getElementById('content');
        if (!content) return;

        switch (page) {
            case 'dashboard':
                this.loadDashboard();
                break;
            case 'storage':
                this.loadStoragePage();
                break;
            case 'shares':
                this.loadSharesPage();
                break;
            case 'docker':
                this.loadDockerPage();
                break;
            case 'network':
                this.loadNetworkPage();
                break;
            case 'users':
                this.loadUsersPage();
                break;
            case 'system':
                this.loadSystemPage();
                break;
        }
    }

    // Dashboard
    loadDashboard() {
        // Dashboard is loaded by default in HTML
        this.updateSystemStats();
    }

    // System Monitoring
    startSystemMonitoring() {
        // Update every 5 seconds
        this.updateSystemStats();
        setInterval(() => this.updateSystemStats(), 5000);
    }

    async updateSystemStats() {
        try {
            // In production, these would be API calls
            // For demo, using simulated values
            const stats = await this.getSystemStats();
            
            this.updateProgressRing('cpuValue', stats.cpu);
            this.updateProgressRing('memValue', stats.memory);
            this.updateProgressRing('storageValue', stats.storage);
            
            document.getElementById('netDown').textContent = stats.networkDown;
            document.getElementById('netUp').textContent = stats.networkUp;
        } catch (error) {
            console.error('Failed to update system stats:', error);
        }
    }

    updateProgressRing(elementId, value) {
        const element = document.getElementById(elementId);
        if (element) {
            element.textContent = `${value}%`;
            const ring = element.closest('.progress-ring');
            if (ring) {
                ring.style.setProperty('--progress', value);
            }
        }
    }

    async getSystemStats() {
        // API call would go here
        // return await fetch(`${this.apiBase}/system/stats`).then(r => r.json());
        
        // Demo values with slight random variation
        return {
            cpu: Math.floor(20 + Math.random() * 15),
            memory: Math.floor(40 + Math.random() * 10),
            storage: 62,
            networkDown: `${Math.floor(100 + Math.random() * 50)} MB/s`,
            networkUp: `${Math.floor(30 + Math.random() * 30)} MB/s`
        };
    }

    // Service Control
    async controlService(serviceName, action) {
        try {
            console.log(`${action}ing ${serviceName}...`);
            // await fetch(`${this.apiBase}/services/${serviceName}/${action}`, { method: 'POST' });
            this.showNotification(`${serviceName} ${action} initiated`, 'success');
        } catch (error) {
            this.showNotification(`Failed to ${action} ${serviceName}`, 'error');
        }
    }

    // Page Templates
    loadStoragePage() {
        const content = document.getElementById('content');
        content.innerHTML = `
            <section class="page-section">
                <div class="section-header">
                    <h3>Storage Pools</h3>
                    <button class="btn-primary">+ Create Pool</button>
                </div>
                <div class="storage-pools">
                    <div class="pool-card">
                        <div class="pool-header">
                            <h4>Main Storage</h4>
                            <span class="pool-type">RAID 5</span>
                        </div>
                        <div class="pool-usage">
                            <div class="usage-bar" style="--usage: 62%"></div>
                            <span>6.2 TB / 10 TB</span>
                        </div>
                        <div class="pool-disks">
                            <span>Disks: /dev/sda, /dev/sdb, /dev/sdc</span>
                        </div>
                        <div class="pool-actions">
                            <button class="btn-small">Manage</button>
                            <button class="btn-small">Scrub</button>
                        </div>
                    </div>
                </div>
            </section>
            
            <section class="page-section">
                <div class="section-header">
                    <h3>Available Disks</h3>
                    <button class="btn-secondary">Scan Disks</button>
                </div>
                <div class="disks-list">
                    <div class="disk-item">
                        <span class="disk-icon">💿</span>
                        <div class="disk-info">
                            <strong>/dev/sdd</strong>
                            <span>Seagate IronWolf 4TB - Unassigned</span>
                        </div>
                        <button class="btn-small">Add to Pool</button>
                    </div>
                </div>
            </section>
        `;
    }

    loadSharesPage() {
        const content = document.getElementById('content');
        content.innerHTML = `
            <section class="page-section">
                <div class="section-header">
                    <h3>Network Shares</h3>
                    <button class="btn-primary">+ Create Share</button>
                </div>
                <div class="shares-table">
                    <table>
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Path</th>
                                <th>Protocol</th>
                                <th>Access</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>Documents</td>
                                <td>/mnt/storage/documents</td>
                                <td>SMB, NFS</td>
                                <td>Read/Write</td>
                                <td><button class="btn-small">Edit</button></td>
                            </tr>
                            <tr>
                                <td>Media</td>
                                <td>/mnt/storage/media</td>
                                <td>SMB</td>
                                <td>Read Only</td>
                                <td><button class="btn-small">Edit</button></td>
                            </tr>
                            <tr>
                                <td>Backups</td>
                                <td>/mnt/storage/backups</td>
                                <td>NFS</td>
                                <td>Read/Write</td>
                                <td><button class="btn-small">Edit</button></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </section>
        `;
    }

    loadDockerPage() {
        const content = document.getElementById('content');
        content.innerHTML = `
            <section class="page-section">
                <div class="section-header">
                    <h3>Running Containers</h3>
                    <button class="btn-primary">+ Deploy Container</button>
                </div>
                <div class="containers-grid">
                    <div class="container-card running">
                        <div class="container-status"></div>
                        <div class="container-info">
                            <h4>Portainer</h4>
                            <span>portainer/portainer-ce:latest</span>
                            <div class="container-stats">
                                <span>CPU: 2%</span>
                                <span>RAM: 45 MB</span>
                            </div>
                        </div>
                        <div class="container-actions">
                            <button class="btn-icon" title="Open">🔗</button>
                            <button class="btn-icon" title="Restart">🔄</button>
                            <button class="btn-icon" title="Stop">⏹️</button>
                        </div>
                    </div>
                    <div class="container-card running">
                        <div class="container-status"></div>
                        <div class="container-info">
                            <h4>Jellyfin</h4>
                            <span>jellyfin/jellyfin:latest</span>
                            <div class="container-stats">
                                <span>CPU: 8%</span>
                                <span>RAM: 256 MB</span>
                            </div>
                        </div>
                        <div class="container-actions">
                            <button class="btn-icon" title="Open">🔗</button>
                            <button class="btn-icon" title="Restart">🔄</button>
                            <button class="btn-icon" title="Stop">⏹️</button>
                        </div>
                    </div>
                </div>
            </section>
            
            <section class="page-section">
                <div class="section-header">
                    <h3>App Store</h3>
                </div>
                <div class="apps-grid">
                    <div class="app-card">
                        <span class="app-icon">📺</span>
                        <h4>Plex</h4>
                        <p>Media Server</p>
                        <button class="btn-primary">Install</button>
                    </div>
                    <div class="app-card">
                        <span class="app-icon">☁️</span>
                        <h4>Nextcloud</h4>
                        <p>Personal Cloud</p>
                        <button class="btn-primary">Install</button>
                    </div>
                    <div class="app-card">
                        <span class="app-icon">🏠</span>
                        <h4>Home Assistant</h4>
                        <p>Home Automation</p>
                        <button class="btn-primary">Install</button>
                    </div>
                    <div class="app-card">
                        <span class="app-icon">🛡️</span>
                        <h4>Pi-hole</h4>
                        <p>Ad Blocker</p>
                        <button class="btn-primary">Install</button>
                    </div>
                </div>
            </section>
        `;
    }

    loadNetworkPage() {
        const content = document.getElementById('content');
        content.innerHTML = `
            <section class="page-section">
                <div class="section-header">
                    <h3>Network Interfaces</h3>
                </div>
                <div class="interfaces-list">
                    <div class="interface-card">
                        <div class="interface-header">
                            <h4>eth0</h4>
                            <span class="status-badge connected">Connected</span>
                        </div>
                        <div class="interface-details">
                            <div><strong>IP:</strong> 192.168.1.100</div>
                            <div><strong>MAC:</strong> 00:11:22:33:44:55</div>
                            <div><strong>Speed:</strong> 1 Gbps</div>
                        </div>
                        <button class="btn-small">Configure</button>
                    </div>
                </div>
            </section>
            
            <section class="page-section">
                <div class="section-header">
                    <h3>DNS Settings</h3>
                </div>
                <div class="form-group">
                    <label>Primary DNS</label>
                    <input type="text" value="1.1.1.1" class="form-input">
                </div>
                <div class="form-group">
                    <label>Secondary DNS</label>
                    <input type="text" value="8.8.8.8" class="form-input">
                </div>
                <button class="btn-primary">Save DNS Settings</button>
            </section>
        `;
    }

    loadUsersPage() {
        const content = document.getElementById('content');
        content.innerHTML = `
            <section class="page-section">
                <div class="section-header">
                    <h3>Users</h3>
                    <button class="btn-primary">+ Add User</button>
                </div>
                <div class="users-table">
                    <table>
                        <thead>
                            <tr>
                                <th>Username</th>
                                <th>Full Name</th>
                                <th>Groups</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>admin</td>
                                <td>Administrator</td>
                                <td>admin, docker, storage</td>
                                <td><span class="status-badge active">Active</span></td>
                                <td><button class="btn-small">Edit</button></td>
                            </tr>
                            <tr>
                                <td>user1</td>
                                <td>John Doe</td>
                                <td>users, media</td>
                                <td><span class="status-badge active">Active</span></td>
                                <td><button class="btn-small">Edit</button></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </section>
            
            <section class="page-section">
                <div class="section-header">
                    <h3>Groups</h3>
                    <button class="btn-secondary">+ Add Group</button>
                </div>
                <div class="groups-list">
                    <div class="group-item">
                        <span>admin</span>
                        <span class="member-count">1 member</span>
                    </div>
                    <div class="group-item">
                        <span>users</span>
                        <span class="member-count">2 members</span>
                    </div>
                    <div class="group-item">
                        <span>media</span>
                        <span class="member-count">1 member</span>
                    </div>
                </div>
            </section>
        `;
    }

    loadSystemPage() {
        const content = document.getElementById('content');
        content.innerHTML = `
            <section class="page-section">
                <div class="section-header">
                    <h3>System Information</h3>
                </div>
                <div class="system-info-grid">
                    <div class="info-item">
                        <label>Hostname</label>
                        <span>nasbox.local</span>
                    </div>
                    <div class="info-item">
                        <label>NASBox Version</label>
                        <span>1.0.0</span>
                    </div>
                    <div class="info-item">
                        <label>Kernel</label>
                        <span>6.6.0-nasbox</span>
                    </div>
                    <div class="info-item">
                        <label>Uptime</label>
                        <span id="uptime">14 days, 3 hours</span>
                    </div>
                </div>
            </section>
            
            <section class="page-section">
                <div class="section-header">
                    <h3>System Actions</h3>
                </div>
                <div class="action-buttons">
                    <button class="btn-secondary">Check Updates</button>
                    <button class="btn-secondary">Backup Settings</button>
                    <button class="btn-secondary">Restore Settings</button>
                    <button class="btn-warning">Reboot</button>
                    <button class="btn-danger">Shutdown</button>
                </div>
            </section>
            
            <section class="page-section">
                <div class="section-header">
                    <h3>System Logs</h3>
                </div>
                <div class="logs-viewer">
                    <pre id="logsContent">[2024-01-15 10:30:45] System started
[2024-01-15 10:30:46] Docker service started
[2024-01-15 10:30:47] Samba service started
[2024-01-15 10:30:48] NFS service started
[2024-01-15 10:30:50] Web GUI started on port 8080</pre>
                </div>
            </section>
        `;
    }

    // Notifications
    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.textContent = message;
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.classList.add('show');
        }, 10);
        
        setTimeout(() => {
            notification.classList.remove('show');
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    }
}

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.nasbox = new NASBoxApp();
});
