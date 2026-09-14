# Desktop Browser - Architecture and Testing Guide

## Application Architecture

### High-Level Structure

```
┌─────────────────────────────────────────┐
│         DesktopBrowserApp (@main)       │
│         App entry point                 │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│           ContentView                    │
│  State management: showBrowser,         │
│  urlToLoad                              │
│  Routes to HomeScreen or BrowserView   │
└─────────────────┬─────────────────────┬─┘
         ┌────────┘                 ┌────┘
         ▼                          ▼
    ┌─────────────┐          ┌──────────────┐
    │ HomeScreen  │          │ BrowserView  │
    │             │          │              │
    │ • URLParser │          │ • WebViewMgr │
    │ • Google    │          │ • Navigation │
    │   search    │          │ • Progress   │
    └──────┬──────┘          │ • Error UI   │
           │                 └──────┬───────┘
           │                        │
           └────────────┬───────────┘
                        ▼
                ┌──────────────────┐
                │ WebViewManager   │
                │                  │
                │ • WKWebView      │
                │ • User-Agent     │
                │ • Navigation     │
                │ • Callbacks      │
                │ • Delegates      │
                └────────┬─────────┘
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
      ┌────────────────┐    ┌───────────────┐
      │  Navigation    │    │    UI         │
      │  Delegate      │    │  Delegate     │
      │                │    │               │
      │ • didStart()   │    │ • createNew() │
      │ • didFinish()  │    │ • popup()     │
      │ • didFail()    │    │               │
      └────────────────┘    └───────────────┘

                ▼
        ┌──────────────────┐
        │   WKWebView      │
        │                  │
        │  • Desktop UA    │
        │  • Cookies       │
        │  • Sessions      │
        │  • WebKit engine │
        └──────────────────┘
                ▼
        ┌──────────────────┐
        │  Network         │
        │  (HTTP/HTTPS)    │
        └──────────────────┘
```

### Module Responsibilities

#### 1. **DesktopBrowserApp.swift**
- **Purpose**: App entry point and scene setup
- **Responsibility**: Create window and root view
- **Key Code**: `@main` attribute marks this as app launch point
- **Dependencies**: None
- **Flow**: Launches → ContentView()

#### 2. **ContentView.swift**
- **Purpose**: Main navigation and state management
- **Responsibility**: Route between HomeScreen and BrowserView
- **Key State**:
  - `showBrowser`: Bool (which screen to show)
  - `urlToLoad`: String? (URL to load in browser)
- **Logic**: 
  - If showBrowser is false → show HomeScreen
  - If showBrowser is true → show BrowserView
- **Transitions**: Animated transition between views
- **Dependencies**: HomeScreen, BrowserView

#### 3. **HomeScreen.swift**
- **Purpose**: Search and URL input interface
- **Responsibility**: Get user input and prepare URLs for loading
- **Key State**:
  - `searchText`: Bound to text field
  - `isSearchFocused`: Auto-focuses keyboard on appear
- **Flow**:
  1. User types in search field
  2. User taps "Go" or presses return
  3. `URLParser.parse()` is called
  4. Result passed to `onSearch` callback
  5. ContentView updates state and shows BrowserView
- **UI Features**:
  - Rounded search bar with gradient background
  - Clear button (X) when text is entered
  - "Go" button (disabled when empty)
  - Example hints at bottom
  - Auto-keyboard focus
- **Dependencies**: URLParser

#### 4. **BrowserView.swift**
- **Purpose**: Browser interface and controls
- **Responsibility**: Show web content and browser controls
- **Key Components**:
  - Navigation buttons (back, forward, reload)
  - URL display bar
  - Home and share buttons
  - Progress indicator
  - WebViewContainer (UIViewRepresentable)
  - Error overlay
- **State Management**:
  - `webViewManager`: Manages WKWebView
  - `currentURL`: Displayed in address bar
  - `canGoBack/Forward`: Button disabled state
  - `isLoading`: Progress bar visibility
  - `loadingProgress`: Progress bar value
  - `showingError`: Error dialog visibility
- **Features**:
  - Interactive URL bar (user can edit and navigate)
  - Live progress feedback
  - Error recovery options
  - Share functionality
