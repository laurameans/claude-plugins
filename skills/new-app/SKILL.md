# /new-app - Create and Build a JCS/JWS Full-Stack Application

Create a new full-stack application by cloning the StarterApp scaffold, then agentically build it out based on your requirements.

## CRITICAL RULES - READ BEFORE IMPLEMENTING

### NEVER USE:
- `NavigationView`, `NavigationStack`, `NavigationSplitView` - we use Interface routing via `interface.route`
- `.toolbar` or native SwiftUI toolbars - we use `GaiaTopBar`/`JCSTopBar` modifiers
- Custom VStack layouts with topBar/bottomBar components - we use JCS modifiers
- `.font()` modifier on Images - use `.resizable().aspectRatio().frame()` instead
- `Spacer()` + content + `Spacer()` for centering - use `.frame(alignment:)` instead
- `.frame(maxWidth: .infinity, maxHeight: .infinity)` on child views without alignment
- `List` or `Form` for scrollable content - use `ScrollView` + `LazyVStack`

### ALWAYS USE:
- JCS modifier stack in ORDER: `JCSBottomBar` -> `GaiaTopBar` -> `JCSMain`
- `.jTag()` for view visibility in ZStack content switching
- Fibonacci sizing for frames: `Fibonacci.large.wholeValue`, `.large`, `.medium`, etc.
- `ScrollView` with `LazyVStack` for scrollable content
- `.frame(alignment: .center)` for centered content
- **CRITICAL BAR HEIGHT CONSTANTS** - Define at file level in ContentView.swift:
  ```swift
  let topBarHeight: CGFloat = 52
  let bottomBarHeight: CGFloat = 100
  ```
- **ALWAYS apply both paddings** inside ScrollView content:
  ```swift
  .padding(.top, topBarHeight)
  .padding(.bottom, bottomBarHeight)
  ```
- Interface routing: `interface.route = Interface.Routes.myRoute`
- **NO COMMENTS** - Write clean, self-documenting code without inline comments

---

## CORRECT IMAGE PATTERN

ALWAYS use this pattern for images and icons:

```swift
// CORRECT - SF Symbols
Image(systemName: "star.fill")
    .resizable()
    .aspectRatio(contentMode: .fit)
    .frame(width: Fibonacci.large.wholeValue, height: Fibonacci.large.wholeValue)
    .foregroundStyle(Interface.Colors.accent)

// CORRECT - Template images
Image("my-icon")
    .renderingMode(.template)
    .resizable()
    .aspectRatio(contentMode: .fit)
    .frame(width: Fibonacci.medium.wholeValue, height: Fibonacci.medium.wholeValue)
    .foregroundStyle(.accentColor)
```

---

## CORRECT CONTENTVIEW PATTERN

The ContentView MUST use JCS modifiers in the correct order:

```swift
struct ContentView: View {
    @EnvironmentObject var interface: Interface
    @EnvironmentObject var network: Network
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack(alignment: .center) {
            HomeView()
                .jTag(interface.route as? Interface.Routes == Interface.Routes.home)

            SettingsView()
                .jTag(interface.route as? Interface.Routes == Interface.Routes.settings)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(JCSBottomBar<Interface>(shadowColor: Color.shadowColor, content: {
            TabBarView()
        }, subRouter: { _ in
            EmptyView()
        }))
        .modifier(GaiaTopBar<Interface, Network>(...))
        .modifier(JCSMain<Network, Interface>(...))
        .background {
            backgroundView.edgesIgnoringSafeArea(.all)
        }
    }
}
```

---

## Usage

```
/new-app
/new-app MyAppName
/new-app MyAppName "An app that tracks daily habits and provides reminders"
```

---

## STEP 1: Gather Information

When invoked, Claude MUST ask the user for the following if not provided:

### If no arguments provided:

Ask the user:
> **What would you like to name your app?**
>
> Please provide a name in PascalCase (e.g., "MyTaskApp", "FitnessTracker", "PhotoGallery").

