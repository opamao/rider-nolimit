import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
//import 'package:flutter_braintree/flutter_braintree.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
//import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:flutter_paytabs_bridge/BaseBillingShippingInfo.dart' as payTab;
import 'package:flutter_paytabs_bridge/IOSThemeConfiguration.dart';
import 'package:flutter_paytabs_bridge/PaymentSdkApms.dart';
import 'package:flutter_paytabs_bridge/PaymentSdkConfigurationDetails.dart';
import 'package:flutter_paytabs_bridge/flutter_paytabs_bridge.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:flutterwave_standard/flutterwave.dart';
// import 'package:flutterwave_standard/view/view_utils.dart';
import 'package:http/http.dart' as http;

// import 'package:mercado_pago_mobile_checkout/mercado_pago_mobile_checkout.dart';
import 'package:my_fatoorah/my_fatoorah.dart';
//import 'package:paytm/paytm.dart';
//import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../screens/DashBoardScreen.dart';
import '../utils/Extensions/StringExtensions.dart';

import '../../main.dart';
import '../../network/NetworkUtils.dart';
import '../../network/RestApis.dart';
import '../../utils/Colors.dart';
import '../../utils/Common.dart';
import '../../utils/Constants.dart';
import '../../utils/Extensions/AppButtonWidget.dart';
import '../../utils/Extensions/app_common.dart';
import '../model/PaymentListModel.dart';
import '../model/StripePayModel.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/images.dart';

class PaymentScreen extends StatefulWidget {
  final int? amount;

  PaymentScreen({this.amount});

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  List<PaymentModel> paymentList = [];

  String? selectedPaymentType,
      stripPaymentKey,
      stripPaymentPublishKey,
      payStackPublicKey,
      payPalTokenizationKey,
      flutterWavePublicKey,
      flutterWaveSecretKey,
      flutterWaveEncryptionKey,
      payTabsProfileId,
      payTabsServerKey,
      payTabsClientKey,
      // mercadoPagoPublicKey,
      // mercadoPagoAccessToken,
      myFatoorahToken,
      paytmMerchantId,
      paytmMerchantKey;

