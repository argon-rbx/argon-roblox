# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), that adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Support for new `Content` data type
- Minor UI enhancements

### Fixed

- Changing unsynced properties like `GuiState` no longer triggers syncback

### Changed

- All initial sync changes can now be reverted in a single undo or redo step
- Updated `rbx-dom` library to the latest major version

### Fixed

- MeshPart's MeshId property is now properly applied when connecting for the first time
- Improper instance class changes no longer cause a crash

## [2.0.17] - 2025-02-05

### Fixed

- Some new instance properties no longer cause critical error when syncing with `Client` priority
- Two-way sync now works as intended for non-script instances when `Only Code Mode` is disabled

## [2.0.16] - 2025-01-26

### Fixed

- Synced `rbx_dom_lua` with upstream, fixing various issues with syncing binary strings and enum items

### Changed

- Two-way sync is now disabled by default to prevent accidental data loss

## [2.0.15] - 2024-11-22

### Added

- TextBox is now highlighted when editing its contents ([#13](https://github.com/argon-rbx/argon-roblox/pull/13))

### Fixed

- Some icon setting are no longer invisible in light mode ([#8](https://github.com/argon-rbx/argon-roblox/pull/8))
- Argon widget doesn't pop up in playtest anymore on Windows ([#9](https://github.com/argon-rbx/argon-roblox/pull/9))
- Updated obsolete commands in Help widget

### Changed

- TextBoxes now scroll instead of scale when text is too long ([#10](https://github.com/argon-rbx/argon-roblox/pull/10))
- Improved border contrast and added setting category highlight ([#11](https://github.com/argon-rbx/argon-roblox/pull/11))

## [2.0.14] - 2024-10-24

### Fixed

- Changing parent instance class no longer causes children to be removed
- Properties of non-script instances are no longer included when syncing from client and `Syncback Properties` setting is disabled
- Two-way sync toggle now properly enables two-way sync when changed during sync session
- Two-way sync now respects `Only Code Mode` setting

## [2.0.13] - 2024-09-19

### Fixed

- GitHub release is no longer corrupted ("MsgPack is not a valid member of ModuleScript" error)

## [2.0.12] - 2024-09-19

### Added

- `Live Hydrate` setting to automatically hydrate with the server when target instance doesn't exist
- Improved project details widget and support for displaying latest project root instances
- New `Changes Threshold` setting to limit the number of changes that will be applied before prompting the user

### Fixed

- External code execution works again
- Two-way sync now works with the new root instances added after the initial sync

### Changed

- Moved `Skip Initial Sync` setting to a new option `None` in `Initial Sync Priority` setting
- Settings are now categorized and collapsible to help with readability

## [2.0.11] - 2024-09-08

### Fixed

- Floating point errors no longer cause some properties to be detected as changed
- Argon UI quality no longer drops with extreme widget sizes
- General UI visual and performance improvements
- Settings, Help and Project Details widgets now open properly after begin closed with `x` button

### Changed

- `Sync Properties` setting is now `Syncback Properties` and doesn't require `Two-Way Sync`
- Settings, Help and Project Details buttons now toggle their widgets

## [2.0.10] - 2024-07-19

### Fixed

- `Keep Unknowns` setting now works at the level of diffing changes rather than applying them
- Syncing `PhysicalProperties` from Studio to the file system no longer causes `Bad Request` error

## [2.0.9] - 2024-07-11

### Added

- Experimental support for syncing MeshPart's MeshId
- Argon sync actions can now be undone an unlimited number of times

### Fixed

- Two-way sync is now properly debounced when a new instance is added

## [2.0.8] - 2024-06-25

### Added

- Proper support for `PackageLink` managed instances (`Override Packages` setting)
- When Argon fails to apply property changes it provides the reason now

### Fixed

- Modifying properties of newly added services no longer crashes Argon

## [2.0.7] - 2024-06-16

### Fixed

- `Tags` and `Attributes` of `Value` like instances now sync back in two-way sync
- Argon no longer stops when the plugin widget is closed ([#3](https://github.com/argon-rbx/argon-roblox/issues/3))

## [2.0.6] - 2024-05-12

### Added

- `Only Code Mode` setting - when enabled only scripts will be synced initially
- `Skip Initial Sync` setting - totally disables initial sync

### Fixed

- Argon no longer tries to sync changes when testing the game (even if auto connect is enabled)

## [2.0.5] - 2024-05-08

### Added

- Current plugin status is now displayed on the Argon's toolbar icon

### Fixed

- The plugin widget's previous state is now restored correctly

## [2.0.4] - 2024-05-05

### Added

- "Creating" services is now possible via hydration

### Fixed

- `workspace.Camera` is now ignored by syncback so HTTP request limit no longer gets exceeded
- Removing services no longer causes Argon to crash, instead the user receives a warning

### Changed

- Two-way sync is now rate limited to a maximum of 2 requests per second

## [2.0.3] - 2024-05-04

### Fixed

- `Int64` is now serialized properly instead of converting it to `Float64` (MessagePack)
- Tables are stringified with appropriate indentation

## [2.0.2] - 2024-05-03

### Fixed

- Syncing back instances with one of the properties set to `math.huge` no longer causes Argon to crash

### Changed

- Applying corrupted instance changes no longer causes Argon to crash
- Dom database is now saved in MessagePack, this fixes some issues & decreases the plugin size

## [2.0.1] - 2024-05-02

### Fixed

- Syncing with `Client` priority no longer causes `Payload Too Large` error

### Changed

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

### Changed

- Argon network protocol now uses MessagePack instead of JSON
- Argon UI now supports custom Studio themes
- All floating widgets and some UI elements

### Fixed

- Open In Editor works again (caused by usage of Luau buffers)

## [2.0.0-pre5] - 2024-03-22

### Fixed

- Main host and port box now works without need for the first input

## [2.0.0-pre4] - 2024-03-21

### Added

- Project for in Studio testing

### Fixed

- Instance name changes are now synced properly
- Argon UI no longer flickers after connection cancellation

## [2.0.0-pre3] - 2024-03-20

### Fixed

- Locked property error ([#1](https://github.com/argon-rbx/argon-roblox/issues/1))
- Sync confirmation cancellation not working
- Text inputs in the Settings widget

## [2.0.0-pre2] - 2024-03-19

### Fixed

- Release workflow installs Wally dependencies

## [2.0.0-pre1] - 2024-03-18

### Added

- First Argon 2 plugin pre-release

[unreleased]: https://github.com/argon-rbx/argon-roblox/compare/2.0.17...HEAD
[2.0.17]: https://github.com/argon-rbx/argon-roblox/compare/2.0.16...2.0.17
[2.0.16]: https://github.com/argon-rbx/argon-roblox/compare/2.0.15...2.0.16
[2.0.15]: https://github.com/argon-rbx/argon-roblox/compare/2.0.14...2.0.15
[2.0.14]: https://github.com/argon-rbx/argon-roblox/compare/2.0.13...2.0.14
[2.0.13]: https://github.com/argon-rbx/argon-roblox/compare/2.0.12...2.0.13
[2.0.12]: https://github.com/argon-rbx/argon-roblox/compare/2.0.11...2.0.12
[2.0.11]: https://github.com/argon-rbx/argon-roblox/compare/2.0.10...2.0.11
[2.0.10]: https://github.com/argon-rbx/argon-roblox/compare/2.0.9...2.0.10
[2.0.9]: https://github.com/argon-rbx/argon-roblox/compare/2.0.8...2.0.9
[2.0.8]: https://github.com/argon-rbx/argon-roblox/compare/2.0.7...2.0.8
[2.0.7]: https://github.com/argon-rbx/argon-roblox/compare/2.0.6...2.0.7
[2.0.6]: https://github.com/argon-rbx/argon-roblox/compare/2.0.5...2.0.6
[2.0.5]: https://github.com/argon-rbx/argon-roblox/compare/2.0.4...2.0.5
[2.0.4]: https://github.com/argon-rbx/argon-roblox/compare/2.0.3...2.0.4
[2.0.3]: https://github.com/argon-rbx/argon-roblox/compare/HEAD...2.0.3
[2.0.2]: https://github.com/argon-rbx/argon-roblox/compare/2.0.1...2.0.2
[2.0.1]: https://github.com/argon-rbx/argon-roblox/compare/2.0.0...2.0.1
[2.0.0]: https://github.com/argon-rbx/argon-roblox/compare/2.0.0-pre5...2.0.0
[2.0.0-pre5]: https://github.com/argon-rbx/argon-roblox/compare/2.0.0-pre4...2.0.0-pre5
[2.0.0-pre4]: https://github.com/argon-rbx/argon-roblox/compare/2.0.0-pre3...2.0.0-pre4
[2.0.0-pre3]: https://github.com/argon-rbx/argon-roblox/compare/2.0.0-pre2...2.0.0-pre3
[2.0.0-pre2]: https://github.com/argon-rbx/argon-roblox/compare/2.0.0-pre1...2.0.0-pre2
[2.0.0-pre1]: https://github.com/argon-rbx/argon-roblox/compare/8d4d16c128b3400be5ec789bc2f10130e31182b7...2.0.0-pre1
