import Foundation

struct URLParser {
    /// Parse user input and return a complete URL
    /// - If it's a URL: normalize and return it
    /// - If it's a search query: return a Google search URL
    static func parse(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        
        // Check if it's a URL
        if isValidURL(trimmed) {
            return normalizeURL(trimmed)
        }
        
        // Otherwise treat as search query
        return googleSearchURL(for: trimmed)
    }
    
    /// Check if input appears to be a URL
    private static func isValidURL(_ input: String) -> Bool {
        // Check for common URL patterns
        if input.contains("://") {
            return true // Has protocol
        }
        
        if input.contains(".") {
            let parts = input.split(separator: "/")
            let domain = String(parts[0])
            
            // Check if it looks like a domain (has a dot)
            if domain.contains(".") {
                // Make sure it's not just a search query with a dot
                // (e.g., "machine learning" vs "example.com")
                let components = domain.split(separator: ".")
                
                // Valid domain should have reasonable parts
                if components.count >= 2 {
                    // Check if it looks like a real domain (not just words with dots)
                    for component in components {
                        if component.isEmpty {
                            return false
                        }
                    }
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Normalize a URL to ensure it's complete
    private static func normalizeURL(_ urlString: String) -> String {
        var url = urlString.trimmingCharacters(in: .whitespaces)
        
        // Add protocol if missing
        if !url.contains("://") {
            // Check if it starts with common domain indicators
            if url.lowercased().starts(with: "www.") || url.contains(".") {
                url = "https://" + url
            }
        }
        
        // Handle URLs without https when they should have it
        if url.lowercased().starts(with: "http://") || url.lowercased().starts(with: "https://") {
            return url
        }
        
        return url
    }
    
    /// Create a Google search URL for a query
    private static func googleSearchURL(for query: String) -> String {
        let encoded = query
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return "https://www.google.com/search?q=\(encoded)"
    }
}