  String? razorKey;
  bool isTestType = true;
  bool loading = false;
  //final plugin = PaystackPlugin();
//  late Razorpay _razorpay;
  //CheckoutMethod method = CheckoutMethod.card;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    await paymentListApiCall();
    if (paymentList.any((element) => element.type == PAYMENT_TYPE_STRIPE)) {
      Stripe.publishableKey = stripPaymentPublishKey.validate();
      if (Platform.isIOS) {
        Stripe.merchantIdentifier = mStripeIdentifier;
      }
      await Stripe.instance.applySettings().catchError((e) {
        log("${e.toString()}");
      });
    }
    /*if (paymentList.any((element) => element.type == PAYMENT_TYPE_PAYSTACK)) {
      plugin.initialize(publicKey: payStackPublicKey.validate());
    }*/
    /*if (paymentList.any((element) => element.type == PAYMENT_TYPE_RAZORPAY)) {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }*/
  }

  /// Get Payment Gateway Api Call
  Future<void> paymentListApiCall() async {
    appStore.setLoading(true);
    await getPaymentList().then((value) {
      appStore.setLoading(false);
      paymentList.addAll(value.data!);
      selectedPaymentType=paymentList.first.type;
      if (paymentList.isNotEmpty) {
        paymentList.forEach((element) {
          if (element.type == PAYMENT_TYPE_STRIPE) {
            stripPaymentKey = element.isTest == 1 ? element.testValue!.secretKey : element.liveValue!.secretKey;
            stripPaymentPublishKey = element.isTest == 1 ? element.testValue!.publishableKey : element.liveValue!.publishableKey;
          } else if (element.type == PAYMENT_TYPE_PAYSTACK) {
            payStackPublicKey = element.isTest == 1 ? element.testValue!.publicKey : element.liveValue!.publicKey;
          } else if (element.type == PAYMENT_TYPE_RAZORPAY) {
            razorKey = element.isTest == 1 ? element.testValue!.keyId.validate() : element.liveValue!.keyId.validate();
          } else if (element.type == PAYMENT_TYPE_PAYPAL) {
            payPalTokenizationKey = element.isTest == 1 ? element.testValue!.tokenizationKey : element.liveValue!.tokenizationKey;
          } else if (element.type == PAYMENT_TYPE_FLUTTERWAVE) {
            flutterWavePublicKey = element.isTest == 1 ? element.testValue!.publicKey : element.liveValue!.publicKey;
            flutterWaveSecretKey = element.isTest == 1 ? element.testValue!.secretKey : element.liveValue!.secretKey;
            flutterWaveEncryptionKey = element.isTest == 1 ? element.testValue!.encryptionKey : element.liveValue!.encryptionKey;
          } else if (element.type == PAYMENT_TYPE_PAYTABS) {
            payTabsProfileId = element.isTest == 1 ? element.testValue!.profileId : element.liveValue!.profileId;
            payTabsClientKey = element.isTest == 1 ? element.testValue!.clientKey : element.liveValue!.clientKey;
            payTabsServerKey = element.isTest == 1 ? element.testValue!.serverKey : element.liveValue!.serverKey;
          } else if (element.type == PAYMENT_TYPE_MERCADOPAGO) {
            // mercadoPagoPublicKey = element.isTest == 1 ? element.testValue!.publicKey : element.liveValue!.publicKey;
            // mercadoPagoAccessToken = element.isTest == 1 ? element.testValue!.accessToken : element.liveValue!.accessToken;
          } else if (element.type == PAYMENT_TYPE_MYFATOORAH) {
            myFatoorahToken = element.isTest == 1 ? element.testValue!.accessToken : element.liveValue!.accessToken;
          } else if (element.type == PAYMENT_TYPE_PAYTM) {
            paytmMerchantId = element.isTest == 1 ? element.testValue!.merchantId : element.liveValue!.merchantId;
            paytmMerchantKey = element.isTest == 1 ? element.testValue!.merchantKey : element.liveValue!.merchantKey;
          }
        });
      }
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
      log('${error.toString()}');
    });
  }

  /// Razor Pay
 /* void razorPayPayment() {
    var options = {
      'key': razorKey.validate(),
      'amount': (widget.amount! * 100).toInt(),
      'name': mAppName,
      'description': mRazorDescription,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': sharedPref.getString(CONTACT_NUMBER),
        'email': sharedPref.getString(USER_EMAIL),
      },
      'external': {
        'wallets': ['paytm']
      }
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      log(e.toString());
      debugPrint('Error: e');
    }
  }*/

 /* void _handlePaymentSuccess(PaymentSuccessResponse response) {
    toast(language.transactionSuccessful);
    // Fluttertoast.showToast(msg: "SUCCESS: " + response.paymentId!, toastLength: Toast.LENGTH_SHORT);
    paymentConfirm();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    toast(language.transactionFailed);
    Fluttertoast.showToast(msg: "ERROR: " + response.code.toString() + " - " + response.message!, toastLength: Toast.LENGTH_SHORT);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(msg: "EXTERNAL_WALLET: " + response.walletName!, toastLength: Toast.LENGTH_SHORT);
  }*/

  /// StripPayment
  void stripePay() async {
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${stripPaymentKey.validate()}',
      HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
    };

    var request = http.Request('POST', Uri.parse(stripeURL));

    request.bodyFields = {
      'amount': '${(widget.amount! * 100).toInt()}',
      'currency': "${appStore.currencyName.toUpperCase()}",
    };

    log(request.bodyFields);
    request.headers.addAll(headers);

    log(request);

    appStore.setLoading(true);

    await request.send().then((value) {
      appStore.setLoading(false);
      http.Response.fromStream(value).then((response) async {
        if (response.statusCode == 200) {
          var res = StripePayModel.fromJson(await handleResponse(response));

          SetupPaymentSheetParameters setupPaymentSheetParameters = SetupPaymentSheetParameters(
            paymentIntentClientSecret: res.clientSecret.validate(),
            style: ThemeMode.light,
            appearance: PaymentSheetAppearance(colors: PaymentSheetAppearanceColors(primary: primaryColor)),
            // applePay: PaymentSheetApplePay(merchantCountryCode: appStore.currencyName.toUpperCase()),
            googlePay: PaymentSheetGooglePay(merchantCountryCode: appStore.currencyName.toUpperCase(), testEnv: true),
            merchantDisplayName: mAppName,
            customerId: appStore.userId.toString(),
            //customerEphemeralKeySecret: res.clientSecret.validate(),
            //setupIntentClientSecret: res.clientSecret.validate(),
          );

          await Stripe.instance.initPaymentSheet(paymentSheetParameters: setupPaymentSheetParameters).then((value) async {
            await Stripe.instance.presentPaymentSheet().then((value) async {
              toast(language.transactionSuccessful);
              paymentConfirm();
            });
          }).catchError((e) {
            toast(language.transactionFailed);
            log("presentPaymentSheet ${e.toString()}");
          });
          // SetupPaymentSheetParameters setupPaymentSheetParameters = SetupPaymentSheetParameters(
          //   paymentIntentClientSecret: res.clientSecret.validate(),
          //   style: ThemeMode.light,
          //   appearance: PaymentSheetAppearance(colors: PaymentSheetAppearanceColors(primary: primaryColor)),
          //   // applePay: const PaymentSheetApplePay(
          //   //   merchantCountryCode: 'US',
          //   // ),
          //   googlePay: PaymentSheetGooglePay(merchantCountryCode: appStore.currencyName.toUpperCase(), testEnv: true),
          //   merchantDisplayName: 'Nolimit',
          //   customerId: appStore.userId.toString(),
          //   customerEphemeralKeySecret: res.clientSecret.validate(),
          //   setupIntentClientSecret: res.clientSecret.validate(),
          // );
        }
      }).catchError((e) {
        appStore.setLoading(false);
        toast(e.toString(), print: true);
      });
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  Future<void> paymentConfirm() async {
    Map req = {
      "user_id": sharedPref.getInt(USER_ID),
      "type": "credit",
      "amount": widget.amount,
      "transaction_type": "topup",
      "currency": appStore.currencyName,
    };
    appStore.isLoading = true;
    await saveWallet(req).then((value) {
      appStore.isLoading = false;
      Navigator.pop(context,true);
      // launchScreen(context, RiderDashBoardScreen(), isNewTask: true);
    }).catchError((error) {
      appStore.isLoading = false;

      log(error.toString());
    });
  }

  ///PayStack Payment
/* void payStackPayment(BuildContext context) async {
    Charge charge = Charge()
      ..amount = (widget.amount! * 100).toInt() // In base currency
      ..email = sharedPref.getString(USER_EMAIL)
      ..currency = appStore.currencyName.toUpperCase();

    charge.reference = _getReference();

    try {
      CheckoutResponse response = await plugin.checkout(context, method: method, charge: charge, fullscreen: false);
      payStackUpdateStatus(response.reference, response.message);
      if (response.message == 'Success') {
        toast(language.transactionSuccessful);
        paymentConfirm();
      } else {
        toast(language.paymentFailed);
      }
    } catch (e) {
      payStackShowMessage(language.checkConsoleForError);
      rethrow;
    }
  }*/

  payStackUpdateStatus(String? reference, String message) {
    payStackShowMessage(message, const Duration(seconds: 7));
  }

  void payStackShowMessage(String message, [Duration duration = const Duration(seconds: 4)]) {
    toast(message);
    log(message);
  }

  String _getReference() {
    String platform;
    if (Platform.isIOS) {
      platform = 'iOS';
    } else {
      platform = 'Android';
    }
    return 'ChargedFrom${platform}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Paypal Payment
 /* void payPalPayment() async {
    final request = BraintreePayPalRequest(amount: widget.amount.toString(), currencyCode: appStore.currencyName.toUpperCase(), displayName: sharedPref.getString(USER_NAME));
    final result = await Braintree.requestPaypalNonce(
      payPalTokenizationKey!,
      request,
    );
    if (result != null) {
      toast(language.transactionSuccessful);
      paymentConfirm();
    }
  }*/

  /// FlutterWave Payment
 /* void flutterWaveCheckout() async {
    final customer = Customer(name: sharedPref.getString(USER_NAME).validate(), phoneNumber: sharedPref.getString(CONTACT_NUMBER).validate(), email: sharedPref.getString(USER_EMAIL).validate());

    final Flutterwave flutterwave = Flutterwave(
      context: context,
      publicKey: flutterWavePublicKey.validate(),
      currency: appStore.currencyName.toLowerCase(),
      redirectUrl: "https://www.google.com",
      txRef: DateTime.now().millisecond.toString(),
      amount: widget.amount.toString(),
      customer: customer,
      paymentOptions: "card, payattitude",
      customization: Customization(title: "Test Payment"),
      isTestMode: isTestType,
    );
    final ChargeResponse response = await flutterwave.charge();
    if (response.status == 'successful') {
      toast(language.transactionSuccessful);
      paymentConfirm();
    } else {
      FlutterwaveViewUtils.showToast(context, language.transactionFailed);
    }
  } */

  /// PayTabs Payment
  void payTabsPayment() {
    FlutterPaytabsBridge.startCardPayment(generateConfig(), (event) {
      setState(() {
        if (event["status"] == "success") {
          var transactionDetails = event["data"];
          if (transactionDetails["isSuccess"]) {
            toast(language.transactionSuccessful);
            paymentConfirm();
          } else {
            toast(language.transactionFailed);
          }
          toast(language.transactionSuccessful);
        } else if (event["status"] == "error") {
          // print("error");
        } else if (event["status"] == "event") {
          //
        }
      });
    });
  }

  PaymentSdkConfigurationDetails generateConfig() {
    List<PaymentSdkAPms> apms = [];
    apms.add(PaymentSdkAPms.STC_PAY);
    var configuration = PaymentSdkConfigurationDetails(
        profileId: payTabsProfileId,
        serverKey: payTabsServerKey,
        clientKey: payTabsClientKey,
        cartDescription: language.appName,
        //cartId: widget..toString(),
        screentTitle: language.payWithCard,
        amount: widget.amount!.toDouble(),
        showBillingInfo: true,
        forceShippingInfo: false,
        currencyCode: appStore.currencyName.toUpperCase(),
        merchantCountryCode: "IN",
        billingDetails: payTab.BillingDetails(
          sharedPref.getString(USER_NAME).validate(),
          sharedPref.getString(USER_EMAIL).validate(),
          sharedPref.getString(CONTACT_NUMBER).validate(),
          sharedPref.getString(ADDRESS).validate(),
          '',
          '',
          '',
          '',
        ),
        alternativePaymentMethods: apms,
        linkBillingNameWithCardHolderName: true);

    var theme = IOSThemeConfigurations();

    theme.logoImage = ic_logo_white;

    configuration.iOSThemeConfigurations = theme;

    return configuration;
  }

  // /// Mercado Pago payment
  // void mercadoPagoPayment() async {
  //   var body = json.encode({
  //     "items": [
  //       {"title": "Nolimit", "description": "Nolimit", "quantity": 1, "currency_id": appStore.currencyName.toUpperCase(), "unit_price": widget.amount}
  //     ],
  //     "payer": {"email": sharedPref.getString(USER_EMAIL)}
  //   });
  //
  //   try {
  //     final response = await http.post(
  //       Uri.parse('https://api.mercadopago.com/checkout/preferences?access_token=${mercadoPagoAccessToken.toString()}'),
  //       body: body,
  //       headers: {'Content-type': "application/json"},
  //     );
  //     String? preferenceId = json.decode(response.body)['id'];
  //     if (preferenceId != null) {
  //       PaymentResult result = await MercadoPagoMobileCheckout.startCheckout(
  //         mercadoPagoPublicKey!,
  //         preferenceId,
  //       );
  //       if (result.status == 'approved') {
  //         paymentConfirm();
  //       }
  //     } else {
  //       toast(json.decode(response.body)['message']);
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  /// My Fatoorah Payment
  Future<void> myFatoorahPayment() async {
    PaymentResponse response = await MyFatoorah.startPayment(
      context: context,
      successChild: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, size: 50, color: Colors.green),
            SizedBox(height: 16),
            Text(language.success, style: boldTextStyle(color: Colors.green, size: 24)),
          ],
        ),
      ),
      errorChild: Center(child: Text(language.failed, style: boldTextStyle(color: Colors.red, size: 24))),
      request: isTestType
          ? MyfatoorahRequest.test(
              currencyIso: Country.SaudiArabia,
              successUrl: 'https://pub.dev/packages/get',
              errorUrl: 'https://www.google.com/',
              invoiceAmount: widget.amount!.toDouble(),
              language: defaultLanguage == 'ar' ? ApiLanguage.Arabic : ApiLanguage.English,
              token: myFatoorahToken!,
            )
          : MyfatoorahRequest.live(
              currencyIso: Country.SaudiArabia,
              successUrl: 'https://pub.dev/packages/get',
              errorUrl: 'https://www.google.com/',
              invoiceAmount: widget.amount!.toDouble(),
              language: defaultLanguage == 'ar' ? ApiLanguage.Arabic : ApiLanguage.English,
              token: myFatoorahToken!,
            ),
    );
    if (response.isSuccess) {
      toast(language.transactionSuccessful);
      paymentConfirm();
    } else if (response.isError) {
      toast(language.paymentFailed);
    }
  }

  /// PayTm Payment
  /*void paytmPayment() async {
    setState(() {
      loading = true;
    });

    String orderId = DateTime.now().millisecondsSinceEpoch.toString();

    String callBackUrl = (isTestType ? 'https://securegw-stage.paytm.in' : 'https://securegw.paytm.in') + '/theia/paytmCallback?ORDER_ID=' + orderId;

    var url = 'https://desolate-anchorage-29312.herokuapp.com/generateTxnToken';

    var body = json.encode({
      "mid": paytmMerchantId,
      "key_secret": paytmMerchantKey,
      "website": isTestType ? "WEBSTAGING" : "DEFAULT",
      "orderId": orderId,
      "amount": widget.amount.toString(),
      "callbackUrl": callBackUrl,
      "custId": sharedPref.getInt(USER_ID).toString(),
      "testing": isTestType ? 0 : 1
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        body: body,
        headers: {'Content-type': "application/json"},
      );

      String txnToken = response.body;

      var paytmResponse = Paytm.payWithPaytm(
        mId: paytmMerchantId!,
        orderId: orderId,
        txnToken: txnToken,
        txnAmount: widget.amount.toString(),
        callBackUrl: callBackUrl,
        staging: isTestType,
        appInvokeEnabled: false,
      );

      paytmResponse.then((value) {
        setState(() {
          loading = false;
          if (value['error']) {
            toast(language.transactionFailed);
            // toast(value['errorMessage']);
          } else {
            if (value['response'] != null) {
              toast(language.transactionSuccessful);
              // toast(value['response']['RESPMSG']);
              if (value['response']['STATUS'] == 'TXN_SUCCESS') {
                paymentConfirm();
              }
            }
          }
        });
      });
    } catch (e) {
      log(e);
    }
  }
*/
  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(language.payment, style: boldTextStyle(color: appTextPrimaryColorWhite)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: paymentList.map((e) {
                return inkWellWidget(
                  onTap: () {
                    selectedPaymentType = e.type;
                    setState(() {});
                  },
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 48) / 2,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      //backgroundColor: Colors.white,
                      borderRadius: BorderRadius.circular(defaultRadius),
                      border: Border.all(color: selectedPaymentType == e.type ? primaryColor : dividerColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Image.network(e.gatewayLogo!, width: 40, height: 40),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(e.title.validate(), style: primaryTextStyle(), maxLines: 2),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Observer(builder: (context) {
            return Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            );
          }),
          !appStore.isLoading && paymentList.isEmpty ? emptyWidget() : SizedBox(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: Visibility(
          visible: paymentList.isNotEmpty,
          child: AppButtonWidget(
            text: language.pay,
            onTap: () {
              /*if (selectedPaymentType == PAYMENT_TYPE_RAZORPAY) {
                razorPayPayment();
              } else*/ if (selectedPaymentType == PAYMENT_TYPE_STRIPE) {
                stripePay();
              }
             /* else if (selectedPaymentType == PAYMENT_TYPE_PAYSTACK) {
                payStackPayment(context);
              } */
             /* else if (selectedPaymentType == PAYMENT_TYPE_PAYPAL) {
                payPalPayment();
              }*/
              /*else if (selectedPaymentType == PAYMENT_TYPE_FLUTTERWAVE) {
                flutterWaveCheckout();
              } */
              else if (selectedPaymentType == PAYMENT_TYPE_PAYTABS) {
                payTabsPayment();
              } else if (selectedPaymentType == PAYMENT_TYPE_MERCADOPAGO) {
                // mercadoPagoPayment();
              } else if (selectedPaymentType == PAYMENT_TYPE_MYFATOORAH) {
                myFatoorahPayment();
              }
              /*else if (selectedPaymentType == PAYMENT_TYPE_PAYTM) {
                paytmPayment();
              }*/
            },
          ),
        ),
      ),
    );
  }
}
