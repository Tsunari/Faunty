# Changelog

## [1.24.4] - 17-12-2025
### Fixed
- Fixes to assignment list custom
- Fixes to assignment list custom again



## [1.24.3] - 04-12-2025
### Changed
- V2 program organization enhancements



## [1.24.2] - 04-12-2025
### Fixed
- Statistics dropdown async fix



## [1.24.1] - 04-12-2025
### Fixed
- Fix missing import



## [1.24.0] - 04-12-2025
### Added
- New experimental program organisation page



## [1.23.0] - 02-12-2025
### Changed
- Catering list sorting by current day
- Cleaning assign complete rework
- Cleaning page rework
- Web dev configs
### Fixed
- Fixes to snackbar and navigation bar



## [1.22.0] - 01-12-2025
### Added
- Various statistics fixes and additions
### Fixed
- Share image fix



## [1.21.0] - 29-11-2025
### Changed
- Main cleanup
- Random changes
### Fixed
- Fix navigation issues in main
- Home screen re-render fix



## [1.20.0] - 28-11-2025
### Added
- Big Notification additions
- Feedback notifications
### Changed
- Some logic changes
### Fixed
- .env fix
- Fix status bar on web



## [1.19.3] - 22-11-2025
### Fixed
- Fix messaging on production
- Fix navigation rebuilding issue



## [1.19.2] - 22-11-2025
### Fixed
- Small update fix



## [1.19.1] - 22-11-2025
### Added
- Custom notification for debug
- Notification toggle
- Proper oneSignla notification setup init
### Changed
- Changes to push sw path
### Fixed
- Fix notification web and stub
- Update logic fix



## [1.19.0] - 22-11-2025
### Added
- Custom notification for debug
- Notification toggle
- Proper oneSignla notification setup init
### Changed
- Changes to push sw path
### Fixed
- Update logic fix



## [1.18.0] - 07-11-2025
### Added
- Added install button for PWA
### Changed
- Pdf preview page enhancement



## [1.17.0] - 28-10-2025
### Added
- Pdf generation preview page
- Pdf list generation
- Release script enhancement with optional confirmation
### Changed
- Add guard to pdf preview to handle no data to export
- Create user for baskan
- Remove ensureplace logic
### Fixed
- Remove redundant subheader in catering layout



## [1.16.0] - 13-10-2025
### Fixed
- Fix omar stuff and cleaning uid format for placeholders



## [1.15.0] - 22-09-2025
### Added
- Add uniform days functionality to catering service and UI
- Modern view in catering
- Show amount on top of history stack bar stats
### Changed
- Hide starting and ending x axis label in rating chart stats widget
### Fixed
- Fix overflow in frequency stats widget



## [1.14.1] - 21-09-2025
### Fixed
- Attendance table firestore and explicit fixes



## [1.14.0] - 20-09-2025
### Added
- Functionality to set user as "passive" in attendance so that the last state is copied to today on attendance check
### Changed
- Hosting script change
- Statistics page enhancements
- UI enhancements



## [1.13.0] - 20-09-2025
### Added
- Stats page init
### Changed
- Late minutes dialog Ui enhancements
### Fixed
- Further fixes to scrolling issues in attendance table
- Real chache delete refresh on update service
- Today button and day scroll between weekdays specified tabs and default tabs



## [1.12.0] - 20-09-2025
### Added
- Author and date in feedbacks shown
- Functionality to pin feedback reports
- Lateness toggle for each item to be able to set a lateness time in attendance
- Weekdays selection for attendance table per item
### Changed
- Easy way to enable disable firebase quota service
- Migrate feedback reports to global collection
- Padding to icon button in feedback page
### Fixed
- Bug fix for selected tab semi persistence on navigation



## [1.11.0] - 17-09-2025
### Added
- Added feedback functionality
- Enhanced update check/refresh functionality
- New update dialog
### Fixed
- Update JS interop for document.hidden to use getter



## [1.10.0] - 17-09-2025
### Added
- New update dialog



## [1.9.0] - 17-09-2025
### Added
- Added new default state for attendance table
- Connect place functionality
- Iframe init
- OnLeave state on attendance checkbox
### Changed
- Reverse date order on attendance table



## [1.8.0] - 14-09-2025
### Added
- Superuser kantin management
### Changed
- Survey behaviour enhancements
### Fixed
- Fix survey for selecting/deselecting and enhance behaviour
- Survey dialog disposal fix



## [1.7.0] - 13-09-2025
### Added
- Add functionality to manually migrate registered user and hook them up to existing placeholder users
- Firestore quota service init
- Take care of UID missmatch for whole lists and all functionality when migrating placeholder user (the temp uid was used everywhere but now the real UID has to be used)
### Changed
- Add created at Timestamp for firestore user creation
- And some big firestore optimizations yet again
- Show year next to month in attendance table
- Yet another batch of attendance table optimizations
### Fixed
- fix correct user provider usage in catering/cleaning
- fix correct user provider usage in caterin/cleaning


## [1.6.0] - 13-09-2025
### Added
- Added new roles: spectator, archived, unknown
- Added toggle superuser all user places view
- Allow hocas to change place of users
- Auto mail on user creation and talebe default
- Name form fields in welcome screen for unknown role
- Placeholder user management
- Super user reg mode through drawer
### Changed
- Drawer changes
- General role specific enhancements
- Show spectators
- Sortable user list providers



