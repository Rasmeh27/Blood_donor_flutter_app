
import 'package:flutter/material.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/blank_space.dart';
import '../../../../general/utils/responsive.dart';
import '../../../../models/blood_request.dart';
import '../../../../services/api/api_exception.dart';
import '../../../../services/app_services.dart';
import '../../components/widgets/custom_appbar.dart';
import '../../components/widgets/custom_blood_filter_box.dart';
import '../../components/widgets/request_list_status.dart';
import '../../home/widgets/request_feed_item.dart';

class AllRequestScreen extends StatefulWidget {
  static const pageRoute = "/all-request";
  const AllRequestScreen({super.key});

  @override
  State<AllRequestScreen> createState() => _AllRequestScreenState();
}

class _AllRequestScreenState extends State<AllRequestScreen> {
  final _bloodRequestService = AppServices.instance.bloodRequests;
  final _scrollController = ScrollController();

  final List<BloodRequest> _requests = [];
  String? _bloodGroupFilter; // null = "All"
  int _nextPage = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  String? _errorMessage;
  // Descarta respuestas de un filtro anterior si el usuario cambia de filtro rápidamente
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNearEnd);
    _reload();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _changeFilter(String? bloodGroup) {
    _bloodGroupFilter = bloodGroup;
    _reload();
  }

  Future<void> _reload() {
    _loadGeneration++;
    _requests.clear();
    _nextPage = 0;
    _hasMore = true;
    _isLoading = false;
    return _loadNextPage();
  }

  void _loadMoreWhenNearEnd() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;
    final generation = _loadGeneration;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final page = await _bloodRequestService.list(bloodGroup: _bloodGroupFilter, page: _nextPage);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _requests.addAll(page.items);
        _nextPage = page.page + 1;
        _hasMore = page.hasMore;
      });
    } on ApiException catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted && generation == _loadGeneration) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(titlee: "Blood Requests", actionTrue: true),
      body: RefreshIndicator(
        color: AppColor.redColor,
        onRefresh: _reload,
        child: SingleChildScrollView(
        controller: _scrollController,
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
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Filter',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'PoppinsBold',
                      fontWeight: FontWeight.w700,
                    ),
                    textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
                  ),
                  horizontalSpace(twentyPixelWidth(context)*.25),
                  Image.asset("assets/icons/filter.png",
                  width: twelvePixelWidth(context)*2,

                  ),

                ],
              ),
              verticalSpace(twentyPixelHeight(context)*.5),

              CustomBloodFilterBox(onChanged: _changeFilter),

              for (final request in _requests) ...[
                verticalSpace(twentyPixelHeight(context)*1),
                CustomRequestFeedItem(request: request),
              ],

              // Carga inicial, siguiente página, lista vacía o error
              if (_requests.isEmpty || _isLoading || _errorMessage != null)
                RequestListStatus(
                  isLoading: _isLoading,
                  errorMessage: _errorMessage,
                  onRetry: _loadNextPage,
                ),
              verticalSpace(twentyPixelHeight(context)*1.5),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
