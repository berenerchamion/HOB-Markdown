# Changelog

All notable changes to this project are documented here.

## [1.3.1] - 2026-10-27
 - Updated readme and this file
 - Fixed a UI test in app_toolbar_test.dart
 - Updated to latest version of Flutter

## [1.3.0] - 2026-10-27
 - Expanded and improved testing suite: ~40 new tests
 - Added Help  to the menu bar in the app screen
 - Fixed several edge case bugs 

## [1.1.2] - 2026-10-25
- Standardized all labels on com.hob.markdown throughout the entire application
- Updated the README.md with latest information
- Updated the default screen size to be wide enough to show the left sidebar by deault
- Updated the app to store the last user's window size and possition to be used at next launch

## [1.1.1] - 2026-10-25
- Updated the README.md with more details on usage 
- Added CHANGELOG.md (this file) so that there is a running list of big changes

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