import WebKit
import Combine

class WebViewManager: NSObject, ObservableObject {
    let webView: WKWebView
    private let navigationDelegate: WebViewNavigationDelegate
    private let uiDelegate: WebViewUIDelegate
    private weak var progressObserver: NSKeyValueObservation?
    
    // Callbacks
    var onURLChange: ((String) -> Void)?
    var onLoadingChange: ((Bool) -> Void)?
    var onProgressChange: ((Double) -> Void)?
    var onNavigationChange: ((Bool, Bool) -> Void)?
    var onError: ((String) -> Void)?
    
    override init() {
        // Create web view configuration with desktop settings
        let config = WKWebViewConfiguration()
        
        // Set desktop User-Agent
        // This is a modern desktop Safari user agent that will make websites
        // deliver their desktop versions
        let desktopUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        config.applicationNameForUserAgent = "Version/17.0 Safari/605.1.15"
        
        // Configure for desktop browsing
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.preferences.minimumFontSize = 0
        config.defaultWebpagePreferences.preferredContentMode = .desktop
        
        // Enable features
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.allowsAirPlayMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Initialize web view
        self.webView = WKWebView(frame: .zero, configuration: config)
        
        // Setup delegates
        self.navigationDelegate = WebViewNavigationDelegate()
        self.uiDelegate = WebViewUIDelegate()
        
        super.init()
        
        self.webView.navigationDelegate = self.navigationDelegate
        self.webView.uiDelegate = self.uiDelegate
        
        // Set custom user agent
        self.webView.customUserAgent = desktopUserAgent
        
        // Setup progress monitoring
        setupProgressMonitoring()
        
        // Setup callbacks
        setupCallbacks()
    }
    
    private func setupProgressMonitoring() {
        progressObserver = webView.observe(
            \.estimatedProgress,
            options: .new
        ) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.onProgressChange?(self?.webView.estimatedProgress ?? 0)
            }
        }
    }
    
    private func setupCallbacks() {
        navigationDelegate.onDidStartProvisionalNavigation = { [weak self] in
            DispatchQueue.main.async {
                self?.onLoadingChange?(true)
                self?.onProgressChange?(0.1)
            }
        }
        
        navigationDelegate.onDidFinishNavigation = { [weak self] in
            DispatchQueue.main.async {
                self?.onLoadingChange?(false)
                self?.onProgressChange?(1.0)
                self?.updateNavigation()
                self?.updateURL()
            }
        }
        
        navigationDelegate.onDidFailNavigation = { [weak self] error in
            DispatchQueue.main.async {
                self?.onLoadingChange?(false)
                self?.handleError(error)
            }
        }
        
        navigationDelegate.onDidFailProvisionalNavigation = { [weak self] error in
            DispatchQueue.main.async {
                self?.onLoadingChange?(false)
                self?.handleError(error)
            }
        }
        
        uiDelegate.onCreateNewWebView = { [weak self] in
            // Return the same web view to handle new windows in current view
            return self?.webView
        }
    }
    
    func load(url: String) {
        guard let url = URL(string: url) else {
            onError?("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        
        // Ensure desktop user agent is applied to every request
        if let customAgent = webView.customUserAgent {
            request.setValue(customAgent, forHTTPHeaderField: "User-Agent")
        }
        
        webView.load(request)
    }
    
    func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    func reload() {
        webView.reload()
    }
    
    private func updateNavigation() {
        onNavigationChange?(webView.canGoBack, webView.canGoForward)
    }
    
    private func updateURL() {
        if let url = webView.url?.absoluteString {
            onURLChange?(url)
        }
    }
    
    private func handleError(_ error: Error) {
        let nsError = error as NSError
        
        // Filter out common non-critical errors
        if nsError.code == NSURLErrorCancelled {
            return
        }
        
        let message: String
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet:
            message = "No internet connection"
        case NSURLErrorTimedOut:
            message = "Connection timed out"
        case NSURLErrorServerCertificateUntrusted,
             NSURLErrorServerCertificateHasBadDate,
             NSURLErrorServerCertificateHasUnknownRoot,
             NSURLErrorServerCertificateNotYetValid:
            message = "Certificate error - the website may not be secure"
        case NSURLErrorCannotFindHost:
            message = "Cannot find the website"
        case NSURLErrorCannotConnectToHost:
            message = "Cannot connect to the website"
        default:
            message = error.localizedDescription.isEmpty ? "Unknown error" : error.localizedDescription
        }
        
        onError?(message)
    }
}

// MARK: - Navigation Delegate

class WebViewNavigationDelegate: NSObject, WKNavigationDelegate {
    var onDidStartProvisionalNavigation: (() -> Void)?
    var onDidFinishNavigation: (() -> Void)?
    var onDidFailNavigation: ((Error) -> Void)?
    var onDidFailProvisionalNavigation: ((Error) -> Void)?
    
    func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation!
    ) {
        onDidStartProvisionalNavigation?()
    }
    
    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        onDidFinishNavigation?()
    }
    
    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        onDidFailNavigation?(error)
    }
    
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        onDidFailProvisionalNavigation?(error)
    }
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        // Allow all navigation responses
        decisionHandler(.allow)
    }
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        // Allow all navigation actions (link clicks, form submissions, etc.)
        decisionHandler(.allow)
    }
}

// MARK: - UI Delegate

class WebViewUIDelegate: NSObject, WKUIDelegate {
    var onCreateNewWebView: (() -> WKWebView?)?
    
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures!
    ) -> WKWebView? {
        // Handle new window requests by opening in the same view
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
