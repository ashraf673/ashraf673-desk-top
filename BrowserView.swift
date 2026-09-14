import SwiftUI
import WebKit

struct BrowserView: View {
    let urlToLoad: String
    @Binding var isShowing: Bool
    let onNewURL: (String) -> Void
    
    @State private var webViewManager: WebViewManager?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var currentURL = ""
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false
    @State private var loadingProgress: Double = 0
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // URL/Address Bar
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        // Navigation buttons
                        HStack(spacing: 8) {
                            // Back button
                            Button(action: { webViewManager?.goBack() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            .disabled(!canGoBack)
                            .opacity(canGoBack ? 1 : 0.3)
                            
                            // Forward button
                            Button(action: { webViewManager?.goForward() }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            .disabled(!canGoForward)
                            .opacity(canGoForward ? 1 : 0.3)
                            
                            // Reload button
                            Button(action: { webViewManager?.reload() }) {
                                Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(width: 90, alignment: .leading)
                        
                        // URL Display
                        TextField("URL", text: $currentURL)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .submitLabel(.go)
                            .onSubmit {
                                if !currentURL.isEmpty {
                                    let url = URLParser.parse(currentURL)
                                    webViewManager?.load(url: url)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        
                        // Home button
                        Button(action: {
                            withAnimation {
                                isShowing = false
                            }
                        }) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        
                        // Share button
                        ShareLink(
                            item: URL(string: currentURL) ?? URL(string: "https://example.com")!,
                            subject: Text("Check this out"),
                            message: Text(currentURL)
                        ) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    
                    // Progress bar
                    if isLoading {
                        ProgressView(value: loadingProgress)
                            .frame(height: 2)
                            .padding(.horizontal, 12)
                    }
                }
                .background(Color(UIColor.systemBackground))
                .border(Color(UIColor.separator), width: 0.5)
                
                // Web View
                WebViewContainer(
                    manager: webViewManager ?? WebViewManager(),
                    urlToLoad: urlToLoad,
                    onURLChange: { url in
                        currentURL = url
                    },
                    onLoadingChange: { isLoading in
                        self.isLoading = isLoading
                    },
                    onProgressChange: { progress in
                        self.loadingProgress = progress
                    },
                    onNavigationChange: { canBack, canForward in
                        self.canGoBack = canBack
                        self.canGoForward = canForward
                    },
                    onError: { message in
                        self.errorMessage = message
                        self.showingError = true
                    }
                )
                .ignoresSafeArea(edges: .bottom)
            }
            
            // Error overlay
            if showingError {
                ErrorOverlay(
                    message: errorMessage,
                    onDismiss: { showingError = false },
                    onRetry: { webViewManager?.reload() },
                    onHome: {
                        showingError = false
                        withAnimation {
                            isShowing = false
                        }
                    }
                )
            }
        }
        .onAppear {
            if webViewManager == nil {
                webViewManager = WebViewManager()
                webViewManager?.load(url: urlToLoad)
            }
        }
    }
}

// MARK: - Web View Container

struct WebViewContainer: UIViewRepresentable {
    let manager: WebViewManager
    let urlToLoad: String
    let onURLChange: (String) -> Void
    let onLoadingChange: (Bool) -> Void
    let onProgressChange: (Double) -> Void
    let onNavigationChange: (Bool, Bool) -> Void
    let onError: (String) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = manager.webView
        manager.onURLChange = onURLChange
        manager.onLoadingChange = onLoadingChange
        manager.onProgressChange = onProgressChange
        manager.onNavigationChange = onNavigationChange
        manager.onError = onError
        
        // Load the URL
        manager.load(url: urlToLoad)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Update if needed
    }
}

// MARK: - Error Overlay

struct ErrorOverlay: View {
    let message: String
    let onDismiss: () -> Void
    let onRetry: () -> Void
    let onHome: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                
                Text("Unable to Load")
                    .font(.system(size: 18, weight: .bold))
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(5)
                
                HStack(spacing: 12) {
                    Button(action: onHome) {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                    
                    Button(action: onRetry) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Retry")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(24)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .padding(32)
        }
    }
}

#Preview {
    BrowserView(
        urlToLoad: "https://www.apple.com",
        isShowing: .constant(true),
        onNewURL: { _ in }
    )
}
