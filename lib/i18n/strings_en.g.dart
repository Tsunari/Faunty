///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations implements BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// en: 'More'
	String get more => 'More';

	/// en: 'Mo'
	String get mo => 'Mo';

	/// en: 'Tue'
	String get tue => 'Tue';

	/// en: 'Wed'
	String get wed => 'Wed';

	/// en: 'Thu'
	String get thu => 'Thu';

	/// en: 'Fr'
	String get fr => 'Fr';

	/// en: 'Sat'
	String get sat => 'Sat';

	/// en: 'Sun'
	String get sun => 'Sun';

	/// en: 'Faunty'
	String get faunty => 'Faunty';

	/// en: 'Register'
	String get register => 'Register';

	/// en: 'Login'
	String get login => 'Login';

	/// en: 'Monday'
	String get monday => 'Monday';

	/// en: 'Tuesday'
	String get tuesday => 'Tuesday';

	/// en: 'Wednesday'
	String get wednesday => 'Wednesday';

	/// en: 'Thursday'
	String get thursday => 'Thursday';

	/// en: 'Friday'
	String get friday => 'Friday';

	/// en: 'Saturday'
	String get saturday => 'Saturday';

	/// en: 'Sunday'
	String get sunday => 'Sunday';

	/// en: 'Catering'
	String get catering => 'Catering';

	/// en: 'No catering assignments yet!'
	String get no_catering_assignments_yet => 'No catering assignments yet!';

	/// en: 'Tap the edit button below to assign users to meals for the week.'
	String get tap_the_edit_button_below_to_assign_users_to_meals_for_the_week => 'Tap the edit button below to assign users to meals for the week.';

	/// en: 'Edit'
	String get edit => 'Edit';

	/// en: 'Cleaning'
	String get cleaning => 'Cleaning';

	/// en: 'Place'
	String get place => 'Place';

	/// en: 'Assignees'
	String get assignees => 'Assignees';

	/// en: 'No cleaning places yet!'
	String get no_cleaning_places_yet => 'No cleaning places yet!';

	/// en: 'No users assigned to any places.'
	String get no_users_assigned_to_any_places => 'No users assigned to any places.';

	/// en: 'Tap below to create your first place and start assigning users.'
	String get tap_below_to_create_your_first_place_and_start_assigning_users => 'Tap below to create your first place and start assigning users.';

	/// en: 'Assign users to your existing places using the action button below.'
	String get assign_users_to_your_existing_places_using_the_action_button_below => 'Assign users to your existing places using the action button below.';

	/// en: 'Create Place'
	String get create_place => 'Create Place';

	/// en: 'Place name'
	String get place_name => 'Place name';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Create'
	String get create => 'Create';

	/// en: 'No users assigned'
	String get no_users_assigned => 'No users assigned';

	/// en: 'Add Place'
	String get add_place => 'Add Place';

	/// en: 'Add'
	String get add => 'Add';

	/// en: 'Edit Place'
	String get edit_place => 'Edit Place';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Edit Assignments'
	String get edit_assignments => 'Edit Assignments';

	/// en: 'No places yet.'
	String get no_places_yet => 'No places yet.';

	/// en: 'Delete Place'
	String get delete_place => 'Delete Place';

	/// en: 'Waiting for UserEntity... (HomePage was built without a loaded user)'
	String get waiting_for_userentity_homepage_was_built_without_a_loaded_user => 'Waiting for UserEntity... (HomePage was built without a loaded user)';

	/// en: 'Home'
	String get home => 'Home';

	/// en: 'Program'
	String get program => 'Program';

	/// en: 'No program entries found for this week.'
	String get no_program_entries_found_for_this_week => 'No program entries found for this week.';

	/// en: 'Error loading Program: {placeholder}'
	String get error_loading_program_placeholder => 'Error loading Program: {placeholder}';

	/// en: 'Today'
	String get today => 'Today';

	/// en: 'Your next catering assignment:'
	String get your_next_catering_assignment => 'Your next catering assignment:';

	/// en: 'No upcoming catering assignment found.'
	String get no_upcoming_catering_assignment_found => 'No upcoming catering assignment found.';

	/// en: 'Catering wird geladen...'
	String get catering_wird_geladen => 'Catering wird geladen...';

	/// en: 'Error loading Catering.'
	String get error_loading_catering => 'Error loading Catering.';

	/// en: 'No cleaning assignments found.'
	String get no_cleaning_assignments_found => 'No cleaning assignments found.';

	/// en: 'You have no cleaning assignment'
	String get you_have_no_cleaning_assignment => 'You have no cleaning assignment';

	/// en: 'Your cleaning assignment:'
	String get your_cleaning_assignment => 'Your cleaning assignment:';

	/// en: 'Cleaning assignments are loading...'
	String get cleaning_assignments_are_loading => 'Cleaning assignments are loading...';

	/// en: 'Error loading Cleaning data.'
	String get error_loading_cleaning_data => 'Error loading Cleaning data.';

	/// en: 'This email is already registered.'
	String get this_email_is_already_registered => 'This email is already registered.';

	/// en: 'Password is too weak. Please use at least 6 characters.'
	String get password_is_too_weak_please_use_at_least_6_characters => 'Password is too weak. Please use at least 6 characters.';

	/// en: 'Please enter a valid email address.'
	String get please_enter_a_valid_email_address => 'Please enter a valid email address.';

	/// en: 'Registration is currently disabled.'
	String get registration_is_currently_disabled => 'Registration is currently disabled.';

	/// en: 'No internet connection. Please check your network and try again.'
	String get no_internet_connection_please_check_your_network_and_try_again => 'No internet connection. Please check your network and try again.';

	/// en: 'Registration failed.'
	String get registration_failed => 'Registration failed.';

	/// en: 'Registration failed. Please try again.'
	String get registration_failed_please_try_again => 'Registration failed. Please try again.';

	/// en: 'Please wait...'
	String get please_wait => 'Please wait...';

	/// en: 'Already have an account? Login'
	String get already_have_an_account_login => 'Already have an account? Login';

	/// en: 'Don't have an account? Register'
	String get don_t_have_an_account_register => 'Don\'t have an account? Register';

	/// en: 'First Name'
	String get first_name => 'First Name';

	/// en: 'Last Name'
	String get last_name => 'Last Name';

	/// en: 'Email'
	String get email => 'Email';

	/// en: 'Password'
	String get password => 'Password';

	/// en: 'Hide password'
	String get hide_password => 'Hide password';

	/// en: 'Show password'
	String get show_password => 'Show password';

	/// en: 'Confirm Password'
	String get confirm_password => 'Confirm Password';

	/// en: 'Select Place'
	String get select_place => 'Select Place';

	/// en: 'Clear selection'
	String get clear_selection => 'Clear selection';

	/// en: 'About'
	String get about => 'About';

	/// en: 'Welcome to Faunty 2.0'
	String get welcome_to_faunty_2_0 => 'Welcome to Faunty 2.0';

	/// en: 'Faunty is your modern management app, designed to simplify daily organization and communication for teams, communities, and organizations. Built with a focus on usability, security, and beautiful design, Faunty helps you stay connected and productive.'
	String get faunty_is_your_modern_management_app_designed_to_simplify_daily_organization_and_communication_for_teams_communities_and_organizations_built_with_a_focus_on_usability_security_and_beautiful_design_faunty_helps_you_stay_connected_and_productive => 'Faunty is your modern management app, designed to simplify daily organization and communication for teams, communities, and organizations. Built with a focus on usability, security, and beautiful design, Faunty helps you stay connected and productive.';

	/// en: 'Features'
	String get features => 'Features';

	/// en: 'Team & Community Management'
	String get team_community_management => 'Team & Community Management';

	/// en: 'Weekly Program & Assignments'
	String get weekly_program_assignments => 'Weekly Program & Assignments';

	/// en: 'Catering & Cleaning Schedules'
	String get catering_cleaning_schedules => 'Catering & Cleaning Schedules';

	/// en: 'Secure Authentication'
	String get secure_authentication => 'Secure Authentication';

	/// en: 'Custom Notifications'
	String get custom_notifications => 'Custom Notifications';

	/// en: 'Responsive & Mobile Friendly'
	String get responsive_mobile_friendly => 'Responsive & Mobile Friendly';

	/// en: 'About the Project'
	String get about_the_project => 'About the Project';

	/// en: 'Faunty 2.0 is built with Flutter and Firebase, ensuring fast performance and real-time updates. Our mission is to empower users with tools that make everyday management effortless and enjoyable.'
	String get faunty_2_0_is_built_with_flutter_and_firebase_ensuring_fast_performance_and_real_time_updates_our_mission_is_to_empower_users_with_tools_that_make_everyday_management_effortless_and_enjoyable => 'Faunty 2.0 is built with Flutter and Firebase, ensuring fast performance and real-time updates. Our mission is to empower users with tools that make everyday management effortless and enjoyable.';

	/// en: 'Thank you for using Faunty!'
	String get thank_you_for_using_faunty => 'Thank you for using Faunty!';

	/// en: 'For feedback or support, contact us at talebelergfc@gmail.com'
	String get for_feedback_or_support_contact_us_at_talebelergfc_gmail_com => 'For feedback or support, contact us at talebelergfc@gmail.com';

	/// en: 'Account'
	String get account => 'Account';

	/// en: 'No user is currently signed in.'
	String get no_user_is_currently_signed_in => 'No user is currently signed in.';

	/// en: 'Account Details'
	String get account_details => 'Account Details';

	/// en: 'Change Password'
	String get change_password => 'Change Password';

	/// en: 'New Password'
	String get new_password => 'New Password';

	/// en: 'Save Password'
	String get save_password => 'Save Password';

	/// en: 'Please enter a new password.'
	String get please_enter_a_new_password => 'Please enter a new password.';

	/// en: 'Password changed successfully!'
	String get password_changed_successfully => 'Password changed successfully!';

	/// en: 'Re-authentication Required'
	String get re_authentication_required => 'Re-authentication Required';

	/// en: 'For security reasons, please log in again to change your password. You will be redirected to the login screen.'
	String get for_security_reasons_please_log_in_again_to_change_your_password_you_will_be_redirected_to_the_login_screen => 'For security reasons, please log in again to change your password. You will be redirected to the login screen.';

	/// en: 'Created'
	String get created => 'Created';

	/// en: 'Last Sign-in'
	String get last_sign_in => 'Last Sign-in';

	/// en: 'Users'
	String get users => 'Users';

	/// en: 'Active'
	String get active => 'Active';

	/// en: 'Statistics'
	String get statistics => 'Statistics';

	/// en: 'Backup and restore'
	String get backup_and_restore => 'Backup and restore';

	/// en: 'Settings'
	String get settings => 'Settings';

	/// en: 'No user loaded.'
	String get no_user_loaded => 'No user loaded.';

	/// en: 'Edit Name'
	String get edit_name => 'Edit Name';

	/// en: 'Failed to update name: '
	String get failed_to_update_name => 'Failed to update name: ';

	/// en: 'Organisation'
	String get organisation => 'Organisation';

	/// en: 'Save as template'
	String get save_as_template => 'Save as template';

	/// en: 'Select template to override'
	String get select_template_to_override => 'Select template to override';

	/// en: 'Template name'
	String get template_name => 'Template name';

	/// en: 'Override'
	String get kOverride => 'Override';

	/// en: 'Select a template'
	String get select_a_template => 'Select a template';

	/// en: 'No templates found'
	String get no_templates_found => 'No templates found';

	/// en: 'Delete template'
	String get delete_template => 'Delete template';

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'Add new event'
	String get add_new_event => 'Add new event';

	/// en: 'Edit event'
	String get edit_event => 'Edit event';

	/// en: 'Select start time'
	String get select_start_time => 'Select start time';

	/// en: 'Select end time'
	String get select_end_time => 'Select end time';

	/// en: 'Save and go back'
	String get save_and_go_back => 'Save and go back';

	/// en: 'No program entries for this week!'
	String get no_program_entries_for_this_week => 'No program entries for this week!';

	/// en: 'Tap the edit button below to add a program for the week.'
	String get tap_the_edit_button_below_to_add_a_program_for_the_week => 'Tap the edit button below to add a program for the week.';

	/// en: 'Edit program'
	String get edit_program => 'Edit program';

	/// en: 'Registration Mode'
	String get registration_mode => 'Registration Mode';

	/// en: 'Inactive'
	String get inactive => 'Inactive';

	/// en: 'Enable or disable registration'
	String get enable_or_disable_registration => 'Enable or disable registration';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'Help'
	String get help => 'Help';

	/// en: 'Debt'
	String get debt => 'Debt';

	/// en: 'I sincerely apologize but you can not have more debt'
	String get i_sincerely_apologize_but_you_can_not_have_more_debt => 'I sincerely apologize but you can not have more debt';

	/// en: 'Bro pay your debt first'
	String get bro_pay_your_debt_first => 'Bro pay your debt first';

	/// en: 'Kantin'
	String get kantin => 'Kantin';

	/// en: 'A positive value means you owe money. A negative value means you have credit.'
	String get a_positive_value_means_you_owe_money_a_negative_value_means_you_have_credit => 'A positive value means you owe money. A negative value means you have credit.';

	/// en: 'Enter amount'
	String get enter_amount => 'Enter amount';

	/// en: 'Other users'
	String get other_users => 'Other users';

	/// en: 'No other users found'
	String get no_other_users_found => 'No other users found';

	/// en: 'PayPal'
	String get paypal => 'PayPal';

	/// en: 'Did you pay '
	String get did_you_pay => 'Did you pay ';

	/// en: ' € via PayPal?'
	String get via_paypal => ' € via PayPal?';

	/// en: 'Yes'
	String get yes => 'Yes';

	/// en: 'Reset debt'
	String get reset_debt => 'Reset debt';

	/// en: 'Are you sure you want to reset your debt to 0?'
	String get are_you_sure_you_want_to_reset_your_debt_to_0 => 'Are you sure you want to reset your debt to 0?';

	/// en: 'Confirm'
	String get confirm => 'Confirm';

	/// en: 'Debt reset!'
	String get debt_reset => 'Debt reset!';

	/// en: 'System'
	String get system => 'System';

	/// en: 'Light'
	String get light => 'Light';

	/// en: 'Dark'
	String get dark => 'Dark';

	/// en: 'Theme'
	String get theme => 'Theme';

	/// en: 'Breakfast'
	String get breakfast => 'Breakfast';

	/// en: 'Lunch'
	String get lunch => 'Lunch';

	/// en: 'Dinner'
	String get dinner => 'Dinner';

	/// en: 'Montag'
	String get montag => 'Montag';

	/// en: 'Dienstag'
	String get dienstag => 'Dienstag';

	/// en: 'Mittwoch'
	String get mittwoch => 'Mittwoch';

	/// en: 'Donnerstag'
	String get donnerstag => 'Donnerstag';

	/// en: 'Freitag'
	String get freitag => 'Freitag';

	/// en: 'Samstag'
	String get samstag => 'Samstag';

	/// en: 'Sonntag'
	String get sonntag => 'Sonntag';

	/// en: 'Credit'
	String get credit => 'Credit';

	/// en: 'Set Debt'
	String get set_debt => 'Set Debt';

	/// en: 'Debt amount'
	String get debt_amount => 'Debt amount';

	/// en: 'Set'
	String get set => 'Set';

	/// en: 'Choose app language.'
	String get choose_app_language => 'Choose app language.';

	/// en: 'Load template'
	String get load_template => 'Load template';

	/// en: 'Title'
	String get title => 'Title';

	/// en: 'Communication'
	String get communication => 'Communication';

	/// en: 'Tracking'
	String get tracking => 'Tracking';

	/// en: 'Lists'
	String get lists => 'Lists';

	/// en: 'Edit test notification message'
	String get edit_test_notification_message => 'Edit test notification message';

	/// en: 'Body'
	String get body => 'Body';

	/// en: 'Saved'
	String get saved => 'Saved';

	/// en: 'Saved FCM tokens'
	String get saved_fcm_tokens => 'Saved FCM tokens';

	/// en: 'Check notification permission'
	String get check_notification_permission => 'Check notification permission';

	/// en: 'Notification permission checked'
	String get notification_permission_checked => 'Notification permission checked';

	/// en: 'Refresh tokens'
	String get refresh_tokens => 'Refresh tokens';

	/// en: 'Refreshed tokens'
	String get refreshed_tokens => 'Refreshed tokens';

	/// en: 'No token fetched'
	String get no_token_fetched => 'No token fetched';

	/// en: 'No tokens found'
	String get no_tokens_found => 'No tokens found';

	/// en: 'Loading...'
	String get loading => 'Loading...';

	/// en: 'Copy all tokens for user'
	String get copy_all_tokens_for_user => 'Copy all tokens for user';

	/// en: 'All tokens copied'
	String get all_tokens_copied => 'All tokens copied';

	/// en: 'Copy token'
	String get copy_token => 'Copy token';

	/// en: 'Token copied'
	String get token_copied => 'Token copied';

	/// en: 'Send test notification'
	String get send_test_notification => 'Send test notification';

	/// en: 'Test notification sent'
	String get test_notification_sent => 'Test notification sent';

	/// en: 'Delete token?'
	String get delete_token => 'Delete token?';

	/// en: 'Are you sure you want to delete this FCM token?'
	String get are_you_sure_you_want_to_delete_this_fcm_token => 'Are you sure you want to delete this FCM token?';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Token deleted'
	String get token_deleted => 'Token deleted';

	/// en: 'Dismiss'
	String get dismiss => 'Dismiss';

	/// en: 'Notification opened'
	String get notification_opened => 'Notification opened';

	/// en: 'Open'
	String get open => 'Open';

	/// en: 'Show saved FCM tokens'
	String get show_saved_fcm_tokens => 'Show saved FCM tokens';

	/// en: 'Tools'
	String get tools => 'Tools';

	/// en: 'Under Construction'
	String get under_construction => 'Under Construction';

	/// en: 'Feedback'
	String get feedback => 'Feedback';

	/// en: 'UI Test Page'
	String get ui_test_page => 'UI Test Page';

	/// en: 'Debug only'
	String get debug_only => 'Debug only';

	/// en: 'This page is only visible in debug mode.'
	String get this_page_is_only_visible_in_debug_mode => 'This page is only visible in debug mode.';

	/// en: 'Show column headers'
	String get show_column_headers => 'Show column headers';

	/// en: 'Left'
	String get left => 'Left';

	/// en: 'Right'
	String get right => 'Right';

	/// en: 'Create User'
	String get create_user => 'Create User';

	/// en: 'User created successfully. They can now register with this email.'
	String get user_created_successfully_they_can_now_register_with_this_email => 'User created successfully. They can now register with this email.';

	/// en: 'Failed to create user: '
	String get failed_to_create_user => 'Failed to create user: ';

	/// en: 'Create New User'
	String get create_new_user => 'Create New User';

	/// en: 'Please enter an email'
	String get please_enter_an_email => 'Please enter an email';

	/// en: 'Please enter a valid email'
	String get please_enter_a_valid_email => 'Please enter a valid email';

	/// en: 'Please enter first name'
	String get please_enter_first_name => 'Please enter first name';

	/// en: 'Please enter last name'
	String get please_enter_last_name => 'Please enter last name';

	/// en: 'Role'
	String get role => 'Role';

	/// en: 'Note: The user will be created as a placeholder. They can register using this email address (does not have to exist necessarily), and their account will be linked automatically.'
	String get note_the_user_will_be_created_as_a_placeholder_they_can_register_using_this_email_address_does_not_have_to_exist_necessarily_and_their_account_will_be_linked_automatically => 'Note: The user will be created as a placeholder. They can register using this email address (does not have to exist necessarily), and their account will be linked automatically.';

	/// en: 'Remove tracking item'
	String get remove_tracking_item => 'Remove tracking item';

	/// en: 'Remove'
	String get remove => 'Remove';

	/// en: 'Manage tracking items'
	String get manage_tracking_items => 'Manage tracking items';

	/// en: 'Add new item'
	String get add_new_item => 'Add new item';

	/// en: 'Attendance'
	String get attendance => 'Attendance';

	/// en: 'Manage'
	String get manage => 'Manage';

	/// en: 'Use dropdown'
	String get use_dropdown => 'Use dropdown';

	/// en: 'Use tabs'
	String get use_tabs => 'Use tabs';

	/// en: 'No tracking items have been configured yet.'
	String get no_tracking_items_have_been_configured_yet => 'No tracking items have been configured yet.';

	/// en: 'Ask a manager to add tracking items or add them yourself.'
	String get ask_a_manager_to_add_tracking_items_or_add_them_yourself => 'Ask a manager to add tracking items or add them yourself.';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'more': return 'More';
			case 'mo': return 'Mo';
			case 'tue': return 'Tue';
			case 'wed': return 'Wed';
			case 'thu': return 'Thu';
			case 'fr': return 'Fr';
			case 'sat': return 'Sat';
			case 'sun': return 'Sun';
			case 'faunty': return 'Faunty';
			case 'register': return 'Register';
			case 'login': return 'Login';
			case 'monday': return 'Monday';
			case 'tuesday': return 'Tuesday';
			case 'wednesday': return 'Wednesday';
			case 'thursday': return 'Thursday';
			case 'friday': return 'Friday';
			case 'saturday': return 'Saturday';
			case 'sunday': return 'Sunday';
			case 'catering': return 'Catering';
			case 'no_catering_assignments_yet': return 'No catering assignments yet!';
			case 'tap_the_edit_button_below_to_assign_users_to_meals_for_the_week': return 'Tap the edit button below to assign users to meals for the week.';
			case 'edit': return 'Edit';
			case 'cleaning': return 'Cleaning';
			case 'place': return 'Place';
			case 'assignees': return 'Assignees';
			case 'no_cleaning_places_yet': return 'No cleaning places yet!';
			case 'no_users_assigned_to_any_places': return 'No users assigned to any places.';
			case 'tap_below_to_create_your_first_place_and_start_assigning_users': return 'Tap below to create your first place and start assigning users.';
			case 'assign_users_to_your_existing_places_using_the_action_button_below': return 'Assign users to your existing places using the action button below.';
			case 'create_place': return 'Create Place';
			case 'place_name': return 'Place name';
			case 'cancel': return 'Cancel';
			case 'create': return 'Create';
			case 'no_users_assigned': return 'No users assigned';
			case 'add_place': return 'Add Place';
			case 'add': return 'Add';
			case 'edit_place': return 'Edit Place';
			case 'save': return 'Save';
			case 'edit_assignments': return 'Edit Assignments';
			case 'no_places_yet': return 'No places yet.';
			case 'delete_place': return 'Delete Place';
			case 'waiting_for_userentity_homepage_was_built_without_a_loaded_user': return 'Waiting for UserEntity... (HomePage was built without a loaded user)';
			case 'home': return 'Home';
			case 'program': return 'Program';
			case 'no_program_entries_found_for_this_week': return 'No program entries found for this week.';
			case 'error_loading_program_placeholder': return 'Error loading Program: {placeholder}';
			case 'today': return 'Today';
			case 'your_next_catering_assignment': return 'Your next catering assignment:';
			case 'no_upcoming_catering_assignment_found': return 'No upcoming catering assignment found.';
			case 'catering_wird_geladen': return 'Catering wird geladen...';
			case 'error_loading_catering': return 'Error loading Catering.';
			case 'no_cleaning_assignments_found': return 'No cleaning assignments found.';
			case 'you_have_no_cleaning_assignment': return 'You have no cleaning assignment';
			case 'your_cleaning_assignment': return 'Your cleaning assignment:';
			case 'cleaning_assignments_are_loading': return 'Cleaning assignments are loading...';
			case 'error_loading_cleaning_data': return 'Error loading Cleaning data.';
			case 'this_email_is_already_registered': return 'This email is already registered.';
			case 'password_is_too_weak_please_use_at_least_6_characters': return 'Password is too weak. Please use at least 6 characters.';
			case 'please_enter_a_valid_email_address': return 'Please enter a valid email address.';
			case 'registration_is_currently_disabled': return 'Registration is currently disabled.';
			case 'no_internet_connection_please_check_your_network_and_try_again': return 'No internet connection. Please check your network and try again.';
			case 'registration_failed': return 'Registration failed.';
			case 'registration_failed_please_try_again': return 'Registration failed. Please try again.';
			case 'please_wait': return 'Please wait...';
			case 'already_have_an_account_login': return 'Already have an account? Login';
			case 'don_t_have_an_account_register': return 'Don\'t have an account? Register';
			case 'first_name': return 'First Name';
			case 'last_name': return 'Last Name';
			case 'email': return 'Email';
			case 'password': return 'Password';
			case 'hide_password': return 'Hide password';
			case 'show_password': return 'Show password';
			case 'confirm_password': return 'Confirm Password';
			case 'select_place': return 'Select Place';
			case 'clear_selection': return 'Clear selection';
			case 'about': return 'About';
			case 'welcome_to_faunty_2_0': return 'Welcome to Faunty 2.0';
			case 'faunty_is_your_modern_management_app_designed_to_simplify_daily_organization_and_communication_for_teams_communities_and_organizations_built_with_a_focus_on_usability_security_and_beautiful_design_faunty_helps_you_stay_connected_and_productive': return 'Faunty is your modern management app, designed to simplify daily organization and communication for teams, communities, and organizations. Built with a focus on usability, security, and beautiful design, Faunty helps you stay connected and productive.';
			case 'features': return 'Features';
			case 'team_community_management': return 'Team & Community Management';
			case 'weekly_program_assignments': return 'Weekly Program & Assignments';
			case 'catering_cleaning_schedules': return 'Catering & Cleaning Schedules';
			case 'secure_authentication': return 'Secure Authentication';
			case 'custom_notifications': return 'Custom Notifications';
			case 'responsive_mobile_friendly': return 'Responsive & Mobile Friendly';
			case 'about_the_project': return 'About the Project';
			case 'faunty_2_0_is_built_with_flutter_and_firebase_ensuring_fast_performance_and_real_time_updates_our_mission_is_to_empower_users_with_tools_that_make_everyday_management_effortless_and_enjoyable': return 'Faunty 2.0 is built with Flutter and Firebase, ensuring fast performance and real-time updates. Our mission is to empower users with tools that make everyday management effortless and enjoyable.';
			case 'thank_you_for_using_faunty': return 'Thank you for using Faunty!';
			case 'for_feedback_or_support_contact_us_at_talebelergfc_gmail_com': return 'For feedback or support, contact us at talebelergfc@gmail.com';
			case 'account': return 'Account';
			case 'no_user_is_currently_signed_in': return 'No user is currently signed in.';
			case 'account_details': return 'Account Details';
			case 'change_password': return 'Change Password';
			case 'new_password': return 'New Password';
			case 'save_password': return 'Save Password';
			case 'please_enter_a_new_password': return 'Please enter a new password.';
			case 'password_changed_successfully': return 'Password changed successfully!';
			case 're_authentication_required': return 'Re-authentication Required';
			case 'for_security_reasons_please_log_in_again_to_change_your_password_you_will_be_redirected_to_the_login_screen': return 'For security reasons, please log in again to change your password. You will be redirected to the login screen.';
			case 'created': return 'Created';
			case 'last_sign_in': return 'Last Sign-in';
			case 'users': return 'Users';
			case 'active': return 'Active';
			case 'statistics': return 'Statistics';
			case 'backup_and_restore': return 'Backup and restore';
			case 'settings': return 'Settings';
			case 'no_user_loaded': return 'No user loaded.';
			case 'edit_name': return 'Edit Name';
			case 'failed_to_update_name': return 'Failed to update name: ';
			case 'organisation': return 'Organisation';
			case 'save_as_template': return 'Save as template';
			case 'select_template_to_override': return 'Select template to override';
			case 'template_name': return 'Template name';
			case 'kOverride': return 'Override';
			case 'select_a_template': return 'Select a template';
			case 'no_templates_found': return 'No templates found';
			case 'delete_template': return 'Delete template';
			case 'close': return 'Close';
			case 'add_new_event': return 'Add new event';
			case 'edit_event': return 'Edit event';
			case 'select_start_time': return 'Select start time';
			case 'select_end_time': return 'Select end time';
			case 'save_and_go_back': return 'Save and go back';
			case 'no_program_entries_for_this_week': return 'No program entries for this week!';
			case 'tap_the_edit_button_below_to_add_a_program_for_the_week': return 'Tap the edit button below to add a program for the week.';
			case 'edit_program': return 'Edit program';
			case 'registration_mode': return 'Registration Mode';
			case 'inactive': return 'Inactive';
			case 'enable_or_disable_registration': return 'Enable or disable registration';
			case 'language': return 'Language';
			case 'help': return 'Help';
			case 'debt': return 'Debt';
			case 'i_sincerely_apologize_but_you_can_not_have_more_debt': return 'I sincerely apologize but you can not have more debt';
			case 'bro_pay_your_debt_first': return 'Bro pay your debt first';
			case 'kantin': return 'Kantin';
			case 'a_positive_value_means_you_owe_money_a_negative_value_means_you_have_credit': return 'A positive value means you owe money. A negative value means you have credit.';
			case 'enter_amount': return 'Enter amount';
			case 'other_users': return 'Other users';
			case 'no_other_users_found': return 'No other users found';
			case 'paypal': return 'PayPal';
			case 'did_you_pay': return 'Did you pay ';
			case 'via_paypal': return ' € via PayPal?';
			case 'yes': return 'Yes';
			case 'reset_debt': return 'Reset debt';
			case 'are_you_sure_you_want_to_reset_your_debt_to_0': return 'Are you sure you want to reset your debt to 0?';
			case 'confirm': return 'Confirm';
			case 'debt_reset': return 'Debt reset!';
			case 'system': return 'System';
			case 'light': return 'Light';
			case 'dark': return 'Dark';
			case 'theme': return 'Theme';
			case 'breakfast': return 'Breakfast';
			case 'lunch': return 'Lunch';
			case 'dinner': return 'Dinner';
			case 'montag': return 'Montag';
			case 'dienstag': return 'Dienstag';
			case 'mittwoch': return 'Mittwoch';
			case 'donnerstag': return 'Donnerstag';
			case 'freitag': return 'Freitag';
			case 'samstag': return 'Samstag';
			case 'sonntag': return 'Sonntag';
			case 'credit': return 'Credit';
			case 'set_debt': return 'Set Debt';
			case 'debt_amount': return 'Debt amount';
			case 'set': return 'Set';
			case 'choose_app_language': return 'Choose app language.';
			case 'load_template': return 'Load template';
			case 'title': return 'Title';
			case 'communication': return 'Communication';
			case 'tracking': return 'Tracking';
			case 'lists': return 'Lists';
			case 'edit_test_notification_message': return 'Edit test notification message';
			case 'body': return 'Body';
			case 'saved': return 'Saved';
			case 'saved_fcm_tokens': return 'Saved FCM tokens';
			case 'check_notification_permission': return 'Check notification permission';
			case 'notification_permission_checked': return 'Notification permission checked';
			case 'refresh_tokens': return 'Refresh tokens';
			case 'refreshed_tokens': return 'Refreshed tokens';
			case 'no_token_fetched': return 'No token fetched';
			case 'no_tokens_found': return 'No tokens found';
			case 'loading': return 'Loading...';
			case 'copy_all_tokens_for_user': return 'Copy all tokens for user';
			case 'all_tokens_copied': return 'All tokens copied';
			case 'copy_token': return 'Copy token';
			case 'token_copied': return 'Token copied';
			case 'send_test_notification': return 'Send test notification';
			case 'test_notification_sent': return 'Test notification sent';
			case 'delete_token': return 'Delete token?';
			case 'are_you_sure_you_want_to_delete_this_fcm_token': return 'Are you sure you want to delete this FCM token?';
			case 'delete': return 'Delete';
			case 'token_deleted': return 'Token deleted';
			case 'dismiss': return 'Dismiss';
			case 'notification_opened': return 'Notification opened';
			case 'open': return 'Open';
			case 'show_saved_fcm_tokens': return 'Show saved FCM tokens';
			case 'tools': return 'Tools';
			case 'under_construction': return 'Under Construction';
			case 'feedback': return 'Feedback';
			case 'ui_test_page': return 'UI Test Page';
			case 'debug_only': return 'Debug only';
			case 'this_page_is_only_visible_in_debug_mode': return 'This page is only visible in debug mode.';
			case 'show_column_headers': return 'Show column headers';
			case 'left': return 'Left';
			case 'right': return 'Right';
			case 'create_user': return 'Create User';
			case 'user_created_successfully_they_can_now_register_with_this_email': return 'User created successfully. They can now register with this email.';
			case 'failed_to_create_user': return 'Failed to create user: ';
			case 'create_new_user': return 'Create New User';
			case 'please_enter_an_email': return 'Please enter an email';
			case 'please_enter_a_valid_email': return 'Please enter a valid email';
			case 'please_enter_first_name': return 'Please enter first name';
			case 'please_enter_last_name': return 'Please enter last name';
			case 'role': return 'Role';
			case 'note_the_user_will_be_created_as_a_placeholder_they_can_register_using_this_email_address_does_not_have_to_exist_necessarily_and_their_account_will_be_linked_automatically': return 'Note: The user will be created as a placeholder. They can register using this email address (does not have to exist necessarily), and their account will be linked automatically.';
			case 'remove_tracking_item': return 'Remove tracking item';
			case 'remove': return 'Remove';
			case 'manage_tracking_items': return 'Manage tracking items';
			case 'add_new_item': return 'Add new item';
			case 'attendance': return 'Attendance';
			case 'manage': return 'Manage';
			case 'use_dropdown': return 'Use dropdown';
			case 'use_tabs': return 'Use tabs';
			case 'no_tracking_items_have_been_configured_yet': return 'No tracking items have been configured yet.';
			case 'ask_a_manager_to_add_tracking_items_or_add_them_yourself': return 'Ask a manager to add tracking items or add them yourself.';
			default: return null;
		}
	}
}

