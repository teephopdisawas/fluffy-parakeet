/**
 * NASBox GUI - Main Application JavaScript
 * Lightweight management interface for NAS
 * Modern multi-theme support with optimized performance
 */

class NASBoxApp {
    // Allowed theme values for security
    static ALLOWED_THEMES = ['dark', 'light', 'ocean', 'forest', 'sunset', 'midnight', 'contrast'];
    
    // Cache for DOM elements and API responses
    static CACHE_TTL = 5000; // 5 seconds cache TTL
    
    constructor() {
        this.currentPage = 'dashboard';
        // Validate theme from localStorage against allowed values
        const storedTheme = localStorage.getItem('nasbox-theme');
        this.theme = NASBoxApp.ALLOWED_THEMES.includes(storedTheme) ? storedTheme : 'dark';
        this.apiBase = '/api/v1';
        this.cache = new Map();
        this.elementCache = new Map();
        this.monitoringInterval = null;
        this.init();
    }

    init() {
        this.applyTheme(this.theme);
        this.bindEvents();
        this.startSystemMonitoring();
        this.loadPage(this.currentPage);
    }
    
    // Cached getElementById for frequently accessed elements
    getElement(id) {
        if (!this.elementCache.has(id)) {
            this.elementCache.set(id, document.getElementById(id));
        }
        return this.elementCache.get(id);
    }
    
    // Debounce utility for performance-sensitive operations
    debounce(func, wait) {
        let timeout;
        return (...args) => {
            clearTimeout(timeout);
            timeout = setTimeout(() => func.apply(this, args), wait);
        };
    }

    // Theme Management
    applyTheme(theme) {
        // Validate theme value before applying
        if (!NASBoxApp.ALLOWED_THEMES.includes(theme)) {
            theme = 'dark';
        }
        document.documentElement.setAttribute('data-theme', theme);
        const themeSelect = this.getElement('themeSelect');
        if (themeSelect) {
            themeSelect.value = theme;
        }
        localStorage.setItem('nasbox-theme', theme);
        this.theme = theme;
    }

    setTheme(theme) {
        if (NASBoxApp.ALLOWED_THEMES.includes(theme)) {
            this.applyTheme(theme);
        }
    }

    // Event Bindings
    bindEvents() {
        // Theme selector dropdown - use cached element
        const themeSelect = this.getElement('themeSelect');
        if (themeSelect) {
            themeSelect.addEventListener('change', (e) => {
                this.setTheme(e.target.value);
            });
        }

        // Mobile menu toggle - use cached elements
        const menuToggle = this.getElement('menuToggle');
        const sidebar = this.getElement('sidebar');
        if (menuToggle && sidebar) {
            menuToggle.addEventListener('click', () => {
                sidebar.classList.toggle('open');
            });
        }

        // Navigation - use event delegation for efficiency
        const navMenu = document.querySelector('.nav-menu');
        if (navMenu) {
            navMenu.addEventListener('click', (e) => {
                const navItem = e.target.closest('.nav-item');
                if (navItem) {
                    const page = navItem.dataset.page;
                    this.navigateTo(page);
                }
            });
        }

        // Service buttons - use event delegation for efficiency
        const servicesSection = document.querySelector('.services-section');
        if (servicesSection) {
            servicesSection.addEventListener('click', (e) => {
                if (e.target.classList.contains('btn-small')) {
                    const serviceItem = e.target.closest('.service-item');
                    if (serviceItem) {
                        const serviceName = serviceItem.querySelector('.service-name').textContent;
                        const action = e.target.textContent.toLowerCase();
                        this.controlService(serviceName, action);
                    }
                }
            });
        }
    }

    // Navigation
    navigateTo(page) {
        // Update active state - use single querySelectorAll and cache result
        const navItems = document.querySelectorAll('.nav-item');
        navItems.forEach(item => {
            const isActive = item.dataset.page === page;
            item.classList.toggle('active', isActive);
        });

        // Update title - use cached element
        const pageTitle = this.getElement('pageTitle');
        if (pageTitle) {
            pageTitle.textContent = page.charAt(0).toUpperCase() + page.slice(1);
        }

        // Close mobile menu - use cached element
        const sidebar = this.getElement('sidebar');
        if (sidebar) {
            sidebar.classList.remove('open');
        }

        this.currentPage = page;
        this.loadPage(page);
    }

    // Page Loading
    async loadPage(page) {
        const content = this.getElement('content');
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
        // Clear any existing interval to prevent memory leaks
        if (this.monitoringInterval) {
            clearInterval(this.monitoringInterval);
        }
        // Update immediately
        this.updateSystemStats();
        // Update every 5 seconds
        this.monitoringInterval = setInterval(() => this.updateSystemStats(), 5000);
    }
    
    // Stop monitoring when page is hidden to save resources
    stopSystemMonitoring() {
        if (this.monitoringInterval) {
            clearInterval(this.monitoringInterval);
            this.monitoringInterval = null;
        }
    }

    async updateSystemStats() {
        try {
            // In production, these would be API calls
            // For demo, using simulated values
            const stats = await this.getSystemStats();
            
            // Batch DOM updates for efficiency
            requestAnimationFrame(() => {
                this.updateProgressRing('cpuValue', stats.cpu);
                this.updateProgressRing('memValue', stats.memory);
                this.updateProgressRing('storageValue', stats.storage);
                
                const netDown = this.getElement('netDown');
                const netUp = this.getElement('netUp');
                if (netDown) netDown.textContent = stats.networkDown;
                if (netUp) netUp.textContent = stats.networkUp;
            });
        } catch (error) {
            console.error('Failed to update system stats:', error);
        }
    }

    updateProgressRing(elementId, value) {
        const element = this.getElement(elementId);
        if (element) {
            element.textContent = `${value}%`;
            const ring = element.closest('.progress-ring');
            if (ring) {
                ring.style.setProperty('--progress', value);
            }
        }
    }

    async getSystemStats() {
        // Check cache first
        const cacheKey = 'systemStats';
        const cached = this.cache.get(cacheKey);
        if (cached && (Date.now() - cached.timestamp < NASBoxApp.CACHE_TTL)) {
            return cached.data;
        }
        
        // API call would go here in production
        // return await fetch(`${this.apiBase}/system/stats`).then(r => r.json());
        
        // Demo values with slight random variation
        const stats = {
            cpu: Math.floor(20 + Math.random() * 15),
            memory: Math.floor(40 + Math.random() * 10),
            storage: 62,
            networkDown: `${Math.floor(100 + Math.random() * 50)} MB/s`,
            networkUp: `${Math.floor(30 + Math.random() * 30)} MB/s`
        };
        
        // Cache the result
        this.cache.set(cacheKey, { data: stats, timestamp: Date.now() });
        return stats;
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
        const content = this.getElement('content');
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
        const content = this.getElement('content');
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
        const content = this.getElement('content');
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
        const content = this.getElement('content');
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
        const content = this.getElement('content');
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
        const content = this.getElement('content');
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