Then ask:
> **What should your app do?**
>
> Describe the main features and functionality. For example:
> - "A task manager where users can create, organize, and complete tasks with due dates"
> - "A recipe app where users can save, search, and share recipes"
> - "A fitness tracker that logs workouts and shows progress charts"

### If only app name provided:

Ask the user:
> **What should [AppName] do?**
>
> Describe the main features and functionality you need.

### If both provided:

Proceed directly to scaffold creation.

---

## STEP 2: Confirm Before Proceeding

After gathering information, confirm with the user:

> **Ready to create [AppName]**
>
> Based on your description, I'll build:
> - [List 3-5 key features/models identified]
>
> This will create:
> - `[AppName]/` - iOS/macOS client app
> - `[AppName]Bridge/` - Shared data models
> - `[AppName]Server/` - Backend API server
>
> **Proceed?** (yes/no)

---

# JWS Platform Architecture Reference

## Overview

The JWS (Justin Web Services) platform is a comprehensive full-stack Swift development ecosystem providing unified architecture for iOS, macOS, visionOS, tvOS, and watchOS with a shared Vapor-based backend.

## Platform Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                        YOUR APPLICATION                          │
├─────────────────────────────────────────────────────────────────┤
│  JCX (Extensions)  │  JUI (UI Components)  │  JCS (Client)      │
├─────────────────────────────────────────────────────────────────┤
│                          JBS (Business Logic)                    │
├─────────────────────────────────────────────────────────────────┤
│                     JWS (Server Framework)                       │
└─────────────────────────────────────────────────────────────────┘
```

### JCX - Extensions & Macros
- Swift macros for code generation
- Common extensions on Foundation types
- Utility functions used across all layers

### JUI - UI Components
- Reusable SwiftUI components
- Design system primitives
- Platform-adaptive layouts

### JBS - Business Logic & DTOs
- Data Transfer Objects (shared client/server)
- Business logic models
- Type-safe API contracts

### JCS - Client Services
- **JCSCore** - Core client functionality
- **JCSAuthCore** - Authentication (SIWA, email/password)
- **InterfaceEngine** - App routing and navigation
- Network layer with async/await
- Keychain integration

### JWS - Server Framework (Vapor-based)
- Modular architecture
- Fluent ORM integration
- Authentication middleware
- PostgreSQL support
- Docker deployment ready

---

## Application Architecture Patterns

### The Bridge Pattern

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Client     │────▶│    Bridge    │◀────│   Server     │
│  (SwiftUI)   │     │   (DTOs)     │     │   (Vapor)    │
└──────────────┘     └──────────────┘     └──────────────┘
```

The Bridge contains shared code: User models, API types, enums, route definitions.

### Client Architecture

```swift
@main
struct MyApp: App {
    let network: Network      // JCSAuthCore conformance
    let interface: Interface  // InterfaceEngine conformance
}

@MainActor
public final class Network: JCSAuthBase, JCSCore, JCSAuthCore {
    public typealias JCSAuthUser = MyAppAuthUser
    public nonisolated static var apiBase: String { "api.myapp.com" }
    public nonisolated static var keychainTokenKey: String { "com.outtakes.myapp.authToken" }
}

@MainActor
public class Interface: InterfaceEngineBase, InterfaceEngine {
    public enum Routes: String, CaseIterable, JCS.Routeable {
        case home, settings
    }
}
```

### JCS Modifier Stack (ORDER MATTERS)

```swift
ContentView()
    .jcsBottomBar()      // 1. Bottom navigation
    .gaiaTopBar()        // 2. Top bar
    .jcsMain()           // 3. Main wrapper
    .jcsBackground()     // 4. Background
```

### DTO Pattern in Bridge

```swift
public enum Feature {
    public struct Micro: Codable, Hashable, Identifiable, Sendable {
        public var id: UUID?
        // minimal fields
    }

    public struct Global: Codable, Hashable, Sendable {
        public var micro: Micro
        // public fields
    }

    public struct CreateData: Codable, Sendable {
        // fields for creation
    }
}
```

---

## Testing with Swift Testing (Swift 6)

