# /new-app - Create and Build a JCS/JWS Full-Stack Application

Create a new full-stack application by cloning the StarterApp scaffold, then agentically build it out based on your requirements.

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

## Critical Rules for Claude

1. **CLONE FIRST, MODIFY SECOND** - ALWAYS `cp -R StarterApp` first, then use surgical Edit calls. NEVER write files from scratch.
2. **Deployment Targets** - ONLY use Swift 6.2, macOS v26, iOS v26, visionOS v26, watchOS v26, tvOS v26. NO FALLBACKS.
3. **Always prompt for name and description** if not provided
4. **Confirm before creating** - show the user what will be built
5. **Bridge First** - Define DTOs before implementing client or server (if using Bridge)
6. **Tests Required** - Write swift-testing tests for ALL models
7. **Build Loop** - Always run build.sh and fix errors before proceeding
8. **Modifier Order** - JCS modifier stack order is critical
9. **Sendable** - All DTOs must be Sendable for Swift 6
10. **No XCTest** - Use ONLY swift-testing framework
11. **Agentic Loop** - Implement → Test → Build → Fix → Repeat
12. **Track Progress** - Use TodoWrite to track all tasks
13. **LAUNCH THE APP** - After successful build, open the app so the user sees it running
