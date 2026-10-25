# Changelog

All notable changes to this project are documented here.

## [Unreleased]

## [1.1.0] - 2026-10-25

### Added
- Open With and double-click support for markdown files on macOS, including
  cold start and opening a second file while the app is running
- Unicode printing: bundled Noto fonts so symbols and emoji print correctly
- Docked help panel with the welcome guide and keyboard shortcuts
- Global error handlers, so unexpected errors are logged instead of lost

### Changed
- Upgraded `file_picker` to 13.x and moved to the new static API
- Replaced the discontinued `flutter_markdown` with `flutter_markdown_plus`
- The welcome guide now loads from the asset bundle, so installed builds show
  the same startup document as development builds
- Files that aren't valid UTF-8 now open instead of failing
- Improved exception handling and debug logic across the whole app

### Fixed
- Opening a file from Finder loaded the default document instead of the file
- Removed redundant second write when using Save As

### Removed
- The floating pseudo-window help screen