**IMPORTANT**: Use ONLY `swift-testing` framework, NOT XCTest.

```swift
import Testing
@testable import MyAppBridge

@Suite("Feature Tests")
struct FeatureTests {

    @Test("Feature creates with valid data")
    func createFeature() {
        let item = Feature.Micro(id: UUID(), name: "Test")
        #expect(item.name == "Test")
    }

    @Test("Feature encodes to JSON")
    func encodeFeature() throws {
        let item = Feature.Micro(id: UUID(), name: "Test")
        let data = try JSONEncoder().encode(item)
        #expect(!data.isEmpty)
    }
}
```

---

## STEP 3: Claude's Execution Process

### Phase 1: Clone and Setup

**CRITICAL: ALWAYS clone StarterApp first, then modify surgically. NEVER write files from scratch.**

```bash
NEW_APP="[AppName]"
NEW_APP_LOWER=$(echo "$NEW_APP" | tr '[:upper:]' '[:lower:]')
SOURCE="/Users/justinmeans/Documents/JMLLC/StarterApp"
TARGET="/Users/justinmeans/Documents/JMLLC/$NEW_APP"

# STEP 1: Clone the ENTIRE StarterApp first
cp -R "$SOURCE" "$TARGET"

# STEP 2: Clean build artifacts only
rm -rf "$TARGET/StarterApp/StarterApp.xcodeproj"
rm -rf "$TARGET/StarterBridge/.build"
rm -rf "$TARGET/StarterServer/.build"
find "$TARGET" -name "build_number.txt" -delete
find "$TARGET" -name "*.xcuserstate" -delete

# STEP 3: Rename directories
mv "$TARGET/StarterApp" "$TARGET/$NEW_APP"
mv "$TARGET/StarterBridge" "$TARGET/${NEW_APP}Bridge"
mv "$TARGET/StarterServer" "$TARGET/${NEW_APP}Server"

# STEP 4: Mass rename all file contents using find + sed
find "$TARGET" -type f \( -name "*.swift" -o -name "*.yml" -o -name "*.md" -o -name "*.plist" -o -name "*.entitlements" -o -name "Dockerfile" -o -name "*.sh" \) -exec sed -i '' \
    -e "s/StarterApp/${NEW_APP}/g" \
    -e "s/StarterBridge/${NEW_APP}Bridge/g" \
    -e "s/StarterServer/${NEW_APP}Server/g" \
    -e "s/StarterServerApp/${NEW_APP}ServerApp/g" \
    -e "s/starterapp/${NEW_APP_LOWER}/g" \
    -e "s/ai\.means\.starterapp/com.outtakes.${NEW_APP_LOWER}/g" \
    {} \;

# STEP 5: Rename the main app file
mv "$TARGET/$NEW_APP/Shared/StarterAppApp.swift" "$TARGET/$NEW_APP/Shared/${NEW_APP}App.swift"
```

**Then use surgical Edit tool calls to modify specific files for app-specific functionality.**

### Phase 2: Mass Rename References

Use sed to replace:
- `StarterApp` → `$NEW_APP`
- `StarterBridge` → `${NEW_APP}Bridge`
- `StarterServer` → `${NEW_APP}Server`
- `StarterServerApp` → `${NEW_APP}ServerApp`
- `starterapp` → `$NEW_APP_LOWER`
- `com.outtakes.starterapp` → `ai.means.$NEW_APP_LOWER`

### Phase 3: Verify Scaffold Builds

```bash
cd "$TARGET" && ./build.sh
```

### Phase 4: Agentic Build Loop

Based on user's app description:

1. **Create TodoWrite task list** for all features

2. **For each feature, execute this loop**:

   ```
   ┌─────────────────────────────────────────┐
   │  a. Define DTOs in Bridge               │
   ├─────────────────────────────────────────┤
   │  b. Write swift-testing tests           │
   ├─────────────────────────────────────────┤
   │  c. Run tests: swift test               │
   ├─────────────────────────────────────────┤
   │  d. Fix until tests pass                │
   ├─────────────────────────────────────────┤
   │  e. Add Server module                   │
   ├─────────────────────────────────────────┤
   │  f. Update Client views/routes          │
   ├─────────────────────────────────────────┤
   │  g. Run build.sh                        │
   ├─────────────────────────────────────────┤
   │  h. Fix errors, loop until clean        │
   └─────────────────────────────────────────┘
   ```

