import SwiftUI

struct HomeScreen: View {
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    let onSearch: (String) -> Void
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(UIColor.systemBackground),
                    Color(UIColor.secondarySystemBackground)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header spacer
                VStack {
                    Spacer()
                        .frame(height: 40)
                    
                    // Logo/Title
                    VStack(spacing: 16) {
                        Image(systemName: "globe")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("Desktop Browser")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                        .frame(height: 60)
                }
                
                // Search bar container
                VStack(spacing: 20) {
                    // URL/Search input
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        TextField("Search or enter URL", text: $searchText)
                            .focused($isSearchFocused)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .submitLabel(.go)
                            .onSubmit {
                                performSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color.blue.opacity(isSearchFocused ? 1 : 0),
                                lineWidth: 2
                            )
                    )
                    .padding(.horizontal, 16)
                    
                    // Go/Search Button
                    Button(action: performSearch) {
                        HStack {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Go")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(searchText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                }
                .padding(.vertical, 32)
                
                Spacer()
                
                // Quick tips
                VStack(spacing: 8) {
                    Text("Examples:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Label("amazon.com", systemImage: "link")
                            .font(.caption)
                        Label("weather today", systemImage: "magnifyingglass")
                            .font(.caption)
                        Label("https://example.com", systemImage: "safari")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isSearchFocused = true
                }
            }
        }
    }
    
    private func performSearch() {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let urlString = URLParser.parse(trimmed)
        onSearch(urlString)
    }
}

#Preview {
    HomeScreen(onSearch: { _ in })
}
