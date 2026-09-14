import SwiftUI

struct ContentView: View {
    @State private var showBrowser = false
    @State private var urlToLoad: String?
    
    var body: some View {
        ZStack {
            if showBrowser, let url = urlToLoad {
                BrowserView(
                    urlToLoad: url,
                    isShowing: $showBrowser,
                    onNewURL: { newURL in
                        urlToLoad = newURL
                    }
                )
                .transition(.move(edge: .trailing))
            } else {
                HomeScreen(
                    onSearch: { url in
                        urlToLoad = url
                        withAnimation {
                            showBrowser = true
                        }
                    }
                )
                .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showBrowser)
    }
}

#Preview {
    ContentView()
}
