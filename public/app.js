// Desktop Browser Web Application
// Handles URL parsing, navigation, and browser functionality

class DesktopBrowser {
    constructor() {
        this.currentURL = '';
        this.history = [];
        this.historyIndex = -1;
        this.isLoading = false;

        this.initializeElements();
        this.attachEventListeners();
        this.focusSearchInput();
    }

    // Initialize DOM elements
    initializeElements() {
        // Search elements
        this.searchInput = document.getElementById('searchInput');
        this.clearBtn = document.getElementById('clearBtn');
        this.goBtn = document.getElementById('goBtn');
        this.searchSection = document.getElementById('searchSection');

        // Browser elements
        this.browserSection = document.getElementById('browserSection');
        this.backBtn = document.getElementById('backBtn');
        this.forwardBtn = document.getElementById('forwardBtn');
        this.reloadBtn = document.getElementById('reloadBtn');
        this.stopBtn = document.getElementById('stopBtn');
        this.urlBar = document.getElementById('urlBar');
        this.homeBtn = document.getElementById('homeBtn');
        this.shareBtn = document.getElementById('shareBtn');
        this.browserFrame = document.getElementById('browserFrame');
        this.progressBar = document.getElementById('progressBar');
        this.loadingIndicator = document.getElementById('loadingIndicator');
        this.errorScreen = document.getElementById('errorScreen');
        this.errorMessage = document.getElementById('errorMessage');
        this.errorRetryBtn = document.getElementById('errorRetryBtn');
        this.errorHomeBtn = document.getElementById('errorHomeBtn');

        // Modal elements
        this.aboutModal = document.getElementById('aboutModal');
        this.aboutBtn = document.getElementById('aboutBtn');
        this.closeAboutBtn = document.getElementById('closeAboutBtn');
    }