## [1.5.0] - 12-09-2025
### Added
- Added home drawer
- Superuser switch place
### Changed
- Chip on icon with info on tap instead of next to title
- Permission update for attendance table
- Realtime updates on inline cells
- Rolegate to chip on icon
- Some optimizations to attendance table
- User list per role icons
- Value notifier for expanded state in attendance table



## [1.4.0] - 11-09-2025
### Added
- Show count of role category in user page
- Functionality to add placeholder users without them having registered and hook up after registration with mail
### Changed
- Placeholder user UI enhancements
### Fixed
- Fix Dropdown issues in user page

## [1.3.0] - 10-09-2025
### Added
- Add tabview in attendance
- Add way to change test notification content in UI
- Added easy way test fcm functionality  from UI
- Added survey page
- Attendance
- Attendance item edit page
- Baseline for custom lists
- Custom lists
- Delete on table widget and edit mode in shell
- Dev hosting init
- FCM init for web
- Firebase functions init and intensive testing
- Implement foreground messages
- Make tab in list page persistent
- Multiple list support for attendance
- Reorderable item manager in attendance management
- Under construction page
- WORKING NOTIFICATIONS
### Changed
- [Drastic] reusable attendance table
- Add icon registry
- Add padding to attendance dropdown
- Add RoleGate to add Lists
- Again notification enhancements
- Assignment_list_widget init
- Icon update
- Introduce TabPage component for better tab management in Communication and Tracking pages.
- Lists page in navBar
- Refactor to id storing in firestore in attendance
- Replace ListsPage with a stateless implementation
- Some notification enhancements
- Survey firestore integration and enhancement
- Update NavBar destinations
### Fixed
- Fix token behaviour
- Logic fixes in attendance
- Small alignment fixes
- Theme card overflow fix



## [1.2.0] - 11-08-2025
### Added
- Add dialog to kantin widget
### Changed
- Add translations
- Change circle avatar background
- Custom sliver app bar component ready to use
- Enhance UI components
- Some more ui enhancements
- Update color scheme usage and adjust layout dimensions in various pages
- Update padding in CustomAppBar actions and improve color scheme in CateringOrganisationPage
- Use design across app
### Fixed
- Enhance user navigation condition in UserWelcomePage
- Fix language persistence loading not working till navigating to a page with language dropdown
- Local storage import fix



## [1.1.0] - 11-08-2025
### Global
- Release script
- Workflows enhancement

### Added
- Add settings page
- Add sharedPreferences and use it for themes
- Add theme dropdown
- Add theme selection with persistence functionality
- Implement language selection and persistence
### Changed
- Enhance theme preset UI and add more
- Update commit guidelines and fix APK naming convention
- Use ConsumerWidgets in main



## 1.0.0 (2025-08-10)

### Breaking Changes
- APP RELEASE

### Features
- versioning in app
- multi instances will now be handled correctly as navigation is streamed with userProvider
- Add PayPal payment integration and reset debt functionality
- Add debt management features and localization updates
- BIG ASS INTERNALIZATION STUFF
- internalization helper
- internalization init
- program organization add template option refined
- Overhaul of the template UI in Program
- Stream and cool
- GROUNDBREAKING Big Ass Place Enum to PlaceModel migration
- login modularization
- Require firstName lastName in user creation
- save login status and add splash page to load the status
- perfectly working login and registration with firestore auth and riverpod state management
- dashboard ordner
- cool dashboard one cool test comment
- cool dashboard
- models, firestore and provider init
- mapping of program and indicator for current day and event in program
- catering_orgaisation ui fix and programm organisation copy button
- AppLogo - More Page skeleton
- programm UI
- program init
- New page Programm
- auth init
- Catering delete button
- appbar catering
- Catering center
- final catering
- better NavBar and dark colorScheme
- update NavBar
- update skeleton
- skeleton with navbar and pages

### Fixes
- instructions update
- small fixes and new url API
- translations refresh
- lower case issue fix and login dropdown
- fix double red in home appointment widget and update on a perfect minute basis
- Enhance error handling in authentication methods and improve user feedback
- Fix Navigation issues and double loading
- Update README.md
- Release Script Enhancement
- Release Script for Hosting
- globals migration to StreamProvider
- SWITCH MAP IN USERPROVIDERRRRR SOOOOO COOOOL OMG
- fix Navigation issues which came up with proper userProvider
- userProvider migration to StreamProvider
- user provider invalidation on logout
- firebase hosting init
- about page and manifest changes
- account page
- Logic lecture did help did not expect
- showing right users in lists assign and confirm dialog component used
- padding fix
- cleaning assign stuff
- home page scrollcontroller added
- fix Padding issues in Program
- fix user page roles assignment issues and Routing problem when user role is set to User in Login Page
- program sorting
- Bug fixes in Program
- cleaning widget
- home page widgets firestore connection
- improvements
- Ui enhancements
- program fix
- visual stuff program
- program firestore connection
- catering firestore connection
- auth bug fix
- cleaning done
- firestore users performance, cleaning firestore init, login and auth performance

### Other
- stuff
- some changes
- cool dashboard one cool test comment
- omar weird ass import fix wtf are you doing
- Unnötige page
- Bunu alalim hocam lütfen UwU
- Initial commit
