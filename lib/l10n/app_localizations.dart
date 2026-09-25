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
  /// **'Profile photo'**
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

  /// No description provided for @profileUnnamedUser.
  ///
  /// In en, this message translates to:
  /// **'Farmora user'**
  String get profileUnnamedUser;

  /// No description provided for @profileVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get profileVerified;

  /// No description provided for @profileVerificationPending.
  ///
  /// In en, this message translates to:
  /// **'Verification pending'**
  String get profileVerificationPending;

  /// No description provided for @profileNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get profileNotVerified;

  /// No description provided for @profileMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String profileMemberSince(String date);

  /// No description provided for @profileChangePhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get profileChangePhotoHint;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated.'**
  String get profilePhotoUpdated;

  /// No description provided for @profilePhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update your photo. Please try again.'**
  String get profilePhotoFailed;

  /// No description provided for @profileStatProducts.
  ///
  /// In en, this message translates to:
  /// **'Products listed'**
  String get profileStatProducts;

  /// No description provided for @profileStatCompletedOrders.
  ///
  /// In en, this message translates to:
  /// **'Completed orders'**
  String get profileStatCompletedOrders;

  /// No description provided for @profileReviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String profileReviewCount(int count);

  /// No description provided for @profileCompletePercent.
  ///
  /// In en, this message translates to:
  /// **'Profile {percent}% complete'**
  String profileCompletePercent(int percent);

  /// No description provided for @profileCompleteHint.
  ///
  /// In en, this message translates to:
  /// **'Finish these steps so buyers can trust you.'**
  String get profileCompleteHint;

  /// No description provided for @profileCompleteHintBuyer.
  ///
  /// In en, this message translates to:
  /// **'Finish these steps for faster ordering.'**
  String get profileCompleteHintBuyer;

  /// No description provided for @profileMissingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get profileMissingPhoto;

  /// No description provided for @profileMissingDistrict.
  ///
  /// In en, this message translates to:
  /// **'Add district'**
  String get profileMissingDistrict;

  /// No description provided for @profileMissingFarm.
  ///
  /// In en, this message translates to:
  /// **'Add farm details'**
  String get profileMissingFarm;

  /// No description provided for @profileMissingBank.
  ///
  /// In en, this message translates to:
  /// **'Add bank details'**
  String get profileMissingBank;

  /// No description provided for @profileMissingVerification.
  ///
  /// In en, this message translates to:
  /// **'Get verified'**
  String get profileMissingVerification;

  /// No description provided for @profileSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileSectionAccount;

  /// No description provided for @profileSectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location & transport'**
  String get profileSectionLocation;

  /// No description provided for @profileSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profileSectionPreferences;

  /// No description provided for @profileSectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get profileSectionSupport;

  /// No description provided for @profileSectionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get profileSectionPrivacy;

  /// No description provided for @profileEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, photo and district'**
  String get profileEditSubtitle;

  /// No description provided for @profileFarmDetails.
  ///
  /// In en, this message translates to:
  /// **'Farm details'**
  String get profileFarmDetails;

  /// No description provided for @profileFarmDetailsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add your farm name, size and main crops'**
  String get profileFarmDetailsEmpty;

  /// No description provided for @profileBankDetails.
  ///
  /// In en, this message translates to:
  /// **'Bank details'**
  String get profileBankDetails;

  /// No description provided for @profileBankDetailsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Needed so buyers can pay by bank deposit'**
  String get profileBankDetailsEmpty;

  /// No description provided for @profileVerification.
  ///
  /// In en, this message translates to:
  /// **'Account verification'**
  String get profileVerification;

  /// No description provided for @profileVerificationNoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload your documents for review'**
  String get profileVerificationNoneSubtitle;

  /// No description provided for @profileVerificationPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We are checking your documents'**
  String get profileVerificationPendingSubtitle;

  /// No description provided for @profileVerificationDoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is verified'**
  String get profileVerificationDoneSubtitle;

  /// No description provided for @profileNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Order, payment and delivery alerts'**
  String get profileNotificationsSubtitle;

  /// No description provided for @profileHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Questions and contact us'**
  String get profileHelpSubtitle;

  /// No description provided for @profileTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get profileTerms;

  /// No description provided for @profilePrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get profilePrivacyPolicy;

  /// No description provided for @profileAbout.
  ///
  /// In en, this message translates to:
  /// **'About Farmora'**
  String get profileAbout;

  /// No description provided for @profileAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String profileAppVersion(String version);

  /// No description provided for @profileAboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Farmora connects Sri Lankan farmers directly with buyers and transporters.'**
  String get profileAboutDescription;

  /// No description provided for @profileLiveLocation.
  ///
  /// In en, this message translates to:
  /// **'Live location sharing'**
  String get profileLiveLocation;

  /// No description provided for @profileLiveLocationOn.
  ///
  /// In en, this message translates to:
  /// **'On — nearby transporters and your order partners can see your location'**
  String get profileLiveLocationOn;

  /// No description provided for @profileLiveLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Off — turn on so nearby transporters can find you'**
  String get profileLiveLocationOff;

  /// No description provided for @profileLiveLocationStarted.
  ///
  /// In en, this message translates to:
  /// **'Live location sharing started.'**
  String get profileLiveLocationStarted;

  /// No description provided for @profileLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Allow it in Settings.'**
  String get profileLocationDenied;

  /// No description provided for @profileLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Device location is turned off.'**
  String get profileLocationOff;

  /// No description provided for @profileNearbyTransporters.
  ///
  /// In en, this message translates to:
  /// **'Nearby transporters'**
  String get profileNearbyTransporters;

  /// No description provided for @profileNearbyTransportersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find verified transporters close to you'**
  String get profileNearbyTransportersSubtitle;

  /// No description provided for @profileExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy all your Farmora data'**
  String get profileExportSubtitle;

  /// No description provided for @profileExportCopied.
  ///
  /// In en, this message translates to:
  /// **'Your data was copied to the clipboard.'**
  String get profileExportCopied;

  /// No description provided for @profileExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export your data. Please try again.'**
  String get profileExportFailed;

  /// No description provided for @profileDeleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account'**
  String get profileDeleteSubtitle;

  /// No description provided for @profileDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get profileDeleteTitle;

  /// No description provided for @profileDeleteIntro.
  ///
  /// In en, this message translates to:
  /// **'If you continue:'**
  String get profileDeleteIntro;

  /// No description provided for @profileDeletePoint1.
  ///
  /// In en, this message translates to:
  /// **'Your profile, photo and contact details are removed.'**
  String get profileDeletePoint1;

  /// No description provided for @profileDeletePoint2.
  ///
  /// In en, this message translates to:
  /// **'Your products, offers, messages and notifications are deleted.'**
  String get profileDeletePoint2;

  /// No description provided for @profileDeletePoint3.
  ///
  /// In en, this message translates to:
  /// **'Past orders and payments are kept without your name, for records.'**
  String get profileDeletePoint3;

  /// No description provided for @profileDeletePoint4.
  ///
  /// In en, this message translates to:
  /// **'You will be signed out. This cannot be undone.'**
  String get profileDeletePoint4;

  /// No description provided for @profileDeleteConfirmCheck.
  ///
  /// In en, this message translates to:
  /// **'I understand this cannot be undone'**
  String get profileDeleteConfirmCheck;

  /// No description provided for @profileDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete your account. Please try again.'**
  String get profileDeleteFailed;

  /// No description provided for @profileLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get profileLogoutTitle;

  /// No description provided for @profileLogoutMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to use Farmora.'**
  String get profileLogoutMessage;

  /// No description provided for @profileRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh your profile. Check your connection.'**
  String get profileRefreshFailed;

  /// No description provided for @profileCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileCancel;

  /// No description provided for @editProfilePersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get editProfilePersonal;

  /// No description provided for @editProfileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get editProfileFullName;

  /// No description provided for @editProfileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get editProfileNameRequired;

  /// No description provided for @editProfileTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep it under {max} characters'**
  String editProfileTooLong(int max);

  /// No description provided for @editProfileDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get editProfileDistrict;

  /// No description provided for @editProfilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get editProfilePhone;

  /// No description provided for @editProfilePhoneLocked.
  ///
  /// In en, this message translates to:
  /// **'Contact support to change your phone number'**
  String get editProfilePhoneLocked;

  /// No description provided for @editProfileFarmSection.
  ///
  /// In en, this message translates to:
  /// **'Farm details'**
  String get editProfileFarmSection;

  /// No description provided for @editProfileFarmName.
  ///
  /// In en, this message translates to:
  /// **'Farm name'**
  String get editProfileFarmName;

  /// No description provided for @editProfileFarmSize.
  ///
  /// In en, this message translates to:
  /// **'Farm size'**
  String get editProfileFarmSize;

  /// No description provided for @editProfileFarmSizeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2 acres'**
  String get editProfileFarmSizeHint;

  /// No description provided for @editProfileMainCrops.
  ///
  /// In en, this message translates to:
  /// **'Main crops'**
  String get editProfileMainCrops;

  /// No description provided for @editProfileMainCropsHint.
  ///
  /// In en, this message translates to:
  /// **'Separate with commas, e.g. Carrot, Leeks'**
  String get editProfileMainCropsHint;

  /// No description provided for @editProfileTooManyCrops.
  ///
  /// In en, this message translates to:
  /// **'Add up to 10 crops'**
  String get editProfileTooManyCrops;

  /// No description provided for @editProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get editProfileSave;

  /// No description provided for @editProfileSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get editProfileSaving;

  /// No description provided for @editProfileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your profile. Please try again.'**
  String get editProfileSaveFailed;

  /// No description provided for @editProfilePhotoPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open your photos.'**
  String get editProfilePhotoPickFailed;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// No description provided for @statusPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get statusPickedUp;

  /// No description provided for @statusInTransit.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get statusInTransit;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get statusDeclined;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get statusRequested;

  /// No description provided for @statusCountered.
  ///
  /// In en, this message translates to:
  /// **'Counter offer'**
  String get statusCountered;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @statusOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get statusOutOfStock;

  /// No description provided for @statusEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get statusEmpty;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get statusCollected;

  /// No description provided for @statusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get statusProcessing;

  /// No description provided for @statusSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get statusSettled;

  /// No description provided for @statusOnHold.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get statusOnHold;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get statusUnpaid;

  /// No description provided for @statusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get statusRefunded;

  /// No description provided for @statusDisputed.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get statusDisputed;

  /// No description provided for @statusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get statusUnderReview;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @statusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get statusSuspended;

  /// No description provided for @statusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get statusVerified;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusHarvested.
  ///
  /// In en, this message translates to:
  /// **'Harvested'**
  String get statusHarvested;

  /// No description provided for @statusSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get statusSold;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @paymentAwaitingDeposit.
  ///
  /// In en, this message translates to:
  /// **'Awaiting deposit'**
  String get paymentAwaitingDeposit;

  /// No description provided for @paymentCashDue.
  ///
  /// In en, this message translates to:
  /// **'Cash due on delivery'**
  String get paymentCashDue;

  /// No description provided for @paymentReceiptSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Receipt submitted'**
  String get paymentReceiptSubmitted;

  /// No description provided for @paymentReceiptRejected.
  ///
  /// In en, this message translates to:
  /// **'Receipt rejected'**
  String get paymentReceiptRejected;

  /// No description provided for @roleFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get roleFarmer;

  /// No description provided for @roleBuyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get roleBuyer;

  /// No description provided for @roleTransporter.
  ///
  /// In en, this message translates to:
  /// **'Transporter'**
  String get roleTransporter;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'System admin'**
  String get roleAdmin;

  /// No description provided for @roleFarmerDescription.
  ///
  /// In en, this message translates to:
  /// **'Sell your harvest with confidence.'**
  String get roleFarmerDescription;

  /// No description provided for @roleBuyerDescription.
  ///
  /// In en, this message translates to:
  /// **'Fresh produce, straight to you.'**
  String get roleBuyerDescription;

  /// No description provided for @roleTransporterDescription.
  ///
  /// In en, this message translates to:
  /// **'Earn while you serve your community.'**
  String get roleTransporterDescription;

  /// No description provided for @roleAdminDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage the Farmora ecosystem.'**
  String get roleAdminDescription;

  /// No description provided for @disputeReasonDamaged.
  ///
  /// In en, this message translates to:
  /// **'Damaged goods'**
  String get disputeReasonDamaged;

  /// No description provided for @disputeReasonWrongItems.
  ///
  /// In en, this message translates to:
  /// **'Wrong items'**
  String get disputeReasonWrongItems;

  /// No description provided for @disputeReasonLate.
  ///
  /// In en, this message translates to:
  /// **'Late delivery'**
  String get disputeReasonLate;

  /// No description provided for @disputeReasonQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality issues'**
  String get disputeReasonQuality;

  /// No description provided for @disputeReasonPricing.
  ///
  /// In en, this message translates to:
  /// **'Price difference'**
  String get disputeReasonPricing;

  /// No description provided for @disputeReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get disputeReasonOther;

  /// No description provided for @ratingExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get ratingExcellent;

  /// No description provided for @ratingGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get ratingGood;

  /// No description provided for @ratingAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get ratingAverage;

  /// No description provided for @ratingPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get ratingPoor;

  /// No description provided for @ratingTerrible.
  ///
  /// In en, this message translates to:
  /// **'Very bad'**
  String get ratingTerrible;

  /// No description provided for @ratingNone.
  ///
  /// In en, this message translates to:
  /// **'No rating'**
  String get ratingNone;

  /// No description provided for @trustHigh.
  ///
  /// In en, this message translates to:
  /// **'Highly trusted'**
  String get trustHigh;

  /// No description provided for @trustNewFarmer.
  ///
  /// In en, this message translates to:
  /// **'New farmer'**
  String get trustNewFarmer;

  /// No description provided for @trustStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get trustStandard;

  /// No description provided for @errorServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'The Farmora server could not be reached. Please try again later.'**
  String get errorServerUnreachable;

  /// No description provided for @errorSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again and retry.'**
  String get errorSignInAgain;

  /// No description provided for @errorNoPermission.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do this.'**
  String get errorNoPermission;

  /// No description provided for @errorInvalidDetails.
  ///
  /// In en, this message translates to:
  /// **'Some details are invalid.'**
  String get errorInvalidDetails;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Check your connection.'**
  String get errorTimeout;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Check your connection.'**
  String get errorOffline;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'That item no longer exists.'**
  String get errorNotFound;

  /// No description provided for @errorUploadNoPermission.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to upload this file.'**
  String get errorUploadNoPermission;

  /// No description provided for @errorUploadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Upload cancelled.'**
  String get errorUploadCancelled;

  /// No description provided for @errorStorageFull.
  ///
  /// In en, this message translates to:
  /// **'Storage is full. Please try again later.'**
  String get errorStorageFull;

  /// No description provided for @errorUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Check your connection and try again.'**
  String get errorUploadFailed;

  /// No description provided for @errorFileMissing.
  ///
  /// In en, this message translates to:
  /// **'The file no longer exists.'**
  String get errorFileMissing;

  /// No description provided for @errorStorageNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'Photo storage is not set up yet. Please contact support.'**
  String get errorStorageNotSetUp;

  /// No description provided for @errorPhotoAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Photo access was denied. Allow it in your device settings.'**
  String get errorPhotoAccessDenied;

  /// No description provided for @errorCameraAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access was denied. Allow it in your device settings.'**
  String get errorCameraAccessDenied;

  /// No description provided for @errorNoCamera.
  ///
  /// In en, this message translates to:
  /// **'No camera is available on this device.'**
  String get errorNoCamera;

  /// No description provided for @errorPickerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the photo picker.'**
  String get errorPickerFailed;

  /// No description provided for @errorImageEmpty.
  ///
  /// In en, this message translates to:
  /// **'The selected file is empty.'**
  String get errorImageEmpty;

  /// No description provided for @errorImageUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file. Please choose a JPG, PNG or WebP photo.'**
  String get errorImageUnsupported;

  /// No description provided for @errorImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image is too large ({size} MB). The limit is 5 MB.'**
  String errorImageTooLarge(String size);

  /// No description provided for @errorTooManyPhotos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Only 1 more photo can be added.} other{Only {count} more photos can be added.}}'**
  String errorTooManyPhotos(int count);

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get commonViewAll;

  /// No description provided for @commonViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get commonViewDetails;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get commonRequired;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get commonTotal;

  /// No description provided for @commonUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get commonUnknown;

  /// No description provided for @commonNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get commonNotAvailable;

  /// No description provided for @commonJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get commonJustNow;

  /// No description provided for @commonMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min ago} other{{count} mins ago}}'**
  String commonMinutesAgo(int count);

  /// No description provided for @commonHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String commonHoursAgo(int count);

  /// No description provided for @commonDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String commonDaysAgo(int count);

  /// No description provided for @commonYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @commonPerKg.
  ///
  /// In en, this message translates to:
  /// **'/kg'**
  String get commonPerKg;

  /// No description provided for @farmerEarningsRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh earnings. {reason}'**
  String farmerEarningsRefreshFailed(String reason);

  /// No description provided for @farmerEarningsSelectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select month'**
  String get farmerEarningsSelectMonth;

  /// No description provided for @farmerEarningsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get farmerEarningsThisMonth;

  /// No description provided for @farmerEarningsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get farmerEarningsThisWeek;

  /// No description provided for @farmerEarningsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly Earnings'**
  String get farmerEarningsMonthly;

  /// No description provided for @farmerEarningsMonthsShort.
  ///
  /// In en, this message translates to:
  /// **'{count}M'**
  String farmerEarningsMonthsShort(int count);

  /// No description provided for @farmerEarningsTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get farmerEarningsTransactions;

  /// No description provided for @farmerEarningsNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions in {month}.'**
  String farmerEarningsNoTransactions(String month);

  /// No description provided for @farmerEarningsNoFilteredTransactions.
  ///
  /// In en, this message translates to:
  /// **'No {filter} transactions in {month}.'**
  String farmerEarningsNoFilteredTransactions(String filter, String month);

  /// No description provided for @farmerEarningsUndatedNote.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 paid order has no payment date. It is included in Total Earnings but not in monthly figures.} other{{count} paid orders have no payment date. They are included in Total Earnings but not in monthly figures.}}'**
  String farmerEarningsUndatedNote(int count);

  /// No description provided for @farmerEarningsFilterCod.
  ///
  /// In en, this message translates to:
  /// **'COD'**
  String get farmerEarningsFilterCod;

  /// No description provided for @farmerBankDeposit.
  ///
  /// In en, this message translates to:
  /// **'Bank Deposit'**
  String get farmerBankDeposit;

  /// No description provided for @farmerCashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get farmerCashOnDelivery;

  /// No description provided for @farmerEarningsTotalUpper.
  ///
  /// In en, this message translates to:
  /// **'TOTAL EARNINGS'**
  String get farmerEarningsTotalUpper;

  /// No description provided for @farmerEarningsPendingHint.
  ///
  /// In en, this message translates to:
  /// **'Unpaid, receipt under review, or rejected'**
  String get farmerEarningsPendingHint;

  /// No description provided for @farmerEarningsChartEmpty.
  ///
  /// In en, this message translates to:
  /// **'No earnings yet. Completed payments will appear here.'**
  String get farmerEarningsChartEmpty;

  /// No description provided for @farmerEarningsPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get farmerEarningsPreviousMonth;

  /// No description provided for @farmerEarningsNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get farmerEarningsNextMonth;

  /// No description provided for @farmerEarningsMonthSummary.
  ///
  /// In en, this message translates to:
  /// **'{month} summary'**
  String farmerEarningsMonthSummary(String month);

  /// No description provided for @farmerEarningsTotalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get farmerEarningsTotalIncome;

  /// No description provided for @farmerEarningsChangeVs.
  ///
  /// In en, this message translates to:
  /// **'{percent}% vs {month}'**
  String farmerEarningsChangeVs(String percent, String month);

  /// No description provided for @farmerEarningsNoCompare.
  ///
  /// In en, this message translates to:
  /// **'No income in {month} to compare'**
  String farmerEarningsNoCompare(String month);

  /// No description provided for @farmerEarningsPaidOrders.
  ///
  /// In en, this message translates to:
  /// **'Paid orders'**
  String get farmerEarningsPaidOrders;

  /// No description provided for @farmerEarningsPendingThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Pending this month'**
  String get farmerEarningsPendingThisMonth;

  /// No description provided for @farmerEarningsByMethod.
  ///
  /// In en, this message translates to:
  /// **'By payment method'**
  String get farmerEarningsByMethod;

  /// No description provided for @farmerOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order {number}'**
  String farmerOrderNumber(String number);

  /// No description provided for @adminReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Review & Feedback Moderation'**
  String get adminReviewsTitle;

  /// No description provided for @adminReviewsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String adminReviewsFilterAll(int count);

  /// No description provided for @adminReviewsFilterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending ({count})'**
  String adminReviewsFilterPending(int count);

  /// No description provided for @adminReviewsFilterFlagged.
  ///
  /// In en, this message translates to:
  /// **'Flagged / Rejected'**
  String get adminReviewsFilterFlagged;

  /// No description provided for @adminReviewsFilterLowRating.
  ///
  /// In en, this message translates to:
  /// **'Low Rating ({count})'**
  String adminReviewsFilterLowRating(int count);

  /// No description provided for @adminReviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reviews found for this filter'**
  String get adminReviewsEmpty;

  /// No description provided for @adminReviewsReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed: {name}'**
  String adminReviewsReviewed(String name);

  /// No description provided for @adminReviewsOrder.
  ///
  /// In en, this message translates to:
  /// **'Order: {number}'**
  String adminReviewsOrder(String number);

  /// No description provided for @adminReviewsAdminNote.
  ///
  /// In en, this message translates to:
  /// **'Admin Note: {note}'**
  String adminReviewsAdminNote(String note);

  /// No description provided for @adminReviewsAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get adminReviewsAddNote;

  /// No description provided for @adminReviewsApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminReviewsApprove;

  /// No description provided for @adminReviewsApprovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Review approved and visible publicly.'**
  String get adminReviewsApprovedSnack;

  /// No description provided for @adminReviewsFlag.
  ///
  /// In en, this message translates to:
  /// **'Flag'**
  String get adminReviewsFlag;

  /// No description provided for @adminReviewsFlaggedSnack.
  ///
  /// In en, this message translates to:
  /// **'Review flagged and hidden.'**
  String get adminReviewsFlaggedSnack;

  /// No description provided for @adminReviewsDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete Review'**
  String get adminReviewsDeleteTooltip;

  /// No description provided for @adminReviewsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Review?'**
  String get adminReviewsDeleteTitle;

  /// No description provided for @adminReviewsDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this feedback entry from the platform.'**
  String get adminReviewsDeleteMessage;

  /// No description provided for @adminReviewsDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Review permanently removed.'**
  String get adminReviewsDeletedSnack;

  /// No description provided for @adminReviewsNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Moderation Note'**
  String get adminReviewsNoteTitle;

  /// No description provided for @adminReviewsNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Enter internal audit note or reasoning...'**
  String get adminReviewsNoteHint;

  /// No description provided for @adminReviewsNoteSaved.
  ///
  /// In en, this message translates to:
  /// **'Audit note saved.'**
  String get adminReviewsNoteSaved;

  /// No description provided for @adminReviewsSaveNote.
  ///
  /// In en, this message translates to:
  /// **'Save Note'**
  String get adminReviewsSaveNote;

  /// No description provided for @adminVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Review'**
  String get adminVerificationTitle;

  /// No description provided for @adminVerificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and approve farmer verification documents'**
  String get adminVerificationSubtitle;

  /// No description provided for @adminVerificationEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No verification requests'**
  String get adminVerificationEmptyTitle;

  /// No description provided for @adminVerificationEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Verification requests will appear here when farmers submit documents'**
  String get adminVerificationEmptyMessage;

  /// No description provided for @adminVerificationPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get adminVerificationPendingReview;

  /// No description provided for @adminVerificationFileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get adminVerificationFileName;

  /// No description provided for @adminVerificationFileSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get adminVerificationFileSize;

  /// No description provided for @adminVerificationImages.
  ///
  /// In en, this message translates to:
  /// **'Document Images'**
  String get adminVerificationImages;

  /// No description provided for @adminVerificationFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get adminVerificationFront;

  /// No description provided for @adminVerificationBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get adminVerificationBack;

  /// No description provided for @adminVerificationDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get adminVerificationDocument;

  /// No description provided for @adminVerificationPreview.
  ///
  /// In en, this message translates to:
  /// **'Document Preview'**
  String get adminVerificationPreview;

  /// No description provided for @adminVerificationRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason'**
  String get adminVerificationRejectionReason;

  /// No description provided for @adminVerificationRejectionHint.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for rejection...'**
  String get adminVerificationRejectionHint;

  /// No description provided for @adminVerificationApproving.
  ///
  /// In en, this message translates to:
  /// **'Approving...'**
  String get adminVerificationApproving;

  /// No description provided for @adminVerificationApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminVerificationApprove;

  /// No description provided for @adminVerificationReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminVerificationReject;

  /// No description provided for @adminVerificationConfirmRejection.
  ///
  /// In en, this message translates to:
  /// **'Confirm Rejection'**
  String get adminVerificationConfirmRejection;

  /// No description provided for @adminVerificationDocApproved.
  ///
  /// In en, this message translates to:
  /// **'This document has been approved'**
  String get adminVerificationDocApproved;

  /// No description provided for @adminVerificationDocRejected.
  ///
  /// In en, this message translates to:
  /// **'This document has been rejected'**
  String get adminVerificationDocRejected;

  /// No description provided for @adminVerificationApprovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Verification document approved successfully'**
  String get adminVerificationApprovedSnack;

  /// No description provided for @adminVerificationRejectedSnack.
  ///
  /// In en, this message translates to:
  /// **'Verification document rejected'**
  String get adminVerificationRejectedSnack;

  /// No description provided for @adminVerificationApproveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to approve: {message}'**
  String adminVerificationApproveFailed(String message);

  /// No description provided for @adminVerificationRejectFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject: {message}'**
  String adminVerificationRejectFailed(String message);

  /// No description provided for @adminServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Firebase & Server Control'**
  String get adminServerTitle;

  /// No description provided for @adminServerMaintenanceMode.
  ///
  /// In en, this message translates to:
  /// **'Platform Maintenance Mode'**
  String get adminServerMaintenanceMode;

  /// No description provided for @adminServerMaintenanceOnSnack.
  ///
  /// In en, this message translates to:
  /// **'🚨 Platform placed in MAINTENANCE MODE. Non-admin access restricted.'**
  String get adminServerMaintenanceOnSnack;

  /// No description provided for @adminServerMaintenanceOffSnack.
  ///
  /// In en, this message translates to:
  /// **'✅ Maintenance mode disabled. Marketplace trades live.'**
  String get adminServerMaintenanceOffSnack;

  /// No description provided for @adminServerMaintenanceActive.
  ///
  /// In en, this message translates to:
  /// **'Active: All buyer and farmer clients receive maintenance screen broadcast.'**
  String get adminServerMaintenanceActive;

  /// No description provided for @adminServerMaintenanceInactive.
  ///
  /// In en, this message translates to:
  /// **'Disabled: All marketplace bidding, logistics, and order operations running normally.'**
  String get adminServerMaintenanceInactive;

  /// No description provided for @adminServerNoticeLabel.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Broadcast Banner'**
  String get adminServerNoticeLabel;

  /// No description provided for @adminServerNoticeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Server upgrade in progress. Estimated return: 3:00 PM.'**
  String get adminServerNoticeHint;

  /// No description provided for @adminServerNoticeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Maintenance notice updated.'**
  String get adminServerNoticeUpdated;

  /// No description provided for @adminServerUpdateNotice.
  ///
  /// In en, this message translates to:
  /// **'Update Notice'**
  String get adminServerUpdateNotice;

  /// No description provided for @adminServerHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Firebase Infrastructure Health Monitor'**
  String get adminServerHealthTitle;

  /// No description provided for @adminServerHealthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live telemetry and cloud service status for Farmora Web & App'**
  String get adminServerHealthSubtitle;

  /// No description provided for @adminServerFirestoreName.
  ///
  /// In en, this message translates to:
  /// **'Cloud Firestore Database'**
  String get adminServerFirestoreName;

  /// No description provided for @adminServerFirestoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Active · Multi-Region (asia-south1) · 38ms'**
  String get adminServerFirestoreDetails;

  /// No description provided for @adminServerAuthName.
  ///
  /// In en, this message translates to:
  /// **'Firebase Authentication & Security Rules'**
  String get adminServerAuthName;

  /// No description provided for @adminServerAuthDetails.
  ///
  /// In en, this message translates to:
  /// **'Operational · OTP & Email/Password · RBAC enforce'**
  String get adminServerAuthDetails;

  /// No description provided for @adminServerStorageName.
  ///
  /// In en, this message translates to:
  /// **'Cloud Storage (CDN Media Bucket)'**
  String get adminServerStorageName;

  /// No description provided for @adminServerStorageDetails.
  ///
  /// In en, this message translates to:
  /// **'Connected · 100MB video quota · Image compression'**
  String get adminServerStorageDetails;

  /// No description provided for @adminServerFcmName.
  ///
  /// In en, this message translates to:
  /// **'Firebase Cloud Messaging (FCM)'**
  String get adminServerFcmName;

  /// No description provided for @adminServerFcmDetails.
  ///
  /// In en, this message translates to:
  /// **'Active · In-App Broadcasts & Push Delivery'**
  String get adminServerFcmDetails;

  /// No description provided for @adminServerHealthy.
  ///
  /// In en, this message translates to:
  /// **'HEALTHY'**
  String get adminServerHealthy;

  /// No description provided for @adminServerRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Marketplace Rules & Engine Tuning'**
  String get adminServerRulesTitle;

  /// No description provided for @adminServerCommission.
  ///
  /// In en, this message translates to:
  /// **'Platform Commission Cut'**
  String get adminServerCommission;

  /// No description provided for @adminServerPercent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String adminServerPercent(String value);

  /// No description provided for @adminServerEscrowWindow.
  ///
  /// In en, this message translates to:
  /// **'Escrow Auto-Release Window'**
  String get adminServerEscrowWindow;

  /// No description provided for @adminServerHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String adminServerHours(int count);

  /// No description provided for @adminServerHoursShort.
  ///
  /// In en, this message translates to:
  /// **'{count} h'**
  String adminServerHoursShort(int count);

  /// No description provided for @adminServerMinVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum Required Client Version'**
  String get adminServerMinVersionLabel;

  /// No description provided for @adminServerMinVersionEnforced.
  ///
  /// In en, this message translates to:
  /// **'Minimum version requirement enforced.'**
  String get adminServerMinVersionEnforced;

  /// No description provided for @adminServerEnforce.
  ///
  /// In en, this message translates to:
  /// **'Enforce'**
  String get adminServerEnforce;

  /// No description provided for @adminServerActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Operational & Maintenance Actions'**
  String get adminServerActionsTitle;

  /// No description provided for @adminServerPurgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Purge Client Cache & Force Resync'**
  String get adminServerPurgeTitle;

  /// No description provided for @adminServerPurgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clears in-memory caches and re-queries real-time listeners'**
  String get adminServerPurgeSubtitle;

  /// No description provided for @adminServerPurgeSnack.
  ///
  /// In en, this message translates to:
  /// **'🔄 Local client state purged and refreshed.'**
  String get adminServerPurgeSnack;

  /// No description provided for @adminServerBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Trigger Database Backup Snapshot'**
  String get adminServerBackupTitle;

  /// No description provided for @adminServerBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export cloud backup snapshot to cloud storage bucket'**
  String get adminServerBackupSubtitle;

  /// No description provided for @adminServerBackupSnack.
  ///
  /// In en, this message translates to:
  /// **'💾 Database backup snapshot initiated to {bucket}'**
  String adminServerBackupSnack(String bucket);

  /// No description provided for @adminServerSeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Re-seed Sri Lankan Marketplace Data'**
  String get adminServerSeedTitle;

  /// No description provided for @adminServerSeedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Attaches real LKR produce, regional orders, and logistics jobs'**
  String get adminServerSeedSubtitle;

  /// No description provided for @adminServerSeeding.
  ///
  /// In en, this message translates to:
  /// **'Seeding Sri Lankan marketplace…'**
  String get adminServerSeeding;

  /// No description provided for @adminServerSeedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Seeded successfully with authentic LKR produce and orders.'**
  String get adminServerSeedSuccess;

  /// No description provided for @adminServerSeedNotice.
  ///
  /// In en, this message translates to:
  /// **'Seed notice: {message}'**
  String adminServerSeedNotice(String message);

  /// No description provided for @adminSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform Settings'**
  String get adminSettingsTitle;

  /// No description provided for @adminSettingsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Settings update failed: {message}'**
  String adminSettingsUpdateFailed(String message);

  /// No description provided for @adminSettingsMaintenanceMode.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Mode'**
  String get adminSettingsMaintenanceMode;

  /// No description provided for @adminSettingsMaintenanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Disable access to the platform for all non-admin users.'**
  String get adminSettingsMaintenanceSubtitle;

  /// No description provided for @adminSettingsFeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Fee Configuration'**
  String get adminSettingsFeeTitle;

  /// No description provided for @adminSettingsFeeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current: {percent}%'**
  String adminSettingsFeeCurrent(String percent);

  /// No description provided for @adminSettingsFeeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform fee (basis points)'**
  String get adminSettingsFeeDialogTitle;

  /// No description provided for @adminSettingsSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Policies'**
  String get adminSettingsSecurityTitle;

  /// No description provided for @adminSettingsSessionTimeout.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Session timeout: 1 minute} other{Session timeout: {count} minutes}}'**
  String adminSettingsSessionTimeout(int count);

  /// No description provided for @adminSettingsSessionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Session timeout (minutes)'**
  String get adminSettingsSessionDialogTitle;

  /// No description provided for @adminSettingsMarketPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Market Price Intelligence'**
  String get adminSettingsMarketPriceTitle;

  /// No description provided for @adminSettingsMarketPriceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure Sri Lankan wholesale Pola benchmark rates'**
  String get adminSettingsMarketPriceSubtitle;

  /// No description provided for @adminSettingsBroadcastTitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Advisories & Weather Alerts'**
  String get adminSettingsBroadcastTitle;

  /// No description provided for @adminSettingsBroadcastSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Push emergency and operational notices to users'**
  String get adminSettingsBroadcastSubtitle;

  /// No description provided for @adminSettingsDisputeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute & Escrow Arbitrator Desk'**
  String get adminSettingsDisputeTitle;

  /// No description provided for @adminSettingsDisputeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inspect claims and trigger escrow payouts'**
  String get adminSettingsDisputeSubtitle;

  /// No description provided for @adminSettingsKycTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer & Transporter KYC Verification'**
  String get adminSettingsKycTitle;

  /// No description provided for @adminSettingsKycSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review national identity, land permits, and driving licenses'**
  String get adminSettingsKycSubtitle;

  /// No description provided for @adminSettingsAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform Analytics & Insights'**
  String get adminSettingsAnalyticsTitle;

  /// No description provided for @adminSettingsAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'GMV, volume flow, regional distribution, and export reports'**
  String get adminSettingsAnalyticsSubtitle;

  /// No description provided for @adminSettingsReviewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Moderate buyer and farmer ratings, audit notes, and flags'**
  String get adminSettingsReviewsSubtitle;

  /// No description provided for @adminSettingsServerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance mode, service latency, version enforcement, and cache ops'**
  String get adminSettingsServerSubtitle;

  /// No description provided for @adminSettingsTreasuryTitle.
  ///
  /// In en, this message translates to:
  /// **'Treasury & Bank Wire Settlements'**
  String get adminSettingsTreasuryTitle;

  /// No description provided for @adminSettingsTreasurySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer & transporter CEFT/SLIP payouts, escrow release, and wire manifests'**
  String get adminSettingsTreasurySubtitle;

  /// No description provided for @adminSettingsFleetTitle.
  ///
  /// In en, this message translates to:
  /// **'Fleet & Supply Chain Dispatch Radar'**
  String get adminSettingsFleetTitle;

  /// No description provided for @adminSettingsFleetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time tracking of active hauls, transit checkpoints, and driver loads'**
  String get adminSettingsFleetSubtitle;

  /// No description provided for @adminSettingsAuditTitle.
  ///
  /// In en, this message translates to:
  /// **'Compliance & Security Audit Trail'**
  String get adminSettingsAuditTitle;

  /// No description provided for @adminSettingsAuditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tamper-proof event logs for admin actions, security alerts, and exports'**
  String get adminSettingsAuditSubtitle;

  /// No description provided for @adminSettingsSeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Seed Sri Lankan marketplace'**
  String get adminSettingsSeedTitle;

  /// No description provided for @adminSettingsSeedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Requires registered farmer + buyer. Attaches real LKR produce, orders and jobs to those accounts.'**
  String get adminSettingsSeedSubtitle;

  /// No description provided for @adminSettingsSeeded.
  ///
  /// In en, this message translates to:
  /// **'Seeded. Sign in as farmer/buyer/transporter to see data.'**
  String get adminSettingsSeeded;

  /// No description provided for @adminSettingsSeedFailed.
  ///
  /// In en, this message translates to:
  /// **'Seed failed: {message}'**
  String adminSettingsSeedFailed(String message);

  /// No description provided for @transporterAllLocations.
  ///
  /// In en, this message translates to:
  /// **'All locations'**
  String get transporterAllLocations;

  /// No description provided for @transporterAllDestinations.
  ///
  /// In en, this message translates to:
  /// **'All destinations'**
  String get transporterAllDestinations;

  /// No description provided for @transporterAllProduce.
  ///
  /// In en, this message translates to:
  /// **'All produce'**
  String get transporterAllProduce;

  /// No description provided for @jobSignInToAccept.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to accept this job.'**
  String get jobSignInToAccept;

  /// No description provided for @jobNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This job is no longer available.'**
  String get jobNoLongerAvailable;

  /// No description provided for @jobAcceptedNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Job accepted successfully'**
  String get jobAcceptedNotifTitle;

  /// No description provided for @jobAcceptedNotifBody.
  ///
  /// In en, this message translates to:
  /// **'{produce} has been added to your active jobs.'**
  String jobAcceptedNotifBody(String produce);

  /// No description provided for @jobAcceptedAddedToMyJobs.
  ///
  /// In en, this message translates to:
  /// **'Job accepted and added to My Jobs.'**
  String get jobAcceptedAddedToMyJobs;

  /// No description provided for @jobIssueOnlyActive.
  ///
  /// In en, this message translates to:
  /// **'Only active deliveries can have an issue reported.'**
  String get jobIssueOnlyActive;

  /// No description provided for @jobIssueReportedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Issue reported. Farmora support will follow up shortly.'**
  String get jobIssueReportedSuccess;

  /// No description provided for @jobInvalidRating.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid rating.'**
  String get jobInvalidRating;

  /// No description provided for @jobThanksFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback.'**
  String get jobThanksFeedback;

  /// No description provided for @jobDeliveryCompletedNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery completed'**
  String get jobDeliveryCompletedNotifTitle;

  /// No description provided for @jobDeliveryCompletedNotifBody.
  ///
  /// In en, this message translates to:
  /// **'{produce} was delivered successfully.'**
  String jobDeliveryCompletedNotifBody(String produce);

  /// No description provided for @jobPickupConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Pickup confirmed.'**
  String get jobPickupConfirmed;

  /// No description provided for @jobDeliveryStarted.
  ///
  /// In en, this message translates to:
  /// **'Delivery started.'**
  String get jobDeliveryStarted;

  /// No description provided for @jobCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'Job cancelled.'**
  String get jobCancelledMessage;

  /// No description provided for @jobDeliveryCompletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Delivery completed successfully.'**
  String get jobDeliveryCompletedSuccess;

  /// No description provided for @transporterAvailabilityUpdated.
  ///
  /// In en, this message translates to:
  /// **'Availability updated.'**
  String get transporterAvailabilityUpdated;

  /// No description provided for @transporterNamePhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and phone number are required.'**
  String get transporterNamePhoneRequired;

  /// No description provided for @transporterRegistrationRequired.
  ///
  /// In en, this message translates to:
  /// **'Vehicle registration number is required.'**
  String get transporterRegistrationRequired;

  /// No description provided for @transporterProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully.'**
  String get transporterProfileUpdated;

  /// No description provided for @jobWarnLoadExceeds.
  ///
  /// In en, this message translates to:
  /// **'Load exceeds vehicle capacity'**
  String get jobWarnLoadExceeds;

  /// No description provided for @jobWarnSmallLoad.
  ///
  /// In en, this message translates to:
  /// **'Small load for your vehicle'**
  String get jobWarnSmallLoad;

  /// No description provided for @jobTimelineCreated.
  ///
  /// In en, this message translates to:
  /// **'Job created'**
  String get jobTimelineCreated;

  /// No description provided for @jobUnknownProduce.
  ///
  /// In en, this message translates to:
  /// **'Unknown produce'**
  String get jobUnknownProduce;

  /// No description provided for @jobNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get jobNotProvided;

  /// No description provided for @jobNotFound.
  ///
  /// In en, this message translates to:
  /// **'Job not found.'**
  String get jobNotFound;

  /// No description provided for @jobUnsupportedStatus.
  ///
  /// In en, this message translates to:
  /// **'Unsupported status update: {status}.'**
  String jobUnsupportedStatus(String status);

  /// No description provided for @jobProduceCollectionFallback.
  ///
  /// In en, this message translates to:
  /// **'Produce collection'**
  String get jobProduceCollectionFallback;

  /// No description provided for @jobPickupNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Pickup location not provided'**
  String get jobPickupNotProvided;

  /// No description provided for @jobDeliveryNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Delivery location not provided'**
  String get jobDeliveryNotProvided;

  /// No description provided for @jobFarmerDetailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Farmer details unavailable'**
  String get jobFarmerDetailsUnavailable;

  /// No description provided for @jobBuyerDetailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Buyer details unavailable'**
  String get jobBuyerDetailsUnavailable;

  /// No description provided for @jobNoPermissionUpdate.
  ///
  /// In en, this message translates to:
  /// **'Your transporter account cannot update this job.'**
  String get jobNoPermissionUpdate;

  /// No description provided for @jobNoLongerExists.
  ///
  /// In en, this message translates to:
  /// **'This collection job no longer exists.'**
  String get jobNoLongerExists;

  /// No description provided for @jobUpdatedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'This job was updated by someone else. Refresh and try again.'**
  String get jobUpdatedElsewhere;

  /// No description provided for @jobCouldNotUpdate.
  ///
  /// In en, this message translates to:
  /// **'Could not update the collection job.'**
  String get jobCouldNotUpdate;

  /// No description provided for @jobNoPermissionView.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view these collection jobs.'**
  String get jobNoPermissionView;

  /// No description provided for @jobDatabaseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The database is temporarily unavailable.'**
  String get jobDatabaseUnavailable;

  /// No description provided for @jobServiceNotReady.
  ///
  /// In en, this message translates to:
  /// **'This service is not ready yet. Please try again later.'**
  String get jobServiceNotReady;

  /// No description provided for @jobCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load collection jobs.'**
  String get jobCouldNotLoad;

  /// No description provided for @jobNotificationFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmora update'**
  String get jobNotificationFallbackTitle;

  /// No description provided for @jobAlreadyAccepted.
  ///
  /// In en, this message translates to:
  /// **'This job has already been accepted by another provider.'**
  String get jobAlreadyAccepted;

  /// No description provided for @jobNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'You are not assigned to this job.'**
  String get jobNotAssigned;

  /// No description provided for @jobCannotChangeStatus.
  ///
  /// In en, this message translates to:
  /// **'Cannot change {from} to {to}.'**
  String jobCannotChangeStatus(String from, String to);

  /// No description provided for @adminSettlementRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Record completed bank transfer'**
  String get adminSettlementRecordTitle;

  /// No description provided for @adminSettlementDisburseFor.
  ///
  /// In en, this message translates to:
  /// **'Disburse funds for {orderNumber} to:'**
  String adminSettlementDisburseFor(String orderNumber);

  /// No description provided for @adminSettlementTransferHint.
  ///
  /// In en, this message translates to:
  /// **'Transfer the funds through your bank first, then enter its real confirmation reference.'**
  String get adminSettlementTransferHint;

  /// No description provided for @adminSettlementReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank confirmation reference'**
  String get adminSettlementReferenceLabel;

  /// No description provided for @adminSettlementRecipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient: {name} ({role})'**
  String adminSettlementRecipient(String name, String role);

  /// No description provided for @adminSettlementBank.
  ///
  /// In en, this message translates to:
  /// **'Bank: {bank}'**
  String adminSettlementBank(String bank);

  /// No description provided for @adminSettlementAccount.
  ///
  /// In en, this message translates to:
  /// **'Account: {account}'**
  String adminSettlementAccount(String account);

  /// No description provided for @adminSettlementGrossOrder.
  ///
  /// In en, this message translates to:
  /// **'Gross Order:'**
  String get adminSettlementGrossOrder;

  /// No description provided for @adminSettlementPlatformFee.
  ///
  /// In en, this message translates to:
  /// **'Platform Fee (5%):'**
  String get adminSettlementPlatformFee;

  /// No description provided for @adminSettlementNetPayout.
  ///
  /// In en, this message translates to:
  /// **'Net Payout:'**
  String get adminSettlementNetPayout;

  /// No description provided for @adminSettlementEnterReference.
  ///
  /// In en, this message translates to:
  /// **'Enter the actual bank transfer reference.'**
  String get adminSettlementEnterReference;

  /// No description provided for @adminSettlementRecordFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not record transfer: {message}'**
  String adminSettlementRecordFailed(String message);

  /// No description provided for @adminSettlementRecorded.
  ///
  /// In en, this message translates to:
  /// **'Transfer reference recorded for {name}.'**
  String adminSettlementRecorded(String name);

  /// No description provided for @adminSettlementRecordTransfer.
  ///
  /// In en, this message translates to:
  /// **'Record Transfer'**
  String get adminSettlementRecordTransfer;

  /// No description provided for @adminSettlementHoldDefaultReason.
  ///
  /// In en, this message translates to:
  /// **'Suspected bank detail mismatch; flagged for manual compliance review.'**
  String get adminSettlementHoldDefaultReason;

  /// No description provided for @adminSettlementHoldTitle.
  ///
  /// In en, this message translates to:
  /// **'Place Settlement On Hold'**
  String get adminSettlementHoldTitle;

  /// No description provided for @adminSettlementHoldMessage.
  ///
  /// In en, this message translates to:
  /// **'Hold disbursement of {amount} for {name}.'**
  String adminSettlementHoldMessage(String amount, String name);

  /// No description provided for @adminSettlementHoldReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Compliance Hold Reason'**
  String get adminSettlementHoldReasonLabel;

  /// No description provided for @adminSettlementHoldApplied.
  ///
  /// In en, this message translates to:
  /// **'Settlement {id} placed on compliance hold.'**
  String adminSettlementHoldApplied(String id);

  /// No description provided for @adminSettlementApplyHold.
  ///
  /// In en, this message translates to:
  /// **'Apply Hold'**
  String get adminSettlementApplyHold;

  /// No description provided for @adminSettlementExported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Exported bank wire batch manifest (1 disbursement) for CEFT/SLIP processing.} other{Exported bank wire batch manifest ({count} disbursements) for CEFT/SLIP processing.}}'**
  String adminSettlementExported(int count);

  /// No description provided for @adminSettlementKpiDisbursed.
  ///
  /// In en, this message translates to:
  /// **'Disbursed To Date'**
  String get adminSettlementKpiDisbursed;

  /// No description provided for @adminSettlementKpiPending.
  ///
  /// In en, this message translates to:
  /// **'Pending In Vault'**
  String get adminSettlementKpiPending;

  /// No description provided for @adminSettlementKpiFees.
  ///
  /// In en, this message translates to:
  /// **'Platform Fees Kept'**
  String get adminSettlementKpiFees;

  /// No description provided for @adminSettlementKpiHeld.
  ///
  /// In en, this message translates to:
  /// **'Held Flagged'**
  String get adminSettlementKpiHeld;

  /// No description provided for @adminSettlementPayoutsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payout} other{{count} payouts}}'**
  String adminSettlementPayoutsCount(int count);

  /// No description provided for @adminSettlementFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String adminSettlementFilterAll(int count);

  /// No description provided for @adminSettlementExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export Wire CSV'**
  String get adminSettlementExportCsv;

  /// No description provided for @adminSettlementEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Settlements Found'**
  String get adminSettlementEmptyTitle;

  /// No description provided for @adminSettlementEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No payout records match \"{status}\".'**
  String adminSettlementEmptyMessage(String status);

  /// No description provided for @adminSettlementBankAccount.
  ///
  /// In en, this message translates to:
  /// **'{bank} · Acc: {account}'**
  String adminSettlementBankAccount(String bank, String account);

  /// No description provided for @adminSettlementBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Gross: {gross} | Fee (5%): {fee} | Method: {method}'**
  String adminSettlementBreakdown(String gross, String fee, String method);

  /// No description provided for @adminSettlementBankRef.
  ///
  /// In en, this message translates to:
  /// **'Bank Ref: {reference}'**
  String adminSettlementBankRef(String reference);

  /// No description provided for @adminSettlementHoldReason.
  ///
  /// In en, this message translates to:
  /// **'Hold Reason: {reason}'**
  String adminSettlementHoldReason(String reason);

  /// No description provided for @adminSettlementApproveWire.
  ///
  /// In en, this message translates to:
  /// **'Approve & Wire'**
  String get adminSettlementApproveWire;

  /// No description provided for @adminSettlementHoldPayout.
  ///
  /// In en, this message translates to:
  /// **'Hold Payout'**
  String get adminSettlementHoldPayout;

  /// No description provided for @adminSettlementResumed.
  ///
  /// In en, this message translates to:
  /// **'Disbursement resumed for wire processing.'**
  String get adminSettlementResumed;

  /// No description provided for @adminSettlementResolveHold.
  ///
  /// In en, this message translates to:
  /// **'Resolve Hold & Resume'**
  String get adminSettlementResolveHold;

  /// No description provided for @adminUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'User Management & Access Control'**
  String get adminUsersTitle;

  /// No description provided for @adminUsersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, phone, email, or user ID...'**
  String get adminUsersSearchHint;

  /// No description provided for @adminUsersAllRoles.
  ///
  /// In en, this message translates to:
  /// **'All Roles ({count})'**
  String adminUsersAllRoles(int count);

  /// No description provided for @adminUsersFarmers.
  ///
  /// In en, this message translates to:
  /// **'Farmers'**
  String get adminUsersFarmers;

  /// No description provided for @adminUsersBuyers.
  ///
  /// In en, this message translates to:
  /// **'Buyers'**
  String get adminUsersBuyers;

  /// No description provided for @adminUsersTransporters.
  ///
  /// In en, this message translates to:
  /// **'Transporters'**
  String get adminUsersTransporters;

  /// No description provided for @adminUsersAdmins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get adminUsersAdmins;

  /// No description provided for @adminUsersVerifiedOnly.
  ///
  /// In en, this message translates to:
  /// **'Verified Only'**
  String get adminUsersVerifiedOnly;

  /// No description provided for @adminUsersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No users match your criteria.'**
  String get adminUsersEmpty;

  /// No description provided for @adminUsersUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get adminUsersUnknownUser;

  /// No description provided for @adminUsersNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get adminUsersNotProvided;

  /// No description provided for @adminUsersDefaultDistrict.
  ///
  /// In en, this message translates to:
  /// **'Sri Lanka'**
  String get adminUsersDefaultDistrict;

  /// No description provided for @adminUsersRoleDistrict.
  ///
  /// In en, this message translates to:
  /// **'Role: {role} · District: {district}'**
  String adminUsersRoleDistrict(String role, String district);

  /// No description provided for @adminUsersUid.
  ///
  /// In en, this message translates to:
  /// **'UID: {uid}'**
  String adminUsersUid(String uid);

  /// No description provided for @adminUsersActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Administrative Actions'**
  String get adminUsersActionsTitle;

  /// No description provided for @adminUsersRevokeBadge.
  ///
  /// In en, this message translates to:
  /// **'Revoke Verified Badge'**
  String get adminUsersRevokeBadge;

  /// No description provided for @adminUsersGrantBadge.
  ///
  /// In en, this message translates to:
  /// **'Grant Verified Badge'**
  String get adminUsersGrantBadge;

  /// No description provided for @adminUsersRevokeBadgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove trust badge from marketplace listings'**
  String get adminUsersRevokeBadgeSubtitle;

  /// No description provided for @adminUsersGrantBadgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mark user as officially verified partner'**
  String get adminUsersGrantBadgeSubtitle;

  /// No description provided for @adminUsersVerifiedSnack.
  ///
  /// In en, this message translates to:
  /// **'User verified successfully'**
  String get adminUsersVerifiedSnack;

  /// No description provided for @adminUsersRevokedSnack.
  ///
  /// In en, this message translates to:
  /// **'Verification badge revoked'**
  String get adminUsersRevokedSnack;

  /// No description provided for @adminUsersLiftSuspension.
  ///
  /// In en, this message translates to:
  /// **'Lift User Suspension'**
  String get adminUsersLiftSuspension;

  /// No description provided for @adminUsersSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend User Account'**
  String get adminUsersSuspend;

  /// No description provided for @adminUsersLiftSuspensionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow user to trade and sign in'**
  String get adminUsersLiftSuspensionSubtitle;

  /// No description provided for @adminUsersSuspendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Block user from logging in or accepting orders'**
  String get adminUsersSuspendSubtitle;

  /// No description provided for @adminUsersRestoredSnack.
  ///
  /// In en, this message translates to:
  /// **'User account restored'**
  String get adminUsersRestoredSnack;

  /// No description provided for @adminUsersSuspendedSnack.
  ///
  /// In en, this message translates to:
  /// **'User account suspended'**
  String get adminUsersSuspendedSnack;

  /// No description provided for @adminUsersChangeRole.
  ///
  /// In en, this message translates to:
  /// **'Change User Role'**
  String get adminUsersChangeRole;

  /// No description provided for @adminUsersCurrentRole.
  ///
  /// In en, this message translates to:
  /// **'Current: {role}'**
  String adminUsersCurrentRole(String role);

  /// No description provided for @adminUsersInspectKyc.
  ///
  /// In en, this message translates to:
  /// **'Inspect KYC Verification Documents'**
  String get adminUsersInspectKyc;

  /// No description provided for @adminUsersInspectKycSubtitle.
  ///
  /// In en, this message translates to:
  /// **'National Identity Card, Land Deeds, Driving License'**
  String get adminUsersInspectKycSubtitle;

  /// No description provided for @adminUsersContact.
  ///
  /// In en, this message translates to:
  /// **'Contact: {phone} · {email}'**
  String adminUsersContact(String phone, String email);

  /// No description provided for @adminUsersChangeRoleFor.
  ///
  /// In en, this message translates to:
  /// **'Change Role for {name}'**
  String adminUsersChangeRoleFor(String name);

  /// No description provided for @adminUsersRoleFarmerOption.
  ///
  /// In en, this message translates to:
  /// **'Farmer (Grower/Producer)'**
  String get adminUsersRoleFarmerOption;

  /// No description provided for @adminUsersRoleBuyerOption.
  ///
  /// In en, this message translates to:
  /// **'Buyer (Wholesaler/Retailer)'**
  String get adminUsersRoleBuyerOption;

  /// No description provided for @adminUsersRoleTransporterOption.
  ///
  /// In en, this message translates to:
  /// **'Transporter (Logistics Provider)'**
  String get adminUsersRoleTransporterOption;

  /// No description provided for @adminUsersRoleAdminOption.
  ///
  /// In en, this message translates to:
  /// **'Admin (Platform Operations)'**
  String get adminUsersRoleAdminOption;

  /// No description provided for @adminUsersConfirmRoleChange.
  ///
  /// In en, this message translates to:
  /// **'Confirm Role Change'**
  String get adminUsersConfirmRoleChange;

  /// No description provided for @adminUsersRoleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {name} role to {role}'**
  String adminUsersRoleUpdated(String name, String role);

  /// No description provided for @adminDashTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Operations Control'**
  String get adminDashTitle;

  /// No description provided for @adminDashTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminDashTabOverview;

  /// No description provided for @adminDashTabAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get adminDashTabAnalytics;

  /// No description provided for @adminDashTabUsers.
  ///
  /// In en, this message translates to:
  /// **'Users & Access'**
  String get adminDashTabUsers;

  /// No description provided for @adminDashTabReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get adminDashTabReviews;

  /// No description provided for @adminDashTabTreasury.
  ///
  /// In en, this message translates to:
  /// **'Treasury & Payouts'**
  String get adminDashTabTreasury;

  /// No description provided for @adminDashTabDisputes.
  ///
  /// In en, this message translates to:
  /// **'Disputes & Escrow'**
  String get adminDashTabDisputes;

  /// No description provided for @adminDashTabFleet.
  ///
  /// In en, this message translates to:
  /// **'Fleet Dispatch'**
  String get adminDashTabFleet;

  /// No description provided for @adminDashTabMarket.
  ///
  /// In en, this message translates to:
  /// **'Market Rates'**
  String get adminDashTabMarket;

  /// No description provided for @adminDashTabAudit.
  ///
  /// In en, this message translates to:
  /// **'Audit Trail'**
  String get adminDashTabAudit;

  /// No description provided for @adminDashTabServer.
  ///
  /// In en, this message translates to:
  /// **'Firebase & Server'**
  String get adminDashTabServer;

  /// No description provided for @adminDashTabAdvisories.
  ///
  /// In en, this message translates to:
  /// **'Advisories'**
  String get adminDashTabAdvisories;

  /// No description provided for @adminDashGmv.
  ///
  /// In en, this message translates to:
  /// **'Platform GMV'**
  String get adminDashGmv;

  /// No description provided for @adminDashTotalTrades.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 total trade} other{{count} total trades}}'**
  String adminDashTotalTrades(int count);

  /// No description provided for @adminDashPlatformCut.
  ///
  /// In en, this message translates to:
  /// **'Platform Cut (5%)'**
  String get adminDashPlatformCut;

  /// No description provided for @adminDashEarnedCommission.
  ///
  /// In en, this message translates to:
  /// **'Earned commission'**
  String get adminDashEarnedCommission;

  /// No description provided for @adminDashEscrowLocked.
  ///
  /// In en, this message translates to:
  /// **'Escrow Locked'**
  String get adminDashEscrowLocked;

  /// No description provided for @adminDashPendingBuyerDelivery.
  ///
  /// In en, this message translates to:
  /// **'Pending buyer delivery'**
  String get adminDashPendingBuyerDelivery;

  /// No description provided for @adminDashRegisteredUsers.
  ///
  /// In en, this message translates to:
  /// **'Registered Users'**
  String get adminDashRegisteredUsers;

  /// No description provided for @adminDashPendingKyc.
  ///
  /// In en, this message translates to:
  /// **'{count} pending KYC'**
  String adminDashPendingKyc(int count);

  /// No description provided for @adminDashQuickHub.
  ///
  /// In en, this message translates to:
  /// **'Quick Operations Hub'**
  String get adminDashQuickHub;

  /// No description provided for @adminDashServerOps.
  ///
  /// In en, this message translates to:
  /// **'Server Ops'**
  String get adminDashServerOps;

  /// No description provided for @adminDashReviewKyc.
  ///
  /// In en, this message translates to:
  /// **'Review KYC'**
  String get adminDashReviewKyc;

  /// No description provided for @adminDashPolaRates.
  ///
  /// In en, this message translates to:
  /// **'Pola Rates'**
  String get adminDashPolaRates;

  /// No description provided for @adminDashBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get adminDashBroadcast;

  /// No description provided for @adminDashTreasuryPayouts.
  ///
  /// In en, this message translates to:
  /// **'Treasury Payouts'**
  String get adminDashTreasuryPayouts;

  /// No description provided for @adminDashEscrowReleases.
  ///
  /// In en, this message translates to:
  /// **'Escrow Releases'**
  String get adminDashEscrowReleases;

  /// No description provided for @adminDashRecentActivities.
  ///
  /// In en, this message translates to:
  /// **'Recent Platform Activities'**
  String get adminDashRecentActivities;

  /// No description provided for @adminDashNoRecentActivities.
  ///
  /// In en, this message translates to:
  /// **'No recent activities.'**
  String get adminDashNoRecentActivities;

  /// No description provided for @adminDashOrderCompleted.
  ///
  /// In en, this message translates to:
  /// **'Order {orderNumber} completed'**
  String adminDashOrderCompleted(String orderNumber);

  /// No description provided for @adminDashNoEscrowPending.
  ///
  /// In en, this message translates to:
  /// **'No delivered orders pending escrow release at this time.'**
  String get adminDashNoEscrowPending;

  /// No description provided for @adminDashEscrowReleased.
  ///
  /// In en, this message translates to:
  /// **'Escrow released to farmer successfully'**
  String get adminDashEscrowReleased;

  /// No description provided for @adminDashReleaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Release failed: {error}'**
  String adminDashReleaseFailed(String error);

  /// No description provided for @adminAuditSeverityInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get adminAuditSeverityInfo;

  /// No description provided for @adminAuditSeverityWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get adminAuditSeverityWarning;

  /// No description provided for @adminAuditSeverityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get adminAuditSeverityCritical;

  /// No description provided for @adminAuditTarget.
  ///
  /// In en, this message translates to:
  /// **'Target: {entity} ({id})'**
  String adminAuditTarget(String entity, String id);

  /// No description provided for @adminAuditEventDetails.
  ///
  /// In en, this message translates to:
  /// **'Audit Event Details'**
  String get adminAuditEventDetails;

  /// No description provided for @adminAuditActor.
  ///
  /// In en, this message translates to:
  /// **'Actor / Operator'**
  String get adminAuditActor;

  /// No description provided for @adminAuditActorValue.
  ///
  /// In en, this message translates to:
  /// **'{name} ({role})'**
  String adminAuditActorValue(String name, String role);

  /// No description provided for @adminAuditRecordedAt.
  ///
  /// In en, this message translates to:
  /// **'Recorded Timestamp'**
  String get adminAuditRecordedAt;

  /// No description provided for @adminAuditExported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Exported 1 audit trail record to compliance CSV archive.} other{Exported {count} audit trail records to compliance CSV archive.}}'**
  String adminAuditExported(int count);

  /// No description provided for @adminAuditSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search audit logs (action, entity ID, actor)...'**
  String get adminAuditSearchHint;

  /// No description provided for @adminAuditExportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export CSV Audit Trail'**
  String get adminAuditExportTooltip;

  /// No description provided for @adminAuditAllSeverity.
  ///
  /// In en, this message translates to:
  /// **'All Severity ({count})'**
  String adminAuditAllSeverity(int count);

  /// No description provided for @adminAuditAllModules.
  ///
  /// In en, this message translates to:
  /// **'All Modules'**
  String get adminAuditAllModules;

  /// No description provided for @adminAuditModuleOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders & Escrow'**
  String get adminAuditModuleOrders;

  /// No description provided for @adminAuditModuleSettlements.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get adminAuditModuleSettlements;

  /// No description provided for @adminAuditModuleSystem.
  ///
  /// In en, this message translates to:
  /// **'System & Server'**
  String get adminAuditModuleSystem;

  /// No description provided for @adminAuditEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Audit Events Found'**
  String get adminAuditEmptyTitle;

  /// No description provided for @adminAuditEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Try changing filters or search terms.'**
  String get adminAuditEmptyHint;

  /// No description provided for @adminBroadcastTitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Advisories & Alerts'**
  String get adminBroadcastTitle;

  /// No description provided for @adminBroadcastTemplates.
  ///
  /// In en, this message translates to:
  /// **'Quick AgriTech Templates'**
  String get adminBroadcastTemplates;

  /// No description provided for @adminBroadcastTplRainTitle.
  ///
  /// In en, this message translates to:
  /// **'Heavy Monsoon Rainfall Warning'**
  String get adminBroadcastTplRainTitle;

  /// No description provided for @adminBroadcastTplRainMessage.
  ///
  /// In en, this message translates to:
  /// **'Department of Meteorology warns of heavy rainfall across Nuwara Eliya and Badulla districts. Expect transport delays along mountain corridors.'**
  String get adminBroadcastTplRainMessage;

  /// No description provided for @adminBroadcastTplPolaTitle.
  ///
  /// In en, this message translates to:
  /// **'Dambulla Pola Festive Market Schedule'**
  String get adminBroadcastTplPolaTitle;

  /// No description provided for @adminBroadcastTplPolaMessage.
  ///
  /// In en, this message translates to:
  /// **'Dambulla Dedicated Economic Center will operate special extended trading hours this weekend. Transporters are advised to book loading bays early.'**
  String get adminBroadcastTplPolaMessage;

  /// No description provided for @adminBroadcastTplSubsidyTitle.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer & Pesticide Subsidy Advisory'**
  String get adminBroadcastTplSubsidyTitle;

  /// No description provided for @adminBroadcastTplSubsidyMessage.
  ///
  /// In en, this message translates to:
  /// **'Agrarian Services Department has updated certified organic fertilizer distribution centers across Central and Southern provinces.'**
  String get adminBroadcastTplSubsidyMessage;

  /// No description provided for @adminBroadcastCompose.
  ///
  /// In en, this message translates to:
  /// **'Compose Announcement'**
  String get adminBroadcastCompose;

  /// No description provided for @adminBroadcastHeadline.
  ///
  /// In en, this message translates to:
  /// **'Advisory Headline'**
  String get adminBroadcastHeadline;

  /// No description provided for @adminBroadcastHeadlineHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Flash Flood Alert in Nuwara Eliya'**
  String get adminBroadcastHeadlineHint;

  /// No description provided for @adminBroadcastMessage.
  ///
  /// In en, this message translates to:
  /// **'Detailed Message'**
  String get adminBroadcastMessage;

  /// No description provided for @adminBroadcastMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Provide actionable details for farmers, buyers, or transporters...'**
  String get adminBroadcastMessageHint;

  /// No description provided for @adminBroadcastAudience.
  ///
  /// In en, this message translates to:
  /// **'Target Audience'**
  String get adminBroadcastAudience;

  /// No description provided for @adminBroadcastFarmersOnly.
  ///
  /// In en, this message translates to:
  /// **'Farmers Only'**
  String get adminBroadcastFarmersOnly;

  /// No description provided for @adminBroadcastBuyersOnly.
  ///
  /// In en, this message translates to:
  /// **'Buyers Only'**
  String get adminBroadcastBuyersOnly;

  /// No description provided for @adminBroadcastTransportersOnly.
  ///
  /// In en, this message translates to:
  /// **'Transporters Only'**
  String get adminBroadcastTransportersOnly;

  /// No description provided for @adminBroadcastPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority Level'**
  String get adminBroadcastPriority;

  /// No description provided for @adminBroadcastPriorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal (Info)'**
  String get adminBroadcastPriorityNormal;

  /// No description provided for @adminBroadcastPriorityEmergency.
  ///
  /// In en, this message translates to:
  /// **'🚨 Emergency Alert'**
  String get adminBroadcastPriorityEmergency;

  /// No description provided for @adminBroadcastSending.
  ///
  /// In en, this message translates to:
  /// **'Broadcasting...'**
  String get adminBroadcastSending;

  /// No description provided for @adminBroadcastSend.
  ///
  /// In en, this message translates to:
  /// **'Send Broadcast Notification'**
  String get adminBroadcastSend;

  /// No description provided for @adminBroadcastMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Please enter both title and message.'**
  String get adminBroadcastMissingFields;

  /// No description provided for @adminBroadcastSent.
  ///
  /// In en, this message translates to:
  /// **'Advisory successfully broadcasted to users!'**
  String get adminBroadcastSent;

  /// No description provided for @adminDisputeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute & Escrow Arbitrator'**
  String get adminDisputeTitle;

  /// No description provided for @adminDisputeNoneOpen.
  ///
  /// In en, this message translates to:
  /// **'No open disputes.'**
  String get adminDisputeNoneOpen;

  /// No description provided for @adminDisputeNoneResolved.
  ///
  /// In en, this message translates to:
  /// **'No resolved disputes.'**
  String get adminDisputeNoneResolved;

  /// No description provided for @adminDisputeNoneAll.
  ///
  /// In en, this message translates to:
  /// **'No disputes.'**
  String get adminDisputeNoneAll;

  /// No description provided for @adminDisputeReference.
  ///
  /// In en, this message translates to:
  /// **'Dispute Reference: {id}'**
  String adminDisputeReference(String id);

  /// No description provided for @adminDisputeClaimReason.
  ///
  /// In en, this message translates to:
  /// **'Buyer Claim Reason'**
  String get adminDisputeClaimReason;

  /// No description provided for @adminDisputeDefaultReason.
  ///
  /// In en, this message translates to:
  /// **'Produce quality damaged upon delivery or missing quantity mismatch.'**
  String get adminDisputeDefaultReason;

  /// No description provided for @adminDisputeEscrowStatus.
  ///
  /// In en, this message translates to:
  /// **'Escrow Status: {status}'**
  String adminDisputeEscrowStatus(String status);

  /// No description provided for @adminDisputeStatusReleased.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get adminDisputeStatusReleased;

  /// No description provided for @adminDisputeStatusSplit.
  ///
  /// In en, this message translates to:
  /// **'Split settled'**
  String get adminDisputeStatusSplit;

  /// No description provided for @adminDisputeArbitrate.
  ///
  /// In en, this message translates to:
  /// **'Arbitrate'**
  String get adminDisputeArbitrate;

  /// No description provided for @adminDisputeArbitrateTitle.
  ///
  /// In en, this message translates to:
  /// **'Arbitrate Dispute'**
  String get adminDisputeArbitrateTitle;

  /// No description provided for @adminDisputeOrderAmount.
  ///
  /// In en, this message translates to:
  /// **'Order: {orderNumber} · Amount: {amount}'**
  String adminDisputeOrderAmount(String orderNumber, String amount);

  /// No description provided for @adminDisputeSelectOutcome.
  ///
  /// In en, this message translates to:
  /// **'Select Arbitration Outcome'**
  String get adminDisputeSelectOutcome;

  /// No description provided for @adminDisputeRefundTitle.
  ///
  /// In en, this message translates to:
  /// **'Full Refund to Buyer (100%)'**
  String get adminDisputeRefundTitle;

  /// No description provided for @adminDisputeRefundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Return locked escrow to buyer. Cancel order.'**
  String get adminDisputeRefundSubtitle;

  /// No description provided for @adminDisputeReleaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Release to Farmer (100%)'**
  String get adminDisputeReleaseTitle;

  /// No description provided for @adminDisputeReleaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dismiss dispute. Payout full funds to farmer.'**
  String get adminDisputeReleaseSubtitle;

  /// No description provided for @adminDisputeSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'Split Settlement (50% / 50%)'**
  String get adminDisputeSplitTitle;

  /// No description provided for @adminDisputeSplitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Partial refund to buyer, remainder to farmer.'**
  String get adminDisputeSplitSubtitle;

  /// No description provided for @adminDisputeNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin Audit Notes'**
  String get adminDisputeNotesLabel;

  /// No description provided for @adminDisputeDefaultNotes.
  ///
  /// In en, this message translates to:
  /// **'Inspected photographic evidence and verified delivery log.'**
  String get adminDisputeDefaultNotes;

  /// No description provided for @adminDisputeNotesRequired.
  ///
  /// In en, this message translates to:
  /// **'Add audit notes before resolving this dispute.'**
  String get adminDisputeNotesRequired;

  /// No description provided for @adminDisputeRecorded.
  ///
  /// In en, this message translates to:
  /// **'Dispute decision recorded.'**
  String get adminDisputeRecorded;

  /// No description provided for @adminDisputeResolveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not resolve the dispute. Try again.'**
  String get adminDisputeResolveFailed;

  /// No description provided for @adminDisputeRecordDecision.
  ///
  /// In en, this message translates to:
  /// **'Record Dispute Decision'**
  String get adminDisputeRecordDecision;

  /// No description provided for @adminLogisticsDefaultRoute.
  ///
  /// In en, this message translates to:
  /// **'Supply Corridor Dispatch'**
  String get adminLogisticsDefaultRoute;

  /// No description provided for @adminLogisticsLinkedOrder.
  ///
  /// In en, this message translates to:
  /// **'Linked Order: {orderId}'**
  String adminLogisticsLinkedOrder(String orderId);

  /// No description provided for @adminLogisticsCargoLoad.
  ///
  /// In en, this message translates to:
  /// **'Cargo Load: {load}'**
  String adminLogisticsCargoLoad(String load);

  /// No description provided for @adminLogisticsWeightKg.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg'**
  String adminLogisticsWeightKg(String weight);

  /// No description provided for @adminLogisticsStandardCrates.
  ///
  /// In en, this message translates to:
  /// **'Standard Agricultural Crates'**
  String get adminLogisticsStandardCrates;

  /// No description provided for @adminLogisticsGpsLive.
  ///
  /// In en, this message translates to:
  /// **'Driver GPS LIVE — {lat}, {lng}'**
  String adminLogisticsGpsLive(String lat, String lng);

  /// No description provided for @adminLogisticsGpsLast.
  ///
  /// In en, this message translates to:
  /// **'Last known driver GPS: {lat}, {lng}'**
  String adminLogisticsGpsLast(String lat, String lng);

  /// No description provided for @adminLogisticsFee.
  ///
  /// In en, this message translates to:
  /// **'Transporter Fee:'**
  String get adminLogisticsFee;

  /// No description provided for @adminLogisticsNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get adminLogisticsNotSet;

  /// No description provided for @adminLogisticsMilestones.
  ///
  /// In en, this message translates to:
  /// **'Transit Milestones'**
  String get adminLogisticsMilestones;

  /// No description provided for @adminLogisticsMilestoneRequested.
  ///
  /// In en, this message translates to:
  /// **'Job requested'**
  String get adminLogisticsMilestoneRequested;

  /// No description provided for @adminLogisticsMilestonePickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup confirmed'**
  String get adminLogisticsMilestonePickup;

  /// No description provided for @adminLogisticsMilestoneDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivery completed'**
  String get adminLogisticsMilestoneDelivered;

  /// No description provided for @adminLogisticsActiveInTransit.
  ///
  /// In en, this message translates to:
  /// **'Active In-Transit'**
  String get adminLogisticsActiveInTransit;

  /// No description provided for @adminLogisticsHauls.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 haul} other{{count} hauls}}'**
  String adminLogisticsHauls(int count);

  /// No description provided for @adminLogisticsAwaitingPickup.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Pickup'**
  String get adminLogisticsAwaitingPickup;

  /// No description provided for @adminLogisticsJobs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 job} other{{count} jobs}}'**
  String adminLogisticsJobs(int count);

  /// No description provided for @adminLogisticsTrips.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 trip} other{{count} trips}}'**
  String adminLogisticsTrips(int count);

  /// No description provided for @adminLogisticsAllJobs.
  ///
  /// In en, this message translates to:
  /// **'All Fleet Jobs ({count})'**
  String adminLogisticsAllJobs(int count);

  /// No description provided for @adminLogisticsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Fleet Hauls Found'**
  String get adminLogisticsEmptyTitle;

  /// No description provided for @adminLogisticsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No transport routes match the selected filter.'**
  String get adminLogisticsEmptyHint;

  /// No description provided for @adminLogisticsCentralCorridor.
  ///
  /// In en, this message translates to:
  /// **'Central Supply Corridor'**
  String get adminLogisticsCentralCorridor;

  /// No description provided for @adminLogisticsKgLoad.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg load'**
  String adminLogisticsKgLoad(String weight);

  /// No description provided for @adminLogisticsCapacity.
  ///
  /// In en, this message translates to:
  /// **'500 kg capacity'**
  String get adminLogisticsCapacity;

  /// No description provided for @adminMarketTitle.
  ///
  /// In en, this message translates to:
  /// **'Market Price Intelligence'**
  String get adminMarketTitle;

  /// No description provided for @adminMarketAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Commodity Rate'**
  String get adminMarketAddTooltip;

  /// No description provided for @adminMarketBenchmarkTitle.
  ///
  /// In en, this message translates to:
  /// **'Sri Lankan Pola Wholesale Benchmark'**
  String get adminMarketBenchmarkTitle;

  /// No description provided for @adminMarketBenchmarkBody.
  ///
  /// In en, this message translates to:
  /// **'Benchmark rates reference Dambulla, Pettah, and regional economic centers to guide buyer offers and farmer listings.'**
  String get adminMarketBenchmarkBody;

  /// No description provided for @adminMarketEmpty.
  ///
  /// In en, this message translates to:
  /// **'No commodity rates found.'**
  String get adminMarketEmpty;

  /// No description provided for @adminMarketTrendRising.
  ///
  /// In en, this message translates to:
  /// **'Price Rising'**
  String get adminMarketTrendRising;

  /// No description provided for @adminMarketTrendSoftening.
  ///
  /// In en, this message translates to:
  /// **'Price Softening'**
  String get adminMarketTrendSoftening;

  /// No description provided for @adminMarketTrendStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get adminMarketTrendStable;

  /// No description provided for @adminMarketCenterCategory.
  ///
  /// In en, this message translates to:
  /// **'{district} Economic Center · {category}'**
  String adminMarketCenterCategory(String district, String category);

  /// No description provided for @adminMarketWholesaleRange.
  ///
  /// In en, this message translates to:
  /// **'Wholesale Range'**
  String get adminMarketWholesaleRange;

  /// No description provided for @adminMarketRangePerKg.
  ///
  /// In en, this message translates to:
  /// **'{min} - {max} / kg'**
  String adminMarketRangePerKg(String min, String max);

  /// No description provided for @adminMarketPricePerKg.
  ///
  /// In en, this message translates to:
  /// **'{price} / kg'**
  String adminMarketPricePerKg(String price);

  /// No description provided for @adminMarketAvgBenchmark.
  ///
  /// In en, this message translates to:
  /// **'Avg Benchmark'**
  String get adminMarketAvgBenchmark;

  /// No description provided for @adminMarketUpdateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Update Rates'**
  String get adminMarketUpdateTooltip;

  /// No description provided for @adminMarketDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete Benchmark'**
  String get adminMarketDeleteTooltip;

  /// No description provided for @adminMarketDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {crop}?'**
  String adminMarketDeleteTitle(String crop);

  /// No description provided for @adminMarketDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the {district} benchmark from the marketplace. Farmers and buyers will no longer see this reference rate.'**
  String adminMarketDeleteBody(String district);

  /// No description provided for @adminMarketDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {crop} benchmark'**
  String adminMarketDeleted(String crop);

  /// No description provided for @adminMarketEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {crop} Benchmark'**
  String adminMarketEditTitle(String crop);

  /// No description provided for @adminMarketMinPriceKg.
  ///
  /// In en, this message translates to:
  /// **'Min Price (LKR/kg)'**
  String get adminMarketMinPriceKg;

  /// No description provided for @adminMarketMaxPriceKg.
  ///
  /// In en, this message translates to:
  /// **'Max Price (LKR/kg)'**
  String get adminMarketMaxPriceKg;

  /// No description provided for @adminMarketTrendLabel.
  ///
  /// In en, this message translates to:
  /// **'Market Trend'**
  String get adminMarketTrendLabel;

  /// No description provided for @adminMarketTrendRisingOption.
  ///
  /// In en, this message translates to:
  /// **'Rising (↑)'**
  String get adminMarketTrendRisingOption;

  /// No description provided for @adminMarketTrendStableOption.
  ///
  /// In en, this message translates to:
  /// **'Stable (→)'**
  String get adminMarketTrendStableOption;

  /// No description provided for @adminMarketTrendSofteningOption.
  ///
  /// In en, this message translates to:
  /// **'Softening (↓)'**
  String get adminMarketTrendSofteningOption;

  /// No description provided for @adminMarketUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {crop} rate'**
  String adminMarketUpdated(String crop);

  /// No description provided for @adminMarketAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Commodity Pola Rate'**
  String get adminMarketAddTitle;

  /// No description provided for @adminMarketCropName.
  ///
  /// In en, this message translates to:
  /// **'Crop / Commodity Name'**
  String get adminMarketCropName;

  /// No description provided for @adminMarketCropHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Red Dambulla Onions'**
  String get adminMarketCropHint;

  /// No description provided for @adminMarketDistrict.
  ///
  /// In en, this message translates to:
  /// **'Economic Center / District'**
  String get adminMarketDistrict;

  /// No description provided for @adminMarketDistrictHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Dambulla, Pettah, Jaffna'**
  String get adminMarketDistrictHint;

  /// No description provided for @adminMarketMinPrice.
  ///
  /// In en, this message translates to:
  /// **'Min Price'**
  String get adminMarketMinPrice;

  /// No description provided for @adminMarketMaxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get adminMarketMaxPrice;

  /// No description provided for @adminMarketAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {crop} rate'**
  String adminMarketAdded(String crop);

  /// No description provided for @adminMarketAddRate.
  ///
  /// In en, this message translates to:
  /// **'Add Rate'**
  String get adminMarketAddRate;

  /// No description provided for @adminAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform Analytics & Insights'**
  String get adminAnalyticsTitle;

  /// No description provided for @adminAnalyticsExportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export Report'**
  String get adminAnalyticsExportTooltip;

  /// No description provided for @adminAnalyticsExportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Report export is not available yet.'**
  String get adminAnalyticsExportUnavailable;

  /// No description provided for @adminAnalyticsGmv.
  ///
  /// In en, this message translates to:
  /// **'Gross Merchandise Value (GMV)'**
  String get adminAnalyticsGmv;

  /// No description provided for @adminAnalyticsEstCommission.
  ///
  /// In en, this message translates to:
  /// **'Est. commission ({rate}%): {amount}'**
  String adminAnalyticsEstCommission(String rate, String amount);

  /// No description provided for @adminAnalyticsAvgDeal.
  ///
  /// In en, this message translates to:
  /// **'Avg Deal: {amount}'**
  String adminAnalyticsAvgDeal(String amount);

  /// No description provided for @adminAnalyticsPaidUnfinished.
  ///
  /// In en, this message translates to:
  /// **'Paid, unfinished'**
  String get adminAnalyticsPaidUnfinished;

  /// No description provided for @adminAnalyticsPaidUnfinishedHint.
  ///
  /// In en, this message translates to:
  /// **'Order value; provider balance unverified'**
  String get adminAnalyticsPaidUnfinishedHint;

  /// No description provided for @adminAnalyticsFulfillment.
  ///
  /// In en, this message translates to:
  /// **'Order Fulfillment'**
  String get adminAnalyticsFulfillment;

  /// No description provided for @adminAnalyticsDeliveredSafely.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 delivered safely} other{{count} delivered safely}}'**
  String adminAnalyticsDeliveredSafely(int count);

  /// No description provided for @adminAnalyticsByLocation.
  ///
  /// In en, this message translates to:
  /// **'Active Listings by Product Location'**
  String get adminAnalyticsByLocation;

  /// No description provided for @adminAnalyticsLoadedNote.
  ///
  /// In en, this message translates to:
  /// **'Counts are based on the currently loaded active listings.'**
  String get adminAnalyticsLoadedNote;

  /// No description provided for @adminAnalyticsNoLocationListings.
  ///
  /// In en, this message translates to:
  /// **'No active listings with a location are loaded.'**
  String get adminAnalyticsNoLocationListings;

  /// No description provided for @adminAnalyticsActiveListings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active listing} other{{count} active listings}}'**
  String adminAnalyticsActiveListings(int count);

  /// No description provided for @adminAnalyticsByCategory.
  ///
  /// In en, this message translates to:
  /// **'Active Listings by Category'**
  String get adminAnalyticsByCategory;

  /// No description provided for @adminAnalyticsNoListings.
  ///
  /// In en, this message translates to:
  /// **'No active listings are loaded.'**
  String get adminAnalyticsNoListings;

  /// No description provided for @adminAnalyticsUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get adminAnalyticsUncategorized;

  /// No description provided for @adminAnalyticsEcosystem.
  ///
  /// In en, this message translates to:
  /// **'Registered Marketplace Ecosystem'**
  String get adminAnalyticsEcosystem;

  /// No description provided for @adminAnalyticsFarmers.
  ///
  /// In en, this message translates to:
  /// **'Farmers'**
  String get adminAnalyticsFarmers;

  /// No description provided for @adminAnalyticsBuyers.
  ///
  /// In en, this message translates to:
  /// **'Buyers'**
  String get adminAnalyticsBuyers;

  /// No description provided for @adminAnalyticsTransporters.
  ///
  /// In en, this message translates to:
  /// **'Transporters'**
  String get adminAnalyticsTransporters;

  /// No description provided for @adminAnalyticsTrust.
  ///
  /// In en, this message translates to:
  /// **'Trading Trust & Dispute Ratio'**
  String get adminAnalyticsTrust;

  /// No description provided for @adminAnalyticsDisputeRate.
  ///
  /// In en, this message translates to:
  /// **'Dispute Arbitration Rate'**
  String get adminAnalyticsDisputeRate;

  /// No description provided for @adminAnalyticsInTransitOrders.
  ///
  /// In en, this message translates to:
  /// **'Active In-Transit Escrow Orders: {count}'**
  String adminAnalyticsInTransitOrders(int count);

  /// No description provided for @adminAnalyticsResolvedOrders.
  ///
  /// In en, this message translates to:
  /// **'Resolved Orders: {count}'**
  String adminAnalyticsResolvedOrders(int count);

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLogin;

  /// No description provided for @authLoginWithOtp.
  ///
  /// In en, this message translates to:
  /// **'Login with OTP'**
  String get authLoginWithOtp;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get authNoAccount;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get authPasswordRequired;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials.'**
  String get authLoginFailed;

  /// No description provided for @authGoogleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed.'**
  String get authGoogleSignInFailed;

  /// No description provided for @authCouldNotSendOtp.
  ///
  /// In en, this message translates to:
  /// **'Could not send OTP.'**
  String get authCouldNotSendOtp;

  /// No description provided for @authOtpSmsSent.
  ///
  /// In en, this message translates to:
  /// **'Enter the 4-digit code sent via SMS to {phone}'**
  String authOtpSmsSent(String phone);

  /// No description provided for @authVerifyAndLogin.
  ///
  /// In en, this message translates to:
  /// **'Verify & Login'**
  String get authVerifyAndLogin;

  /// No description provided for @authResendSms.
  ///
  /// In en, this message translates to:
  /// **'Resend Code via SMS'**
  String get authResendSms;

  /// No description provided for @authOtpEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code for {phone}.'**
  String authOtpEnterCode(String phone);

  /// No description provided for @authVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get authVerificationCode;

  /// No description provided for @authNewCodeRequested.
  ///
  /// In en, this message translates to:
  /// **'A new code was requested.'**
  String get authNewCodeRequested;

  /// No description provided for @authCouldNotResendOtp.
  ///
  /// In en, this message translates to:
  /// **'Could not resend OTP.'**
  String get authCouldNotResendOtp;

  /// No description provided for @authOtpVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'OTP verification failed.'**
  String get authOtpVerificationFailed;

  /// No description provided for @authAcceptTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms of Service and Privacy Policy.'**
  String get authAcceptTermsRequired;

  /// No description provided for @authRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get authRegistrationFailed;

  /// No description provided for @authGoogleNeedsMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid mobile number before continuing with Google.'**
  String get authGoogleNeedsMobile;

  /// No description provided for @authGoogleRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Google registration failed.'**
  String get authGoogleRegistrationFailed;

  /// No description provided for @authSignupTermsNote.
  ///
  /// In en, this message translates to:
  /// **'By signing up, you agree to Farmora Marketplace Terms'**
  String get authSignupTermsNote;

  /// No description provided for @authErrInvalidRole.
  ///
  /// In en, this message translates to:
  /// **'Your account role is invalid.'**
  String get authErrInvalidRole;

  /// No description provided for @authErrProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'User profile was not found.'**
  String get authErrProfileNotFound;

  /// No description provided for @authErrNoGoogleProfile.
  ///
  /// In en, this message translates to:
  /// **'No Farmora profile found. Register with Google first.'**
  String get authErrNoGoogleProfile;

  /// No description provided for @authErrNoPhoneProfile.
  ///
  /// In en, this message translates to:
  /// **'No Farmora profile found. Register this phone number first.'**
  String get authErrNoPhoneProfile;

  /// No description provided for @authErrEnterValidMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid mobile number first.'**
  String get authErrEnterValidMobile;

  /// No description provided for @authErrPhoneFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number, for example +94771234567.'**
  String get authErrPhoneFormat;

  /// No description provided for @authErrEnterSixDigits.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit verification code.'**
  String get authErrEnterSixDigits;

  /// No description provided for @authErrRequestNewOtp.
  ///
  /// In en, this message translates to:
  /// **'Request a new OTP first.'**
  String get authErrRequestNewOtp;

  /// No description provided for @authErrPhoneTaken.
  ///
  /// In en, this message translates to:
  /// **'This mobile number is already registered.'**
  String get authErrPhoneTaken;

  /// No description provided for @authErrCouldNotSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not save your profile.'**
  String get authErrCouldNotSaveProfile;

  /// No description provided for @authErrAccountExists.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this phone number.'**
  String get authErrAccountExists;

  /// No description provided for @authErrWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Phone number or password is incorrect.'**
  String get authErrWrongCredentials;

  /// No description provided for @authErrMethodUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is not available right now.'**
  String get authErrMethodUnavailable;

  /// No description provided for @authErrInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number with country code.'**
  String get authErrInvalidPhone;

  /// No description provided for @authErrWrongOtp.
  ///
  /// In en, this message translates to:
  /// **'The OTP is incorrect. Please try again.'**
  String get authErrWrongOtp;

  /// No description provided for @authErrOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'The OTP expired. Request a new code.'**
  String get authErrOtpExpired;

  /// No description provided for @authErrSmsLimit.
  ///
  /// In en, this message translates to:
  /// **'SMS limit reached. Please try again later.'**
  String get authErrSmsLimit;

  /// No description provided for @authErrGoogleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled.'**
  String get authErrGoogleCancelled;

  /// No description provided for @authDistrictAmpara.
  ///
  /// In en, this message translates to:
  /// **'Ampara'**
  String get authDistrictAmpara;

  /// No description provided for @authDistrictAnuradhapura.
  ///
  /// In en, this message translates to:
  /// **'Anuradhapura'**
  String get authDistrictAnuradhapura;

  /// No description provided for @authDistrictBadulla.
  ///
  /// In en, this message translates to:
  /// **'Badulla'**
  String get authDistrictBadulla;

  /// No description provided for @authDistrictBatticaloa.
  ///
  /// In en, this message translates to:
  /// **'Batticaloa'**
  String get authDistrictBatticaloa;

  /// No description provided for @authDistrictColombo.
  ///
  /// In en, this message translates to:
  /// **'Colombo'**
  String get authDistrictColombo;

  /// No description provided for @authDistrictGalle.
  ///
  /// In en, this message translates to:
  /// **'Galle'**
  String get authDistrictGalle;

  /// No description provided for @authDistrictGampaha.
  ///
  /// In en, this message translates to:
  /// **'Gampaha'**
  String get authDistrictGampaha;

  /// No description provided for @authDistrictHambantota.
  ///
  /// In en, this message translates to:
  /// **'Hambantota'**
  String get authDistrictHambantota;

  /// No description provided for @authDistrictJaffna.
  ///
  /// In en, this message translates to:
  /// **'Jaffna'**
  String get authDistrictJaffna;

  /// No description provided for @authDistrictKalutara.
  ///
  /// In en, this message translates to:
  /// **'Kalutara'**
  String get authDistrictKalutara;

  /// No description provided for @authDistrictKandy.
  ///
  /// In en, this message translates to:
  /// **'Kandy'**
  String get authDistrictKandy;

  /// No description provided for @authDistrictKegalle.
  ///
  /// In en, this message translates to:
  /// **'Kegalle'**
  String get authDistrictKegalle;

  /// No description provided for @authDistrictKilinochchi.
  ///
  /// In en, this message translates to:
  /// **'Kilinochchi'**
  String get authDistrictKilinochchi;

  /// No description provided for @authDistrictKurunegala.
  ///
  /// In en, this message translates to:
  /// **'Kurunegala'**
  String get authDistrictKurunegala;

  /// No description provided for @authDistrictMannar.
  ///
  /// In en, this message translates to:
  /// **'Mannar'**
  String get authDistrictMannar;

  /// No description provided for @authDistrictMatale.
  ///
  /// In en, this message translates to:
  /// **'Matale'**
  String get authDistrictMatale;

  /// No description provided for @authDistrictMatara.
  ///
  /// In en, this message translates to:
  /// **'Matara'**
  String get authDistrictMatara;

  /// No description provided for @authDistrictMonaragala.
  ///
  /// In en, this message translates to:
  /// **'Monaragala'**
  String get authDistrictMonaragala;

  /// No description provided for @authDistrictMullaitivu.
  ///
  /// In en, this message translates to:
  /// **'Mullaitivu'**
  String get authDistrictMullaitivu;

  /// No description provided for @authDistrictNuwaraEliya.
  ///
  /// In en, this message translates to:
  /// **'Nuwara Eliya'**
  String get authDistrictNuwaraEliya;

  /// No description provided for @authDistrictPolonnaruwa.
  ///
  /// In en, this message translates to:
  /// **'Polonnaruwa'**
  String get authDistrictPolonnaruwa;

  /// No description provided for @authDistrictPuttalam.
  ///
  /// In en, this message translates to:
  /// **'Puttalam'**
  String get authDistrictPuttalam;

  /// No description provided for @authDistrictRatnapura.
  ///
  /// In en, this message translates to:
  /// **'Ratnapura'**
  String get authDistrictRatnapura;

  /// No description provided for @authDistrictTrincomalee.
  ///
  /// In en, this message translates to:
  /// **'Trincomalee'**
  String get authDistrictTrincomalee;

  /// No description provided for @authDistrictVavuniya.
  ///
  /// In en, this message translates to:
  /// **'Vavuniya'**
  String get authDistrictVavuniya;

  /// No description provided for @buyerCategoryHerbs.
  ///
  /// In en, this message translates to:
  /// **'Herbs'**
  String get buyerCategoryHerbs;

  /// No description provided for @buyerPricePerUnit.
  ///
  /// In en, this message translates to:
  /// **'{price}/{unit}'**
  String buyerPricePerUnit(String price, String unit);

  /// No description provided for @buyerQuantityWithUnit.
  ///
  /// In en, this message translates to:
  /// **'{quantity} {unit}'**
  String buyerQuantityWithUnit(String quantity, String unit);

  /// No description provided for @buyerHarvestGrowing.
  ///
  /// In en, this message translates to:
  /// **'Growing'**
  String get buyerHarvestGrowing;

  /// No description provided for @buyerHarvestPacked.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get buyerHarvestPacked;

  /// No description provided for @buyerCartTitle.
  ///
  /// In en, this message translates to:
  /// **'My Cart'**
  String get buyerCartTitle;

  /// No description provided for @buyerCartClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get buyerCartClearAll;

  /// No description provided for @buyerCartEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get buyerCartEmptyTitle;

  /// No description provided for @buyerCartEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Browse fresh produce and add items to your cart'**
  String get buyerCartEmptyHint;

  /// No description provided for @buyerContinueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue Shopping'**
  String get buyerContinueShopping;

  /// No description provided for @buyerCartSubtotalItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Subtotal (1 item)} other{Subtotal ({count} items)}}'**
  String buyerCartSubtotalItems(int count);

  /// No description provided for @buyerDeliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee'**
  String get buyerDeliveryFee;

  /// No description provided for @buyerDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get buyerDeliveryAddress;

  /// No description provided for @buyerDeliveryAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Street, city, district'**
  String get buyerDeliveryAddressHint;

  /// No description provided for @buyerCartVerifyNote.
  ///
  /// In en, this message translates to:
  /// **'Price, stock and totals are verified when the order is placed.'**
  String get buyerCartVerifyNote;

  /// No description provided for @buyerEnterAddressToOrder.
  ///
  /// In en, this message translates to:
  /// **'Enter a delivery address to place the order.'**
  String get buyerEnterAddressToOrder;

  /// No description provided for @buyerOrderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully!'**
  String get buyerOrderPlaced;

  /// No description provided for @buyerOrderPlaceFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not place order. Check address or try again.'**
  String get buyerOrderPlaceFailed;

  /// No description provided for @buyerPlacingOrder.
  ///
  /// In en, this message translates to:
  /// **'Placing…'**
  String get buyerPlacingOrder;

  /// No description provided for @buyerBrowseProduce.
  ///
  /// In en, this message translates to:
  /// **'Browse Produce'**
  String get buyerBrowseProduce;

  /// No description provided for @buyerSearchProduceHint.
  ///
  /// In en, this message translates to:
  /// **'Search fresh produce...'**
  String get buyerSearchProduceHint;

  /// No description provided for @buyerItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String buyerItemsCount(int count);

  /// No description provided for @buyerCategoryChip.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}'**
  String buyerCategoryChip(String category);

  /// No description provided for @buyerProductsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 product available} other{{count} products available}}'**
  String buyerProductsAvailable(int count);

  /// No description provided for @buyerNoProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get buyerNoProductsFound;

  /// No description provided for @buyerOrganic.
  ///
  /// In en, this message translates to:
  /// **'Organic'**
  String get buyerOrganic;

  /// No description provided for @buyerConventional.
  ///
  /// In en, this message translates to:
  /// **'Conventional'**
  String get buyerConventional;

  /// No description provided for @buyerAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added {product} to cart'**
  String buyerAddedToCart(String product);

  /// No description provided for @buyerAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get buyerAvailable;

  /// No description provided for @buyerFilterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by Category'**
  String get buyerFilterByCategory;

  /// No description provided for @buyerFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get buyerFilterTooltip;

  /// No description provided for @buyerCartTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open cart'**
  String get buyerCartTooltip;

  /// No description provided for @buyerHarvestStatus.
  ///
  /// In en, this message translates to:
  /// **'Harvest status: {status}'**
  String buyerHarvestStatus(String status);

  /// No description provided for @buyerAboutProduct.
  ///
  /// In en, this message translates to:
  /// **'About this product'**
  String get buyerAboutProduct;

  /// No description provided for @buyerRemovedFromCart.
  ///
  /// In en, this message translates to:
  /// **'Removed {product} from cart'**
  String buyerRemovedFromCart(String product);

  /// No description provided for @buyerRemoveFromCart.
  ///
  /// In en, this message translates to:
  /// **'Remove from Cart'**
  String get buyerRemoveFromCart;

  /// No description provided for @buyerMakeOffer.
  ///
  /// In en, this message translates to:
  /// **'Make Offer'**
  String get buyerMakeOffer;

  /// No description provided for @buyerAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get buyerAddToCart;

  /// No description provided for @buyerMakeAnOffer.
  ///
  /// In en, this message translates to:
  /// **'Make an Offer'**
  String get buyerMakeAnOffer;

  /// No description provided for @buyerNegotiateFor.
  ///
  /// In en, this message translates to:
  /// **'Negotiate directly for {product} (Listed: {price})'**
  String buyerNegotiateFor(String product, String price);

  /// No description provided for @buyerQuantityInUnit.
  ///
  /// In en, this message translates to:
  /// **'Quantity ({unit})'**
  String buyerQuantityInUnit(String unit);

  /// No description provided for @buyerQuantityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 50'**
  String get buyerQuantityHint;

  /// No description provided for @buyerProposedUnitPriceIn.
  ///
  /// In en, this message translates to:
  /// **'Proposed Unit Price (LKR / {unit})'**
  String buyerProposedUnitPriceIn(String unit);

  /// No description provided for @buyerPriceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 170'**
  String get buyerPriceHint;

  /// No description provided for @buyerEnterValidQtyPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid quantity and price.'**
  String get buyerEnterValidQtyPrice;

  /// No description provided for @buyerOfferSent.
  ///
  /// In en, this message translates to:
  /// **'Offer of {price} sent to farmer!'**
  String buyerOfferSent(String price);

  /// No description provided for @buyerSubmitProposal.
  ///
  /// In en, this message translates to:
  /// **'Submit Proposal'**
  String get buyerSubmitProposal;

  /// No description provided for @buyerActiveOffersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Active'**
  String buyerActiveOffersCount(int count);

  /// No description provided for @buyerNegotiationTitle.
  ///
  /// In en, this message translates to:
  /// **'Direct Price Negotiation'**
  String get buyerNegotiationTitle;

  /// No description provided for @buyerNegotiationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Propose custom prices and bulk quantities directly to local farmers.'**
  String get buyerNegotiationSubtitle;

  /// No description provided for @buyerFilterWithCount.
  ///
  /// In en, this message translates to:
  /// **'{label} ({count})'**
  String buyerFilterWithCount(String label, int count);

  /// No description provided for @buyerNoOffersFound.
  ///
  /// In en, this message translates to:
  /// **'No Offers Found'**
  String get buyerNoOffersFound;

  /// No description provided for @buyerNoOffersHint.
  ///
  /// In en, this message translates to:
  /// **'Find fresh produce in the marketplace and propose your price.'**
  String get buyerNoOffersHint;

  /// No description provided for @buyerAgriculturalCrop.
  ///
  /// In en, this message translates to:
  /// **'Agricultural Crop'**
  String get buyerAgriculturalCrop;

  /// No description provided for @buyerOfferRequestedQty.
  ///
  /// In en, this message translates to:
  /// **'Requested: {quantity}'**
  String buyerOfferRequestedQty(String quantity);

  /// No description provided for @buyerProposedUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Proposed Unit Price'**
  String get buyerProposedUnitPrice;

  /// No description provided for @buyerTotalContractValue.
  ///
  /// In en, this message translates to:
  /// **'Total Contract Value'**
  String get buyerTotalContractValue;

  /// No description provided for @buyerFarmerCounterProposal.
  ///
  /// In en, this message translates to:
  /// **'Farmer offered counter-proposal: {price}.'**
  String buyerFarmerCounterProposal(String price);

  /// No description provided for @buyerCounterAccepted.
  ///
  /// In en, this message translates to:
  /// **'Counter offer accepted! Order created.'**
  String get buyerCounterAccepted;

  /// No description provided for @buyerWithdrawOffer.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Offer'**
  String get buyerWithdrawOffer;

  /// No description provided for @buyerViewInOrders.
  ///
  /// In en, this message translates to:
  /// **'View in Orders'**
  String get buyerViewInOrders;

  /// No description provided for @buyerOrdersEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Your marketplace orders will appear here.'**
  String get buyerOrdersEmptyHint;

  /// No description provided for @buyerOrderFallback.
  ///
  /// In en, this message translates to:
  /// **'ORDER'**
  String get buyerOrderFallback;

  /// No description provided for @buyerAddressNotSet.
  ///
  /// In en, this message translates to:
  /// **'Address not set'**
  String get buyerAddressNotSet;

  /// No description provided for @buyerEscrowProtected.
  ///
  /// In en, this message translates to:
  /// **'Escrow Protected'**
  String get buyerEscrowProtected;

  /// No description provided for @buyerEscrowReleased.
  ///
  /// In en, this message translates to:
  /// **'Escrow Released'**
  String get buyerEscrowReleased;

  /// No description provided for @buyerEscrowFunded.
  ///
  /// In en, this message translates to:
  /// **'Escrow funded'**
  String get buyerEscrowFunded;

  /// No description provided for @buyerEscrowStatus.
  ///
  /// In en, this message translates to:
  /// **'Escrow: {status}'**
  String buyerEscrowStatus(String status);

  /// No description provided for @buyerTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get buyerTotalAmount;

  /// No description provided for @buyerDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get buyerDetails;

  /// No description provided for @buyerReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get buyerReceipt;

  /// No description provided for @buyerCancelOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this order? Any payment held in escrow will be refunded.'**
  String get buyerCancelOrderConfirm;

  /// No description provided for @buyerOrderDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Detail'**
  String get buyerOrderDetailTitle;

  /// No description provided for @buyerOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'ORDER {number}'**
  String buyerOrderNumber(String number);

  /// No description provided for @buyerDisputedPayoutPaused.
  ///
  /// In en, this message translates to:
  /// **'Disputed — payout paused'**
  String get buyerDisputedPayoutPaused;

  /// No description provided for @buyerRequestedFor.
  ///
  /// In en, this message translates to:
  /// **'Requested for {date}'**
  String buyerRequestedFor(String date);

  /// No description provided for @buyerOrderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get buyerOrderSummary;

  /// No description provided for @buyerProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get buyerProduct;

  /// No description provided for @buyerUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get buyerUnitPrice;

  /// No description provided for @buyerGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get buyerGrade;

  /// No description provided for @buyerLogisticsTransport.
  ///
  /// In en, this message translates to:
  /// **'Logistics & Transport'**
  String get buyerLogisticsTransport;

  /// No description provided for @buyerTransportProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get buyerTransportProvider;

  /// No description provided for @buyerAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned ({id})'**
  String buyerAssignedTo(String id);

  /// No description provided for @buyerPendingAssignment.
  ///
  /// In en, this message translates to:
  /// **'Pending Assignment'**
  String get buyerPendingAssignment;

  /// No description provided for @buyerRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get buyerRoute;

  /// No description provided for @buyerFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get buyerFee;

  /// No description provided for @buyerCancelOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get buyerCancelOrderButton;

  /// No description provided for @buyerStepOrderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order Placed'**
  String get buyerStepOrderPlaced;

  /// No description provided for @buyerStepAcceptedByFarmer.
  ///
  /// In en, this message translates to:
  /// **'Accepted by Farmer'**
  String get buyerStepAcceptedByFarmer;

  /// No description provided for @buyerOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'Order Status'**
  String get buyerOrderStatus;

  /// No description provided for @buyerEnterNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter new address'**
  String get buyerEnterNewAddress;

  /// No description provided for @buyerReviewOnlyAfterDelivery.
  ///
  /// In en, this message translates to:
  /// **'Reviews are allowed only after delivery, one per order.'**
  String get buyerReviewOnlyAfterDelivery;

  /// No description provided for @buyerWriteReviewFirst.
  ///
  /// In en, this message translates to:
  /// **'Please write a short review comment first.'**
  String get buyerWriteReviewFirst;

  /// No description provided for @buyerReviewSubmittedModeration.
  ///
  /// In en, this message translates to:
  /// **'Review submitted for moderation.'**
  String get buyerReviewSubmittedModeration;

  /// No description provided for @reviewSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit review: {error}'**
  String reviewSubmitFailed(String error);

  /// No description provided for @buyerComplaintOpened.
  ///
  /// In en, this message translates to:
  /// **'Complaint opened. Escrow is protected while it is reviewed.'**
  String get buyerComplaintOpened;

  /// No description provided for @buyerTrustAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Trust and support'**
  String get buyerTrustAndSupport;

  /// No description provided for @buyerReviewsUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reviews unlock after delivery (one per order). Complaints pause escrow release.'**
  String get buyerReviewsUnlockHint;

  /// No description provided for @buyerStarsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String buyerStarsCount(int count);

  /// No description provided for @buyerProductRating.
  ///
  /// In en, this message translates to:
  /// **'Product rating'**
  String get buyerProductRating;

  /// No description provided for @buyerReviewOrComplaintDetails.
  ///
  /// In en, this message translates to:
  /// **'Review or complaint details'**
  String get buyerReviewOrComplaintDetails;

  /// No description provided for @buyerNotFarmoraCode.
  ///
  /// In en, this message translates to:
  /// **'This is not a Farmora authenticity code.'**
  String get buyerNotFarmoraCode;

  /// No description provided for @buyerBarcodeVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Barcode could not be verified or is not assigned to you.'**
  String get buyerBarcodeVerifyFailed;

  /// No description provided for @buyerScanInstructions.
  ///
  /// In en, this message translates to:
  /// **'Scan the Farmora code attached to your parcel. Verification is required before escrow can be released.'**
  String get buyerScanInstructions;

  /// No description provided for @buyerTotalValue.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String buyerTotalValue(String amount);

  /// No description provided for @buyerFarmPickup.
  ///
  /// In en, this message translates to:
  /// **'Farm pickup'**
  String get buyerFarmPickup;

  /// No description provided for @buyerInNetwork.
  ///
  /// In en, this message translates to:
  /// **'in network'**
  String get buyerInNetwork;

  /// No description provided for @buyerDeliveryStatus.
  ///
  /// In en, this message translates to:
  /// **'Delivery Status'**
  String get buyerDeliveryStatus;

  /// No description provided for @buyerAwaitingFarmerConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting farmer confirmation'**
  String get buyerAwaitingFarmerConfirmation;

  /// No description provided for @buyerStepFarmerAccepted.
  ///
  /// In en, this message translates to:
  /// **'Farmer accepted the order'**
  String get buyerStepFarmerAccepted;

  /// No description provided for @buyerStepOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way to the buyer'**
  String get buyerStepOnTheWay;

  /// No description provided for @buyerStepBuyerReceived.
  ///
  /// In en, this message translates to:
  /// **'Buyer received the produce'**
  String get buyerStepBuyerReceived;

  /// No description provided for @buyerCourierLive.
  ///
  /// In en, this message translates to:
  /// **'Courier location is LIVE'**
  String get buyerCourierLive;

  /// No description provided for @buyerCourierLastKnown.
  ///
  /// In en, this message translates to:
  /// **'Last known courier position'**
  String get buyerCourierLastKnown;

  /// No description provided for @buyerCourierUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time} • Delivery: {status}'**
  String buyerCourierUpdated(String time, String status);

  /// No description provided for @buyerCourierDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery: {status}'**
  String buyerCourierDelivery(String status);

  /// No description provided for @buyerInProgress.
  ///
  /// In en, this message translates to:
  /// **'in progress'**
  String get buyerInProgress;

  /// No description provided for @buyerOrderInformation.
  ///
  /// In en, this message translates to:
  /// **'Order Information'**
  String get buyerOrderInformation;

  /// No description provided for @buyerOrderNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Order #'**
  String get buyerOrderNumberLabel;

  /// No description provided for @buyerDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get buyerDate;

  /// No description provided for @disputeCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Dispute'**
  String get disputeCreateTitle;

  /// No description provided for @disputeReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Reason for Dispute'**
  String get disputeReasonTitle;

  /// No description provided for @disputeReasonDamagedDesc.
  ///
  /// In en, this message translates to:
  /// **'Items arrived damaged or broken'**
  String get disputeReasonDamagedDesc;

  /// No description provided for @disputeReasonWrongItemsDesc.
  ///
  /// In en, this message translates to:
  /// **'Received different items than ordered'**
  String get disputeReasonWrongItemsDesc;

  /// No description provided for @disputeReasonLateDesc.
  ///
  /// In en, this message translates to:
  /// **'Delivery was significantly delayed'**
  String get disputeReasonLateDesc;

  /// No description provided for @disputeReasonQualityDesc.
  ///
  /// In en, this message translates to:
  /// **'Product quality did not meet expectations'**
  String get disputeReasonQualityDesc;

  /// No description provided for @disputeReasonPricingDesc.
  ///
  /// In en, this message translates to:
  /// **'Charged differently than agreed price'**
  String get disputeReasonPricingDesc;

  /// No description provided for @disputeReasonOtherDesc.
  ///
  /// In en, this message translates to:
  /// **'Other issue not listed above'**
  String get disputeReasonOtherDesc;

  /// No description provided for @disputeDescriptionHelp.
  ///
  /// In en, this message translates to:
  /// **'Please provide details about your dispute'**
  String get disputeDescriptionHelp;

  /// No description provided for @disputeDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please provide a description'**
  String get disputeDescriptionRequired;

  /// No description provided for @disputeDescriptionTooShort.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least {min} characters'**
  String disputeDescriptionTooShort(int min);

  /// No description provided for @disputeDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue in detail...'**
  String get disputeDescriptionHint;

  /// No description provided for @disputeEvidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Evidence (Optional)'**
  String get disputeEvidenceTitle;

  /// No description provided for @disputeEvidenceHelp.
  ///
  /// In en, this message translates to:
  /// **'Add photos to support your dispute'**
  String get disputeEvidenceHelp;

  /// No description provided for @disputeLoadingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Loading photos…'**
  String get disputeLoadingPhotos;

  /// No description provided for @disputeAddPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'Add Photo ({count}/{max})'**
  String disputeAddPhotoCount(int count, int max);

  /// No description provided for @disputeRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get disputeRemovePhoto;

  /// No description provided for @disputeSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Dispute'**
  String get disputeSubmit;

  /// No description provided for @disputeOpenedEscrowPaused.
  ///
  /// In en, this message translates to:
  /// **'Dispute {id} opened. Escrow is paused while it is reviewed.'**
  String disputeOpenedEscrowPaused(String id);

  /// No description provided for @disputeSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit dispute: {error}'**
  String disputeSubmitFailed(String error);

  /// No description provided for @reviewHowWasExperience.
  ///
  /// In en, this message translates to:
  /// **'How was your experience?'**
  String get reviewHowWasExperience;

  /// No description provided for @reviewTapToRate.
  ///
  /// In en, this message translates to:
  /// **'Tap to rate'**
  String get reviewTapToRate;

  /// No description provided for @reviewCommentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional Comments (Optional)'**
  String get reviewCommentsTitle;

  /// No description provided for @reviewCommentsHelp.
  ///
  /// In en, this message translates to:
  /// **'Share more details about your experience'**
  String get reviewCommentsHelp;

  /// No description provided for @reviewCommentTooLong.
  ///
  /// In en, this message translates to:
  /// **'Comment must be less than {max} characters'**
  String reviewCommentTooLong(int max);

  /// No description provided for @reviewCommentHint.
  ///
  /// In en, this message translates to:
  /// **'What did you like or dislike?'**
  String get reviewCommentHint;

  /// No description provided for @reviewGuidelinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Guidelines'**
  String get reviewGuidelinesTitle;

  /// No description provided for @reviewGuidelineHonest.
  ///
  /// In en, this message translates to:
  /// **'Be honest and specific'**
  String get reviewGuidelineHonest;

  /// No description provided for @reviewGuidelineFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus on the product and service'**
  String get reviewGuidelineFocus;

  /// No description provided for @reviewGuidelineLanguage.
  ///
  /// In en, this message translates to:
  /// **'Avoid offensive language'**
  String get reviewGuidelineLanguage;

  /// No description provided for @reviewGuidelineModeration.
  ///
  /// In en, this message translates to:
  /// **'Reviews are subject to moderation'**
  String get reviewGuidelineModeration;

  /// No description provided for @ordersTrackEveryStep.
  ///
  /// In en, this message translates to:
  /// **'Track every step from farm to table.'**
  String get ordersTrackEveryStep;

  /// No description provided for @bankDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank Details'**
  String get bankDetailsTitle;

  /// No description provided for @bankSaved.
  ///
  /// In en, this message translates to:
  /// **'Bank details saved. Buyers can now pay by bank deposit.'**
  String get bankSaved;

  /// No description provided for @bankSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save bank details: {reason}'**
  String bankSaveFailed(String reason);

  /// No description provided for @bankIntro.
  ///
  /// In en, this message translates to:
  /// **'Buyers who choose Bank Deposit will see these details and upload their deposit slip in the order chat. Money goes directly to your account.'**
  String get bankIntro;

  /// No description provided for @bankNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank name'**
  String get bankNameLabel;

  /// No description provided for @bankNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bank of Ceylon'**
  String get bankNameHint;

  /// No description provided for @bankBranchLabel.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get bankBranchLabel;

  /// No description provided for @bankBranchHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Nuwara Eliya'**
  String get bankBranchHint;

  /// No description provided for @bankHolderLabel.
  ///
  /// In en, this message translates to:
  /// **'Account holder name'**
  String get bankHolderLabel;

  /// No description provided for @bankAccountNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get bankAccountNumberLabel;

  /// No description provided for @bankAccountDigits.
  ///
  /// In en, this message translates to:
  /// **'Enter 6–18 digits'**
  String get bankAccountDigits;

  /// No description provided for @bankSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save bank details'**
  String get bankSaveButton;

  /// No description provided for @bankLabelBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bankLabelBank;

  /// No description provided for @bankLabelAccountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get bankLabelAccountName;

  /// No description provided for @bankLabelAccountNo.
  ///
  /// In en, this message translates to:
  /// **'Account no.'**
  String get bankLabelAccountNo;

  /// No description provided for @bankCopyAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Copy account number'**
  String get bankCopyAccountNumber;

  /// No description provided for @bankAccountNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Account number copied'**
  String get bankAccountNumberCopied;

  /// No description provided for @payMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get payMethodTitle;

  /// No description provided for @payMethodCod.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get payMethodCod;

  /// No description provided for @payMethodBankDeposit.
  ///
  /// In en, this message translates to:
  /// **'Bank Deposit'**
  String get payMethodBankDeposit;

  /// No description provided for @payMethodOnline.
  ///
  /// In en, this message translates to:
  /// **'Online (PayHere)'**
  String get payMethodOnline;

  /// No description provided for @payBankUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Bank deposit is unavailable: a farmer in your cart has not added bank details.'**
  String get payBankUnavailable;

  /// No description provided for @payBankDepositHint.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see the farmer\'s bank details on the order. Upload the deposit slip in the order chat.'**
  String get payBankDepositHint;

  /// No description provided for @payMarkCashTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark cash received?'**
  String get payMarkCashTitle;

  /// No description provided for @payMarkCashBody.
  ///
  /// In en, this message translates to:
  /// **'Confirm you received {amount} in cash from {buyer}. This adds it to your earnings and cannot be undone.'**
  String payMarkCashBody(String amount, String buyer);

  /// No description provided for @payMarkCashBodyNoName.
  ///
  /// In en, this message translates to:
  /// **'Confirm you received {amount} in cash from the buyer. This adds it to your earnings and cannot be undone.'**
  String payMarkCashBodyNoName(String amount);

  /// No description provided for @payCashReceived.
  ///
  /// In en, this message translates to:
  /// **'Cash received'**
  String get payCashReceived;

  /// No description provided for @payCashRecorded.
  ///
  /// In en, this message translates to:
  /// **'Cash payment recorded.'**
  String get payCashRecorded;

  /// No description provided for @payConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment?'**
  String get payConfirmTitle;

  /// No description provided for @payConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Only confirm after you see {amount} in your bank account. This adds it to your earnings.'**
  String payConfirmBody(String amount);

  /// No description provided for @payConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment'**
  String get payConfirmAction;

  /// No description provided for @payConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed.'**
  String get payConfirmed;

  /// No description provided for @payReceiptRejectedNotified.
  ///
  /// In en, this message translates to:
  /// **'Receipt rejected. The buyer has been notified.'**
  String get payReceiptRejectedNotified;

  /// No description provided for @payUploadSlipTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload deposit slip'**
  String get payUploadSlipTitle;

  /// No description provided for @payReceiptSentToFarmer.
  ///
  /// In en, this message translates to:
  /// **'Receipt sent to the farmer for confirmation.'**
  String get payReceiptSentToFarmer;

  /// No description provided for @payReceiptChatFailed.
  ///
  /// In en, this message translates to:
  /// **'Receipt submitted, but it could not be posted in chat: {reason}'**
  String payReceiptChatFailed(String reason);

  /// No description provided for @payReceiptRejectedReason.
  ///
  /// In en, this message translates to:
  /// **'Receipt rejected: {reason}'**
  String payReceiptRejectedReason(String reason);

  /// No description provided for @payOpenDepositSlip.
  ///
  /// In en, this message translates to:
  /// **'Open deposit slip'**
  String get payOpenDepositSlip;

  /// No description provided for @payDepositSlip.
  ///
  /// In en, this message translates to:
  /// **'Deposit slip'**
  String get payDepositSlip;

  /// No description provided for @payTapToView.
  ///
  /// In en, this message translates to:
  /// **'Tap to view'**
  String get payTapToView;

  /// No description provided for @payUploadingReceipt.
  ///
  /// In en, this message translates to:
  /// **'Uploading receipt... {percent}%'**
  String payUploadingReceipt(int percent);

  /// No description provided for @payReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received.'**
  String get payReceived;

  /// No description provided for @payReceivedOn.
  ///
  /// In en, this message translates to:
  /// **'Payment received on {date}.'**
  String payReceivedOn(String date);

  /// No description provided for @payGuideFarmerProof.
  ///
  /// In en, this message translates to:
  /// **'The buyer uploaded a deposit slip. Check your bank account before confirming.'**
  String get payGuideFarmerProof;

  /// No description provided for @payGuideBuyerProof.
  ///
  /// In en, this message translates to:
  /// **'Receipt sent. Waiting for the farmer to confirm the deposit.'**
  String get payGuideBuyerProof;

  /// No description provided for @payGuideFarmerRejected.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the buyer to upload a new receipt.'**
  String get payGuideFarmerRejected;

  /// No description provided for @payGuideBuyerRejected.
  ///
  /// In en, this message translates to:
  /// **'Please upload a new receipt.'**
  String get payGuideBuyerRejected;

  /// No description provided for @payGuideRefunded.
  ///
  /// In en, this message translates to:
  /// **'This payment was refunded.'**
  String get payGuideRefunded;

  /// No description provided for @payGuideDisputed.
  ///
  /// In en, this message translates to:
  /// **'Payment is on hold while the dispute is reviewed.'**
  String get payGuideDisputed;

  /// No description provided for @payGuideCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled — no payment due.'**
  String get payGuideCancelled;

  /// No description provided for @payGuideFarmerDeposit.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the buyer to deposit and upload the slip.'**
  String get payGuideFarmerDeposit;

  /// No description provided for @payGuideBuyerDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit the total to the account below, then upload a photo of the slip.'**
  String get payGuideBuyerDeposit;

  /// No description provided for @payGuideFarmerCodDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered. Mark the cash as received once you have it.'**
  String get payGuideFarmerCodDelivered;

  /// No description provided for @payGuideFarmerCod.
  ///
  /// In en, this message translates to:
  /// **'The buyer pays cash on delivery.'**
  String get payGuideFarmerCod;

  /// No description provided for @payGuideBuyerCod.
  ///
  /// In en, this message translates to:
  /// **'Pay the farmer in cash when your order is delivered.'**
  String get payGuideBuyerCod;

  /// No description provided for @payMarkCashButton.
  ///
  /// In en, this message translates to:
  /// **'Mark Cash Received'**
  String get payMarkCashButton;

  /// No description provided for @payConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get payConfirmButton;

  /// No description provided for @payRetryUpload.
  ///
  /// In en, this message translates to:
  /// **'Retry Upload'**
  String get payRetryUpload;

  /// No description provided for @payUploadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Upload Payment Receipt'**
  String get payUploadReceipt;

  /// No description provided for @payUploadNewReceipt.
  ///
  /// In en, this message translates to:
  /// **'Upload New Receipt'**
  String get payUploadNewReceipt;

  /// No description provided for @payChooseDifferentPhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a different photo'**
  String get payChooseDifferentPhoto;

  /// No description provided for @payMessageBuyer.
  ///
  /// In en, this message translates to:
  /// **'Message Buyer'**
  String get payMessageBuyer;

  /// No description provided for @payMessageFarmer.
  ///
  /// In en, this message translates to:
  /// **'Message Farmer'**
  String get payMessageFarmer;

  /// No description provided for @payRejectReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject receipt'**
  String get payRejectReceiptTitle;

  /// No description provided for @payRejectReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (shown to the buyer)'**
  String get payRejectReasonLabel;

  /// No description provided for @payRejectReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Amount does not match / slip is unreadable'**
  String get payRejectReasonHint;

  /// No description provided for @widgetAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get widgetAddPhoto;

  /// No description provided for @widgetTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get widgetTakePhoto;

  /// No description provided for @widgetChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get widgetChooseFromGallery;

  /// No description provided for @farmerOrderDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Detail'**
  String get farmerOrderDetailTitle;

  /// No description provided for @farmerOrderNumberUpper.
  ///
  /// In en, this message translates to:
  /// **'ORDER {number}'**
  String farmerOrderNumberUpper(String number);

  /// No description provided for @farmerOrderRequestedFor.
  ///
  /// In en, this message translates to:
  /// **'Requested for {date}'**
  String farmerOrderRequestedFor(String date);

  /// No description provided for @farmerOrderCalling.
  ///
  /// In en, this message translates to:
  /// **'Calling {name}...'**
  String farmerOrderCalling(String name);

  /// No description provided for @farmerOrderDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get farmerOrderDeliveryAddress;

  /// No description provided for @farmerOrderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get farmerOrderSummary;

  /// No description provided for @farmerOrderProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get farmerOrderProduct;

  /// No description provided for @farmerOrderUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get farmerOrderUnitPrice;

  /// No description provided for @farmerOrderTransportJob.
  ///
  /// In en, this message translates to:
  /// **'Transport Job'**
  String get farmerOrderTransportJob;

  /// No description provided for @farmerOrderDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get farmerOrderDriver;

  /// No description provided for @farmerOrderDriverAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned ({id})'**
  String farmerOrderDriverAssigned(String id);

  /// No description provided for @farmerOrderFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get farmerOrderFee;

  /// No description provided for @farmerOrderAcceptedBalance.
  ///
  /// In en, this message translates to:
  /// **'Order accepted! Balance updated.'**
  String get farmerOrderAcceptedBalance;

  /// No description provided for @farmerOrderAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept Order'**
  String get farmerOrderAccept;

  /// No description provided for @farmerOrderTrackLogistics.
  ///
  /// In en, this message translates to:
  /// **'Track Logistics'**
  String get farmerOrderTrackLogistics;

  /// No description provided for @farmerOrderOfferedFee.
  ///
  /// In en, this message translates to:
  /// **'Offered delivery fee'**
  String get farmerOrderOfferedFee;

  /// No description provided for @farmerOrderTransportRequested.
  ///
  /// In en, this message translates to:
  /// **'Transport requested successfully!'**
  String get farmerOrderTransportRequested;

  /// No description provided for @farmerOrderTransportRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Transport request failed. {reason}'**
  String farmerOrderTransportRequestFailed(String reason);

  /// No description provided for @farmerOrderRequestTransport.
  ///
  /// In en, this message translates to:
  /// **'Request Transport'**
  String get farmerOrderRequestTransport;

  /// No description provided for @farmerBarcodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Authenticity barcode'**
  String get farmerBarcodeTitle;

  /// No description provided for @farmerBarcodeHint.
  ///
  /// In en, this message translates to:
  /// **'Issue a signed QR for the buyer to scan after delivery.'**
  String get farmerBarcodeHint;

  /// No description provided for @farmerBarcodeIssuing.
  ///
  /// In en, this message translates to:
  /// **'Issuing...'**
  String get farmerBarcodeIssuing;

  /// No description provided for @farmerBarcodeIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue authenticity QR'**
  String get farmerBarcodeIssue;

  /// No description provided for @jobUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Job unavailable'**
  String get jobUnavailableTitle;

  /// No description provided for @jobUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This job may have been removed. Return to the jobs list.'**
  String get jobUnavailableMessage;

  /// No description provided for @jobGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get jobGoBack;

  /// No description provided for @jobNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Job #{id}'**
  String jobNumberTitle(String id);

  /// No description provided for @jobTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Job timeline'**
  String get jobTimelineTitle;

  /// No description provided for @jobVehicleSuitability.
  ///
  /// In en, this message translates to:
  /// **'Vehicle suitability'**
  String get jobVehicleSuitability;

  /// No description provided for @jobCollectionRoute.
  ///
  /// In en, this message translates to:
  /// **'Collection route'**
  String get jobCollectionRoute;

  /// No description provided for @jobPickupLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get jobPickupLabel;

  /// No description provided for @jobDeliveryLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get jobDeliveryLabel;

  /// No description provided for @jobDeliverLabel.
  ///
  /// In en, this message translates to:
  /// **'Deliver'**
  String get jobDeliverLabel;

  /// No description provided for @jobDropoffLabel.
  ///
  /// In en, this message translates to:
  /// **'Dropoff'**
  String get jobDropoffLabel;

  /// No description provided for @jobCollectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get jobCollectionLabel;

  /// No description provided for @jobCollectionNotes.
  ///
  /// In en, this message translates to:
  /// **'Collection notes'**
  String get jobCollectionNotes;

  /// No description provided for @jobNoNotes.
  ///
  /// In en, this message translates to:
  /// **'No special collection instructions were provided.'**
  String get jobNoNotes;

  /// No description provided for @jobContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get jobContacts;

  /// No description provided for @jobNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get jobNavigation;

  /// No description provided for @jobViewPickup.
  ///
  /// In en, this message translates to:
  /// **'View pickup'**
  String get jobViewPickup;

  /// No description provided for @jobCompletion.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get jobCompletion;

  /// No description provided for @jobTransactionFeedback.
  ///
  /// In en, this message translates to:
  /// **'Transaction feedback'**
  String get jobTransactionFeedback;

  /// No description provided for @jobRated.
  ///
  /// In en, this message translates to:
  /// **'Rated'**
  String get jobRated;

  /// No description provided for @jobUpdateRating.
  ///
  /// In en, this message translates to:
  /// **'Update rating'**
  String get jobUpdateRating;

  /// No description provided for @jobRateTransaction.
  ///
  /// In en, this message translates to:
  /// **'Rate this transaction'**
  String get jobRateTransaction;

  /// No description provided for @jobDeliverySupport.
  ///
  /// In en, this message translates to:
  /// **'Delivery support'**
  String get jobDeliverySupport;

  /// No description provided for @jobIssueReportedNote.
  ///
  /// In en, this message translates to:
  /// **'Issue reported — Farmora support is following up.'**
  String get jobIssueReportedNote;

  /// No description provided for @jobReportAnotherIssue.
  ///
  /// In en, this message translates to:
  /// **'Report another issue'**
  String get jobReportAnotherIssue;

  /// No description provided for @jobReportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get jobReportIssue;

  /// No description provided for @jobAcceptJobButton.
  ///
  /// In en, this message translates to:
  /// **'Accept Job'**
  String get jobAcceptJobButton;

  /// No description provided for @jobMarkAsCollected.
  ///
  /// In en, this message translates to:
  /// **'Mark as Collected'**
  String get jobMarkAsCollected;

  /// No description provided for @jobStartDeliveryButton.
  ///
  /// In en, this message translates to:
  /// **'Start Delivery'**
  String get jobStartDeliveryButton;

  /// No description provided for @jobConfirmDeliveryButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delivery'**
  String get jobConfirmDeliveryButton;

  /// No description provided for @jobCompleteDeliveryButton.
  ///
  /// In en, this message translates to:
  /// **'Complete Delivery'**
  String get jobCompleteDeliveryButton;

  /// No description provided for @jobCancelJobButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel job'**
  String get jobCancelJobButton;

  /// No description provided for @jobAcceptConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept this job?'**
  String get jobAcceptConfirmTitle;

  /// No description provided for @jobAcceptConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You will be responsible for collecting {quantity} of {produce} and delivering it to {destination}.'**
  String jobAcceptConfirmMessage(
      String quantity, String produce, String destination);

  /// No description provided for @jobAcceptConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Accept job'**
  String get jobAcceptConfirmAction;

  /// No description provided for @jobConfirmPickupTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm pickup?'**
  String get jobConfirmPickupTitle;

  /// No description provided for @jobStartDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Start delivery?'**
  String get jobStartDeliveryTitle;

  /// No description provided for @jobConfirmDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm delivery?'**
  String get jobConfirmDeliveryTitle;

  /// No description provided for @jobConfirmPickupMessage.
  ///
  /// In en, this message translates to:
  /// **'Have you collected this produce from the farmer?'**
  String get jobConfirmPickupMessage;

  /// No description provided for @jobStartDeliveryMessage.
  ///
  /// In en, this message translates to:
  /// **'Start the delivery to {destination}?'**
  String jobStartDeliveryMessage(String destination);

  /// No description provided for @jobConfirmDeliveryMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm that the produce reached {destination}.'**
  String jobConfirmDeliveryMessage(String destination);

  /// No description provided for @jobContinueDeliveryMessage.
  ///
  /// In en, this message translates to:
  /// **'Continue this delivery to {destination}?'**
  String jobContinueDeliveryMessage(String destination);

  /// No description provided for @jobMarkCollectedAction.
  ///
  /// In en, this message translates to:
  /// **'Mark collected'**
  String get jobMarkCollectedAction;

  /// No description provided for @jobStartDeliveryAction.
  ///
  /// In en, this message translates to:
  /// **'Start delivery'**
  String get jobStartDeliveryAction;

  /// No description provided for @jobCompleteDeliveryAction.
  ///
  /// In en, this message translates to:
  /// **'Complete delivery'**
  String get jobCompleteDeliveryAction;

  /// No description provided for @jobConfirmPickupAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm pickup'**
  String get jobConfirmPickupAction;

  /// No description provided for @jobConfirmDeliveryAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm delivery'**
  String get jobConfirmDeliveryAction;

  /// No description provided for @jobCancelReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Why are you cancelling?'**
  String get jobCancelReasonTitle;

  /// No description provided for @jobCancelReasonBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Vehicle breakdown'**
  String get jobCancelReasonBreakdown;

  /// No description provided for @jobCancelReasonEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get jobCancelReasonEmergency;

  /// No description provided for @jobCancelReasonUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach pickup location'**
  String get jobCancelReasonUnreachable;

  /// No description provided for @jobReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get jobReasonOther;

  /// No description provided for @jobCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this job?'**
  String get jobCancelConfirmTitle;

  /// No description provided for @jobCancelConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This cancellation will be recorded for {produce}.'**
  String jobCancelConfirmMessage(String produce);

  /// No description provided for @jobIssueVehicleProblem.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Problem'**
  String get jobIssueVehicleProblem;

  /// No description provided for @jobIssueFarmerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Farmer Unavailable'**
  String get jobIssueFarmerUnavailable;

  /// No description provided for @jobIssueBuyerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Buyer Unavailable'**
  String get jobIssueBuyerUnavailable;

  /// No description provided for @jobIssueWrongPickup.
  ///
  /// In en, this message translates to:
  /// **'Incorrect Pickup Location'**
  String get jobIssueWrongPickup;

  /// No description provided for @jobIssueWrongDelivery.
  ///
  /// In en, this message translates to:
  /// **'Incorrect Delivery Location'**
  String get jobIssueWrongDelivery;

  /// No description provided for @jobIssueProduceQuantity.
  ///
  /// In en, this message translates to:
  /// **'Produce/Quantity Issue'**
  String get jobIssueProduceQuantity;

  /// No description provided for @jobDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get jobDescriptionOptional;

  /// No description provided for @jobCommentOptional.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get jobCommentOptional;

  /// No description provided for @jobSuitableForVehicle.
  ///
  /// In en, this message translates to:
  /// **'Suitable for your vehicle'**
  String get jobSuitableForVehicle;

  /// No description provided for @jobMayExceedCapacity.
  ///
  /// In en, this message translates to:
  /// **'Load may exceed your vehicle capacity'**
  String get jobMayExceedCapacity;

  /// No description provided for @jobOrderAndPostRefs.
  ///
  /// In en, this message translates to:
  /// **'Order {order}  •  Produce post {post}'**
  String jobOrderAndPostRefs(String order, String post);

  /// No description provided for @jobNotLinked.
  ///
  /// In en, this message translates to:
  /// **'not linked'**
  String get jobNotLinked;

  /// No description provided for @jobPhoneNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Phone not provided'**
  String get jobPhoneNotProvided;

  /// No description provided for @jobNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get jobNotNow;

  /// No description provided for @jobCancelledNote.
  ///
  /// In en, this message translates to:
  /// **'Job cancelled'**
  String get jobCancelledNote;

  /// No description provided for @jobCancelledSeeNotes.
  ///
  /// In en, this message translates to:
  /// **'Job cancelled — see notes below'**
  String get jobCancelledSeeNotes;

  /// No description provided for @jobDeliveryFeeLine.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee: {amount}'**
  String jobDeliveryFeeLine(String amount);

  /// No description provided for @jobCompletedOn.
  ///
  /// In en, this message translates to:
  /// **'Completed {date}'**
  String jobCompletedOn(String date);

  /// No description provided for @jobCollectOn.
  ///
  /// In en, this message translates to:
  /// **'Collect {date}'**
  String jobCollectOn(String date);

  /// No description provided for @jobScoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'Suitability score: {score}/100'**
  String jobScoreTooltip(int score);

  /// No description provided for @transporterCouldNotLoadJobs.
  ///
  /// In en, this message translates to:
  /// **'Could not load jobs'**
  String get transporterCouldNotLoadJobs;

  /// No description provided for @jobActiveDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Delivery'**
  String get jobActiveDeliveryTitle;

  /// No description provided for @jobLiveSharingStarted.
  ///
  /// In en, this message translates to:
  /// **'Live location sharing is ON. Customers on this order can see you.'**
  String get jobLiveSharingStarted;

  /// No description provided for @jobLocationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied — enable it in Settings to share live location.'**
  String get jobLocationPermissionDenied;

  /// No description provided for @jobLocationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location updated.'**
  String get jobLocationUpdated;

  /// No description provided for @jobNoGpsFix.
  ///
  /// In en, this message translates to:
  /// **'Could not get a GPS fix. Try again outdoors.'**
  String get jobNoGpsFix;

  /// No description provided for @jobCouldNotUpdateDelivery.
  ///
  /// In en, this message translates to:
  /// **'Could not update delivery: {reason}'**
  String jobCouldNotUpdateDelivery(String reason);

  /// No description provided for @jobCallsPrivate.
  ///
  /// In en, this message translates to:
  /// **'Calls go through the app: open chat to reach the farmer or buyer. Phone numbers stay private.'**
  String get jobCallsPrivate;

  /// No description provided for @jobDestinationLine.
  ///
  /// In en, this message translates to:
  /// **'Destination: {destination}'**
  String jobDestinationLine(String destination);

  /// No description provided for @jobFeeLine.
  ///
  /// In en, this message translates to:
  /// **'Fee: {fee}'**
  String jobFeeLine(String fee);

  /// No description provided for @jobDeliveryStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery Status'**
  String get jobDeliveryStatusTitle;

  /// No description provided for @jobStepDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get jobStepDone;

  /// No description provided for @jobMarkStatus.
  ///
  /// In en, this message translates to:
  /// **'Mark {status}'**
  String jobMarkStatus(String status);

  /// No description provided for @jobLiveSharingOn.
  ///
  /// In en, this message translates to:
  /// **'Live location sharing ON'**
  String get jobLiveSharingOn;

  /// No description provided for @jobShareLiveLocation.
  ///
  /// In en, this message translates to:
  /// **'Share live location'**
  String get jobShareLiveLocation;

  /// No description provided for @jobSharingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location sharing unavailable for this job state'**
  String get jobSharingUnavailable;

  /// No description provided for @jobLiveBadge.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get jobLiveBadge;

  /// No description provided for @jobStaleBadge.
  ///
  /// In en, this message translates to:
  /// **'STALE'**
  String get jobStaleBadge;

  /// No description provided for @jobSharingOnHelp.
  ///
  /// In en, this message translates to:
  /// **'The farmer and buyer on this order can see your position in real time. Sharing stops automatically after delivery.'**
  String get jobSharingOnHelp;

  /// No description provided for @jobSharingOffHelp.
  ///
  /// In en, this message translates to:
  /// **'While a delivery is accepted and in progress you can broadcast your GPS position so the farmer and buyer can track you live.'**
  String get jobSharingOffHelp;

  /// No description provided for @jobRestartSharing.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get jobRestartSharing;

  /// No description provided for @jobStartSharing.
  ///
  /// In en, this message translates to:
  /// **'Start sharing'**
  String get jobStartSharing;

  /// No description provided for @jobUpdateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get jobUpdateNow;

  /// No description provided for @transporterVerifyToSeeJobs.
  ///
  /// In en, this message translates to:
  /// **'Verify your transporter account to see available jobs.'**
  String get transporterVerifyToSeeJobs;

  /// No description provided for @transporterDeliveryHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery History'**
  String get transporterDeliveryHistoryTitle;

  /// No description provided for @transporterNoDeliveryHistory.
  ///
  /// In en, this message translates to:
  /// **'No delivery history found.'**
  String get transporterNoDeliveryHistory;

  /// No description provided for @jobDeliveryNumber.
  ///
  /// In en, this message translates to:
  /// **'Delivery #{id}'**
  String jobDeliveryNumber(String id);

  /// No description provided for @jobOrderDeliveryFallback.
  ///
  /// In en, this message translates to:
  /// **'Order Delivery'**
  String get jobOrderDeliveryFallback;

  /// No description provided for @jobRouteFallback.
  ///
  /// In en, this message translates to:
  /// **'Farm → Destination'**
  String get jobRouteFallback;

  /// No description provided for @transporterAvailableJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Jobs'**
  String get transporterAvailableJobsTitle;

  /// No description provided for @transporterRefreshJobs.
  ///
  /// In en, this message translates to:
  /// **'Refresh jobs'**
  String get transporterRefreshJobs;

  /// No description provided for @transporterSearchJobsHint.
  ///
  /// In en, this message translates to:
  /// **'Search produce or location'**
  String get transporterSearchJobsHint;

  /// No description provided for @transporterClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get transporterClearSearch;

  /// No description provided for @transporterPickupArea.
  ///
  /// In en, this message translates to:
  /// **'Pickup area'**
  String get transporterPickupArea;

  /// No description provided for @transporterProduceLabel.
  ///
  /// In en, this message translates to:
  /// **'Produce'**
  String get transporterProduceLabel;

  /// No description provided for @transporterDestinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get transporterDestinationLabel;

  /// No description provided for @transporterAllStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get transporterAllStatuses;

  /// No description provided for @transporterAnyCollectionDate.
  ///
  /// In en, this message translates to:
  /// **'Any collection date'**
  String get transporterAnyCollectionDate;

  /// No description provided for @transporterSuitableForMyVehicle.
  ///
  /// In en, this message translates to:
  /// **'Suitable for my vehicle'**
  String get transporterSuitableForMyVehicle;

  /// No description provided for @transporterNoMatchingJobs.
  ///
  /// In en, this message translates to:
  /// **'No matching jobs'**
  String get transporterNoMatchingJobs;

  /// No description provided for @transporterNoMatchingJobsHint.
  ///
  /// In en, this message translates to:
  /// **'Try changing your filters or pull down to refresh.'**
  String get transporterNoMatchingJobsHint;

  /// No description provided for @transporterClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get transporterClearFilters;

  /// No description provided for @transporterOpenJobsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 open job} other{{count} open jobs}}'**
  String transporterOpenJobsCount(int count);

  /// No description provided for @transporterSummaryAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get transporterSummaryAvailable;

  /// No description provided for @transporterNearbyJobs.
  ///
  /// In en, this message translates to:
  /// **'Nearby available jobs'**
  String get transporterNearbyJobs;

  /// No description provided for @transporterNoOpenJobsNearby.
  ///
  /// In en, this message translates to:
  /// **'No open jobs nearby'**
  String get transporterNoOpenJobsNearby;

  /// No description provided for @transporterPullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh or check again shortly.'**
  String get transporterPullToRefresh;

  /// No description provided for @transporterRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get transporterRefresh;

  /// No description provided for @transporterGoodDay.
  ///
  /// In en, this message translates to:
  /// **'Good day,'**
  String get transporterGoodDay;

  /// No description provided for @transporterTagline.
  ///
  /// In en, this message translates to:
  /// **'Keep Sri Lanka’s harvest moving'**
  String get transporterTagline;

  /// No description provided for @transporterAvailableForJobs.
  ///
  /// In en, this message translates to:
  /// **'Available for jobs'**
  String get transporterAvailableForJobs;

  /// No description provided for @transporterCurrentlyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Currently unavailable'**
  String get transporterCurrentlyUnavailable;

  /// No description provided for @transporterReadyToClaim.
  ///
  /// In en, this message translates to:
  /// **'Ready to claim collections'**
  String get transporterReadyToClaim;

  /// No description provided for @transporterJobsStillVisible.
  ///
  /// In en, this message translates to:
  /// **'New jobs remain visible'**
  String get transporterJobsStillVisible;

  /// No description provided for @transporterEarningsSummary.
  ///
  /// In en, this message translates to:
  /// **'Today {today}\nWeek {week}\nTotal {total}'**
  String transporterEarningsSummary(String today, String week, String total);

  /// No description provided for @transporterMyJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Jobs'**
  String get transporterMyJobsTitle;

  /// No description provided for @transporterNoActiveJobs.
  ///
  /// In en, this message translates to:
  /// **'No active jobs'**
  String get transporterNoActiveJobs;

  /// No description provided for @transporterNoActiveJobsHint.
  ///
  /// In en, this message translates to:
  /// **'Jobs you accept will appear here.'**
  String get transporterNoActiveJobsHint;

  /// No description provided for @transporterNoCompletedDeliveries.
  ///
  /// In en, this message translates to:
  /// **'No completed deliveries'**
  String get transporterNoCompletedDeliveries;

  /// No description provided for @transporterNoCompletedHint.
  ///
  /// In en, this message translates to:
  /// **'Your delivery history will appear here.'**
  String get transporterNoCompletedHint;

  /// No description provided for @transporterNoCancelledJobs.
  ///
  /// In en, this message translates to:
  /// **'No cancelled jobs'**
  String get transporterNoCancelledJobs;

  /// No description provided for @transporterNoCancelledHint.
  ///
  /// In en, this message translates to:
  /// **'Cancelled assigned jobs will appear here.'**
  String get transporterNoCancelledHint;

  /// No description provided for @transporterLocationPermissionOff.
  ///
  /// In en, this message translates to:
  /// **'Location permission is off — showing all transporters without distances.'**
  String get transporterLocationPermissionOff;

  /// No description provided for @transporterDeviceLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Device location is off — showing all transporters without distances.'**
  String get transporterDeviceLocationOff;

  /// No description provided for @transporterLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Distances hidden.'**
  String get transporterLocationFailed;

  /// No description provided for @transporterNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby Transporters'**
  String get transporterNearbyTitle;

  /// No description provided for @transporterSearchNameDistrict.
  ///
  /// In en, this message translates to:
  /// **'Search by name or district…'**
  String get transporterSearchNameDistrict;

  /// No description provided for @transporterUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get transporterUseMyLocation;

  /// No description provided for @transporterLocationSet.
  ///
  /// In en, this message translates to:
  /// **'Location set — sorted by distance'**
  String get transporterLocationSet;

  /// No description provided for @transporterProvidersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 provider} other{{count} providers}}'**
  String transporterProvidersCount(int count);

  /// No description provided for @transporterNoProviders.
  ///
  /// In en, this message translates to:
  /// **'No transport providers found yet. Check back soon — new providers join after admin verification.'**
  String get transporterNoProviders;

  /// No description provided for @transporterCapacityLine.
  ///
  /// In en, this message translates to:
  /// **'Capacity: {amount}'**
  String transporterCapacityLine(String amount);

  /// No description provided for @transporterCapacityAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} {unit}'**
  String transporterCapacityAmount(String amount, String unit);

  /// No description provided for @transporterUnitTons.
  ///
  /// In en, this message translates to:
  /// **'tons'**
  String get transporterUnitTons;

  /// No description provided for @transporterAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get transporterAvailable;

  /// No description provided for @transporterBusy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get transporterBusy;

  /// No description provided for @transporterConnectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Messaging is order-scoped: open an order and tap Message to reach this provider directly.'**
  String get transporterConnectTooltip;

  /// No description provided for @transporterConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get transporterConnect;

  /// No description provided for @transporterDeliveredCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 delivered} other{{count} delivered}}'**
  String transporterDeliveredCount(int count);

  /// No description provided for @transporterThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get transporterThisMonth;

  /// No description provided for @transporterThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get transporterThisWeek;

  /// No description provided for @transporterRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get transporterRecentTransactions;

  /// No description provided for @transporterNoEarningsYet.
  ///
  /// In en, this message translates to:
  /// **'No earnings yet'**
  String get transporterNoEarningsYet;

  /// No description provided for @transporterTotalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get transporterTotalEarnings;

  /// No description provided for @transporterMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get transporterMarkAllRead;

  /// No description provided for @transporterNoNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get transporterNoNotifications;

  /// No description provided for @transporterNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Job updates and reminders will appear here.'**
  String get transporterNotificationsHint;

  /// No description provided for @transporterAvailableForNewJobs.
  ///
  /// In en, this message translates to:
  /// **'Available for new jobs'**
  String get transporterAvailableForNewJobs;

  /// No description provided for @transporterUnavailableForNewJobs.
  ///
  /// In en, this message translates to:
  /// **'Unavailable for new jobs'**
  String get transporterUnavailableForNewJobs;

  /// No description provided for @transporterManageVehicle.
  ///
  /// In en, this message translates to:
  /// **'Manage vehicle'**
  String get transporterManageVehicle;

  /// No description provided for @transporterManageVehicleHint.
  ///
  /// In en, this message translates to:
  /// **'Type, registration and load capacity'**
  String get transporterManageVehicleHint;

  /// No description provided for @transporterVehicleInfo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle information'**
  String get transporterVehicleInfo;

  /// No description provided for @transporterRegistrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Registration number'**
  String get transporterRegistrationNumber;

  /// No description provided for @transporterMaxCapacity.
  ///
  /// In en, this message translates to:
  /// **'Maximum capacity'**
  String get transporterMaxCapacity;

  /// No description provided for @transporterLogoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get transporterLogoutConfirmTitle;

  /// No description provided for @transporterLogoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to manage collection jobs.'**
  String get transporterLogoutConfirmMessage;

  /// No description provided for @transporterFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get transporterFullName;

  /// No description provided for @transporterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get transporterPhoneNumber;

  /// No description provided for @transporterFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String transporterFieldRequired(String field);

  /// No description provided for @transporterCapacityUnit.
  ///
  /// In en, this message translates to:
  /// **'Capacity unit'**
  String get transporterCapacityUnit;

  /// No description provided for @transporterUnitKilograms.
  ///
  /// In en, this message translates to:
  /// **'Kilograms (kg)'**
  String get transporterUnitKilograms;

  /// No description provided for @transporterUnitTonsOption.
  ///
  /// In en, this message translates to:
  /// **'Tons'**
  String get transporterUnitTonsOption;

  /// No description provided for @transporterMaxLoadCapacity.
  ///
  /// In en, this message translates to:
  /// **'Maximum load capacity'**
  String get transporterMaxLoadCapacity;

  /// No description provided for @transporterVehicleDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Vehicle description (optional)'**
  String get transporterVehicleDescriptionOptional;

  /// No description provided for @transporterSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get transporterSaveChanges;

  /// No description provided for @transporterRequestDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Details'**
  String get transporterRequestDetailsTitle;

  /// No description provided for @transporterMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get transporterMessage;

  /// No description provided for @jobTransportJobFallback.
  ///
  /// In en, this message translates to:
  /// **'Transport job'**
  String get jobTransportJobFallback;

  /// No description provided for @jobRouteLine.
  ///
  /// In en, this message translates to:
  /// **'{pickup} → {dropoff}'**
  String jobRouteLine(String pickup, String dropoff);

  /// No description provided for @transporterDistrictLine.
  ///
  /// In en, this message translates to:
  /// **'District: {district}'**
  String transporterDistrictLine(String district);

  /// No description provided for @transporterLoadLine.
  ///
  /// In en, this message translates to:
  /// **'Load: {weight} kg'**
  String transporterLoadLine(String weight);

  /// No description provided for @transporterLinkedOrderId.
  ///
  /// In en, this message translates to:
  /// **'Linked Order ID'**
  String get transporterLinkedOrderId;

  /// No description provided for @transporterStatusLine.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String transporterStatusLine(String status);

  /// No description provided for @transporterPickupDropoffLine.
  ///
  /// In en, this message translates to:
  /// **'Pickup: {pickup} · Dropoff: {dropoff}'**
  String transporterPickupDropoffLine(String pickup, String dropoff);

  /// No description provided for @transporterContactPrivate.
  ///
  /// In en, this message translates to:
  /// **'Contact via in-app messaging — phone numbers stay private.'**
  String get transporterContactPrivate;

  /// No description provided for @transporterAcceptRequest.
  ///
  /// In en, this message translates to:
  /// **'Accept Request'**
  String get transporterAcceptRequest;

  /// No description provided for @transporterMarkPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Mark as Picked Up'**
  String get transporterMarkPickedUp;

  /// No description provided for @transporterMarkInTransit.
  ///
  /// In en, this message translates to:
  /// **'Mark as In Transit'**
  String get transporterMarkInTransit;

  /// No description provided for @transporterMarkDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark as Delivered'**
  String get transporterMarkDelivered;

  /// No description provided for @farmerOrderDeclinedSnack.
  ///
  /// In en, this message translates to:
  /// **'Declined {number}'**
  String farmerOrderDeclinedSnack(String number);

  /// No description provided for @farmerOrderAcceptedSnack.
  ///
  /// In en, this message translates to:
  /// **'Accepted {number}! Balance updated.'**
  String farmerOrderAcceptedSnack(String number);

  /// No description provided for @farmerJobsCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this transport request?'**
  String get farmerJobsCancelConfirm;

  /// No description provided for @farmerJobsCancelRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get farmerJobsCancelRequestButton;

  /// No description provided for @farmerJobsOneLoad.
  ///
  /// In en, this message translates to:
  /// **'1 load'**
  String get farmerJobsOneLoad;

  /// No description provided for @farmerJobsDirectBuyer.
  ///
  /// In en, this message translates to:
  /// **'Direct Buyer'**
  String get farmerJobsDirectBuyer;

  /// No description provided for @farmerProductName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get farmerProductName;

  /// No description provided for @farmerPricePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Price per unit'**
  String get farmerPricePerUnit;

  /// No description provided for @chatSendDepositSlip.
  ///
  /// In en, this message translates to:
  /// **'Send deposit slip'**
  String get chatSendDepositSlip;

  /// No description provided for @chatSendPhoto.
  ///
  /// In en, this message translates to:
  /// **'Send a photo'**
  String get chatSendPhoto;

  /// No description provided for @chatNoPeerKey.
  ///
  /// In en, this message translates to:
  /// **'The other person has not opened chat yet, so text can\'t be encrypted for them. You can still send photos.'**
  String get chatNoPeerKey;

  /// No description provided for @chatReceiptSent.
  ///
  /// In en, this message translates to:
  /// **'Receipt sent. The farmer will confirm your payment.'**
  String get chatReceiptSent;

  /// No description provided for @chatPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get chatPhoto;

  /// No description provided for @chatPhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send a picture of your produce or delivery'**
  String get chatPhotoSubtitle;

  /// No description provided for @chatPaymentReceipt.
  ///
  /// In en, this message translates to:
  /// **'Payment receipt'**
  String get chatPaymentReceipt;

  /// No description provided for @chatReceiptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit slip for {amount} — the farmer will confirm it'**
  String chatReceiptSubtitle(String amount);

  /// No description provided for @chatEncryptedPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'[encrypted]'**
  String get chatEncryptedPlaceholder;

  /// No description provided for @chatUndecryptable.
  ///
  /// In en, this message translates to:
  /// **'[undecryptable]'**
  String get chatUndecryptable;

  /// No description provided for @chatOrderChatWith.
  ///
  /// In en, this message translates to:
  /// **'Order chat · {product}'**
  String chatOrderChatWith(String product);

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'Say hello. Messages are order-scoped and text is encrypted for the recipient.'**
  String get chatEmpty;

  /// No description provided for @chatOpenReceipt.
  ///
  /// In en, this message translates to:
  /// **'Open payment receipt'**
  String get chatOpenReceipt;

  /// No description provided for @chatOpenPhoto.
  ///
  /// In en, this message translates to:
  /// **'Open photo'**
  String get chatOpenPhoto;

  /// No description provided for @chatNotSent.
  ///
  /// In en, this message translates to:
  /// **'Not sent.'**
  String get chatNotSent;

  /// No description provided for @chatRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get chatRetry;

  /// No description provided for @chatDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get chatDiscard;

  /// No description provided for @chatAttachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach photo'**
  String get chatAttachPhoto;

  /// No description provided for @chatTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get chatTypeMessage;

  /// No description provided for @chatStartWithFarmer.
  ///
  /// In en, this message translates to:
  /// **'Start a private chat with the farmer about this order. Phone numbers stay private.'**
  String get chatStartWithFarmer;

  /// No description provided for @chatStartWithBuyer.
  ///
  /// In en, this message translates to:
  /// **'Start a private chat with the buyer about this order. Phone numbers stay private.'**
  String get chatStartWithBuyer;

  /// No description provided for @chatMessageTheFarmer.
  ///
  /// In en, this message translates to:
  /// **'Message the farmer'**
  String get chatMessageTheFarmer;

  /// No description provided for @chatMessageTheBuyer.
  ///
  /// In en, this message translates to:
  /// **'Message the buyer'**
  String get chatMessageTheBuyer;

  /// No description provided for @chatNoConversations.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Open an order and tap Message to contact the other party. Phone numbers stay private.'**
  String get chatNoConversations;

  /// No description provided for @chatNoMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatNoMessagesYet;

  /// No description provided for @chatEncryptedMessage.
  ///
  /// In en, this message translates to:
  /// **'Encrypted message'**
  String get chatEncryptedMessage;

  /// No description provided for @chatOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String chatOrderTitle(String id);

  /// No description provided for @chatOrderTitleNoId.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get chatOrderTitleNoId;

  /// No description provided for @chatUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unread message} other{{count} unread messages}}'**
  String chatUnreadCount(int count);

  /// No description provided for @widgetImageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'This image could not be loaded.'**
  String get widgetImageLoadFailed;

  /// No description provided for @widgetVideoLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load harvest video.'**
  String get widgetVideoLoadFailed;

  /// No description provided for @widgetHarvestVideo.
  ///
  /// In en, this message translates to:
  /// **'Harvest video'**
  String get widgetHarvestVideo;

  /// No description provided for @widgetPlayVideo.
  ///
  /// In en, this message translates to:
  /// **'Play video'**
  String get widgetPlayVideo;

  /// No description provided for @widgetPauseVideo.
  ///
  /// In en, this message translates to:
  /// **'Pause video'**
  String get widgetPauseVideo;

  /// No description provided for @widgetFarmPickup.
  ///
  /// In en, this message translates to:
  /// **'Farm pickup'**
  String get widgetFarmPickup;

  /// No description provided for @widgetDeliveryPoint.
  ///
  /// In en, this message translates to:
  /// **'Delivery point'**
  String get widgetDeliveryPoint;

  /// No description provided for @widgetCourier.
  ///
  /// In en, this message translates to:
  /// **'Courier'**
  String get widgetCourier;

  /// No description provided for @widgetEnRoute.
  ///
  /// In en, this message translates to:
  /// **'{percent}% en route'**
  String widgetEnRoute(int percent);

  /// No description provided for @widgetVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification status'**
  String get widgetVerificationStatus;

  /// No description provided for @stateReceiptNotNeeded.
  ///
  /// In en, this message translates to:
  /// **'This order does not need a payment receipt.'**
  String get stateReceiptNotNeeded;

  /// No description provided for @stateSignInToUploadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to upload a payment receipt.'**
  String get stateSignInToUploadReceipt;

  /// No description provided for @statePaymentActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This payment action is not available.'**
  String get statePaymentActionUnavailable;

  /// No description provided for @stateProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Your profile could not be found.'**
  String get stateProfileNotFound;

  /// No description provided for @stateSignInToChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Sign in to change your photo.'**
  String get stateSignInToChangePhoto;

  /// No description provided for @stateWithdrawalFailed.
  ///
  /// In en, this message translates to:
  /// **'Your payout request could not be sent. Please try again.'**
  String get stateWithdrawalFailed;

  /// No description provided for @stateDisputeResolvedTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute resolved: order {orderNumber}'**
  String stateDisputeResolvedTitle(String orderNumber);

  /// No description provided for @stateDisputeSettledTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute settled: order {orderNumber}'**
  String stateDisputeSettledTitle(String orderNumber);

  /// No description provided for @stateDisputeResolvedBody.
  ///
  /// In en, this message translates to:
  /// **'The admin resolved the dispute: {resolution}. Notes: {notes}'**
  String stateDisputeResolvedBody(String resolution, String notes);

  /// No description provided for @stateResolutionRefundBuyer.
  ///
  /// In en, this message translates to:
  /// **'Refund to the buyer'**
  String get stateResolutionRefundBuyer;

  /// No description provided for @stateResolutionReleaseFarmer.
  ///
  /// In en, this message translates to:
  /// **'Payment released to the farmer'**
  String get stateResolutionReleaseFarmer;

  /// No description provided for @stateResolutionSplit.
  ///
  /// In en, this message translates to:
  /// **'Amount split between buyer and farmer'**
  String get stateResolutionSplit;

  /// No description provided for @homeNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeNavHome;

  /// No description provided for @homeNavProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get homeNavProducts;

  /// No description provided for @homeNavOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get homeNavOrders;

  /// No description provided for @homeNavDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get homeNavDeliveries;

  /// No description provided for @homeNavEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get homeNavEarnings;

  /// No description provided for @homeNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeNavProfile;

  /// No description provided for @homeNavJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get homeNavJobs;

  /// No description provided for @homeNavAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get homeNavAlerts;

  /// No description provided for @homeNavOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get homeNavOffers;

  /// No description provided for @homeNavDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get homeNavDashboard;

  /// No description provided for @homeNavVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get homeNavVerify;

  /// No description provided for @homeNavUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get homeNavUsers;

  /// No description provided for @homeNavLogistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get homeNavLogistics;

  /// No description provided for @homeNavSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeNavSettings;

  /// No description provided for @dashboardFarmActivity.
  ///
  /// In en, this message translates to:
  /// **'Farm Activity'**
  String get dashboardFarmActivity;

  /// No description provided for @dashboardYourProduce.
  ///
  /// In en, this message translates to:
  /// **'Your current produce'**
  String get dashboardYourProduce;

  /// No description provided for @dashboardEarningsOverview.
  ///
  /// In en, this message translates to:
  /// **'Earnings Overview'**
  String get dashboardEarningsOverview;

  /// No description provided for @dashboardRecentOrders.
  ///
  /// In en, this message translates to:
  /// **'Recent Orders'**
  String get dashboardRecentOrders;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardRecentNotifications.
  ///
  /// In en, this message translates to:
  /// **'Recent Notifications'**
  String get dashboardRecentNotifications;

  /// No description provided for @dashboardGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning, {name} 👋'**
  String dashboardGoodMorning(String name);

  /// No description provided for @dashboardGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon, {name} 👋'**
  String dashboardGoodAfternoon(String name);

  /// No description provided for @dashboardGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening, {name} 👋'**
  String dashboardGoodEvening(String name);

  /// No description provided for @dashboardHappeningInDistrict.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what\'s happening in {district} today.'**
  String dashboardHappeningInDistrict(String district);

  /// No description provided for @dashboardHappeningOnFarm.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what\'s happening with your farm today.'**
  String get dashboardHappeningOnFarm;

  /// No description provided for @dashboardTodaysOrders.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Orders'**
  String get dashboardTodaysOrders;

  /// No description provided for @dashboardTrendFromYesterday.
  ///
  /// In en, this message translates to:
  /// **'+{count} from yesterday'**
  String dashboardTrendFromYesterday(int count);

  /// No description provided for @dashboardActiveProducts.
  ///
  /// In en, this message translates to:
  /// **'Active Products'**
  String get dashboardActiveProducts;

  /// No description provided for @dashboardListedForSale.
  ///
  /// In en, this message translates to:
  /// **'Listed for sale'**
  String get dashboardListedForSale;

  /// No description provided for @dashboardPendingOrders.
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get dashboardPendingOrders;

  /// No description provided for @dashboardAwaitingResponse.
  ///
  /// In en, this message translates to:
  /// **'Awaiting response'**
  String get dashboardAwaitingResponse;

  /// No description provided for @dashboardThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get dashboardThisMonth;

  /// No description provided for @dashboardNoProduceYet.
  ///
  /// In en, this message translates to:
  /// **'No produce listed yet'**
  String get dashboardNoProduceYet;

  /// No description provided for @dashboardOrganic.
  ///
  /// In en, this message translates to:
  /// **'Organic'**
  String get dashboardOrganic;

  /// No description provided for @dashboardInStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get dashboardInStock;

  /// No description provided for @dashboardActiveOrdersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active order} other{{count} active orders}}'**
  String dashboardActiveOrdersCount(int count);

  /// No description provided for @dashboardMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get dashboardMonthly;

  /// No description provided for @dashboardWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get dashboardWeekly;

  /// No description provided for @dashboardThisMonthEarnings.
  ///
  /// In en, this message translates to:
  /// **'This month\'s earnings'**
  String get dashboardThisMonthEarnings;

  /// No description provided for @dashboardThisWeekEarnings.
  ///
  /// In en, this message translates to:
  /// **'This week\'s earnings'**
  String get dashboardThisWeekEarnings;

  /// No description provided for @dashboardVsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'{percent} vs last month'**
  String dashboardVsLastMonth(String percent);

  /// No description provided for @dashboardVsLastWeek.
  ///
  /// In en, this message translates to:
  /// **'{percent} vs last week'**
  String dashboardVsLastWeek(String percent);

  /// No description provided for @dashboardNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get dashboardNoData;

  /// No description provided for @dashboardNoRecentOrders.
  ///
  /// In en, this message translates to:
  /// **'No recent orders'**
  String get dashboardNoRecentOrders;

  /// No description provided for @dashboardAddProduce.
  ///
  /// In en, this message translates to:
  /// **'Add Produce'**
  String get dashboardAddProduce;

  /// No description provided for @dashboardManageOrders.
  ///
  /// In en, this message translates to:
  /// **'Manage Orders'**
  String get dashboardManageOrders;

  /// No description provided for @dashboardPriceOffers.
  ///
  /// In en, this message translates to:
  /// **'Price Offers'**
  String get dashboardPriceOffers;

  /// No description provided for @dashboardViewEarnings.
  ///
  /// In en, this message translates to:
  /// **'View Earnings'**
  String get dashboardViewEarnings;

  /// No description provided for @dashboardFarmProfile.
  ///
  /// In en, this message translates to:
  /// **'Farm Profile'**
  String get dashboardFarmProfile;

  /// No description provided for @dashboardMarketRates.
  ///
  /// In en, this message translates to:
  /// **'Market Rates'**
  String get dashboardMarketRates;

  /// No description provided for @dashboardNearbyTransport.
  ///
  /// In en, this message translates to:
  /// **'Nearby Transport'**
  String get dashboardNearbyTransport;

  /// No description provided for @dashboardProduce.
  ///
  /// In en, this message translates to:
  /// **'Produce'**
  String get dashboardProduce;

  /// No description provided for @dashboardMyOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get dashboardMyOrders;

  /// No description provided for @dashboardMyCart.
  ///
  /// In en, this message translates to:
  /// **'My Cart'**
  String get dashboardMyCart;

  /// No description provided for @dashboardLiveTracking.
  ///
  /// In en, this message translates to:
  /// **'Live Tracking'**
  String get dashboardLiveTracking;

  /// No description provided for @dashboardNoActiveDelivery.
  ///
  /// In en, this message translates to:
  /// **'No active delivery right now. Accept a job to start live tracking.'**
  String get dashboardNoActiveDelivery;

  /// No description provided for @dashboardUserManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get dashboardUserManagement;

  /// No description provided for @dashboardMarketplaceOrders.
  ///
  /// In en, this message translates to:
  /// **'MARKETPLACE ORDERS'**
  String get dashboardMarketplaceOrders;

  /// No description provided for @dashboardActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String dashboardActiveCount(int count);

  /// No description provided for @dashboardEscrowNote.
  ///
  /// In en, this message translates to:
  /// **'Total order volume handled via secure escrow'**
  String get dashboardEscrowNote;

  /// No description provided for @dashboardActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'Active Orders'**
  String get dashboardActiveOrders;

  /// No description provided for @dashboardInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get dashboardInProgress;

  /// No description provided for @dashboardInCart.
  ///
  /// In en, this message translates to:
  /// **'In Cart'**
  String get dashboardInCart;

  /// No description provided for @dashboardReadyToOrder.
  ///
  /// In en, this message translates to:
  /// **'Ready to order'**
  String get dashboardReadyToOrder;

  /// No description provided for @dashboardOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get dashboardOffers;

  /// No description provided for @dashboardNegotiations.
  ///
  /// In en, this message translates to:
  /// **'Negotiations'**
  String get dashboardNegotiations;

  /// No description provided for @dashboardActiveDelivery.
  ///
  /// In en, this message translates to:
  /// **'Active Delivery'**
  String get dashboardActiveDelivery;

  /// No description provided for @dashboardTrackProduceLive.
  ///
  /// In en, this message translates to:
  /// **'Track your produce live'**
  String get dashboardTrackProduceLive;

  /// No description provided for @dashboardOrderAndAddress.
  ///
  /// In en, this message translates to:
  /// **'Order {number} • {address}'**
  String dashboardOrderAndAddress(String number, String address);

  /// No description provided for @dashboardStage.
  ///
  /// In en, this message translates to:
  /// **'Stage: {status}'**
  String dashboardStage(String status);

  /// No description provided for @dashboardFeaturedProduce.
  ///
  /// In en, this message translates to:
  /// **'Featured Produce'**
  String get dashboardFeaturedProduce;

  /// No description provided for @dashboardBrowseAll.
  ///
  /// In en, this message translates to:
  /// **'Browse All'**
  String get dashboardBrowseAll;

  /// No description provided for @dashboardNoProduceListed.
  ///
  /// In en, this message translates to:
  /// **'No produce currently listed'**
  String get dashboardNoProduceListed;

  /// No description provided for @dashboardAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'{product} added to cart!'**
  String dashboardAddedToCart(String product);

  /// No description provided for @dashboardAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get dashboardAdd;

  /// No description provided for @dashboardActiveJobs.
  ///
  /// In en, this message translates to:
  /// **'Active Jobs'**
  String get dashboardActiveJobs;

  /// No description provided for @dashboardTotalDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Total deliveries'**
  String get dashboardTotalDeliveries;

  /// No description provided for @dashboardTotalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get dashboardTotalUsers;

  /// No description provided for @dashboardRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get dashboardRegistered;

  /// No description provided for @dashboardTotalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get dashboardTotalOrders;

  /// No description provided for @dashboardAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get dashboardAllTime;

  /// No description provided for @farmerOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Buyer Offers'**
  String get farmerOffersTitle;

  /// No description provided for @farmerOffersPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Pending'**
  String farmerOffersPendingCount(int count);

  /// No description provided for @farmerOffersFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} ({count})'**
  String farmerOffersFilterLabel(String label, int count);

  /// No description provided for @farmerOffersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No offers matching this filter'**
  String get farmerOffersEmpty;

  /// No description provided for @farmerOffersProduceOffer.
  ///
  /// In en, this message translates to:
  /// **'Produce Order Offer'**
  String get farmerOffersProduceOffer;

  /// No description provided for @farmerOffersBuyerLine.
  ///
  /// In en, this message translates to:
  /// **'Buyer: {buyer}'**
  String farmerOffersBuyerLine(String buyer);

  /// No description provided for @farmerOffersVerifiedBuyer.
  ///
  /// In en, this message translates to:
  /// **'Verified Buyer'**
  String get farmerOffersVerifiedBuyer;

  /// No description provided for @farmerQuantityKg.
  ///
  /// In en, this message translates to:
  /// **'{quantity} kg'**
  String farmerQuantityKg(String quantity);

  /// No description provided for @farmerPricePerKgValue.
  ///
  /// In en, this message translates to:
  /// **'{price} /kg'**
  String farmerPricePerKgValue(String price);

  /// No description provided for @farmerOffersOfferPrice.
  ///
  /// In en, this message translates to:
  /// **'Offer Price'**
  String get farmerOffersOfferPrice;

  /// No description provided for @farmerOffersTotalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get farmerOffersTotalValue;

  /// No description provided for @farmerOffersAccepted.
  ///
  /// In en, this message translates to:
  /// **'Offer accepted! New order created in Orders.'**
  String get farmerOffersAccepted;

  /// No description provided for @farmerOffersRejectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to decline this offer for {quantity} kg of {product}?'**
  String farmerOffersRejectConfirm(String quantity, String product);

  /// No description provided for @farmerOffersProductLine.
  ///
  /// In en, this message translates to:
  /// **'Product: {product}'**
  String farmerOffersProductLine(String product);

  /// No description provided for @farmerOffersQuantityLine.
  ///
  /// In en, this message translates to:
  /// **'Quantity: {quantity} kg'**
  String farmerOffersQuantityLine(String quantity);

  /// No description provided for @farmerOffersBuyerOfferLine.
  ///
  /// In en, this message translates to:
  /// **'Buyer Offer: {price} /kg'**
  String farmerOffersBuyerOfferLine(String price);

  /// No description provided for @farmerOffersCounterPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Counter Price (LKR / kg)'**
  String get farmerOffersCounterPriceLabel;

  /// No description provided for @farmerOffersInvalidCounterPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid counter price'**
  String get farmerOffersInvalidCounterPrice;

  /// No description provided for @farmerOffersCounterSent.
  ///
  /// In en, this message translates to:
  /// **'Counter offer sent: {price} /kg'**
  String farmerOffersCounterSent(String price);

  /// No description provided for @farmerOffersCounterFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send counter offer. {reason}'**
  String farmerOffersCounterFailed(String reason);

  /// No description provided for @langSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get langSelectTitle;

  /// No description provided for @langSelectHint.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in your profile.'**
  String get langSelectHint;

  /// No description provided for @langChangedTo.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {language}'**
  String langChangedTo(String language);

  /// No description provided for @langSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The language changed on this device but could not be saved to your account. Check your connection.'**
  String get langSaveFailed;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Connecting Farmers, Buyers & Transport'**
  String get splashTagline;

  /// No description provided for @splashFarmers.
  ///
  /// In en, this message translates to:
  /// **'Farmers'**
  String get splashFarmers;

  /// No description provided for @splashBuyers.
  ///
  /// In en, this message translates to:
  /// **'Buyers'**
  String get splashBuyers;

  /// No description provided for @splashTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get splashTransport;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Connecting agricultural network…'**
  String get splashLoading;

  /// No description provided for @helpSupportHours.
  ///
  /// In en, this message translates to:
  /// **'Support hours: Mon–Sat, 8:00 AM – 6:00 PM'**
  String get helpSupportHours;

  /// No description provided for @helpContactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get helpContactUs;

  /// No description provided for @helpCallSupport.
  ///
  /// In en, this message translates to:
  /// **'Call support'**
  String get helpCallSupport;

  /// No description provided for @helpEmailUs.
  ///
  /// In en, this message translates to:
  /// **'Email us'**
  String get helpEmailUs;

  /// No description provided for @helpWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get helpWhatsApp;

  /// No description provided for @helpFaqTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get helpFaqTitle;

  /// No description provided for @helpFaqOrdersQ.
  ///
  /// In en, this message translates to:
  /// **'How do orders work?'**
  String get helpFaqOrdersQ;

  /// No description provided for @helpFaqOrdersA.
  ///
  /// In en, this message translates to:
  /// **'A buyer places an order and you accept it. A verified transporter collects your produce and delivers it to the buyer. You can follow every step in the app.'**
  String get helpFaqOrdersA;

  /// No description provided for @helpFaqPayoutQ.
  ///
  /// In en, this message translates to:
  /// **'When do I get paid?'**
  String get helpFaqPayoutQ;

  /// No description provided for @helpFaqPayoutA.
  ///
  /// In en, this message translates to:
  /// **'Once the buyer confirms delivery, your payment is released to you within 24 hours.'**
  String get helpFaqPayoutA;

  /// No description provided for @helpFaqTransportQ.
  ///
  /// In en, this message translates to:
  /// **'Who arranges transport?'**
  String get helpFaqTransportQ;

  /// No description provided for @helpFaqTransportA.
  ///
  /// In en, this message translates to:
  /// **'Farmora sends the transport request to verified transporters. You only need to pack the harvest and keep it ready at your farm.'**
  String get helpFaqTransportA;

  /// No description provided for @helpFaqVerificationQ.
  ///
  /// In en, this message translates to:
  /// **'Why do I need verification?'**
  String get helpFaqVerificationQ;

  /// No description provided for @helpFaqVerificationA.
  ///
  /// In en, this message translates to:
  /// **'Verification helps buyers trust you. Verified farmers are shown first and get paid faster.'**
  String get helpFaqVerificationA;

  /// No description provided for @legalPrivacy1.
  ///
  /// In en, this message translates to:
  /// **'Farmora collects your profile, listings, orders and delivery data to operate the marketplace.'**
  String get legalPrivacy1;

  /// No description provided for @legalPrivacy2.
  ///
  /// In en, this message translates to:
  /// **'Phone numbers stay private by default. Buyers, farmers and transporters contact each other through in-app messages for each order.'**
  String get legalPrivacy2;

  /// No description provided for @legalPrivacy3.
  ///
  /// In en, this message translates to:
  /// **'Media you upload (product images, harvest videos, verification documents) is stored in Firebase Storage and shown only where needed for trade and verification.'**
  String get legalPrivacy3;

  /// No description provided for @legalPrivacy4.
  ///
  /// In en, this message translates to:
  /// **'You can request data export or account deletion from Help & Support. Deletion removes your profile and personal data, subject to legal record-keeping for completed transactions.'**
  String get legalPrivacy4;

  /// No description provided for @legalTerms1.
  ///
  /// In en, this message translates to:
  /// **'Farmora connects farmers, buyers and transport providers. Prices, stock and order totals are confirmed by Farmora\'s secure server, not by the app.'**
  String get legalTerms1;

  /// No description provided for @legalTerms2.
  ///
  /// In en, this message translates to:
  /// **'Farmers may list only produce they can supply. Buyers pay for confirmed orders. Transporters accept only jobs they can complete and follow the delivery steps in order.'**
  String get legalTerms2;

  /// No description provided for @legalTerms3.
  ///
  /// In en, this message translates to:
  /// **'You can review each delivered order once, and reviews may be moderated. Abuse, fraud or harassment leads to suspension.'**
  String get legalTerms3;

  /// No description provided for @legalTerms4.
  ///
  /// In en, this message translates to:
  /// **'While a dispute is open, the held payment is not released until an administrator resolves it.'**
  String get legalTerms4;

  /// No description provided for @legalSupportNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Support contact is not set up yet'**
  String get legalSupportNotConfigured;

  /// No description provided for @legalSupportNotConfiguredHint.
  ///
  /// In en, this message translates to:
  /// **'Use the account data controls below or contact your Farmora administrator.'**
  String get legalSupportNotConfiguredHint;

  /// No description provided for @legalDataRequest.
  ///
  /// In en, this message translates to:
  /// **'Request data export or deletion'**
  String get legalDataRequest;

  /// No description provided for @legalDataRequestHint.
  ///
  /// In en, this message translates to:
  /// **'Use the privacy controls in your profile.'**
  String get legalDataRequestHint;

  /// No description provided for @stateAccountRole.
  ///
  /// In en, this message translates to:
  /// **'Account role'**
  String get stateAccountRole;

  /// No description provided for @stateRoleFixed.
  ///
  /// In en, this message translates to:
  /// **'This role is fixed to your account.'**
  String get stateRoleFixed;

  /// No description provided for @notifFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notifFilterUnread;

  /// No description provided for @notifPreferencesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notifPreferencesTooltip;

  /// No description provided for @notifAllMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get notifAllMarkedRead;

  /// No description provided for @notifPrefOrderUpdates.
  ///
  /// In en, this message translates to:
  /// **'Order status updates'**
  String get notifPrefOrderUpdates;

  /// No description provided for @notifPrefMessages.
  ///
  /// In en, this message translates to:
  /// **'New messages and alerts'**
  String get notifPrefMessages;

  /// No description provided for @notifPrefsSaved.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences saved.'**
  String get notifPrefsSaved;

  /// No description provided for @notifEmptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'No notifications here.'**
  String get notifEmptyFiltered;

  /// No description provided for @farmerCategoryHerbs.
  ///
  /// In en, this message translates to:
  /// **'Herbs'**
  String get farmerCategoryHerbs;

  /// No description provided for @farmerCategoryDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get farmerCategoryDairy;

  /// No description provided for @farmerUnitLbs.
  ///
  /// In en, this message translates to:
  /// **'lbs'**
  String get farmerUnitLbs;

  /// No description provided for @farmerUnitPcs.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get farmerUnitPcs;

  /// No description provided for @farmerUnitBox.
  ///
  /// In en, this message translates to:
  /// **'box'**
  String get farmerUnitBox;

  /// No description provided for @farmerUnitBunches.
  ///
  /// In en, this message translates to:
  /// **'bunches'**
  String get farmerUnitBunches;

  /// No description provided for @farmerHarvestGrowing.
  ///
  /// In en, this message translates to:
  /// **'Growing'**
  String get farmerHarvestGrowing;

  /// No description provided for @farmerHarvestPacked.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get farmerHarvestPacked;

  /// No description provided for @farmerOrganic.
  ///
  /// In en, this message translates to:
  /// **'Organic'**
  String get farmerOrganic;

  /// No description provided for @farmerConventional.
  ///
  /// In en, this message translates to:
  /// **'Conventional'**
  String get farmerConventional;

  /// No description provided for @farmerQuantityAvailable.
  ///
  /// In en, this message translates to:
  /// **'{quantity} {unit} available'**
  String farmerQuantityAvailable(String quantity, String unit);

  /// No description provided for @farmerPricePerUnitValue.
  ///
  /// In en, this message translates to:
  /// **'{price} / {unit}'**
  String farmerPricePerUnitValue(String price, String unit);

  /// No description provided for @farmerProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get farmerProductsTitle;

  /// No description provided for @farmerProductsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get farmerProductsSearchHint;

  /// No description provided for @farmerProductsCategoryChip.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}'**
  String farmerProductsCategoryChip(String category);

  /// No description provided for @farmerProductsFilterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by Category'**
  String get farmerProductsFilterByCategory;

  /// No description provided for @farmerProductsReplaceVideo.
  ///
  /// In en, this message translates to:
  /// **'Replace harvest video'**
  String get farmerProductsReplaceVideo;

  /// No description provided for @farmerProductsUploadVideo.
  ///
  /// In en, this message translates to:
  /// **'Upload harvest video'**
  String get farmerProductsUploadVideo;

  /// No description provided for @farmerProductsVideoStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String farmerProductsVideoStatus(String status);

  /// No description provided for @farmerProductsVideoHint.
  ///
  /// In en, this message translates to:
  /// **'MP4 up to 100 MB — auto-deleted after delivery'**
  String get farmerProductsVideoHint;

  /// No description provided for @farmerProductsPreviewVideo.
  ///
  /// In en, this message translates to:
  /// **'Preview harvest video'**
  String get farmerProductsPreviewVideo;

  /// No description provided for @farmerProductsVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} video'**
  String farmerProductsVideoTitle(String name);

  /// No description provided for @farmerProductsRefreshQr.
  ///
  /// In en, this message translates to:
  /// **'Refresh packing QR'**
  String get farmerProductsRefreshQr;

  /// No description provided for @farmerProductsGenerateQr.
  ///
  /// In en, this message translates to:
  /// **'Generate packing QR'**
  String get farmerProductsGenerateQr;

  /// No description provided for @farmerProductsQrHint.
  ///
  /// In en, this message translates to:
  /// **'Marks harvest as packed for buyers'**
  String get farmerProductsQrHint;

  /// No description provided for @farmerProductsQrFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not generate QR'**
  String get farmerProductsQrFailed;

  /// No description provided for @farmerProductsQrReady.
  ///
  /// In en, this message translates to:
  /// **'Packing QR ready'**
  String get farmerProductsQrReady;

  /// No description provided for @farmerProductsQrError.
  ///
  /// In en, this message translates to:
  /// **'QR failed. {reason}'**
  String farmerProductsQrError(String reason);

  /// No description provided for @farmerProductsMarkOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Mark as Out of Stock'**
  String get farmerProductsMarkOutOfStock;

  /// No description provided for @farmerProductsMarkInStock.
  ///
  /// In en, this message translates to:
  /// **'Mark as Active / In Stock'**
  String get farmerProductsMarkInStock;

  /// No description provided for @farmerProductsStockUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {name} stock status'**
  String farmerProductsStockUpdated(String name);

  /// No description provided for @farmerProductsEditListing.
  ///
  /// In en, this message translates to:
  /// **'Edit Listing'**
  String get farmerProductsEditListing;

  /// No description provided for @farmerProductsRemoveListing.
  ///
  /// In en, this message translates to:
  /// **'Remove Listing'**
  String get farmerProductsRemoveListing;

  /// No description provided for @farmerProductsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}'**
  String farmerProductsDeleted(String name);

  /// No description provided for @farmerProductsVideoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Video upload failed'**
  String get farmerProductsVideoUploadFailed;

  /// No description provided for @farmerProductsVideoUploadFailedReason.
  ///
  /// In en, this message translates to:
  /// **'Video upload failed. {reason}'**
  String farmerProductsVideoUploadFailedReason(String reason);

  /// No description provided for @farmerProductsVideoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Harvest video uploaded for {name}'**
  String farmerProductsVideoUploaded(String name);

  /// No description provided for @farmerAddProductEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get farmerAddProductEditTitle;

  /// No description provided for @farmerAddProductBasicDetails.
  ///
  /// In en, this message translates to:
  /// **'Basic Details'**
  String get farmerAddProductBasicDetails;

  /// No description provided for @farmerAddProductNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get farmerAddProductNameLabel;

  /// No description provided for @farmerAddProductNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a product name'**
  String get farmerAddProductNameRequired;

  /// No description provided for @farmerAddProductNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Nuwara Eliya Carrots'**
  String get farmerAddProductNameHint;

  /// No description provided for @farmerAddProductDistrict.
  ///
  /// In en, this message translates to:
  /// **'Farm District / Location'**
  String get farmerAddProductDistrict;

  /// No description provided for @farmerAddProductInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory & Pricing'**
  String get farmerAddProductInventory;

  /// No description provided for @farmerAddProductQtyRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter qty'**
  String get farmerAddProductQtyRequired;

  /// No description provided for @farmerAddProductPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter price'**
  String get farmerAddProductPriceRequired;

  /// No description provided for @farmerAddProductAvailabilityDate.
  ///
  /// In en, this message translates to:
  /// **'Availability Date'**
  String get farmerAddProductAvailabilityDate;

  /// No description provided for @farmerAddProductSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get farmerAddProductSelectDate;

  /// No description provided for @farmerAddProductDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the quality, origin, and any certifications...'**
  String get farmerAddProductDescriptionHint;

  /// No description provided for @farmerAddProductImages.
  ///
  /// In en, this message translates to:
  /// **'Product Images'**
  String get farmerAddProductImages;

  /// No description provided for @farmerAddProductImagesHint.
  ///
  /// In en, this message translates to:
  /// **'Upload up to {count} clear photos of your product.'**
  String farmerAddProductImagesHint(int count);

  /// No description provided for @farmerAddProductImagesTip.
  ///
  /// In en, this message translates to:
  /// **'Tap a photo to replace it. The first photo is the cover.'**
  String get farmerAddProductImagesTip;

  /// No description provided for @farmerAddProductUploadingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Uploading photos...'**
  String get farmerAddProductUploadingPhotos;

  /// No description provided for @farmerSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get farmerSaving;

  /// No description provided for @farmerAddProductPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish Product'**
  String get farmerAddProductPublish;

  /// No description provided for @farmerAddProductAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get farmerAddProductAddPhoto;

  /// No description provided for @farmerAddProductPhotoSemantics.
  ///
  /// In en, this message translates to:
  /// **'Product photo {index}. Tap to replace.'**
  String farmerAddProductPhotoSemantics(int index);

  /// No description provided for @farmerAddProductCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get farmerAddProductCover;

  /// No description provided for @farmerAddProductRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo {index}'**
  String farmerAddProductRemovePhoto(int index);

  /// No description provided for @farmerAddProductInvalidQtyPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity and price.'**
  String get farmerAddProductInvalidQtyPrice;

  /// No description provided for @farmerAddProductUploadRetry.
  ///
  /// In en, this message translates to:
  /// **'{reason} Tap {button} to retry.'**
  String farmerAddProductUploadRetry(String reason, String button);

  /// No description provided for @farmerAddProductVideoPrompt.
  ///
  /// In en, this message translates to:
  /// **'Optional: upload a short harvest video (MP4, max 100 MB). It is auto-deleted after delivery.'**
  String get farmerAddProductVideoPrompt;

  /// No description provided for @farmerAddProductUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {name} successfully!'**
  String farmerAddProductUpdated(String name);

  /// No description provided for @farmerAddProductPublished.
  ///
  /// In en, this message translates to:
  /// **'Published {name} successfully!'**
  String farmerAddProductPublished(String name);

  /// No description provided for @svcProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'This product is no longer available.'**
  String get svcProductNotFound;

  /// No description provided for @svcNotEnoughStock.
  ///
  /// In en, this message translates to:
  /// **'Not enough stock.'**
  String get svcNotEnoughStock;

  /// No description provided for @svcFarmerNoBankDeposit.
  ///
  /// In en, this message translates to:
  /// **'This farmer does not accept bank deposits yet.'**
  String get svcFarmerNoBankDeposit;

  /// No description provided for @svcOrderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found.'**
  String get svcOrderNotFound;

  /// No description provided for @svcJobNotFound.
  ///
  /// In en, this message translates to:
  /// **'Delivery job not found.'**
  String get svcJobNotFound;

  /// No description provided for @svcAddressLocked.
  ///
  /// In en, this message translates to:
  /// **'The address can only be changed while the order is pending.'**
  String get svcAddressLocked;

  /// No description provided for @svcOfferNotFound.
  ///
  /// In en, this message translates to:
  /// **'Offer not found.'**
  String get svcOfferNotFound;

  /// No description provided for @svcOfferNotPending.
  ///
  /// In en, this message translates to:
  /// **'This offer has already been answered.'**
  String get svcOfferNotPending;

  /// No description provided for @svcOfferCannotChange.
  ///
  /// In en, this message translates to:
  /// **'This offer can no longer be changed.'**
  String get svcOfferCannotChange;

  /// No description provided for @svcOfferCannotCounter.
  ///
  /// In en, this message translates to:
  /// **'This offer can no longer be countered.'**
  String get svcOfferCannotCounter;

  /// No description provided for @svcCounterPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid counter price.'**
  String get svcCounterPriceRequired;

  /// No description provided for @svcNoChatPeer.
  ///
  /// In en, this message translates to:
  /// **'There is no one to chat with on this order yet.'**
  String get svcNoChatPeer;

  /// No description provided for @svcBarcodeWrongBuyer.
  ///
  /// In en, this message translates to:
  /// **'This barcode is for another buyer\'s order.'**
  String get svcBarcodeWrongBuyer;

  /// No description provided for @svcDisputeNotOpen.
  ///
  /// In en, this message translates to:
  /// **'This order has no open dispute.'**
  String get svcDisputeNotOpen;

  /// No description provided for @svcDisputeClosed.
  ///
  /// In en, this message translates to:
  /// **'This dispute is already closed.'**
  String get svcDisputeClosed;

  /// No description provided for @svcBankFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'All bank fields are required.'**
  String get svcBankFieldsRequired;

  /// No description provided for @svcReceiptNotNeeded.
  ///
  /// In en, this message translates to:
  /// **'This order no longer needs a payment receipt.'**
  String get svcReceiptNotNeeded;

  /// No description provided for @svcReceiptBankOnly.
  ///
  /// In en, this message translates to:
  /// **'Receipts are only needed for bank deposit orders.'**
  String get svcReceiptBankOnly;

  /// No description provided for @svcPaidByBank.
  ///
  /// In en, this message translates to:
  /// **'This order is paid by bank deposit.'**
  String get svcPaidByBank;

  /// No description provided for @svcCashAfterDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash can be marked received after delivery.'**
  String get svcCashAfterDelivery;

  /// No description provided for @svcNoReceiptWaiting.
  ///
  /// In en, this message translates to:
  /// **'No payment receipt is waiting for review.'**
  String get svcNoReceiptWaiting;

  /// No description provided for @svcRejectReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please give the buyer a reason.'**
  String get svcRejectReasonRequired;

  /// No description provided for @svcFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File must be smaller than 5 MB.'**
  String get svcFileTooLarge;

  /// No description provided for @svcProfilePhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Profile photo must be smaller than 5 MB.'**
  String get svcProfilePhotoTooLarge;

  /// No description provided for @svcVideoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Video must be smaller than 100 MB.'**
  String get svcVideoTooLarge;

  /// No description provided for @svcEvidenceTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Evidence photo must be smaller than 5 MB.'**
  String get svcEvidenceTooLarge;

  /// No description provided for @svcImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image is too large. The limit is 5 MB.'**
  String get svcImageTooLarge;

  /// No description provided for @svcSeedNeedsUsers.
  ///
  /// In en, this message translates to:
  /// **'Register a farmer and buyer first, then seed again.'**
  String get svcSeedNeedsUsers;

  /// No description provided for @farmerTrackOrderHash.
  ///
  /// In en, this message translates to:
  /// **'Order #{number}'**
  String farmerTrackOrderHash(String number);

  /// No description provided for @farmerTrackPickupRequested.
  ///
  /// In en, this message translates to:
  /// **'Pickup requested'**
  String get farmerTrackPickupRequested;

  /// No description provided for @farmerTrackDeliveryStatus.
  ///
  /// In en, this message translates to:
  /// **'DELIVERY STATUS'**
  String get farmerTrackDeliveryStatus;

  /// No description provided for @farmerTrackPickupNote.
  ///
  /// In en, this message translates to:
  /// **'3PL Automated Pickup: Driver collects directly from your farm gate loading dock.'**
  String get farmerTrackPickupNote;

  /// No description provided for @farmerTrackTransportProvider.
  ///
  /// In en, this message translates to:
  /// **'Transport provider'**
  String get farmerTrackTransportProvider;

  /// No description provided for @farmerTrackAwaitingTransporter.
  ///
  /// In en, this message translates to:
  /// **'Awaiting transporter acceptance'**
  String get farmerTrackAwaitingTransporter;

  /// No description provided for @farmerTrackAssignedTransporter.
  ///
  /// In en, this message translates to:
  /// **'Assigned transporter'**
  String get farmerTrackAssignedTransporter;

  /// No description provided for @farmerTrackVehicleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Vehicle details unavailable'**
  String get farmerTrackVehicleUnavailable;

  /// No description provided for @farmerTrackEstimatedArrival.
  ///
  /// In en, this message translates to:
  /// **'Estimated Arrival'**
  String get farmerTrackEstimatedArrival;

  /// No description provided for @farmerTrackEtaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'ETA unavailable'**
  String get farmerTrackEtaUnavailable;

  /// No description provided for @farmerTrackCallDriver.
  ///
  /// In en, this message translates to:
  /// **'Call Driver'**
  String get farmerTrackCallDriver;

  /// No description provided for @farmerTrackLiveGps.
  ///
  /// In en, this message translates to:
  /// **'Live driver GPS: {lat}, {lng}'**
  String farmerTrackLiveGps(String lat, String lng);

  /// No description provided for @farmerTrackRouteWaypoints.
  ///
  /// In en, this message translates to:
  /// **'Route Waypoints'**
  String get farmerTrackRouteWaypoints;

  /// No description provided for @farmerTrackGpsRoute.
  ///
  /// In en, this message translates to:
  /// **'GPS route'**
  String get farmerTrackGpsRoute;

  /// No description provided for @farmerTrackRoutePreview.
  ///
  /// In en, this message translates to:
  /// **'Route preview'**
  String get farmerTrackRoutePreview;

  /// No description provided for @farmerTrackFarmPickup.
  ///
  /// In en, this message translates to:
  /// **'Farm pickup'**
  String get farmerTrackFarmPickup;

  /// No description provided for @farmerTrackDriverLive.
  ///
  /// In en, this message translates to:
  /// **'Driver location LIVE'**
  String get farmerTrackDriverLive;

  /// No description provided for @farmerTrackDriverUpdating.
  ///
  /// In en, this message translates to:
  /// **'Driver location updating…'**
  String get farmerTrackDriverUpdating;

  /// No description provided for @farmerTrackRouteProgress.
  ///
  /// In en, this message translates to:
  /// **'Route progress'**
  String get farmerTrackRouteProgress;

  /// No description provided for @farmerTrackSharingLive.
  ///
  /// In en, this message translates to:
  /// **'Driver is sharing live GPS — watch the map marker move.'**
  String get farmerTrackSharingLive;

  /// No description provided for @farmerTrackLastKnown.
  ///
  /// In en, this message translates to:
  /// **'Showing last known driver position.'**
  String get farmerTrackLastKnown;

  /// No description provided for @farmerTrackPickupOrigin.
  ///
  /// In en, this message translates to:
  /// **'Pickup Origin'**
  String get farmerTrackPickupOrigin;

  /// No description provided for @farmerTrackDeliveryDestination.
  ///
  /// In en, this message translates to:
  /// **'Delivery Destination'**
  String get farmerTrackDeliveryDestination;

  /// No description provided for @farmerTrackNoInstructions.
  ///
  /// In en, this message translates to:
  /// **'No delivery instructions provided.'**
  String get farmerTrackNoInstructions;

  /// No description provided for @farmerTrackOrderLifecycle.
  ///
  /// In en, this message translates to:
  /// **'Order Lifecycle'**
  String get farmerTrackOrderLifecycle;

  /// No description provided for @farmerTrackPickupChecklist.
  ///
  /// In en, this message translates to:
  /// **'Pickup Checklist'**
  String get farmerTrackPickupChecklist;

  /// No description provided for @farmerTrackChecklistDone.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} Done'**
  String farmerTrackChecklistDone(int done, int total);

  /// No description provided for @farmerTrackPrepareBefore.
  ///
  /// In en, this message translates to:
  /// **'Prepare prior to driver arrival'**
  String get farmerTrackPrepareBefore;

  /// No description provided for @farmerTrackHandedConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Produce handed to driver confirmed!'**
  String get farmerTrackHandedConfirmed;

  /// No description provided for @farmerTrackConfirmHanded.
  ///
  /// In en, this message translates to:
  /// **'Confirm Produce Handed to Driver'**
  String get farmerTrackConfirmHanded;

  /// No description provided for @farmerTrackViewPaymentStatus.
  ///
  /// In en, this message translates to:
  /// **'View Payment Status'**
  String get farmerTrackViewPaymentStatus;

  /// No description provided for @farmerTrackStepRequested.
  ///
  /// In en, this message translates to:
  /// **'Transport requested'**
  String get farmerTrackStepRequested;

  /// No description provided for @farmerTrackStepAccepted.
  ///
  /// In en, this message translates to:
  /// **'Transport accepted'**
  String get farmerTrackStepAccepted;

  /// No description provided for @farmerTrackStepPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Produce picked up'**
  String get farmerTrackStepPickedUp;

  /// No description provided for @farmerTrackStepInTransit.
  ///
  /// In en, this message translates to:
  /// **'Delivery in transit'**
  String get farmerTrackStepInTransit;

  /// No description provided for @farmerTrackStepCompleted.
  ///
  /// In en, this message translates to:
  /// **'Delivery completed'**
  String get farmerTrackStepCompleted;

  /// No description provided for @farmerTrackStepRequestedDesc.
  ///
  /// In en, this message translates to:
  /// **'A transport provider can accept this delivery.'**
  String get farmerTrackStepRequestedDesc;

  /// No description provided for @farmerTrackStepAcceptedDesc.
  ///
  /// In en, this message translates to:
  /// **'The provider has accepted the delivery request.'**
  String get farmerTrackStepAcceptedDesc;

  /// No description provided for @farmerTrackStepPickedUpDesc.
  ///
  /// In en, this message translates to:
  /// **'The provider has recorded pickup.'**
  String get farmerTrackStepPickedUpDesc;

  /// No description provided for @farmerTrackStepInTransitDesc.
  ///
  /// In en, this message translates to:
  /// **'The provider has started the delivery route.'**
  String get farmerTrackStepInTransitDesc;

  /// No description provided for @farmerTrackStepCompletedDesc.
  ///
  /// In en, this message translates to:
  /// **'The provider has marked the order delivered.'**
  String get farmerTrackStepCompletedDesc;

  /// No description provided for @farmerTrackCheckPack.
  ///
  /// In en, this message translates to:
  /// **'Pack the produce for pickup'**
  String get farmerTrackCheckPack;

  /// No description provided for @farmerTrackCheckReview.
  ///
  /// In en, this message translates to:
  /// **'Review the order and delivery instructions'**
  String get farmerTrackCheckReview;

  /// No description provided for @farmerTrackCheckHandOffAssigned.
  ///
  /// In en, this message translates to:
  /// **'Hand off produce to the assigned transport provider'**
  String get farmerTrackCheckHandOffAssigned;

  /// No description provided for @farmerTrackCheckHandOffTo.
  ///
  /// In en, this message translates to:
  /// **'Hand off produce to {name}'**
  String farmerTrackCheckHandOffTo(String name);

  /// No description provided for @farmerTrackContactPartner.
  ///
  /// In en, this message translates to:
  /// **'Contact Delivery Partner'**
  String get farmerTrackContactPartner;

  /// No description provided for @farmerTrackContactBody.
  ///
  /// In en, this message translates to:
  /// **'Your delivery partner and buyer are reachable through the order chat. Messages are encrypted for the recipient and phone numbers stay private.'**
  String get farmerTrackContactBody;

  /// No description provided for @farmerTrackContactNote.
  ///
  /// In en, this message translates to:
  /// **'You will see the assigned driver details (name, vehicle, ratings) inside the conversation once a transporter accepts this delivery.'**
  String get farmerTrackContactNote;

  /// No description provided for @farmerTrackPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Payment details'**
  String get farmerTrackPaymentDetails;

  /// No description provided for @farmerTrackOrderTotal.
  ///
  /// In en, this message translates to:
  /// **'Order total:'**
  String get farmerTrackOrderTotal;

  /// No description provided for @farmerTrackPaymentStatusColon.
  ///
  /// In en, this message translates to:
  /// **'Payment status:'**
  String get farmerTrackPaymentStatusColon;

  /// No description provided for @farmerTrackSettlementInfo.
  ///
  /// In en, this message translates to:
  /// **'Settlement information'**
  String get farmerTrackSettlementInfo;

  /// No description provided for @farmerTrackSettlementBody.
  ///
  /// In en, this message translates to:
  /// **'This screen shows the payment state recorded for this order. Settlement timing and dispute outcomes depend on the configured payment provider and platform policy.'**
  String get farmerTrackSettlementBody;

  /// No description provided for @svcDocNationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID card (NIC)'**
  String get svcDocNationalId;

  /// No description provided for @svcDocLandOwnership.
  ///
  /// In en, this message translates to:
  /// **'Land ownership document'**
  String get svcDocLandOwnership;

  /// No description provided for @svcDocFarmPhoto.
  ///
  /// In en, this message translates to:
  /// **'Farm photo'**
  String get svcDocFarmPhoto;

  /// No description provided for @svcDocBankProof.
  ///
  /// In en, this message translates to:
  /// **'Bank passbook or statement'**
  String get svcDocBankProof;

  /// No description provided for @svcDocDrivingLicence.
  ///
  /// In en, this message translates to:
  /// **'Driving licence'**
  String get svcDocDrivingLicence;

  /// No description provided for @svcDocVehicleRegistration.
  ///
  /// In en, this message translates to:
  /// **'Vehicle registration'**
  String get svcDocVehicleRegistration;

  /// No description provided for @svcDocVehicleInsurance.
  ///
  /// In en, this message translates to:
  /// **'Vehicle insurance'**
  String get svcDocVehicleInsurance;

  /// No description provided for @svcDocFarmerRegistration.
  ///
  /// In en, this message translates to:
  /// **'Farmer registration certificate'**
  String get svcDocFarmerRegistration;

  /// No description provided for @svcDocBusinessRegistration.
  ///
  /// In en, this message translates to:
  /// **'Business registration'**
  String get svcDocBusinessRegistration;

  /// No description provided for @svcDocGeneric.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get svcDocGeneric;

  /// No description provided for @svcDocUploadedForReview.
  ///
  /// In en, this message translates to:
  /// **'Uploaded for manual review'**
  String get svcDocUploadedForReview;

  /// No description provided for @farmerVerificationSaved.
  ///
  /// In en, this message translates to:
  /// **'Transporter profile saved.'**
  String get farmerVerificationSaved;

  /// No description provided for @farmerVerificationSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save profile. {reason}'**
  String farmerVerificationSaveFailed(String reason);

  /// No description provided for @farmerVerificationUploadedQueued.
  ///
  /// In en, this message translates to:
  /// **'Document uploaded and queued for manual review.'**
  String get farmerVerificationUploadedQueued;

  /// No description provided for @farmerVerificationUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. {reason}'**
  String farmerVerificationUploadFailed(String reason);

  /// No description provided for @farmerVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Verification'**
  String get farmerVerificationTitle;

  /// No description provided for @farmerVerificationHeading.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Account'**
  String get farmerVerificationHeading;

  /// No description provided for @farmerVerificationIntro.
  ///
  /// In en, this message translates to:
  /// **'Please provide the following documents to activate your Farmora profile.'**
  String get farmerVerificationIntro;

  /// No description provided for @farmerVerificationVehicleSection.
  ///
  /// In en, this message translates to:
  /// **'Vehicle & service area'**
  String get farmerVerificationVehicleSection;

  /// No description provided for @farmerVerificationVehicleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pickup, Van, Lorry'**
  String get farmerVerificationVehicleHint;

  /// No description provided for @farmerVerificationCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity (kg)'**
  String get farmerVerificationCapacity;

  /// No description provided for @farmerVerificationDistricts.
  ///
  /// In en, this message translates to:
  /// **'Service districts'**
  String get farmerVerificationDistricts;

  /// No description provided for @farmerVerificationDistrictsHint.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated, e.g. Colombo, Gampaha'**
  String get farmerVerificationDistrictsHint;

  /// No description provided for @farmerVerificationSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get farmerVerificationSaveProfile;

  /// No description provided for @farmerVerificationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Documents submitted for verification review!'**
  String get farmerVerificationSubmitted;

  /// No description provided for @farmerVerificationSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get farmerVerificationSubmit;

  /// No description provided for @farmerVerificationAllRequired.
  ///
  /// In en, this message translates to:
  /// **'All required documents must be uploaded to submit.'**
  String get farmerVerificationAllRequired;

  /// No description provided for @farmerVerificationFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get farmerVerificationFront;

  /// No description provided for @farmerVerificationBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get farmerVerificationBack;

  /// No description provided for @farmerVerificationUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get farmerVerificationUploaded;

  /// No description provided for @farmerVerificationNewPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploaded new clear vehicle photo!'**
  String get farmerVerificationNewPhoto;

  /// No description provided for @farmerVerificationSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get farmerVerificationSelectFile;

  /// No description provided for @stateSettlementReferenceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the actual bank or payout provider reference.'**
  String get stateSettlementReferenceRequired;

  /// No description provided for @stateInvalidWithdrawalAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid withdrawal amount. Available balance: {balance}'**
  String stateInvalidWithdrawalAmount(String balance);

  /// No description provided for @authLanguageButton.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get authLanguageButton;
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
