import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/models/referral_data.dart';
import 'package:juan_heart/services/facility_service.dart';

class FacilitySelectionScreen extends StatefulWidget {
  const FacilitySelectionScreen({Key? key}) : super(key: key);

  @override
  State<FacilitySelectionScreen> createState() =>
      _FacilitySelectionScreenState();
}

class _FacilitySelectionScreenState extends State<FacilitySelectionScreen> {
  bool _isLoading = true;
  bool _locationError = false;
  String _errorMessage = '';

  Position? _userLocation;
  List<HealthcareFacility> _facilities = [];
  List<HealthcareFacility> _filteredFacilities = [];
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFacilities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFacilities() async {
    setState(() {
      _isLoading = true;
      _locationError = false;
      _errorMessage = '';
    });

    try {
      // Get user location
      Position? location = await FacilityService.getCurrentLocation();

      if (location == null) {
        final isFilipino = Get.locale?.languageCode == 'fil';
        setState(() {
          _isLoading = false;
          _locationError = true;
          _errorMessage = isFilipino
              ? 'Hindi ma-access ang iyong lokasyon. Mangyaring i-enable ang location services.'
              : 'Unable to access your location. Please enable location services.';
        });
        return;
      }

      setState(() {
        _userLocation = location;
      });

      // Get nearby facilities
      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: location,
        maxDistance: 50.0, // Increased to 50km for more options
        maxResults: 20,
      );

      setState(() {
        _facilities = facilities;
        _filteredFacilities = facilities;
        _isLoading = false;
      });
    } catch (e) {
      final isFilipino = Get.locale?.languageCode == 'fil';
      setState(() {
        _isLoading = false;
        _locationError = true;
        _errorMessage = isFilipino
            ? 'May error sa pagkuha ng mga pasilidad: $e'
            : 'Error loading facilities: $e';
      });
    }
  }

  void _searchFacilities(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredFacilities = List.from(_facilities);
      } else {
        _filteredFacilities = _facilities.where((facility) {
          final searchLower = query.toLowerCase();
          return facility.name.toLowerCase().contains(searchLower) ||
              facility.address.toLowerCase().contains(searchLower) ||
              facility.typeName.toLowerCase().contains(searchLower);
        }).toList();
      }
    });
  }

  void _selectFacility(HealthcareFacility facility) {
    Get.back(result: facility);
  }

  @override
  Widget build(BuildContext context) {
    final isFilipino = Get.locale?.languageCode == 'fil';

    return Scaffold(
      backgroundColor: ColorConstant.whiteBackground,
      appBar: AppBar(
        backgroundColor: ColorConstant.whiteBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorConstant.bluedark),
          onPressed: () => Get.back(),
        ),
        title: Text(
          isFilipino ? 'Pumili ng Pasilidad' : 'Select Facility',
          style: TextStyle(
            color: ColorConstant.bluedark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: isFilipino
                    ? 'Maghanap ng pasilidad...'
                    : 'Search for facilities...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchFacilities('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ColorConstant.lightRed),
                ),
              ),
              onChanged: _searchFacilities,
            ),
          ),

          // Results count
          if (!_isLoading && !_locationError)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                isFilipino
                    ? '${_filteredFacilities.length} pasilidad na nakita'
                    : '${_filteredFacilities.length} facilities found',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 8),

          // Facility List
          Expanded(
            child: _buildBody(isFilipino),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isFilipino) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_locationError) {
      return _buildErrorState(isFilipino);
    }

    if (_filteredFacilities.isEmpty) {
      return _buildEmptyState(isFilipino);
    }

    return RefreshIndicator(
      onRefresh: _loadFacilities,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredFacilities.length,
        itemBuilder: (context, index) {
          final facility = _filteredFacilities[index];
          return _buildFacilityCard(facility, isFilipino);
        },
      ),
    );
  }

  Widget _buildFacilityCard(HealthcareFacility facility, bool isFilipino) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _selectFacility(facility),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorConstant.lightRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      facility.typeIcon,
                      color: ColorConstant.lightRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facility.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: ColorConstant.bluedark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          facility.typeName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (facility.is24Hours)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green[300]!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '24/7',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      facility.address,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (facility.distanceKm != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.directions_car,
                        size: 16, color: ColorConstant.lightRed),
                    const SizedBox(width: 4),
                    Text(
                      facility.distanceText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ColorConstant.lightRed,
                      ),
                    ),
                  ],
                ),
              ],
              if (facility.contactNumber != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      facility.contactNumber!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _selectFacility(facility),
                    child: Text(
                      isFilipino ? 'Piliin' : 'Select',
                      style: TextStyle(
                        color: ColorConstant.lightRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isFilipino) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFacilities,
              icon: const Icon(Icons.refresh),
              label: Text(isFilipino ? 'Subukan Ulit' : 'Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstant.lightRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isFilipino) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isFilipino
                  ? 'Walang nakitang pasilidad'
                  : 'No facilities found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFilipino
                  ? 'Subukan ang ibang search term'
                  : 'Try a different search term',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