3. **Mark TodoWrite items complete** as each feature ships

4. **Final verification**:
```bash
cd "$TARGET/${NEW_APP}Bridge" && swift test
cd "$TARGET" && ./build.sh
```

### Phase 5: Launch the App

After successful build, **launch the app so the user sees it running**:

```bash
# Find and launch the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "${NEW_APP}.app" -path "*/Build/Products/Debug/*" -type d 2>/dev/null | head -1)

if [ -n "$APP_PATH" ]; then
    open "$APP_PATH"
    echo "Launched $NEW_APP"
else
    # Fallback: build and run via xcodebuild
    cd "$TARGET/$NEW_APP"
    xcodebuild -project ${NEW_APP}.xcodeproj -scheme ${NEW_APP} -configuration Debug build
    open ~/Library/Developer/Xcode/DerivedData/${NEW_APP}*/Build/Products/Debug/${NEW_APP}.app
fi
```

**The user should see their new app running on screen.**

### Phase 6: Report Completion

Provide summary:
- App location
- Features implemented
- Test status (all passing)
- Build status (success)
- **App launched and running**
- Next steps (API config, database setup, deployment, etc.)

---

## Project Structure

```
$NEW_APP/
├── $NEW_APP/                    # Client app
│   ├── Shared/
│   │   ├── ${NEW_APP}App.swift  # Entry point
│   │   ├── Controllers/
│   │   │   ├── Engine.swift     # Routes
│   │   │   └── Network.swift    # API
│   │   └── Views/
│   ├── project.yml              # XcodeGen
│   ├── build.sh
│   └── AGENTS.md
├── ${NEW_APP}Bridge/            # Shared DTOs
│   ├── Package.swift
│   ├── Sources/
│   └── Tests/                   # swift-testing
├── ${NEW_APP}Server/            # Vapor backend
│   ├── Package.swift
│   ├── Dockerfile
│   └── Sources/
└── build.sh                     # Root build
```

---

## Build Commands

```bash
# Build all (macOS)
./build.sh

# Individual components
./${NEW_APP}/build.sh
./${NEW_APP}Bridge/build.sh
./${NEW_APP}Server/build.sh

# Run tests
cd ${NEW_APP}Bridge && swift test
```

---

## iOS Device Deployment (CLI - No Xcode GUI Required)

### List Connected Devices

```bash
# List all available iOS devices
xcrun devicectl list devices
```

Output shows device name, identifier, and state (available/unavailable).

### Build for iOS Device

```bash
# First regenerate project with xcodegen
cd ${NEW_APP}
xcodegen generate

# Build for specific device (use device ID from list above)
xcodebuild -scheme ${NEW_APP}-iOS \
  -destination 'id=DEVICE_IDENTIFIER' \
  -configuration Debug \
  -skipMacroValidation \
  -skipPackageSignatureValidation \
  -allowProvisioningUpdates \
  build
```

**Note**: `-allowProvisioningUpdates` handles provisioning profiles automatically.

### Install App on Device

```bash
# Install the built app
xcrun devicectl device install app \
  --device DEVICE_IDENTIFIER \
  ~/Library/Developer/Xcode/DerivedData/${NEW_APP}-*/Build/Products/Debug-iphoneos/${NEW_APP}-iOS.app
```

### Launch App on Device

```bash
# Launch the installed app
xcrun devicectl device process launch \
  --device DEVICE_IDENTIFIER \
  com.outtakes.${NEW_APP_LOWER}
```

### One-Liner Build & Deploy

