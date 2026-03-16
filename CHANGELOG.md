# Changelog

## [0.2.2]

### Changed
- Reorganized pubspec.yaml with repository, homepage, and issue_tracker fields
- Updated README with better formatting and support section

### Added
- Topics metadata in pubspec.yaml for better discoverability
- GitHub workflows for testing and publishing

### Fixed
- Updated footer in README with proper attribution

## [0.2.1]

### Added
- Example app demonstrating scoped dependencies with pushed package

## [0.2.0]

### Changed
- Updated get_it from ^7.6.0 to ^9.2.1
- Updated go_router from ^14.0.0 to ^17.1.0
- Updated equatable from ^2.0.0 to ^2.0.8
- Updated very_good_analysis from ^6.0.0 to ^10.2.0
- Enhanced SDK constraints for better stability and compatibility

### Added
- Complete export of public API in main library file (ScopeObserver, extensions)
- Improved type safety and documentation
- Support for latest go_router features and improvements
- Enhanced compatibility with latest get_it service locator features
- MIT License content

### Fixed
- Fixed missing exports for ScopeObserver and GoRoute/GoRouter extensions

## [0.1.0]

### Added
- Initial release of pushed package
- RouteScopeManager for managing route-scoped dependencies
- Core models (ScopedRouteConfig)
- ScopeObserver for automatic scope lifecycle management
- GoRoute extension for scope configuration
- GoRouter extension for scope management helpers
