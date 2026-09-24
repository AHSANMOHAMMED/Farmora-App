import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Farmora'**
  String get appName;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @phoneOTP.
  ///
  /// In en, this message translates to:
  /// **'Phone OTP'**
  String get phoneOTP;

  /// No description provided for @googleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get googleSignIn;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Farmora'**
  String get welcome;

  /// No description provided for @roleSelection.
  ///
  /// In en, this message translates to:
  /// **'Select Your Role'**
  String get roleSelection;

  /// No description provided for @farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmer;

  /// No description provided for @buyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get buyer;

  /// No description provided for @transporter.
  ///
  /// In en, this message translates to:
  /// **'Transport Provider'**
  String get transporter;

  /// No description provided for @administrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administrator;

  /// No description provided for @splashTitle.
  ///
  /// In en, this message translates to:
  /// **'Connecting farmers, buyers, and transport providers'**
  String get splashTitle;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Agricultural marketplace for direct trade'**
  String get splashSubtitle;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Fresh Produce'**
  String get onboardingTitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Delivery Network'**
  String get onboardingTitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'List and sell your harvest'**
  String get onboardingDesc1;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Accept and arrange delivery jobs'**
  String get onboardingDesc2;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Browse and order fresh produce'**
  String get onboardingDesc3;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @myProducts.
  ///
  /// In en, this message translates to:
  /// **'My Products'**
  String get myProducts;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @transports.
  ///
  /// In en, this message translates to:
  /// **'Transports'**
  String get transports;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @sinhala.
  ///
  /// In en, this message translates to:
  /// **'Sinhala'**
  String get sinhala;

  /// No description provided for @tamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get tamil;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @emptyState.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyState;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternet;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessage;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get yourRating;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get writeReview;

  /// No description provided for @dispute.
  ///
  /// In en, this message translates to:
  /// **'Open Dispute'**
  String get dispute;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @submitVerification.
  ///
  /// In en, this message translates to:
  /// **'Submit Verification Document'**
  String get submitVerification;

  /// No description provided for @awaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Administrator Approval'**
  String get awaitingApproval;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @inTransit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get inTransit;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @rejectedOrder.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejectedOrder;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get confirmOrder;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get maxPrice;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFee;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @paymentRequired.
  ///
  /// In en, this message translates to:
  /// **'Payment Required'**
  String get paymentRequired;

  /// No description provided for @paymentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment Completed'**
  String get paymentCompleted;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @trackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get trackOrder;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @verifyBarcode.
  ///
  /// In en, this message translates to:
  /// **'Verify Barcode'**
  String get verifyBarcode;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @disputes.
  ///
  /// In en, this message translates to:
  /// **'Disputes'**
  String get disputes;

  /// No description provided for @openDispute.
  ///
  /// In en, this message translates to:
  /// **'Open Dispute'**
  String get openDispute;

  /// No description provided for @noDisputes.
  ///
  /// In en, this message translates to:
  /// **'No disputes'**
  String get noDisputes;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markRead;

  /// No description provided for @unreadMessages.
  ///
  /// In en, this message translates to:
  /// **'Unread messages'**
  String get unreadMessages;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @maintenanceMode.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Mode'**
  String get maintenanceMode;

  /// No description provided for @platformFee.
  ///
  /// In en, this message translates to:
  /// **'Platform Fee'**
  String get platformFee;

  /// No description provided for @sessionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Session Timeout'**
  String get sessionTimeout;

  /// No description provided for @developerSettings.
  ///
  /// In en, this message translates to:
  /// **'Developer Settings'**
  String get developerSettings;

  /// No description provided for @signInWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Phone'**
  String get signInWithPhone;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get requiredField;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhone;

  /// No description provided for @invalidOTP.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get invalidOTP;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired, please try again'**
  String get sessionExpired;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later'**
  String get tooManyAttempts;

  /// No description provided for @qrScan.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get qrScan;

  /// No description provided for @barcodeGenerated.
  ///
  /// In en, this message translates to:
  /// **'Barcode generated'**
  String get barcodeGenerated;

  /// No description provided for @barcodeVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify barcode'**
  String get barcodeVerify;

  /// No description provided for @barcodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid barcode'**
  String get barcodeInvalid;

  /// No description provided for @disputeOpened.
  ///
  /// In en, this message translates to:
  /// **'Dispute opened'**
  String get disputeOpened;

  /// No description provided for @disputeClosed.
  ///
  /// In en, this message translates to:
  /// **'Dispute closed'**
  String get disputeClosed;

  /// No description provided for @reviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Review submitted'**
  String get reviewSubmitted;

  /// No description provided for @reviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Review required after delivery'**
  String get reviewRequired;

  /// No description provided for @oneReviewPerOrder.
  ///
  /// In en, this message translates to:
  /// **'One review per order'**
  String get oneReviewPerOrder;

  /// No description provided for @moderation.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get moderation;

  /// No description provided for @reported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get reported;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @reportAbuse.
  ///
  /// In en, this message translates to:
  /// **'Report abuse'**
  String get reportAbuse;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get terms;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get accountCreated;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChanged;

  /// No description provided for @phoneVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone number verified'**
  String get phoneVerified;

  /// No description provided for @resendOTP.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOTP;

  /// No description provided for @otpSent.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to your phone'**
  String get otpSent;

  /// No description provided for @enterOTP.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit verification code sent to your phone'**
  String get enterOTP;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneNumberRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @roleRequired.
  ///
  /// In en, this message translates to:
  /// **'Role is required'**
  String get roleRequired;

  /// No description provided for @districtRequired.
  ///
  /// In en, this message translates to:
  /// **'District is required'**
  String get districtRequired;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select a role to continue'**
  String get selectRole;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profilePhoto;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get uploadPhoto;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed'**
  String get languageChanged;

  /// No description provided for @earningsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Earnings This Month'**
  String get earningsThisMonth;

  /// No description provided for @earningsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Earnings This Week'**
  String get earningsThisWeek;

  /// No description provided for @pendingPayments.
  ///
  /// In en, this message translates to:
  /// **'Pending Payments'**
  String get pendingPayments;

  /// No description provided for @grossSales.
  ///
  /// In en, this message translates to:
  /// **'Gross Sales'**
  String get grossSales;

  /// No description provided for @transportDeductions.
  ///
  /// In en, this message translates to:
  /// **'Transport Deductions'**
  String get transportDeductions;

  /// No description provided for @netEarnings.
  ///
  /// In en, this message translates to:
  /// **'Net Earnings'**
  String get netEarnings;

  /// No description provided for @noEarnings.
  ///
  /// In en, this message translates to:
  /// **'No earnings yet'**
  String get noEarnings;

  /// No description provided for @noOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrders;

  /// No description provided for @noJobs.
  ///
  /// In en, this message translates to:
  /// **'No jobs available'**
  String get noJobs;

  /// No description provided for @acceptJob.
  ///
  /// In en, this message translates to:
  /// **'Accept Job'**
  String get acceptJob;

  /// No description provided for @jobAccepted.
  ///
  /// In en, this message translates to:
  /// **'Job Accepted'**
  String get jobAccepted;

  /// No description provided for @jobAvailable.
  ///
  /// In en, this message translates to:
  /// **'Job Available'**
  String get jobAvailable;

  /// No description provided for @requested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get requested;

  /// No description provided for @pickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked Up'**
  String get pickedUp;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @logistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get logistics;

  /// No description provided for @deliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveries;

  /// No description provided for @myOffers.
  ///
  /// In en, this message translates to:
  /// **'My Offers'**
  String get myOffers;

  /// No description provided for @confirmCodPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm COD payment'**
  String get confirmCodPayment;

  /// No description provided for @exportMyData.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get exportMyData;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @releaseEscrow.
  ///
  /// In en, this message translates to:
  /// **'Release escrow'**
  String get releaseEscrow;

  /// No description provided for @verifyTransporterHint.
  ///
  /// In en, this message translates to:
  /// **'Verify your transporter account to see available jobs.'**
  String get verifyTransporterHint;

  /// No description provided for @joinFarmoraAs.
  ///
  /// In en, this message translates to:
  /// **'Join Farmora as'**
  String get joinFarmoraAs;

  /// No description provided for @roleSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Farmora. Choose how you want to participate in the agricultural marketplace.'**
  String get roleSelectionSubtitle;

  /// No description provided for @continueToFarmora.
  ///
  /// In en, this message translates to:
  /// **'Continue to Farmora'**
  String get continueToFarmora;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @logInLink.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logInLink;

  /// No description provided for @registerLink.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerLink;

  /// No description provided for @chooseRoleHint.
  ///
  /// In en, this message translates to:
  /// **'Choose your role to continue'**
  String get chooseRoleHint;

  /// No description provided for @iWantToSell.
  ///
  /// In en, this message translates to:
  /// **'I want to sell my products'**
  String get iWantToSell;

  /// No description provided for @iWantToBuy.
  ///
  /// In en, this message translates to:
  /// **'I want to buy products'**
  String get iWantToBuy;

  /// No description provided for @iWantToDeliver.
  ///
  /// In en, this message translates to:
  /// **'I want to deliver products'**
  String get iWantToDeliver;

  /// No description provided for @joiningAs.
  ///
  /// In en, this message translates to:
  /// **'Joining as {role}'**
  String joiningAs(String role);

  /// No description provided for @changeRole.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeRole;

  /// No description provided for @uploadPhotoOptional.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo (Optional)'**
  String get uploadPhotoOptional;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @districtLocation.
  ///
  /// In en, this message translates to:
  /// **'District / Location'**
  String get districtLocation;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kamal Perera'**
  String get nameHint;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 077 123 4567'**
  String get phoneHint;

  /// No description provided for @selectDistrict.
  ///
  /// In en, this message translates to:
  /// **'Select your district'**
  String get selectDistrict;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Create a strong password'**
  String get passwordHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordHint;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your harvest, orders, and transport.'**
  String get signInSubtitle;

  /// No description provided for @nameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get nameRequiredError;

  /// No description provided for @phoneRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get phoneRequiredError;

  /// No description provided for @districtRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please select your district'**
  String get districtRequiredError;

  /// No description provided for @passwordRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get passwordRequiredError;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @confirmPasswordRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequiredError;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @agreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and Privacy Policy'**
  String get agreeToTerms;

  /// No description provided for @forFarmers.
  ///
  /// In en, this message translates to:
  /// **'FOR FARMERS'**
  String get forFarmers;

  /// No description provided for @forBuyers.
  ///
  /// In en, this message translates to:
  /// **'FOR BUYERS'**
  String get forBuyers;

  /// No description provided for @forTransporters.
  ///
  /// In en, this message translates to:
  /// **'FOR TRANSPORTERS'**
  String get forTransporters;

  /// No description provided for @onboardingSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Sell Your Harvest Directly'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Desc.
  ///
  /// In en, this message translates to:
  /// **'Connect directly with buyers without middlemen. Set your own fair prices and receive fast, guaranteed payouts.'**
  String get onboardingSlide1Desc;

  /// No description provided for @onboardingSlide1H1.
  ///
  /// In en, this message translates to:
  /// **'Direct Sales'**
  String get onboardingSlide1H1;

  /// No description provided for @onboardingSlide1H2.
  ///
  /// In en, this message translates to:
  /// **'Fair Pricing'**
  String get onboardingSlide1H2;

  /// No description provided for @onboardingSlide1H3.
  ///
  /// In en, this message translates to:
  /// **'Fast Payout'**
  String get onboardingSlide1H3;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Get Fresh Products Easily'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Desc.
  ///
  /// In en, this message translates to:
  /// **'Browse farm-fresh produce straight from local fields. Enjoy trusted quality and transparent wholesale prices.'**
  String get onboardingSlide2Desc;

  /// No description provided for @onboardingSlide2H1.
  ///
  /// In en, this message translates to:
  /// **'100% Farm Fresh'**
  String get onboardingSlide2H1;

  /// No description provided for @onboardingSlide2H2.
  ///
  /// In en, this message translates to:
  /// **'Direct Sourcing'**
  String get onboardingSlide2H2;

  /// No description provided for @onboardingSlide2H3.
  ///
  /// In en, this message translates to:
  /// **'Easy Ordering'**
  String get onboardingSlide2H3;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Reliable Transport for Every Order'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Desc.
  ///
  /// In en, this message translates to:
  /// **'Find dependable delivery trips along your routes. Transport fresh produce safely and maximize your vehicle earnings.'**
  String get onboardingSlide3Desc;

  /// No description provided for @onboardingSlide3H1.
  ///
  /// In en, this message translates to:
  /// **'Verified Cargo'**
  String get onboardingSlide3H1;

  /// No description provided for @onboardingSlide3H2.
  ///
  /// In en, this message translates to:
  /// **'Guaranteed Trips'**
  String get onboardingSlide3H2;

  /// No description provided for @onboardingSlide3H3.
  ///
  /// In en, this message translates to:
  /// **'Extra Income'**
  String get onboardingSlide3H3;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get noNotificationsYet;

  /// No description provided for @pleaseEnterAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter account number'**
  String get pleaseEnterAccountNumber;

  /// No description provided for @invalidPayoutAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid payout amount'**
  String get invalidPayoutAmount;

  /// No description provided for @confirmPayout.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payout'**
  String get confirmPayout;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @transportRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Transport request cancelled'**
  String get transportRequestCancelled;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request?'**
  String get cancelRequest;

  /// No description provided for @trackLive.
  ///
  /// In en, this message translates to:
  /// **'Track Live'**
  String get trackLive;

  /// No description provided for @reupload.
  ///
  /// In en, this message translates to:
  /// **'Re-upload'**
  String get reupload;

  /// No description provided for @transporterProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Transporter profile saved.'**
  String get transporterProfileSaved;

  /// No description provided for @openOrderChat.
  ///
  /// In en, this message translates to:
  /// **'Open Order Chat'**
  String get openOrderChat;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// No description provided for @organicCertified.
  ///
  /// In en, this message translates to:
  /// **'Organic certified'**
  String get organicCertified;

  /// No description provided for @addHarvestVideo.
  ///
  /// In en, this message translates to:
  /// **'Add harvest video?'**
  String get addHarvestVideo;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @productDescription.
  ///
  /// In en, this message translates to:
  /// **'Product Description'**
  String get productDescription;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @newTotal.
  ///
  /// In en, this message translates to:
  /// **'New Total:'**
  String get newTotal;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @rejectOffer.
  ///
  /// In en, this message translates to:
  /// **'Reject Offer?'**
  String get rejectOffer;

  /// No description provided for @counter.
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get counter;

  /// No description provided for @sendCounterOffer.
  ///
  /// In en, this message translates to:
  /// **'Send Counter Offer'**
  String get sendCounterOffer;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @submitCounter.
  ///
  /// In en, this message translates to:
  /// **'Submit Counter'**
  String get submitCounter;

  /// No description provided for @offerRejected.
  ///
  /// In en, this message translates to:
  /// **'Offer rejected'**
  String get offerRejected;

  /// No description provided for @addAProduct.
  ///
  /// In en, this message translates to:
  /// **'Add a product'**
  String get addAProduct;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @barcodePayloadCopied.
  ///
  /// In en, this message translates to:
  /// **'Barcode payload copied'**
  String get barcodePayloadCopied;

  /// No description provided for @copyPayload.
  ///
  /// In en, this message translates to:
  /// **'Copy payload'**
  String get copyPayload;

  /// No description provided for @transportFeeLkr.
  ///
  /// In en, this message translates to:
  /// **'Transport fee (LKR)'**
  String get transportFeeLkr;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @orderRejected.
  ///
  /// In en, this message translates to:
  /// **'Order rejected'**
  String get orderRejected;

  /// No description provided for @accountCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get accountCreatedSuccessfully;

  /// No description provided for @enterYourPhoneNumberFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number first.'**
  String get enterYourPhoneNumberFirst;

  /// No description provided for @verifyPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Verify phone number'**
  String get verifyPhoneNumber;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @markAsDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark as Delivered'**
  String get markAsDelivered;

  /// No description provided for @markAsInTransit.
  ///
  /// In en, this message translates to:
  /// **'Mark as In Transit'**
  String get markAsInTransit;

  /// No description provided for @markAsPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Mark as Picked Up'**
  String get markAsPickedUp;

  /// No description provided for @availableJobs.
  ///
  /// In en, this message translates to:
  /// **'Available Jobs'**
  String get availableJobs;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get allStatuses;

  /// No description provided for @suitableForMyVehicle.
  ///
  /// In en, this message translates to:
  /// **'Suitable for my vehicle'**
  String get suitableForMyVehicle;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @myJobs.
  ///
  /// In en, this message translates to:
  /// **'My Jobs'**
  String get myJobs;

  /// No description provided for @noDeliveryHistoryFound.
  ///
  /// In en, this message translates to:
  /// **'No delivery history found.'**
  String get noDeliveryHistoryFound;

  /// No description provided for @reportAnIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get reportAnIssue;

  /// No description provided for @cancelJob.
  ///
  /// In en, this message translates to:
  /// **'Cancel job'**
  String get cancelJob;

  /// No description provided for @jobDetails.
  ///
  /// In en, this message translates to:
  /// **'Job details'**
  String get jobDetails;

  /// No description provided for @viewPickup.
  ///
  /// In en, this message translates to:
  /// **'View pickup'**
  String get viewPickup;

  /// No description provided for @rateThisTransaction.
  ///
  /// In en, this message translates to:
  /// **'Rate this transaction'**
  String get rateThisTransaction;

  /// No description provided for @navigateToDelivery.
  ///
  /// In en, this message translates to:
  /// **'Navigate to delivery'**
  String get navigateToDelivery;

  /// No description provided for @whyAreYouCancelling.
  ///
  /// In en, this message translates to:
  /// **'Why are you cancelling?'**
  String get whyAreYouCancelling;

  /// No description provided for @completeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Complete Delivery'**
  String get completeDelivery;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle type'**
  String get vehicleType;

  /// No description provided for @kilogramsKg.
  ///
  /// In en, this message translates to:
  /// **'Kilograms (kg)'**
  String get kilogramsKg;

  /// No description provided for @maximumCapacity.
  ///
  /// In en, this message translates to:
  /// **'Maximum capacity'**
  String get maximumCapacity;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @tons.
  ///
  /// In en, this message translates to:
  /// **'Tons'**
  String get tons;

  /// No description provided for @registrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Registration number'**
  String get registrationNumber;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @verifiedOnly.
  ///
  /// In en, this message translates to:
  /// **'Verified Only'**
  String get verifiedOnly;

  /// No description provided for @suspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get suspended;

  /// No description provided for @confirmRoleChange.
  ///
  /// In en, this message translates to:
  /// **'Confirm Role Change'**
  String get confirmRoleChange;

  /// No description provided for @farmerGrowerproducer.
  ///
  /// In en, this message translates to:
  /// **'Farmer (Grower/Producer)'**
  String get farmerGrowerproducer;

  /// No description provided for @buyerWholesalerretailer.
  ///
  /// In en, this message translates to:
  /// **'Buyer (Wholesaler/Retailer)'**
  String get buyerWholesalerretailer;

  /// No description provided for @adminPlatformOperations.
  ///
  /// In en, this message translates to:
  /// **'Admin (Platform Operations)'**
  String get adminPlatformOperations;

  /// No description provided for @changeUserRole.
  ///
  /// In en, this message translates to:
  /// **'Change User Role'**
  String get changeUserRole;

  /// No description provided for @verificationDocumentRejected.
  ///
  /// In en, this message translates to:
  /// **'Verification document rejected'**
  String get verificationDocumentRejected;

  /// No description provided for @confirmRejection.
  ///
  /// In en, this message translates to:
  /// **'Confirm Rejection'**
  String get confirmRejection;

  /// No description provided for @grossOrder.
  ///
  /// In en, this message translates to:
  /// **'Gross Order:'**
  String get grossOrder;

  /// No description provided for @recordTransfer.
  ///
  /// In en, this message translates to:
  /// **'Record Transfer'**
  String get recordTransfer;

  /// No description provided for @applyHold.
  ///
  /// In en, this message translates to:
  /// **'Apply Hold'**
  String get applyHold;

  /// No description provided for @resolveHoldResume.
  ///
  /// In en, this message translates to:
  /// **'Resolve Hold & Resume'**
  String get resolveHoldResume;

  /// No description provided for @placeSettlementOnHold.
  ///
  /// In en, this message translates to:
  /// **'Place Settlement On Hold'**
  String get placeSettlementOnHold;

  /// No description provided for @recordCompletedBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Record completed bank transfer'**
  String get recordCompletedBankTransfer;

  /// No description provided for @approveWire.
  ///
  /// In en, this message translates to:
  /// **'Approve & Wire'**
  String get approveWire;

  /// No description provided for @holdPayout.
  ///
  /// In en, this message translates to:
  /// **'Hold Payout'**
  String get holdPayout;

  /// No description provided for @seedSriLankanMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Seed Sri Lankan marketplace'**
  String get seedSriLankanMarketplace;

  /// No description provided for @platformAnalyticsInsights.
  ///
  /// In en, this message translates to:
  /// **'Platform Analytics & Insights'**
  String get platformAnalyticsInsights;

  /// No description provided for @feeConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Fee Configuration'**
  String get feeConfiguration;

  /// No description provided for @securityPolicies.
  ///
  /// In en, this message translates to:
  /// **'Security Policies'**
  String get securityPolicies;

  /// No description provided for @firebaseServerControl.
  ///
  /// In en, this message translates to:
  /// **'Firebase & Server Control'**
  String get firebaseServerControl;

  /// No description provided for @reviewFeedbackModeration.
  ///
  /// In en, this message translates to:
  /// **'Review & Feedback Moderation'**
  String get reviewFeedbackModeration;

  /// No description provided for @marketPriceIntelligence.
  ///
  /// In en, this message translates to:
  /// **'Market Price Intelligence'**
  String get marketPriceIntelligence;

  /// No description provided for @updateNotice.
  ///
  /// In en, this message translates to:
  /// **'Update Notice'**
  String get updateNotice;

  /// No description provided for @maintenanceNoticeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Maintenance notice updated.'**
  String get maintenanceNoticeUpdated;

  /// No description provided for @enforce.
  ///
  /// In en, this message translates to:
  /// **'Enforce'**
  String get enforce;

  /// No description provided for @recordDisputeDecision.
  ///
  /// In en, this message translates to:
  /// **'Record Dispute Decision'**
  String get recordDisputeDecision;

  /// No description provided for @splitSettlement5050.
  ///
  /// In en, this message translates to:
  /// **'Split Settlement (50% / 50%)'**
  String get splitSettlement5050;

  /// No description provided for @fullRefundToBuyer100.
  ///
  /// In en, this message translates to:
  /// **'Full Refund to Buyer (100%)'**
  String get fullRefundToBuyer100;

  /// No description provided for @disputeDecisionRecorded.
  ///
  /// In en, this message translates to:
  /// **'Dispute decision recorded.'**
  String get disputeDecisionRecorded;

  /// No description provided for @arbitrate.
  ///
  /// In en, this message translates to:
  /// **'Arbitrate'**
  String get arbitrate;

  /// No description provided for @releaseToFarmer100.
  ///
  /// In en, this message translates to:
  /// **'Release to Farmer (100%)'**
  String get releaseToFarmer100;

  /// No description provided for @stable.
  ///
  /// In en, this message translates to:
  /// **'Stable (→)'**
  String get stable;

  /// No description provided for @spices.
  ///
  /// In en, this message translates to:
  /// **'Spices'**
  String get spices;

  /// No description provided for @rising.
  ///
  /// In en, this message translates to:
  /// **'Rising (↑)'**
  String get rising;

  /// No description provided for @addCommodityPolaRate.
  ///
  /// In en, this message translates to:
  /// **'Add Commodity Pola Rate'**
  String get addCommodityPolaRate;

  /// No description provided for @softening.
  ///
  /// In en, this message translates to:
  /// **'Softening (↓)'**
  String get softening;

  /// No description provided for @fruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get fruits;

  /// No description provided for @vegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get vegetables;

  /// No description provided for @grains.
  ///
  /// In en, this message translates to:
  /// **'Grains'**
  String get grains;

  /// No description provided for @addRate.
  ///
  /// In en, this message translates to:
  /// **'Add Rate'**
  String get addRate;

  /// No description provided for @release.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get release;

  /// No description provided for @normalInfo.
  ///
  /// In en, this message translates to:
  /// **'Normal (Info)'**
  String get normalInfo;

  /// No description provided for @transportersOnly.
  ///
  /// In en, this message translates to:
  /// **'Transporters Only'**
  String get transportersOnly;

  /// No description provided for @important.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get important;

  /// No description provided for @emergencyAlert.
  ///
  /// In en, this message translates to:
  /// **'🚨 Emergency Alert'**
  String get emergencyAlert;

  /// No description provided for @allUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get allUsers;

  /// No description provided for @buyersOnly.
  ///
  /// In en, this message translates to:
  /// **'Buyers Only'**
  String get buyersOnly;

  /// No description provided for @farmersOnly.
  ///
  /// In en, this message translates to:
  /// **'Farmers Only'**
  String get farmersOnly;

  /// No description provided for @noActiveListingsAreLoaded.
  ///
  /// In en, this message translates to:
  /// **'No active listings are loaded.'**
  String get noActiveListingsAreLoaded;

  /// No description provided for @auditNoteSaved.
  ///
  /// In en, this message translates to:
  /// **'Audit note saved.'**
  String get auditNoteSaved;

  /// No description provided for @reviewFlaggedAndHidden.
  ///
  /// In en, this message translates to:
  /// **'Review flagged and hidden.'**
  String get reviewFlaggedAndHidden;

  /// No description provided for @deleteReview.
  ///
  /// In en, this message translates to:
  /// **'Delete Review?'**
  String get deleteReview;

  /// No description provided for @adminModerationNote.
  ///
  /// In en, this message translates to:
  /// **'Admin Moderation Note'**
  String get adminModerationNote;

  /// No description provided for @reviewPermanentlyRemoved.
  ///
  /// In en, this message translates to:
  /// **'Review permanently removed.'**
  String get reviewPermanentlyRemoved;

  /// No description provided for @saveNote.
  ///
  /// In en, this message translates to:
  /// **'Save Note'**
  String get saveNote;

  /// No description provided for @emailFarmoraSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Farmora support'**
  String get emailFarmoraSupport;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @callFarmoraSupport.
  ///
  /// In en, this message translates to:
  /// **'Call Farmora support'**
  String get callFarmoraSupport;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully.'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @orderChat.
  ///
  /// In en, this message translates to:
  /// **'Order chat'**
  String get orderChat;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @savePreferences.
  ///
  /// In en, this message translates to:
  /// **'Save Preferences'**
  String get savePreferences;

  /// No description provided for @newMessagesAlerts.
  ///
  /// In en, this message translates to:
  /// **'New messages & alerts'**
  String get newMessagesAlerts;

  /// No description provided for @quietHours10pm7am.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours (10pm – 7am)'**
  String get quietHours10pm7am;

  /// No description provided for @promotionsPriceUpdates.
  ///
  /// In en, this message translates to:
  /// **'Promotions & price updates'**
  String get promotionsPriceUpdates;

  /// No description provided for @orderStatusUpdates.
  ///
  /// In en, this message translates to:
  /// **'Order status updates'**
  String get orderStatusUpdates;

  /// No description provided for @cartCleared.
  ///
  /// In en, this message translates to:
  /// **'Cart cleared'**
  String get cartCleared;

  /// No description provided for @priceHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get priceHighToLow;

  /// No description provided for @nameAz.
  ///
  /// In en, this message translates to:
  /// **'Name A–Z'**
  String get nameAz;

  /// No description provided for @newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// No description provided for @priceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get priceLowToHigh;

  /// No description provided for @noKeep.
  ///
  /// In en, this message translates to:
  /// **'No, Keep'**
  String get noKeep;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order?'**
  String get cancelOrder;

  /// No description provided for @exploreProduce.
  ///
  /// In en, this message translates to:
  /// **'Explore Produce'**
  String get exploreProduce;

  /// No description provided for @orderCancelledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled successfully'**
  String get orderCancelledSuccessfully;

  /// No description provided for @maximum5ImagesAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 images allowed'**
  String get maximum5ImagesAllowed;

  /// No description provided for @acceptCounter.
  ///
  /// In en, this message translates to:
  /// **'Accept Counter'**
  String get acceptCounter;

  /// No description provided for @makeAnOfferOnCrops.
  ///
  /// In en, this message translates to:
  /// **'Make an Offer on Crops'**
  String get makeAnOfferOnCrops;

  /// No description provided for @verifyHarvest.
  ///
  /// In en, this message translates to:
  /// **'Verify harvest'**
  String get verifyHarvest;

  /// No description provided for @messageFarmerTransporter.
  ///
  /// In en, this message translates to:
  /// **'Message farmer / transporter'**
  String get messageFarmerTransporter;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @verifyHarvestBarcode.
  ///
  /// In en, this message translates to:
  /// **'Verify harvest barcode'**
  String get verifyHarvestBarcode;

  /// No description provided for @confirmCodOnly.
  ///
  /// In en, this message translates to:
  /// **'Confirm COD only'**
  String get confirmCodOnly;

  /// No description provided for @openComplaint.
  ///
  /// In en, this message translates to:
  /// **'Open complaint'**
  String get openComplaint;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled.'**
  String get orderCancelled;

  /// No description provided for @addressUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Address updated successfully'**
  String get addressUpdatedSuccessfully;

  /// No description provided for @codPaymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'COD payment confirmed.'**
  String get codPaymentConfirmed;

  /// No description provided for @leaveAReview.
  ///
  /// In en, this message translates to:
  /// **'Leave a review?'**
  String get leaveAReview;

  /// No description provided for @editDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit Delivery Address'**
  String get editDeliveryAddress;

  /// No description provided for @harvestAuthenticityVerified.
  ///
  /// In en, this message translates to:
  /// **'Harvest authenticity verified.'**
  String get harvestAuthenticityVerified;

  /// No description provided for @reviewSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Review submitted successfully!'**
  String get reviewSubmittedSuccessfully;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
