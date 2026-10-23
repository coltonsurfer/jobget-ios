# JobGet iOS demo app

A SwiftUI demo of the JobGet worker app: the mobile-first marketplace for hourly and frontline workers.

Screens:

- **Jobs** — location-aware feed, search, filter chips ("Hiring today", "Part-time", …), job cards with pay and distance, 1-Tap Apply.
- **Job detail** — pay / applicants / posted stats, schedule, requirements, hiring manager, 1-Tap Apply → confirmation sheet → chat with the hiring manager.
- **Messages** — JobGet's real-time chat: conversation inbox with unread badges, chat bubbles, typing indicator, quick replies, interview-confirmation cards. Employer replies are simulated locally.
- **Schedule** — current employer, week strip, shift cards with coworkers, upcoming shifts, and the store team (the base the Shift Trade & Cover Board feature builds on).
- **Profile** — profile strength, application statuses, availability, skills, documents.

All data is local mock data (`JobGet/Data/MockData.swift`); there is no backend.

## Build & run

Requires Xcode 26+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`). The `.xcodeproj` is generated and not committed.

```sh
xcodegen generate
xcodebuild -project JobGet.xcodeproj -scheme JobGet \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

Then install on a booted iPhone 17 simulator:

```sh
APP=$(find ~/Library/Developer/Xcode/DerivedData/JobGet-*/Build/Products/Debug-iphonesimulator -name JobGet.app | head -1)
xcrun simctl install booted "$APP" && xcrun simctl launch booted com.jobget.demo
```