- **Dependencies**: WebViewManager, WebViewContainer, ErrorOverlay

#### 5. **WebViewManager.swift** ⭐ CORE COMPONENT
- **Purpose**: WKWebView configuration and management
- **Responsibility**: Force desktop mode and handle all web interactions
- **Desktop Mode Implementation**:
  ```swift
  // 1. Set desktop user-agent string
  let desktopUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)..."
  config.applicationNameForUserAgent = "Version/17.0 Safari/605.1.15"
  webView.customUserAgent = desktopUserAgent
  
  // 2. Set desktop content mode
  config.defaultWebpagePreferences.preferredContentMode = .desktop
  
  // 3. Apply to every request
  request.setValue(customAgent, forHTTPHeaderField: "User-Agent")
  ```
- **Key Methods**:
  - `load(url:)`: Load a URL with desktop UA applied
  - `goBack()`: Navigate to previous page
  - `goForward()`: Navigate to next page
  - `reload()`: Refresh current page
- **Callbacks** (called from delegates):
  - `onURLChange`: URL changed during navigation
  - `onLoadingChange`: Page started/finished loading
  - `onProgressChange`: Loading progress update
  - `onNavigationChange`: Back/forward availability changed
  - `onError`: Network or page error occurred
- **Delegates**:
  - `WebViewNavigationDelegate`: Navigation lifecycle
  - `WebViewUIDelegate`: UI events (new windows, etc.)
- **Key Features**:
  - Progress tracking via KVO observation
  - Error categorization and user-friendly messages
  - Cookie and session persistence
  - New window requests handled in current view
- **Dependencies**: WKWebView, URLRequest, Combine

#### 6. **URLParser.swift**
- **Purpose**: Parse user input and generate correct URLs
- **Key Functions**:
  - `parse(_:)`: Main entry point
    - Returns either normalized URL or Google search URL
  - `isValidURL(_:)`: Detect if input is a URL
    - Checks for `://` (explicit protocol)
    - Checks for `.` (domain indicator)
    - Validates domain structure
  - `normalizeURL(_:)`: Add protocol if missing
    - Adds `https://` to URLs without protocol
    - Returns URL as-is if already has protocol
  - `googleSearchURL(for:)`: Create Google search URL
    - URL-encodes query
    - Returns `https://www.google.com/search?q=QUERY`
- **Logic Examples**:
  - `amazon.com` → isValidURL=true → `https://amazon.com`
  - `weather today` → isValidURL=false → Google search
  - `https://example.com` → isValidURL=true → returned as-is
  - `www.test.co.uk` → isValidURL=true → `https://www.test.co.uk`
- **Dependencies**: Foundation only

### Data Flow

#### Flow 1: Load a Website
```
HomeScreen (user types "amazon.com")
    ↓
User taps "Go"
    ↓
URLParser.parse("amazon.com")
    ↓
Returns "https://amazon.com"
    ↓
onSearch callback invoked
    ↓
ContentView sets showBrowser=true, urlToLoad="https://amazon.com"
    ↓
BrowserView appears with urlToLoad parameter
    ↓
WebViewContainer created with manager and urlToLoad
    ↓
WebViewManager.load(url:) called
    ↓
URLRequest created with desktop User-Agent
    ↓
WKWebView.load(request:) executes
    ↓
WebKit makes HTTP request with desktop UA header
    ↓
Server responds with desktop HTML (not mobile)
    ↓
HTML renders in WKWebView on iPhone screen
```

#### Flow 2: Google Search
```
HomeScreen (user types "weather today")
    ↓
URLParser.parse("weather today")
    ↓
isValidURL returns false (no . or ://)
    ↓
googleSearchURL(for:) called
    ↓
Returns "https://www.google.com/search?q=weather+today"
    ↓
Rest is same as Flow 1
```

#### Flow 3: Navigation
```
BrowserView (user taps back button)
    ↓
onTap action: webViewManager?.goBack()
    ↓
WebViewManager.goBack() calls webView.goBack()
    ↓
WKWebView navigates to previous page
    ↓
WebViewNavigationDelegate.didStartProvisionalNavigation()
    ↓
onLoadingChange(true) callback fired
    ↓
BrowserView state updated: isLoading = true
    ↓
Progress indicator appears
    ↓
... page loads ...
    ↓
WebViewNavigationDelegate.didFinish()
    ↓
onLoadingChange(false) and onURLChange callbacks
    ↓
BrowserView updates: isLoading = false, currentURL updated
```

