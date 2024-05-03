# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), that adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.2] - 2024-05-03

### Fixed

- Syncing back instances with one of the properties set to `math.huge` no longer causes Argon to crash

### Improved

- Applying corrupted instance changes no longer causes Argon to crash
- Dom database is now saved in MessagePack, this fixes some issues & decreases the plugin size

## [2.0.1] - 2024-05-02

### Fixed

- Syncing with `Client` priority no longer causes `Payload Too Large` error, reported by [@OctoShot](https://devforum.roblox.com/u/octoshotr)

### Improved

- Plugin now compares the server version to check whether it is compatible

## [2.0.0] - 2024-05-01

### Added

- Full two-way sync
- Sync direction indicator
- Place "porting" - Initial Sync Priority setting
- Auto Reconnect setting
- Option to control when user should be prompted for confirmation
- Support for `keepUnknowns` property
- Ability to re-release the same version when needed
- UI icon pre-loader
- Helper scripts

### Improved

- Argon network protocol now uses MessagePack instead of JSON
- Argon UI now supports custom Studio themes
- All floating widgets and some UI elements

### Fixed

- Open In Editor works again (caused by usage of Luau buffers)

## [2.0.0-pre5] - 2024-03-22

### Fixed

- Main host and port box now works without need for the first input, reported by [@Arid](https://github.com/AridAjd)

## [2.0.0-pre4] - 2024-03-21

### Added

- Project for in Studio testing

### Fixed

- Instance name changes are now synced properly
- Argon UI no longer flickers after connection cancellation

## [2.0.0-pre3] - 2024-03-20

### Fixed

- Locked property error, reported by [@EthanMichalicek](https://github.com/EthanMichalicek) in [#1](https://github.com/argon-rbx/argon-roblox/issues/1)
- Sync confirmation cancellation not working
- Text inputs in the Settings widget

## [2.0.0-pre2] - 2024-03-19

### Fixed

- Release workflow installs Wally dependencies

## [2.0.0-pre1] - 2024-03-18

### Added

- First Argon 2 plugin pre-release

[unreleased]: https://github.com/argon-rbx/argon-roblox/compare/2.0.2...HEAD
[2.0.2]: https://github.com/argon-rbx/argon-roblox/compare/2.0.1...2.0.2
[2.0.1]: https://github.com/argon-rbx/argon-roblox/compare/2.0.0...2.0.1
[2.0.0]: https://github.com/argon-rbx/argon-roblox/compare/2.0.0-pre5...2.0.0
[2.0.0-pre5]: https://github.com/argon-rbx/argon-roblox/compare/2.0.0-pre4...2.0.0-pre5
[2.0.0-pre4]: https://github.com/argon-rbx/argon-roblox/compare/2.0.0-pre3...2.0.0-pre4
[2.0.0-pre3]: https://github.com/argon-rbx/argon-roblox/compare/2.0.0-pre2...2.0.0-pre3
[2.0.0-pre2]: https://github.com/argon-rbx/argon-roblox/compare/2.0.0-pre1...2.0.0-pre2
[2.0.0-pre1]: https://github.com/argon-rbx/argon-roblox/compare/8d4d16c128b3400be5ec789bc2f10130e31182b7...2.0.0-pre1