```bash
# Build, install, and launch in one go
DEVICE_ID=$(xcrun devicectl list devices 2>/dev/null | grep "available (paired)" | head -1 | awk '{print $NF}' | tr -d '()')
xcodegen generate && \
xcodebuild -scheme ${NEW_APP}-iOS -destination "id=$DEVICE_ID" -configuration Debug -skipMacroValidation -skipPackageSignatureValidation -allowProvisioningUpdates build && \
xcrun devicectl device install app --device $DEVICE_ID ~/Library/Developer/Xcode/DerivedData/${NEW_APP}-*/Build/Products/Debug-iphoneos/${NEW_APP}-iOS.app && \
xcrun devicectl device process launch --device $DEVICE_ID com.outtakes.${NEW_APP_LOWER}
```

### Required project.yml Settings for iOS

```yaml
settings:
  base:
    DEVELOPMENT_TEAM: "PASKH93M73"  # Outtakes LLC

targets:
  ${NEW_APP}-iOS:
    type: application
    platform: iOS
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.outtakes.${NEW_APP_LOWER}
        CODE_SIGN_STYLE: Automatic
```

---

## Critical Rules for Claude

### Development Rules
1. **CLONE FIRST, MODIFY SECOND** - ALWAYS `cp -R StarterApp` first, then use surgical Edit calls. NEVER write files from scratch.
2. **Deployment Targets** - ONLY use Swift 6.2, macOS v26, iOS v26, visionOS v26, watchOS v26, tvOS v26. NO FALLBACKS.
3. **Always prompt for name and description** if not provided
4. **Confirm before creating** - show the user what will be built
5. **Bridge First** - Define DTOs before implementing client or server (if using Bridge)
6. **Tests Required** - Write swift-testing tests for ALL models
7. **Build Loop** - Always run build.sh and fix errors before proceeding
8. **Modifier Order** - JCS modifier stack order is CRITICAL: JCSBottomBar -> GaiaTopBar -> JCSMain
9. **Sendable** - All DTOs must be Sendable for Swift 6
10. **No XCTest** - Use ONLY swift-testing framework
11. **Agentic Loop** - Implement → Test → Build → Fix → Repeat
12. **Track Progress** - Use TodoWrite to track all tasks
13. **LAUNCH THE APP** - After successful build, open the app so the user sees it running
14. **No NavigationView** - Use Interface routing with .jTag() for view switching
15. **No .font() on Images** - Use .resizable().aspectRatio().frame() pattern
16. **No Spacer centering** - Use .frame(alignment: .center) instead
17. **Always bar padding** - Child views need `.padding(.top, topBarHeight)` AND `.padding(.bottom, bottomBarHeight)`

### Distribution Rules
18. **ALWAYS verify `asc` is installed** before distribution phases
19. **ALWAYS verify authentication** with `asc auth status`
20. **Build Release config** for distribution (not Debug)
21. **Wait for build processing** after upload (~30-60 seconds)
22. **Add localized release notes** for all builds
23. **Monitor crash reports** after TestFlight distribution
24. **Respond to low-star reviews** promptly and professionally
25. **Get user approval** before submitting to App Store review
26. **Never auto-release** - always confirm with user first
27. **Log all distribution actions** for audit trail

---

## Example Feature Templates

### Bridge DTO

```swift
// ${NEW_APP}Bridge/Sources/${NEW_APP}Bridge/[Feature].swift
import Foundation
import JBS

public enum [Feature] {
    public struct Micro: Codable, Hashable, Identifiable, Sendable {
        public var id: UUID?
        public var name: String
        public var createdDate: Date?

        public init(id: UUID? = nil, name: String, createdDate: Date? = nil) {
            self.id = id
            self.name = name
            self.createdDate = createdDate
        }
    }

    public struct CreateData: Codable, Sendable {
        public var name: String

        public init(name: String) {
            self.name = name
        }
    }
}
```

### Swift Testing

