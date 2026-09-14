# Desktop Browser App - Complete Setup Instructions

Follow these step-by-step instructions to create and run the Desktop Browser iOS app in Xcode.

## Part 1: Create Xcode Project

### Step 1: Launch Xcode and Create New Project

1. Open **Xcode**
2. Click **File → New → Project** (or Cmd+Shift+N)
3. Select **iOS** at the top
4. Choose **App** template
5. Click **Next**

### Step 2: Configure Project Settings

Fill in the following settings:

| Setting | Value |
|---------|-------|
| **Product Name** | `DesktopBrowser` |
| **Team** | Your Apple Developer account (or "None") |
| **Organization Identifier** | `com.example` (or your domain) |
| **Bundle Identifier** | Auto-filled as `com.example.DesktopBrowser` |
| **Interface** | SwiftUI |
| **Language** | Swift |
| **Storage** | (leave unchecked) |
| **Use Core Data** | (leave unchecked) |
| **Include Tests** | (uncheck if you prefer) |

Click **Next** and choose a location to save the project.

### Step 3: Xcode Project Structure

After creation, your project structure should look like:

```
DesktopBrowser/
├── DesktopBrowser/
│   ├── DesktopBrowserApp.swift
│   ├── ContentView.swift
│   ├── Preview Content/
│   │   └── Preview Assets.xcassets
│   ├── Assets.xcassets
│   └── ... (other files)
├── DesktopBrowserTests/
├── DesktopBrowser.xcodeproj
└── (other project files)
```

## Part 2: Replace/Add Source Files

### Step 1: Replace Existing Files

Xcode auto-generates some files. Replace them:

#### 1. Replace `DesktopBrowserApp.swift`
- In Xcode, click `DesktopBrowserApp.swift` in the Project Navigator
- Delete the existing content
- Copy the entire content from our `DesktopBrowserApp.swift`
- Paste it in

#### 2. Replace `ContentView.swift`
- Click `ContentView.swift`
- Delete existing content
- Paste our `ContentView.swift`

### Step 2: Add New Swift Files

Create new Swift files by:
1. Right-click on the **DesktopBrowser** folder in Project Navigator
2. Select **New File** (or Cmd+N)
3. Choose **Swift File**
4. Name it and click **Create**
5. Add the content

**Create these files in order:**

#### File 1: `HomeScreen.swift`
- Create new file → name it `HomeScreen.swift`
- Paste the full content from our `HomeScreen.swift`

#### File 2: `BrowserView.swift`
- Create new file → name it `BrowserView.swift`
- Paste the full content from our `BrowserView.swift`

#### File 3: `WebViewManager.swift`
- Create new file → name it `WebViewManager.swift`
- Paste the full content from our `WebViewManager.swift`

#### File 4: `URLParser.swift`
- Create new file → name it `URLParser.swift`
- Paste the full content from our `URLParser.swift`

#### File 5: `SceneDelegate.swift`
- Create new file → name it `SceneDelegate.swift`
- Paste the full content from our `SceneDelegate.swift`

### Step 3: Update or Create Info.plist

**Option A: Update existing Info.plist**
1. Click **Info.plist** in Project Navigator
2. Right-click and select **Open As → Source Code**
3. Replace entire content with our `Info.plist`
4. Right-click and select **Open As → Property List**

**Option B: Edit in Property List Editor**
1. Click **Info.plist**
2. Click the **+** button to add new keys:

| Key | Type | Value |
|-----|------|-------|
| NSAppTransportSecurity | Dictionary | - |
| → NSAllowsArbitraryLoads | Boolean | YES |
| UIRequiredDeviceCapabilities | Array | - |
| → Item 0 | String | armv7 |
| UIUserInterfaceStyle | String | Automatic |

## Part 3: Configure Build Settings

### Step 1: Open Project Settings

1. Click **DesktopBrowser.xcodeproj** in Project Navigator
2. Select the **DesktopBrowser** target
3. Go to the **Build Settings** tab

### Step 2: Configure Key Settings

Search for and set these values:

| Setting | Value |
|---------|-------|
| **iOS Deployment Target** | 14.0 (or higher) |
| **Swift Language Version** | Swift 5.9 |
| **Minimum Deployment Target** | 14.0 |
| **Support for Swift Language** | 5.9 |

### Step 3: Configure General Settings

Click the **General** tab and verify:

- **Display Name**: DesktopBrowser
- **Bundle Identifier**: com.example.DesktopBrowser
- **Deployment Target**: iOS 14.0 or later
- **Supported Destinations**: iPhone (uncheck iPad if needed)
- **Supported Orientations**: Portrait (iPhone)

### Step 4: Add Files to Target

Make sure all Swift files are added to the target:

1. Select each `.swift` file in Project Navigator
2. Open **File Inspector** (right panel)
3. In **Target Membership** section, check **DesktopBrowser**

## Part 4: Verify Project Integrity

### Step 1: Check Build Phase

