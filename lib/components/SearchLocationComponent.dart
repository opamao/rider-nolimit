import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:nolimit/utils/Extensions/StringExtensions.dart';
import '../main.dart';
import '../model/LocationModel.dart';
import '../screens/NewEstimateRideListWidget.dart';
import '../model/GoogleMapSearchModel.dart';
import '../model/ServiceModel.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../screens/GoogleMapScreen.dart';

class SearchLocationComponent extends StatefulWidget {
  final String title;

  SearchLocationComponent({required this.title});

  @override
  SearchLocationComponentState createState() => SearchLocationComponentState();
}

class SearchLocationComponentState extends State<SearchLocationComponent> {
  TextEditingController sourceLocation = TextEditingController();
  TextEditingController destinationLocation = TextEditingController();

  FocusNode sourceFocus = FocusNode();
  FocusNode desFocus = FocusNode();

  String mLocation = "";
  bool isDone = true;
  bool isPickup = true;
  bool isDrop = false;
  double? totalAmount;

  List<ServiceList> list = [];
  List<Prediction> listAddress = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    sourceLocation.text = widget.title;
    await getServices().then((value) {
      list.addAll(value.data!);
      setState(() {});
    });

    sourceFocus.addListener(() {
      sourceLocation.selection = TextSelection.collapsed(offset: sourceLocation.text.length);
      if (sourceFocus.hasFocus) sourceLocation.clear();
    });