    // Attach event listeners
    attachEventListeners() {
        // Search section
        this.searchInput.addEventListener('input', () => this.handleSearchInput());
        this.searchInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.performSearch();
        });
        this.clearBtn.addEventListener('click', () => this.clearSearch());
        this.goBtn.addEventListener('click', () => this.performSearch());

        // Browser section
        this.backBtn.addEventListener('click', () => this.goBack());
        this.forwardBtn.addEventListener('click', () => this.goForward());
        this.reloadBtn.addEventListener('click', () => this.reload());
        this.stopBtn.addEventListener('click', () => this.stopLoading());
        this.homeBtn.addEventListener('click', () => this.goHome());
        this.shareBtn.addEventListener('click', () => this.shareURL());
        
        this.urlBar.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                const url = this.parseURL(this.urlBar.value);
                this.loadURL(url);
            }
        });

        // Error screen
        this.errorRetryBtn.addEventListener('click', () => this.retry());
        this.errorHomeBtn.addEventListener('click', () => this.goHome());

        // Modal
        this.aboutBtn.addEventListener('click', () => this.openAboutModal());
        this.closeAboutBtn.addEventListener('click', () => this.closeAboutModal());
        this.aboutModal.addEventListener('click', (e) => {
            if (e.target === this.aboutModal) this.closeAboutModal();
        });

        // iframe events
        this.browserFrame.addEventListener('load', () => this.onFrameLoad());
        this.browserFrame.addEventListener('error', () => this.onFrameError());

        // Listen for iframe messages
        window.addEventListener('message', (e) => this.handleFrameMessage(e));

        // Handle example clicks
        document.querySelectorAll('.example-item').forEach(item => {
            item.addEventListener('click', () => {
                const text = item.textContent.trim();
                this.searchInput.value = text;
                this.handleSearchInput();
                this.performSearch();
            });
        });
    }

    // ===== SEARCH SECTION HANDLERS =====

    handleSearchInput() {
        const hasText = this.searchInput.value.trim().length > 0;
        this.clearBtn.style.display = hasText ? 'flex' : 'none';
        this.goBtn.disabled = !hasText;
    }

    clearSearch() {
        this.searchInput.value = '';
        this.handleSearchInput();
        this.searchInput.focus();
    }

    performSearch() {
        const input = this.searchInput.value.trim();
        if (!input) return;

        const url = this.parseURL(input);
        this.loadURL(url);
    }

    // ===== URL PARSING =====

    /**
     * Parse user input and return a complete URL
     * If input looks like URL: normalize it
     * If input looks like search query: create Google search URL
     */
    parseURL(input) {
        const trimmed = input.trim();

        // Check if it's a URL
        if (this.isValidURL(trimmed)) {
            return this.normalizeURL(trimmed);
        }

        // Otherwise treat as search query
        return this.googleSearchURL(trimmed);
    }

    /**
     * Check if input appears to be a URL
     */
    isValidURL(input) {
        // Check for explicit protocol
        if (input.includes('://')) {
            return true;
        }

        // Check if it looks like a domain
        if (input.includes('.')) {
            const parts = input.split('/');
            const domain = parts[0];

            if (domain.includes('.')) {
                const components = domain.split('.');
                
                // Valid domain should have at least 2 parts with no empty parts
                if (components.length >= 2) {
                    for (let component of components) {
                        if (!component || component.length === 0) {
                            return false;
                        }
                    }
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * Normalize URL - add https:// if missing
     */
    normalizeURL(urlString) {
        let url = urlString.trim();

        // Already has protocol
        if (url.includes('://')) {
            return url;
        }

        // Add https:// protocol
        if (url.toLowerCase().startsWith('www.') || url.includes('.')) {
            return 'https://' + url;
        }

        return url;
    }

    /**
     * Create Google search URL
     */
    googleSearchURL(query) {
        const encoded = encodeURIComponent(query);
        return `https://www.google.com/search?q=${encoded}`;
    }

    // ===== BROWSER LOADING =====

    loadURL(url) {
        // Validate URL
        if (!url || url.trim() === '') {
            this.showError('Invalid URL');
            return;
        }

        // Store in history
        this.addToHistory(url);

        // Update UI
        this.currentURL = url;
        this.urlBar.value = url;

        // Show browser section
        this.searchSection.classList.remove('active');
        this.browserSection.classList.add('active');

        // Show loading indicator
        this.showLoading(true);
        this.hideError();
        this.progressBar.style.display = 'block';

        // Load through proxy
        this.loadThroughProxy(url);
    }

    /**
     * Load URL through proxy server to apply desktop user-agent
     */
    loadThroughProxy(url) {
        try {
            // Create proxy URL
            const proxyURL = `/api/proxy?url=${encodeURIComponent(url)}`;
            
            // Load into iframe
            this.browserFrame.src = proxyURL;
        } catch (error) {
            console.error('Error loading URL:', error);
            this.showError('Failed to load URL: ' + error.message);
        }
    }

    onFrameLoad() {
        this.showLoading(false);
        this.progressBar.style.display = 'none';
        this.updateNavigationButtons();
    }

    onFrameError() {
        this.showError('Failed to load website. The page may not be accessible.');
        this.showLoading(false);
    }

    handleFrameMessage(event) {
        // Handle messages from iframe if needed
        if (event.data && event.data.type === 'frameError') {
            this.showError(event.data.message);
        }
    }

    // ===== NAVIGATION =====

    goBack() {
        if (this.historyIndex > 0) {
            this.historyIndex--;
            const url = this.history[this.historyIndex];
            this.loadURL(url);
        }
    }

    goForward() {
        if (this.historyIndex < this.history.length - 1) {
            this.historyIndex++;
            const url = this.history[this.historyIndex];
            this.loadURL(url);
        }
    }

    reload() {
        if (this.currentURL) {
            this.showLoading(true);
            this.progressBar.style.display = 'block';
            this.browserFrame.src = `/api/proxy?url=${encodeURIComponent(this.currentURL)}`;
        }
    }

    stopLoading() {
        this.browserFrame.stop?.();
        this.showLoading(false);
        this.progressBar.style.display = 'none';
    }

    goHome() {
        this.searchSection.classList.add('active');
        this.browserSection.classList.remove('active');
        this.searchInput.value = '';
        this.handleSearchInput();
        this.focusSearchInput();
        this.hideError();
    }

    // ===== HISTORY =====

    addToHistory(url) {
        // If we're not at the end, remove forward history
        if (this.historyIndex < this.history.length - 1) {
            this.history = this.history.slice(0, this.historyIndex + 1);
        }

        // Don't add duplicate consecutive URLs
        if (this.history[this.history.length - 1] !== url) {
            this.history.push(url);
            this.historyIndex = this.history.length - 1;
        }

        // Limit history size
        if (this.history.length > 50) {
            this.history = this.history.slice(-50);
            this.historyIndex = this.history.length - 1;
        }

        this.updateNavigationButtons();
    }

    updateNavigationButtons() {
        this.backBtn.disabled = this.historyIndex <= 0;
        this.forwardBtn.disabled = this.historyIndex >= this.history.length - 1;
    }

    // ===== UI STATE =====

    showLoading(show) {
        this.isLoading = show;
        this.loadingIndicator.style.display = show ? 'flex' : 'none';
        this.stopBtn.style.display = show ? 'block' : 'none';
        this.reloadBtn.style.display = show ? 'none' : 'block';
    }

    showError(message) {
        this.errorMessage.textContent = message;
        this.errorScreen.style.display = 'flex';
    }

    hideError() {
        this.errorScreen.style.display = 'none';
    }

    retry() {
        if (this.currentURL) {
            this.reload();
        }
    }

    focusSearchInput() {
        setTimeout(() => {
            this.searchInput.focus();
        }, 100);
    }

    // ===== SHARING =====

    shareURL() {
        if (!this.currentURL) return;

        // Try native share API
        if (navigator.share) {
            navigator.share({
                title: 'Desktop Browser',
                text: 'Check out this website',
                url: this.currentURL
            }).catch(err => {
                if (err.name !== 'AbortError') {
                    this.fallbackShare();
                }
            });
        } else {
            this.fallbackShare();
        }
    }

    fallbackShare() {
        // Copy to clipboard
        navigator.clipboard.writeText(this.currentURL).then(() => {
            // Show temporary notification
            const originalText = this.shareBtn.textContent;
            this.shareBtn.textContent = 'Copied!';
            setTimeout(() => {
                this.shareBtn.textContent = originalText;
            }, 2000);
        }).catch(err => {
            console.error('Failed to copy:', err);
            alert('URL: ' + this.currentURL);
        });
    }

    // ===== MODAL =====

    openAboutModal() {
        this.aboutModal.style.display = 'flex';
    }

    closeAboutModal() {
        this.aboutModal.style.display = 'none';
    }
}

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.browser = new DesktopBrowser();
});

// Handle visibility changes
document.addEventListener('visibilitychange', () => {
    if (document.hidden && window.browser?.isLoading) {
        window.browser.stopLoading();
    }
});