1. Select **DesktopBrowser** target
2. Go to **Build Phases** tab
3. Expand **Compile Sources**
4. Verify all these files are present:
   - DesktopBrowserApp.swift
   - ContentView.swift
   - HomeScreen.swift
   - BrowserView.swift
   - WebViewManager.swift
   - URLParser.swift
   - SceneDelegate.swift

If missing, click **+** and add them.

### Step 2: Check Linked Frameworks

Go to **Build Phases** → **Link Binary With Libraries**

Verify these frameworks are present:
- ✓ WebKit.framework (REQUIRED - may need to add manually)
- ✓ SwiftUI.framework
- ✓ UIKit.framework
- ✓ Combine.framework

**If WebKit.framework is missing:**
1. Click **+** button
2. Search for "WebKit"
3. Select and click **Add**

### Step 3: Verify Copy Bundle Resources

Go to **Build Phases** → **Copy Bundle Resources**

These should appear:
- Assets.xcassets
- LaunchScreen.storyboard

## Part 5: Build and Run

### Step 1: Select Simulator/Device

Top of Xcode window shows device selector. Choose:
- iPhone 15 Pro (or any recent iPhone simulator)
- Or select your actual iPhone device (with valid signing certificate)

### Step 2: Build Project

Press **Cmd+B** to build, or **Product → Build**

**Expected:** Build succeeds with no errors

If errors appear:
- Check that all files are added to target
- Verify Swift language version is 5.9
- Ensure all frameworks are linked
- Check Info.plist is properly formatted

### Step 3: Run App

Press **Cmd+R** to run, or **Product → Run**

**Expected:** 
- Simulator launches
- App appears with clean search interface
- Keyboard appears automatically
- Ready to accept input

## Part 6: Test the App

### Test 1: Search Functionality

1. Type: `amazon.com`
2. Tap "Go" button
3. Expected: Website loads in desktop view

### Test 2: Google Search

1. Type: `weather today`
2. Tap "Go" button
3. Expected: Google search results appear

### Test 3: Navigation

1. Load any website
2. Tap back button → goes to previous page
3. Tap forward button → goes to next page
4. Tap reload button → refreshes page
5. Tap home button → returns to search screen

### Test 4: Error Handling

1. Type: `invalid-domain-that-does-not-exist-12345.com`
2. Tap "Go"
3. Expected: Error dialog appears with "Cannot find the website"
4. Tap "Retry" → tries again
5. Tap "Home" → returns to search

### Test 5: Desktop Mode

1. Load: `reddit.com`
2. Inspect: Should show desktop layout (wider content, desktop formatting)
3. Note: Some websites may still show mobile due to JavaScript detection

## Troubleshooting Build Issues

### Error: "WebKit" not found
**Solution:** Add WebKit.framework in Build Phases → Link Binary With Libraries

### Error: "Cannot find 'URLParser' in scope"
**Solution:** 
- Check URLParser.swift is added to target
- File Inspector → Target Membership

### Error: "The application delegate must implement the window property"
**Solution:** SceneDelegate.swift is properly configured - it's declared as UIScene, not UIApplication

### Simulator Won't Launch
**Solution:**
1. Product → Clean Build Folder (Cmd+Shift+K)
2. Product → Build (Cmd+B)
3. Product → Run (Cmd+R)
4. Or restart Xcode

### Blank White Screen
**Solution:**
- Check that ContentView() is properly returned
- Verify Info.plist has UISceneManifest section
- Check SceneDelegate is configured correctly

## Advanced Configuration (Optional)

### Change App Icon

1. Select **Assets.xcassets** in Project Navigator
2. Select **AppIcon** set
3. Drag your icon image (1024×1024 pixels)
4. Xcode auto-generates sizes

### Change App Name

1. Select **DesktopBrowser** target
2. Go to **General** tab
3. Change **Display Name** field

### Configure for Device Testing

1. Connect iPhone via USB
2. Open Project settings
3. Go to **Signing & Capabilities**
4. Select Team
5. Enter Bundle Identifier
6. Plug in device and trust it
7. Select device in top simulator picker
8. Press Cmd+R to build and run

## Project is Ready!

Once you can:
- ✓ Type in search box
- ✓ Open websites in desktop mode
- ✓ Navigate with back/forward buttons
- ✓ See error handling work

**Your Desktop Browser app is complete and ready for use!**

---

## Files Summary

| File | Purpose |
|------|---------|
| DesktopBrowserApp.swift | App entry point with @main |
| ContentView.swift | Navigation between home and browser |
| HomeScreen.swift | Search/address bar interface |
| BrowserView.swift | Browser UI and controls |
| WebViewManager.swift | WKWebView configuration & desktop mode |
| URLParser.swift | URL vs search detection and parsing |
| SceneDelegate.swift | App lifecycle management |
| Info.plist | App configuration and permissions |

All files work together to provide a complete, production-ready desktop browsing experience on iOS.

---

**Questions?** Check README.md for detailed feature documentation and troubleshooting tips.
