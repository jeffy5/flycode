# FlyCode

[简体中文](./README.zh-CN.md) | [English](./README.md)

## Description

FlyCode is an Android mobile client for `opencode`. It lets you connect to your `opencode server`, browse projects, continue coding sessions, and work with the agent from a mobile device.

> FlyCode requires a running `opencode server`.
> Docs: https://opencode.ai/docs/server/

<p align="center">
  <img src="./screenshots/screenshot-1.jpg" alt="FlyCode screenshot 1" width="22%" style="margin: 8px;" />
  <img src="./screenshots/screenshot-2.jpg" alt="FlyCode screenshot 2" width="22%" style="margin: 8px;" />
  <img src="./screenshots/screenshot-3.jpg" alt="FlyCode screenshot 3" width="22%" style="margin: 8px;" />
  <img src="./screenshots/screenshot-4.jpg" alt="FlyCode screenshot 4" width="22%" style="margin: 8px;" />
</p>

## Features

- Connect to `opencode server` with custom address and optional auth
- Browse projects and jump into new or existing coding sessions
- Mobile-optimized agent chat with real-time SSE streaming
- Review permission requests, todos, diffs, and session context in-app
- Adjust model, language, theme mode, and notification preferences
- **File browser**: browse project directory tree, view file contents
- **Long-press copy path**: quickly copy absolute file/directory paths

## Enhancements over Upstream

### Performance
- **Granular message updates**: SSE deltas only update the affected message bubble via `ValueNotifier`, no full list rebuild
- **Typewriter throttle**: 24ms → 100ms, 75% less markdown re-rendering
- **Signature optimization**: linear scan replaces full List copy in `_messageListSignature`
- **Cache extent**: `cacheExtent: 500` for smoother scrolling

### Network & Caching
- **30-message pagination**: initial fetch of 30, auto-load more on scroll to top
- **sqflite local cache**: messages persisted to phone storage, zero-network cold start
- **HTTP timeout 60s**: large sessions no longer fail
- **In-memory keepAlive**: session switch triggers no re-fetch

### New Features
- **File browser**: 📁 entry in AppBar, browse directories, view file content
- **Delete/rename sessions**: swipe to delete, long-press to rename
- **Todo collapsed by default**: does not block chat view

## Use

1. Start your `opencode server`.

```bash
opencode serve
```

2. By default, the server runs at `http://127.0.0.1:4096`.
3. Install the APK and open FlyCode.
4. The app connects to the default address automatically and goes straight to the project list.
5. Pick a project, open a session, and start working with the agent.
6. To change the server address, go to Settings → Server.

> First launch skips the connection config page and goes straight to the main interface.
> Reason: The original "Save & Enter" button has a navigation bug — clicking it fails to navigate to the project list page. Unable to fix it, so this page is bypassed entirely.
> Default server address can be changed in Settings.

Server references:

- Docs: https://opencode.ai/docs/server/
- OpenAPI doc after startup: `http://127.0.0.1:4096/doc`

## Build

If you want to build FlyCode yourself, make sure you have:

- Flutter SDK
- Dart SDK `^3.11.0`
- Android build environment
- A running `opencode server` for local testing

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

Run on a specific device:

```bash
flutter devices
flutter run -d <device-id>
```

If you change generated models or providers, run:

```bash
dart run build_runner build
```

Build APK:

```bash
flutter build apk --release
```
