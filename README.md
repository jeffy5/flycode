# FlyCode

[English](./README.md) | [简体中文](./README.zh-CN.md)

## Description and Screenshots

FlyCode is a mobile client for `opencode`, built for Android and iOS. It lets you connect to your `opencode server`, browse projects, continue coding sessions, and work with the agent from a phone-first interface.

> FlyCode requires a running `opencode server`.
> Docs: https://opencode.ai/docs/server/

<p align="center">
  <img src="./screenshots/screenshot-1.jpg" alt="FlyCode screenshot 1" width="22%" style="margin: 8px;" />
  <img src="./screenshots/screenshot-2.jpg" alt="FlyCode screenshot 2" width="22%" style="margin: 8px;" />
  <img src="./screenshots/screenshot-3.jpg" alt="FlyCode screenshot 3" width="22%" style="margin: 8px;" />
  <img src="./screenshots/screenshot-4.jpg" alt="FlyCode screenshot 4" width="22%" style="margin: 8px;" />
</p>

## Features

- Connect to `opencode server` with a custom server address and optional authentication
- Browse projects and jump into new or existing coding sessions
- Chat with the coding agent through a mobile-optimized interface
- Review permission requests, todos, diffs, and session context in the app
- Adjust model, language, theme mode, and notification preferences

## Use

1. Start your `opencode server`.

```bash
opencode serve
```

2. By default, the server runs at `http://127.0.0.1:4096`.
3. Install and open FlyCode on your device.
4. Enter the server address in the app and connect.
5. Pick a project, open a session, and start working with the agent.

Server references:

- Docs: https://opencode.ai/docs/server/
- OpenAPI doc after startup: `http://127.0.0.1:4096/doc`

## Build

If you want to build FlyCode yourself, make sure you have:

- Flutter SDK
- Dart SDK `^3.11.0`
- Android or iOS build environment
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
dart run build_runner build --delete-conflicting-outputs
```