#### Flow 4: Error Handling
```
BrowserView loads invalid URL
    ↓
WKWebView makes request
    ↓
Network error occurs (no internet, DNS fail, etc.)
    ↓
WebViewNavigationDelegate.didFailNavigation() called
    ↓
WebViewManager.handleError(error) processes error
    ↓
Creates user-friendly message from NSError code
    ↓
onError callback fired with message
    ↓
BrowserView state: showingError = true, errorMessage = "..."
    ↓
ErrorOverlay appears with message
    ↓
User taps "Retry" → webViewManager?.reload()
    ↓
Or user taps "Home" → returns to HomeScreen
```

---

## Comprehensive Testing Guide

### Test Categories

#### 1. **URL Parsing Tests**

**Test 1.1: Valid URLs with Protocol**
```
Input: "https://www.apple.com"
Expected: "https://www.apple.com"
Status: Returns as-is ✓
```

**Test 1.2: Valid URLs without Protocol**
```
Input: "amazon.com"
Expected: "https://amazon.com"
Status: Adds https:// ✓
```

**Test 1.3: URLs with www**
```
Input: "www.github.com"
Expected: "https://www.github.com"
Status: Adds https:// ✓
```

**Test 1.4: Search Queries**
```
Input: "machine learning tutorials"
Expected: "https://www.google.com/search?q=machine+learning+tutorials"
Status: Google search URL ✓
```

**Test 1.5: Single Word Search**
```
Input: "weather"
Expected: "https://www.google.com/search?q=weather"
Status: Google search URL ✓
```

**Test 1.6: Query with Special Characters**
```
Input: "best pizza near me"
Expected: "https://www.google.com/search?q=best+pizza+near+me"
Status: URL encoded correctly ✓
```

---

#### 2. **Home Screen Tests**

**Test 2.1: Keyboard Auto-Focus**
- Launch app
- Expected: Text field is focused, keyboard appears
- Verify: Can type immediately without tapping

**Test 2.2: Clear Button**
- Type text in search field
- Expected: Clear (X) button appears
- Tap clear button
- Expected: Text field empties, button disappears

**Test 2.3: Go Button State**
- Empty search field
- Expected: "Go" button is disabled (grayed out)
- Type something
- Expected: "Go" button becomes enabled

**Test 2.4: Keyboard Return Action**
- Type "example.com" in field
- Press return key on keyboard
- Expected: Transitions to browser and loads the website

**Test 2.5: Go Button Tap**
- Type "google.com"
- Tap "Go" button
- Expected: Transitions to browser smoothly
- Verify: Website loads with desktop layout

---

#### 3. **Browser Navigation Tests**

**Test 3.1: Back Button Navigation**
- Load two websites (example.com → google.com)
- Tap back button
- Expected: Goes back to example.com
- Verify: URL bar updates, page renders

**Test 3.2: Forward Button Navigation**
- After test 3.1, load third site
- Tap back button twice
- Tap forward button
- Expected: Advances to previous page

**Test 3.3: Button Disabled State**
- Load a website
- Expected: Back button is disabled (grayed out)
- Note: Forward button should be enabled after going back
- Tap back button
- Expected: Forward button becomes enabled

