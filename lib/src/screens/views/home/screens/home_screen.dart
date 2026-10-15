import 'package:flutter/material.dart';
import '../../../../general/config/colors.dart';
import '../../../../general/utils/blank_space.dart';
import '../../../../general/utils/responsive.dart';
import '../../all_requests/screens/all_request_screen.dart';
import '../../components/widgets/home_drawer.dart';
import '../../donor_registration/screens/donor_registration_screen.dart';
import '../../find_donor/screens/find_donor_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../widgets/custom_home_container.dart';
import '../../../../models/blood_request.dart';
import '../../../../services/api/api_exception.dart';
import '../../../../services/app_services.dart';
import '../../../../services/blood_request_api_service.dart';
import '../../components/widgets/request_list_status.dart';
import '../widgets/request_feed_item.dart';

class HomeScreen extends StatefulWidget {
  static const pageRoute = "/home-screen";

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _bloodRequestService = AppServices.instance.bloodRequests;

  List<BloodRequest> _feed = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final page = await _bloodRequestService.list(
        size: BloodRequestApiService.defaultPageSize,
      );
      if (!mounted) return;
      setState(() => _feed = page.items);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Abre una pantalla y, al volver, refresca el feed (por ejemplo, tras crear una solicitud)
  Future<void> _openAndRefresh(Future<Object?> navigation) async {
    await navigation;
    if (mounted) _loadFeed();
  }

  @override
  Widget build(BuildContext context) {
    // En Android 16+ (back predictivo) la tecla Back cerraba la app con el menú abierto
    return PopScope(
      canPop: !_isDrawerOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _scaffoldKey.currentState?.closeDrawer();
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const HomeDrawer(),
        onDrawerChanged: (isOpen) => setState(() => _isDrawerOpen = isOpen),

        appBar: AppBar(
          backgroundColor: AppColor.redColor,
          centerTitle: true,
          leading: InkWell(
            onTap: () => _scaffoldKey.currentState!.openDrawer(),
            child: const Icon(Icons.menu, color: AppColor.whiteColor),
          ),
          actions: [
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, ProfileScreen.pageRoute);
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColor.whiteColor),
                  borderRadius: BorderRadius.circular(200),
                ),
                child: Center(child: Image.asset("assets/images/profile.png")),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: twentyPixelWidth(context) * .5),
            ),
          ],
          title: Text(
            'Blood Donation App',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColor.whiteColor,
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
            textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
          ),
        ),
        body: RefreshIndicator(
          color: AppColor.redColor,
          onRefresh: _loadFeed,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(
                left: twentyPixelWidth(context),
                right: twentyPixelWidth(context),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  verticalSpace(twentyPixelHeight(context)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          _openAndRefresh(
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FindDonorScreen(),
                              ),
                            ),
                          );
                        },
                        child: CustomHomeContainer(
                          containerBgColor: AppColor.whiteColor,
                          containerTextt: "Find a donor",
                          imageUrl: "assets/images/home_donor.png",
                          textColorr: AppColor.redColor,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AllRequestScreen(),
                            ),
                          );
                        },
                        child: CustomHomeContainer(
                          containerBgColor: AppColor.redColor,
                          containerTextt: "Requests",
                          imageUrl: "assets/images/home_request.png",
                          textColorr: AppColor.whiteColor,
                        ),
                      ),
                    ],
                  ),
                  verticalSpace(twentyPixelHeight(context)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DonorRegistrationForm(),
                            ),
                          );
                        },
                        child: CustomHomeContainer(
                          containerBgColor: AppColor.whiteColor,
                          containerTextt: "I want to donate",
                          imageUrl: "assets/images/home_blood.png",
                          textColorr: AppColor.redColor,
                        ),
                      ),
                    ],
                  ),
                  verticalSpace(twentyPixelHeight(context) * 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Request Feed",
                        style: const TextStyle(
                          color: AppColor.blackColor,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                        textScaler: TextScaler.linear(
                          ScaleSize.textScaleFactor(context),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AllRequestScreen.pageRoute,
                          );
                        },
                        child: Text(
                          'See all',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF7A7A7A),
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                          textScaler: TextScaler.linear(
                            ScaleSize.textScaleFactor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_feed.isEmpty)
                    RequestListStatus(
                      isLoading: _isLoading,
                      errorMessage: _errorMessage,
                      onRetry: _loadFeed,
                    )
                  else
                    ListView.builder(
                      itemCount: _feed.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            top: twentyPixelHeight(context) * 1,
                          ),
                          child: CustomRequestFeedItem(request: _feed[index]),
                        );
                      },
                    ),
                  verticalSpace(twentyPixelHeight(context) * 1.5),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