```swift
// ${NEW_APP}Bridge/Tests/${NEW_APP}BridgeTests/[Feature]Tests.swift
import Testing
@testable import ${NEW_APP}Bridge

@Suite("[Feature] Tests")
struct [Feature]Tests {

    @Test("[Feature] initializes correctly")
    func initialization() {
        let item = [Feature].Micro(id: UUID(), name: "Test")
        #expect(item.name == "Test")
    }

    @Test("[Feature] encodes to JSON")
    func encoding() throws {
        let item = [Feature].Micro(id: UUID(), name: "Test")
        let data = try JSONEncoder().encode(item)
        #expect(!data.isEmpty)
    }

    @Test("[Feature] decodes from JSON")
    func decoding() throws {
        let json = """
        {"id": "00000000-0000-0000-0000-000000000001", "name": "Test"}
        """
        let item = try JSONDecoder().decode([Feature].Micro.self, from: json.data(using: .utf8)!)
        #expect(item.name == "Test")
    }
}
```

### Client View

```swift
// ${NEW_APP}/Shared/Views/[Feature]View.swift
import SwiftUI
import JCS
import JUI

struct [Feature]View: View {
    @EnvironmentObject var network: Network
    @EnvironmentObject var interface: Interface

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Content
            }
            .padding()
        }
    }
}
```

### Network Method

```swift
// In Network.swift
func fetch[Feature]s() async throws -> [[Feature].Micro] {
    try await request(
        path: "/[feature]s",
        method: .GET,
        responseType: [[Feature].Micro].self
    )
}
```

---

# App Store Connect Distribution (ASC CLI)

End-to-end agentic distribution to TestFlight and App Store using the `asc` CLI tool.

## Prerequisites

### Install ASC CLI

```bash
# Install via Homebrew
brew tap rudrankriyam/tap && brew install rudrankriyam/tap/asc

# Or via install script
curl -fsSL https://raw.githubusercontent.com/rudrankriyam/App-Store-Connect-CLI/main/install.sh | bash

# Verify installation
asc --version
```

### Authentication Setup

```bash
# Register API credentials (interactive)
asc auth login

# Or with explicit flags
asc auth login \
  --key-id "YOUR_KEY_ID" \
  --issuer-id "YOUR_ISSUER_ID" \
  --private-key-path "/path/to/AuthKey_XXXXXX.p8"

# Verify authentication
asc auth status

# Switch between profiles if multiple exist
asc auth switch --profile "ClientApp"
```

**Environment Variables for CI/CD:**
```bash
export ASC_KEY_ID="ABC123"
export ASC_ISSUER_ID="DEF456"
export ASC_PRIVATE_KEY_PATH="/path/to/AuthKey.p8"
export ASC_PROFILE="ClientApp"
```

---

## PHASE 7: TestFlight Distribution

After successful build, distribute to TestFlight for beta testing.

### Step 1: Build Release Archive

```bash
cd "$TARGET/$NEW_APP"

# Build iOS release archive
xcodebuild -scheme ${NEW_APP}-iOS \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath ./build/${NEW_APP}.xcarchive \
  -skipMacroValidation \
  -skipPackageSignatureValidation \
  -allowProvisioningUpdates \
  archive

# Export IPA for upload
xcodebuild -exportArchive \
  -archivePath ./build/${NEW_APP}.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates
```

### Step 2: Upload Build to App Store Connect

```bash
# Get app ID first
APP_ID=$(asc apps --paginate | jq -r '.[] | select(.name=="'${NEW_APP}'") | .id')

# Upload the IPA
asc builds upload --app "$APP_ID" --ipa "./build/${NEW_APP}.ipa"

# List builds to verify upload
asc builds list --app "$APP_ID" --limit 5
```

### Step 3: Configure TestFlight Beta Groups

```bash
# List existing beta groups
asc beta-groups list --app "$APP_ID"

# Create a new beta group
asc beta-groups create --app "$APP_ID" --name "Internal Testers"

# Add testers to group
asc beta-testers add --app "$APP_ID" --email "tester@example.com" --first-name "Test" --last-name "User"
asc beta-groups add-testers --group "GROUP_ID" --tester-ids "TESTER_ID"

# Add build to beta group
BUILD_ID=$(asc builds list --app "$APP_ID" --limit 1 | jq -r '.[0].id')
asc builds add-groups --build "$BUILD_ID" --group "GROUP_ID"
```