**Test 3.4: Reload Button**
- Load website
- Modify URL bar to different site
- Tap reload button
- Expected: Current page reloads (doesn't navigate)
- Verify: URL bar unchanged

**Test 3.5: Reload During Loading**
- Load a slow website
- While loading, tap reload button
- Expected: Icon changes from circular arrow to X
- Tap reload again
- Expected: Page stops loading

---

#### 4. **Desktop Mode Tests**

**Test 4.1: Reddit Desktop View**
- Load: `reddit.com`
- Expected: Desktop version displays
- Verify: Wide content layout, desktop header
- Note: May need horizontal scroll on some elements

**Test 4.2: Twitter/X Desktop View**
- Load: `twitter.com`
- Expected: Desktop layout (if server delivers it)
- Note: Twitter may still show mobile due to JS detection
- This is expected behavior

**Test 4.3: Medium Desktop View**
- Load: `medium.com`
- Expected: Desktop article layout
- Verify: Full-width content area

**Test 4.4: Wikipedia Desktop**
- Load: `en.wikipedia.org`
- Expected: Desktop layout with sidebar
- Verify: Standard Wikipedia desktop interface

**Test 4.5: User Agent Verification**
- Load: `whoami.dev` or `whatismybrowser.com`
- Expected: Shows desktop Safari user agent
- Verify: Contains "Macintosh" and "Safari"
- Should NOT contain "iPhone" or "Mobile"

---

#### 5. **URL Bar Editing Tests**

**Test 5.1: Edit URL Bar**
- Load: `example.com`
- Tap on URL bar
- Clear and type: `google.com`
- Press return key
- Expected: Navigates to Google
- Verify: Loads without returning to home screen

**Test 5.2: Copy URL from Bar**
- Load website
- Long-press on URL bar
- Expected: Copy option appears
- Copy URL
- Open Notes app and paste
- Expected: URL is in clipboard

**Test 5.3: Paste URL into Bar**
- Copy some URL to clipboard
- Go to home screen
- Paste into search field
- Tap Go
- Expected: Website loads

---

#### 6. **Error Handling Tests**

**Test 6.1: Invalid Domain**
- Input: `thissitedoesnotexist-12345.com`
- Tap Go
- Expected: Error dialog appears
- Message: "Cannot find the website"
- Buttons: "Home" and "Retry"

**Test 6.2: Network Error (offline)**
- Disconnect iPhone from WiFi and disable cellular
- Try to load any website
- Expected: Error dialog appears
- Message: "No internet connection"
- Tap "Home" → returns to home screen

**Test 6.3: Connection Timeout**
- Try to load a server with slow response
- Wait for timeout
- Expected: Error dialog after ~30 seconds
- Message: "Connection timed out"
- Tap "Retry" to try again

**Test 6.4: Retry Button**
- Generate an error (bad URL)
- Error dialog appears
- Tap "Retry"
- Expected: Tries to load again (will fail again for same URL)

**Test 6.5: Home Button in Error**
- Error dialog is showing
- Tap "Home" button
- Expected: Returns to home screen
- URL bar clears
- Search field is focused

---

#### 7. **Share Button Tests**

**Test 7.1: Share Website**
- Load: `example.com`
- Tap share button
- Expected: Share sheet appears
- Options: Message, Mail, Copy, etc.

**Test 7.2: Share URL Format**
- Load website
- Tap share
- Share via Message or Mail
- Verify: Full URL is shared (not truncated)

---

#### 8. **Progress Indicator Tests**

**Test 8.1: Progress Bar Visibility**
- Load a website
- Expected: Progress bar appears while loading
- Verify: Bar grows as page loads
- When complete: Progress bar disappears

**Test 8.2: Fast Loading Sites**
- Load: `example.com` (loads quickly)
- Expected: Progress bar may appear briefly
- Verify: Doesn't linger after load completes

**Test 8.3: Slow Loading Sites**
- Load a slow-loading website
- Expected: Progress bar visible for several seconds
- Verify: Provides visual feedback

---

#### 9. **UI/UX Tests**

**Test 9.1: Dark Mode**
- Enable Dark Mode in Settings
- Launch or restart app
- Expected: All colors invert appropriately
- Verify: Text readable, buttons visible

**Test 9.2: Light Mode**
- Disable Dark Mode
- Restart app
- Expected: Light background, dark text
- Verify: High contrast, readable

**Test 9.3: Different iPhone Sizes**
- Test on iPhone 12 (6.1")
- Test on iPhone SE (4.7")
- Test on iPhone 14 Pro Max (6.7")
- Expected: Layout adapts to screen size
- Verify: No cut-off buttons or text

**Test 9.4: Orientation Changes**
- Load website in portrait
- Rotate to landscape
- Expected: Layout adjusts (browser controls stay accessible)
- Rotate back to portrait
- Expected: Returns to portrait layout

**Test 9.5: Safe Area Handling**
- Test on iPhone with notch
- Test on iPhone 15 Pro with Dynamic Island
- Expected: Content doesn't overlap notch/island
- Verify: All controls remain visible

---

#### 10. **Session & Cookie Tests**

**Test 10.1: Login Persistence**
- Load: `github.com`
- Click login
- Enter credentials and log in
- Navigate to another page on GitHub
- Go back
- Expected: Still logged in (session persists)

**Test 10.2: Form Data Persistence**
- Load: `example.com/form`
- Fill out a form
- Navigate away
- Go back (using back button)
- Expected: Form data may be pre-filled (browser behavior)

**Test 10.3: Multiple Sites with Sessions**
- Load Site A, log in
- Navigate to Site B
- Navigate back to Site A
- Expected: Still logged into Site A
- Navigate to Site B
- Expected: Site B still logged in

---

#### 11. **Performance Tests**

**Test 11.1: Memory Usage**
- Load several websites sequentially
- Tap home and load more sites
- Expected: No crashes
- Verify: App remains responsive

**Test 11.2: Rapid Navigation**
- Quickly tap back button multiple times
- Expected: Handles rapid navigation smoothly
- No freezing or crashes

**Test 11.3: Large Page Loading**
- Load Wikipedia main page (large)
- Expected: Loads without excessive delay
- Verify: Scrolling is smooth

---

#### 12. **Download/Upload Tests**

**Test 12.1: File Upload**
- Find a website with file upload
- Tap upload button
- Expected: File picker appears
- Select file
- Expected: File uploads to website

**Test 12.2: Download**
- Navigate to a downloadable file
- Tap download link
- Expected: Browser handles download
- Note: iOS restricts where downloads save

---

## Automated Testing Recommendations

### Unit Tests (Add to DesktopBrowserTests)

```swift
// Test URLParser
func testURLParsingDomain() {
    let result = URLParser.parse("amazon.com")
    XCTAssertEqual(result, "https://amazon.com")
}

func testURLParsingSearchQuery() {
    let result = URLParser.parse("weather today")
    XCTAssert(result.contains("google.com/search"))
}

func testURLParsingWithProtocol() {
    let result = URLParser.parse("https://example.com")
    XCTAssertEqual(result, "https://example.com")
}
```

### UI Tests

```swift
// Test UI Flow
func testHomeScreenToWebView() {
    let app = XCUIApplication()
    app.launch()
    
    let searchField = app.textFields["Search or enter URL"]
    searchField.typeText("example.com")
    
    app.buttons["Go"].tap()
    
    XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 5))
}
```

---

## Test Checklist

Before releasing, verify all of these pass:

- [ ] URL parsing works correctly
- [ ] Home screen appears on launch
- [ ] Search field is auto-focused
- [ ] Go button works
- [ ] Website loads in desktop mode
- [ ] Back button navigates
- [ ] Forward button navigates
- [ ] Reload refreshes page
- [ ] Home button returns to search
- [ ] Share button works
- [ ] Progress bar appears
- [ ] Error handling works
- [ ] Dark mode works
- [ ] Light mode works
- [ ] Different screen sizes work
- [ ] Orientation changes handled
- [ ] Sessions are persistent
- [ ] No crashes during navigation
- [ ] Desktop user-agent is applied
- [ ] Keyboard works correctly

---

## Known Limitations to Test Against

1. **JavaScript Mobile Detection**: Some sites detect mobile via viewport size regardless of UA
2. **Server-Side Detection**: Some servers detect device via IP or other methods
3. **SSL Self-Signed Certificates**: Will show error (by design)
4. **Pop-Ups**: Handled in current view (won't create new windows)
5. **Some Video Formats**: Depending on codec support

---

## Performance Benchmarks

Target performance metrics:

| Metric | Target |
|--------|--------|
| App Launch | < 2 seconds |
| Website Load | < 5 seconds (varies by site) |
| Navigation Response | < 300ms |
| Memory Usage | < 150MB average |
| Scrolling FPS | 60 FPS |

---

This comprehensive guide ensures the Desktop Browser app functions correctly across all scenarios.