    desFocus.addListener(() {
      if (desFocus.hasFocus) {
        if (mLocation.isNotEmpty) {
          sourceLocation.text = mLocation;
          sourceLocation.selection = TextSelection.collapsed(offset: sourceLocation.text.length);
        } else {
          sourceLocation.text = widget.title;
          sourceLocation.selection = TextSelection.collapsed(offset: sourceLocation.text.length);
        }
      }
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      alignment: Alignment.center,
                      margin: EdgeInsets.only(bottom: 16),
                      height: 5,
                      width: 70,
                      decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(defaultRadius)),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.only(bottom: 16),
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(defaultRadius)),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.near_me, color: Colors.green),
                              SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isPickup == true) Text(language.lblWhereAreYou, style: secondaryTextStyle()),
                                    TextFormField(
                                      controller: sourceLocation,
                                      focusNode: sourceFocus,
                                      decoration: searchInputDecoration(hint: language.currentLocation),
                                      onTap: () {
                                        isPickup = false;
                                        setState(() {});
                                      },
                                      onChanged: (val) {
                                        if (val.isNotEmpty) {
                                          isPickup = true;
                                          if (val.length < 3) {
                                            isDone = false;
                                            listAddress.clear();
                                            setState(() {});
                                          } else {
                                            searchAddressRequest(search: val).then((value) {
                                              isDone = true;
                                              listAddress = value.predictions!;
                                              setState(() {});
                                            }).catchError((error) {
                                              log(error);
                                            });
                                          }
                                        } else {
                                          isPickup = false;
                                          setState(() {});
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 4),
                            ],
                          ),
                          Row(
                            children: [
                              SizedBox(width: 8),
                              SizedBox(
                                height: 46,
                                child: DottedLine(
                                  direction: Axis.vertical,
                                  lineLength: double.infinity,
                                  lineThickness: 1,
                                  dashLength: 3,
                                  dashColor: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.red),
                              SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isDrop == true) Text(language.lblDropOff, style: secondaryTextStyle()),
                                    TextFormField(
                                      controller: destinationLocation,
                                      focusNode: desFocus,
                                      autofocus: true,
                                      decoration: searchInputDecoration(hint: language.destinationLocation),
                                      onTap: () {
                                        isDrop = false;
                                        setState(() {});
                                      },
                                      onChanged: (val) {
                                        if (val.isNotEmpty) {
                                          isDrop = true;
                                          if (val.length < 3) {
                                            listAddress.clear();
                                            setState(() {});
                                          } else {
                                            searchAddressRequest(search: val).then((value) {
                                              listAddress = value.predictions!;
                                              setState(() {});
                                            }).catchError((error) {
                                              log(error);
                                            });
                                          }
                                        } else {
                                          isDrop = false;
                                          setState(() {});
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 4),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (listAddress.isNotEmpty) SizedBox(height: 16),
                  ListView.builder(
                    controller: ScrollController(),
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: listAddress.length,
                    itemBuilder: (context, index) {
                      Prediction mData = listAddress[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.location_on_outlined, color: primaryColor),
                        minLeadingWidth: 16,
                        title: Text(mData.description ?? "", style: primaryTextStyle()),
                        onTap: () async {
                          await searchAddressRequestPlaceId(placeId: mData.placeId).then((value) async {
                            var data = value.result!.geometry;
                            if (sourceFocus.hasFocus) {
                              isDone = true;
                              mLocation = mData.description!;
                              sourceLocation.text = mData.description!;
                              polylineSource = LatLng(data!.location!.lat!, data.location!.lng!);

                              if (!sourceLocation.text.isEmptyOrNull && !destinationLocation.text.isEmptyOrNull) {
                                launchScreen(
                                    context,
                                    NewEstimateRideListWidget(
                                        sourceLatLog: polylineSource, destinationLatLog: polylineDestination, sourceTitle: sourceLocation.text, destinationTitle: destinationLocation.text),
                                    pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                                sourceLocation.clear();
                                destinationLocation.clear();
                              }
                            } else if (desFocus.hasFocus) {
                              destinationLocation.text = mData.description!;
                              polylineDestination = LatLng(data!.location!.lat!, data.location!.lng!);
                              if (!sourceLocation.text.isEmptyOrNull && !destinationLocation.text.isEmptyOrNull) {
                                launchScreen(
                                    context,
                                    NewEstimateRideListWidget(
                                        sourceLatLog: polylineSource, destinationLatLog: polylineDestination, sourceTitle: sourceLocation.text, destinationTitle: destinationLocation.text),
                                    pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                                sourceLocation.clear();
                                destinationLocation.clear();
                              }
                            }
                            listAddress.clear();
                            setState(() {});
                          }).catchError((error) {
                            log(error);
                          });
                        },
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  AppButtonWidget(
                    width: MediaQuery.of(context).size.width,
                    onTap: () async {
                      if (sourceFocus.hasFocus) {
                        isDone = true;
                        PickResult selectedPlace = await launchScreen(context, GoogleMapScreen(isDestination: false), pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                        log(selectedPlace);
                        mLocation = selectedPlace.formattedAddress!;
                        sourceLocation.text = selectedPlace.formattedAddress!;
                        polylineSource = LatLng(selectedPlace.geometry!.location.lat, selectedPlace.geometry!.location.lng);

                        if (sourceLocation.text.isNotEmpty && destinationLocation.text.isNotEmpty) {
                          launchScreen(
                              context,
                              NewEstimateRideListWidget(
                                  sourceLatLog: polylineSource, destinationLatLog: polylineDestination, sourceTitle: sourceLocation.text, destinationTitle: destinationLocation.text),
                              pageRouteAnimation: PageRouteAnimation.SlideBottomTop);

                          sourceLocation.clear();
                          destinationLocation.clear();
                        }else{
                          desFocus.nextFocus();
                        }
                      } else if (desFocus.hasFocus) {
                        PickResult selectedPlace = await launchScreen(context, GoogleMapScreen(isDestination: true), pageRouteAnimation: PageRouteAnimation.SlideBottomTop);

                        destinationLocation.text = selectedPlace.formattedAddress!;
                        polylineDestination = LatLng(selectedPlace.geometry!.location.lat, selectedPlace.geometry!.location.lng);

                        if (sourceLocation.text.isNotEmpty && destinationLocation.text.isNotEmpty) {
                          log(sourceLocation.text);
                          log(destinationLocation.text);

                          launchScreen(
                              context,
                              NewEstimateRideListWidget(
                                  sourceLatLog: polylineSource, destinationLatLog: polylineDestination, sourceTitle: sourceLocation.text, destinationTitle: destinationLocation.text),
                              pageRouteAnimation: PageRouteAnimation.SlideBottomTop);

                          sourceLocation.clear();
                          destinationLocation.clear();
                        }else{
                          sourceFocus.nextFocus();
                        }
                      } else {
                        //
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.my_location_sharp, color: Colors.white),
                        SizedBox(width: 16),
                        Text(language.chooseOnMap, style: boldTextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