### Step 4: Add What's New (Build Localizations)

```bash
# Add release notes for beta testers
asc build-localizations create \
  --build "$BUILD_ID" \
  --locale "en-US" \
  --whats-new "- New feature: [Description]
- Bug fixes and improvements
- Performance optimizations"

# Update existing localization
asc build-localizations update --id "LOCALIZATION_ID" --whats-new "Updated notes..."
```

### Step 5: Monitor TestFlight Feedback

```bash
# Get beta feedback
asc feedback --app "$APP_ID" --paginate

# Filter by device
asc feedback --app "$APP_ID" --device-model "iPhone15,3" --os-version "17.2"

# Get crash reports
asc crashes --app "$APP_ID" --sort -createdDate --limit 10

# Get full crash details
asc crashes --app "$APP_ID" --output table
```

---

## PHASE 8: App Store Review & Submission

Submit to App Store for review.

### Step 1: Create App Store Version

```bash
# List current versions
asc versions list --app "$APP_ID"

# Attach build to version
asc versions attach-build --version-id "VERSION_ID" --build "$BUILD_ID"
```

### Step 2: Submit for Review

```bash
# Submit app for review
asc submit create \
  --app "$APP_ID" \
  --version "1.0.0" \
  --build "$BUILD_ID" \
  --confirm

# Check submission status
asc submit status --version-id "VERSION_ID"

# Cancel submission if needed
asc submit cancel --version-id "VERSION_ID" --confirm
```

### Step 3: Monitor Review Status

```bash
# Check current status (poll in agentic loop)
asc submit status --version-id "VERSION_ID" | jq '.state'

# Possible states: WAITING_FOR_REVIEW, IN_REVIEW, PENDING_DEVELOPER_RELEASE, APPROVED, REJECTED
```

---

## PHASE 9: Review Response & Rebuttal

Handle App Store reviews and respond to user feedback.

### Step 1: Fetch App Reviews

```bash
# Get all reviews
asc reviews --app "$APP_ID" --paginate

# Filter by star rating
asc reviews --app "$APP_ID" --stars 1 --output table

# Filter by territory
asc reviews --app "$APP_ID" --territory US --output markdown

# Sort by date (newest first)
asc reviews --app "$APP_ID" --sort -createdDate --limit 20
```

### Step 2: Respond to Reviews

```bash
# Respond to a specific review
asc reviews respond \
  --review-id "REVIEW_ID" \
  --response "Thank you for your feedback! We've addressed this issue in version 1.1.0. Please update and let us know if you experience any further problems."

# Get existing response
asc reviews response for-review --review-id "REVIEW_ID"

# Update response
asc reviews response get --id "RESPONSE_ID"

# Delete response if needed
asc reviews response delete --id "RESPONSE_ID" --confirm
```

### Step 3: Agentic Review Response Loop

Claude executes this loop for pending reviews:

```
┌─────────────────────────────────────────────────────────────┐
│  1. Fetch unresponded 1-3 star reviews                      │
├─────────────────────────────────────────────────────────────┤
│  2. Analyze review content and identify issues              │
├─────────────────────────────────────────────────────────────┤
│  3. Draft professional, helpful response                    │
├─────────────────────────────────────────────────────────────┤
│  4. Present response to user for approval                   │
├─────────────────────────────────────────────────────────────┤
│  5. Post approved response via asc reviews respond          │
├─────────────────────────────────────────────────────────────┤
│  6. Log response for tracking                               │
└─────────────────────────────────────────────────────────────┘
```

**Response Guidelines:**
- Always thank the reviewer
- Address specific concerns raised
- Mention fixes if applicable
- Invite further feedback
- Keep responses professional and concise
- Never be defensive or argumentative

---

## PHASE 10: Release to App Store

After approval, release to App Store.

### Step 1: Release Version

```bash
# Release approved version
asc versions release --version-id "VERSION_ID" --confirm

# Verify release
asc versions get --version-id "VERSION_ID"
```

