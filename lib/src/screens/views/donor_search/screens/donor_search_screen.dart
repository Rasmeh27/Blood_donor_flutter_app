import 'package:flutter/material.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/blank_space.dart';
import '../../../../general/utils/responsive.dart';
import '../../../../models/donor.dart';
import '../../../../services/api/api_exception.dart';
import '../../../../services/app_services.dart';
import '../../components/widgets/custom_appbar.dart';
import '../../components/widgets/custom_blood_filter_box.dart';
import '../../components/widgets/request_list_status.dart';
import '../widgets/donor_result_item.dart';

/// Pantalla añadida: el diseño original no tenía una pantalla de resultados de donantes.
/// Sigue la misma estructura y estilos de AllRequestScreen. Se abre tras pulsar "Find Donors"
/// en FindDonorScreen, filtrada por el grupo sanguíneo de la solicitud (argumento de la ruta).
/// Solo muestra donantes que autorizaron aparecer; sin teléfono ni correo.
class DonorSearchScreen extends StatefulWidget {
  static const pageRoute = "/donor-search";

  const DonorSearchScreen({super.key});

  @override
  State<DonorSearchScreen> createState() => _DonorSearchScreenState();
}

class _DonorSearchScreenState extends State<DonorSearchScreen> {
  final _donorService = AppServices.instance.donors;
  final _scrollController = ScrollController();

  final List<DonorSearchResult> _donors = [];
  String? _bloodGroupFilter; // null = "All"
  bool _filterInitialized = false;
  int _nextPage = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  String? _errorMessage;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNearEnd);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filterInitialized) return;
    _filterInitialized = true;
    final argument = ModalRoute.of(context)?.settings.arguments;
    _bloodGroupFilter = argument is String ? argument : null;
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
    _donors.clear();
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
      final page = await _donorService.search(bloodGroup: _bloodGroupFilter, page: _nextPage);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _donors.addAll(page.items);
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
      appBar: const CustomAppBar(titlee: "Available Donors", actionTrue: true),
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
                    horizontalSpace(twentyPixelWidth(context) * .25),
                    Image.asset("assets/icons/filter.png", width: twelvePixelWidth(context) * 2),
                  ],
                ),
                verticalSpace(twentyPixelHeight(context) * .5),

                if (_filterInitialized)
                  CustomBloodFilterBox(initialValue: _bloodGroupFilter, onChanged: _changeFilter),

                for (final donor in _donors) ...[
                  verticalSpace(twentyPixelHeight(context) * 1),
                  DonorResultItem(donor: donor),
                ],

                if (_donors.isEmpty || _isLoading || _errorMessage != null)
                  RequestListStatus(
                    isLoading: _isLoading,
                    errorMessage: _errorMessage,
                    onRetry: _loadNextPage,
                    emptyMessage: 'No donors available for this blood group yet.',
                  ),
                verticalSpace(twentyPixelHeight(context) * 1.5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
