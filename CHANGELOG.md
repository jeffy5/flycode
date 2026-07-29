# Changelog

[English](./CHANGELOG.md) | [简体中文](./CHANGELOG.zh-CN.md)

## v1.1.0 - 2026-07-29

### Added
- Added fuzzy search to the project list for faster project navigation.
- Added a file suggestion panel for inserting `@` file mentions in chat.
- Added swipeable and zoomable image previews for chat attachments.
- Added Git and branch comparison modes to the file changes view.

### Changed
- Improved diff view performance by removing syntax highlighting from rendered diffs.

### Fixed
- Fixed unified patch parsing so file changes render correctly.
- Fixed todo lists disappearing or becoming unscrollable during conversations.
- Preserved tool expansion state while message lists update.
- Prevented detached command dispatch from timing out prematurely.
- Restored complete chat configuration, including model and variant state.
- Ensured commands finish autocompleting before messages are sent.
- Prevented onboarding completion persistence from being interrupted during save.

## v1.0.0 - 2026-04-09

### Added
- Initial public release of FlyCode, a Flutter mobile client for connecting to `opencode server`.
- Project browsing and session management for quickly jumping into new or existing coding sessions.
- Mobile-optimized chat experience for interacting with coding agents, including streaming responses and markdown rendering.
- In-app support for reviewing permission requests, interactive questions, todos, diffs, and session context.
- Model and agent configuration, including provider-aware model selection and variant switching.
- File and image input workflows, including `@` file mentions, image attachments, and clipboard image paste support.
- Local persistence for app settings and session-related preferences, plus optional session completion notifications.
- Built-in app personalization with theme mode selection and multilingual localization support.