### Step 2: Post-Release Monitoring

```bash
# Monitor new reviews after release
asc reviews --app "$APP_ID" --sort -createdDate --limit 20

# Check for crash reports
asc crashes --app "$APP_ID" --sort -createdDate

# Expire old builds
asc builds expire-all --app "$APP_ID" --older-than 90d --dry-run
asc builds expire-all --app "$APP_ID" --older-than 90d --confirm
```

---

## Complete Distribution Script

One-command distribution from build to TestFlight:

```bash
#!/bin/bash
# distribute.sh - Full TestFlight distribution

set -e

NEW_APP="$1"
NEW_APP_LOWER=$(echo "$NEW_APP" | tr '[:upper:]' '[:lower:]')
TARGET="/Users/justinmeans/Documents/JMLLC/$NEW_APP"

echo "🏗️ Building release archive..."
cd "$TARGET/$NEW_APP"
xcodebuild -scheme ${NEW_APP}-iOS \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath ./build/${NEW_APP}.xcarchive \
  -skipMacroValidation \
  -skipPackageSignatureValidation \
  -allowProvisioningUpdates \
  archive

echo "📦 Exporting IPA..."
xcodebuild -exportArchive \
  -archivePath ./build/${NEW_APP}.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates

echo "🔍 Getting app ID..."
APP_ID=$(asc apps --paginate | jq -r '.[] | select(.name=="'${NEW_APP}'") | .id')

echo "⬆️ Uploading to App Store Connect..."
asc builds upload --app "$APP_ID" --ipa "./build/${NEW_APP}.ipa"

echo "📋 Getting build ID..."
sleep 30  # Wait for processing
BUILD_ID=$(asc builds list --app "$APP_ID" --limit 1 | jq -r '.[0].id')

echo "📝 Adding release notes..."
asc build-localizations create \
  --build "$BUILD_ID" \
  --locale "en-US" \
  --whats-new "New build uploaded via agentic distribution"

echo "✅ Distribution complete!"
echo "App ID: $APP_ID"
echo "Build ID: $BUILD_ID"
```

---

## ASC CLI Quick Reference

### Apps
```bash
asc apps                          # List all apps
asc apps --paginate               # List all with pagination
```

### Builds
```bash
asc builds list --app "APP_ID"
asc builds upload --app "APP_ID" --ipa "path.ipa"
asc builds info --build "BUILD_ID"
asc builds expire --build "BUILD_ID"
```

### Beta Groups & Testers
```bash
asc beta-groups list --app "APP_ID"
asc beta-groups create --app "APP_ID" --name "Group Name"
asc beta-testers list --app "APP_ID"
asc beta-testers add --app "APP_ID" --email "email" --first-name "First" --last-name "Last"
```

### Reviews
```bash
asc reviews --app "APP_ID"
asc reviews --app "APP_ID" --stars 1
asc reviews respond --review-id "ID" --response "Response text"
```

### Submissions
```bash
asc submit create --app "APP_ID" --version "1.0" --build "BUILD_ID" --confirm
asc submit status --version-id "VERSION_ID"
asc submit cancel --version-id "VERSION_ID" --confirm
```

### Versions
```bash
asc versions list --app "APP_ID"
asc versions attach-build --version-id "VERSION_ID" --build "BUILD_ID"
asc versions release --version-id "VERSION_ID" --confirm
```

### Feedback & Crashes
```bash
asc feedback --app "APP_ID"
asc crashes --app "APP_ID"
```

---

## Distribution Rules for Claude

1. **ALWAYS verify `asc` is installed** before distribution phases
2. **ALWAYS verify authentication** with `asc auth status`
3. **Build Release config** for distribution (not Debug)
4. **Wait for build processing** after upload (~30-60 seconds)
5. **Add localized release notes** for all builds
6. **Monitor crash reports** after TestFlight distribution
7. **Respond to low-star reviews** promptly and professionally
8. **Get user approval** before submitting to App Store review
9. **Never auto-release** - always confirm with user first
10. **Log all distribution actions** for audit trail
