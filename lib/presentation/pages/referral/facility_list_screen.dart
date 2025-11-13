/// Facility List Screen - Enhanced UI/UX
/// 
/// Redesigned with:
/// - Contextual facility recommendations based on risk level
/// - Smart filtering and sorting
/// - Enhanced facility cards with trust indicators
/// - Animated loading states
/// - Improved accessibility
/// - Bilingual Taglish support
/// 
/// Part of the Referral & Care Navigation System

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:juan_heart/core/utils/color_constants.dart';
import 'package:juan_heart/models/referral_data.dart';
import 'package:juan_heart/services/facility_service.dart';
import 'package:juan_heart/routes/app_routes.dart';
import 'package:juan_heart/presentation/widgets/referral_widgets.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';

class FacilityListScreen extends StatefulWidget {
  const FacilityListScreen({Key? key}) : super(key: key);
  
  @override
  State<FacilityListScreen> createState() => _FacilityListScreenState();
}

class _FacilityListScreenState extends State<FacilityListScreen> with SingleTickerProviderStateMixin {
  CareRecommendation? _recommendation;
  Map<String, dynamic>? _assessmentData;
  bool _bookingIntent = false; // NEW: Track if user wants to book appointment

  bool _isLoading = true;
  bool _locationError = false;
  bool _permissionDenied = false;
  bool _permissionDeniedForever = false;
  String _errorMessage = '';

  Position? _userLocation;
  List<HealthcareFacility> _facilities = [];
  List<HealthcareFacility> _filteredFacilities = [];
  HealthcareFacility? _selectedFacility;

  // Filter state
  int _selectedFilterIndex = 0;
  final List<String> _filterOptionsEN = ['All', 'Nearest', 'Emergency', '24/7', 'Public'];
  final List<String> _filterOptionsFIL = ['Lahat', 'Malapit', 'Emergency', '24/7', 'Pampubliko'];

  @override
  void initState() {
    super.initState();
    _loadArguments();
    _checkLocationPermissionAndLoad();
  }
  
  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      _recommendation = args['recommendation'] as CareRecommendation?;
      _assessmentData = args['assessmentData'] as Map<String, dynamic>?;
      _bookingIntent = args['bookingIntent'] as bool? ?? false; // NEW: Read booking intent
    }
  }

  /// Check location permission and show dialog if needed
  Future<void> _checkLocationPermissionAndLoad() async {
    final String lang = Get.locale?.languageCode ?? 'en';

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDialog(lang);
      return;
    }

    // Check permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Show permission request dialog
      _showPermissionRequestDialog(lang);
    } else if (permission == LocationPermission.deniedForever) {
      // Permission permanently denied
      setState(() {
        _permissionDenied = true;
        _permissionDeniedForever = true;
      });
      _loadFacilitiesWithoutLocation();
    } else {
      // Permission granted, load facilities normally
      _loadFacilities();
    }
  }

  /// Show location service disabled dialog
  void _showLocationServiceDialog(String lang) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_off, color: ColorConstant.warningColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                lang == 'fil' ? 'Location Service Nakapatay' : 'Location Service Disabled',
                style: JHTextStyles.h4,
              ),
            ),
          ],
        ),
        content: Text(
          lang == 'fil'
              ? 'Kailangan nating i-enable ang location service ng iyong device para mahanap ang pinakamalapit na healthcare facilities.'
              : 'We need to enable your device\'s location service to find the nearest healthcare facilities.',
          style: JHTextStyles.bodyBase.copyWith(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              setState(() {
                _permissionDenied = true;
              });
              _loadFacilitiesWithoutLocation();
            },
            child: Text(
              lang == 'fil' ? 'Bukas Na Lang' : 'Not Now',
              style: TextStyle(color: ColorConstant.gentleGray),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              bool opened = await FacilityService.openLocationSettings();
              if (opened) {
                // Wait a bit for user to enable location
                await Future.delayed(const Duration(seconds: 1));
                _checkLocationPermissionAndLoad();
              } else {
                setState(() {
                  _permissionDenied = true;
                });
                _loadFacilitiesWithoutLocation();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstant.calmingBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              lang == 'fil' ? 'Buksan Settings' : 'Open Settings',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Show permission request dialog
  void _showPermissionRequestDialog(String lang) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_on, color: ColorConstant.calmingBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                lang == 'fil' ? 'Location Permission' : 'Location Permission',
                style: JHTextStyles.h4,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang == 'fil'
                  ? 'Kailangan namin ang iyong location para mahanap ang pinakamalapit na healthcare facilities.'
                  : 'We need your location to find the nearest healthcare facilities.',
              style: JHTextStyles.bodyBase.copyWith(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstant.calmingBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: ColorConstant.calmingBlue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lang == 'fil'
                          ? 'Makikita ang accurate na distansya'
                          : 'See accurate distances',
                      style: JHTextStyles.bodySmall.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              setState(() {
                _permissionDenied = true;
              });
              _loadFacilitiesWithoutLocation();
            },
            child: Text(
              lang == 'fil' ? 'Hindi Muna' : 'Not Now',
              style: TextStyle(color: ColorConstant.gentleGray),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              LocationPermission permission = await Geolocator.requestPermission();
              if (permission == LocationPermission.denied ||
                  permission == LocationPermission.deniedForever) {
                setState(() {
                  _permissionDenied = true;
                  _permissionDeniedForever = permission == LocationPermission.deniedForever;
                });
                _loadFacilitiesWithoutLocation();
              } else {
                _loadFacilities();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstant.calmingBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              lang == 'fil' ? 'Payagan' : 'Allow',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Load facilities without location (show all facilities without distance sorting)
  Future<void> _loadFacilitiesWithoutLocation() async {
    setState(() {
      _isLoading = true;
      _locationError = false;
      _errorMessage = '';
    });

    try {
      // Create a fake position to get all facilities (far away so all facilities are included)
      Position fakePosition = Position(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      // Get all facilities with a very large radius
      List<HealthcareFacility> allFacilities;

      if (_recommendation?.isEmergency == true) {
        allFacilities = await FacilityService.getEmergencyFacilities(
          userLocation: fakePosition,
          maxDistance: 10000, // Very large radius to get all facilities
        );
      } else if (_recommendation != null) {
        allFacilities = await FacilityService.getNearbyFacilities(
          userLocation: fakePosition,
          facilityTypes: _recommendation!.recommendedFacilities,
          maxDistance: 10000,
          maxResults: 100,
        );
      } else {
        allFacilities = await FacilityService.getNearbyFacilities(
          userLocation: fakePosition,
          maxDistance: 10000,
          maxResults: 100,
        );
      }

      // Sort alphabetically instead of by distance since we don't have real location
      allFacilities.sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _facilities = allFacilities;
        _filteredFacilities = allFacilities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _locationError = true;
        _errorMessage = Get.locale?.languageCode == 'fil'
            ? 'May error sa pagkuha ng mga pasilidad: $e'
            : 'Error loading facilities: $e';
      });
    }
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
        setState(() {
          _isLoading = false;
          _locationError = true;
          _errorMessage = Get.locale?.languageCode == 'fil'
              ? 'Hindi ma-access ang iyong lokasyon. Mangyaring i-enable ang location services.'
              : 'Unable to access your location. Please enable location services.';
        });
        return;
      }
      
      setState(() {
        _userLocation = location;
      });
      
      // Get nearby facilities based on recommendation
      List<HealthcareFacility> facilities;
      
      if (_recommendation?.isEmergency == true) {
        // Emergency: Show emergency facilities only
        facilities = await FacilityService.getEmergencyFacilities(
          userLocation: location,
          maxDistance: 25.0,
        );
      } else if (_recommendation != null) {
        // Filter by recommended facility types
        facilities = await FacilityService.getNearbyFacilities(
          userLocation: location,
          facilityTypes: _recommendation!.recommendedFacilities,
          maxDistance: 25.0,
          maxResults: 15,
        );
      } else {
        // Show all facilities
        facilities = await FacilityService.getNearbyFacilities(
          userLocation: location,
          maxDistance: 25.0,
          maxResults: 15,
        );
      }
      
      setState(() {
        _facilities = facilities;
        _filteredFacilities = facilities;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _locationError = true;
        _errorMessage = Get.locale?.languageCode == 'fil'
            ? 'May error sa pagkuha ng mga pasilidad: $e'
            : 'Error loading facilities: $e';
      });
    }
  }
  
  /// Apply filters to facility list
  void _applyFilter(int filterIndex) {
    setState(() {
      _selectedFilterIndex = filterIndex;
      
      switch (filterIndex) {
        case 0: // All
          _filteredFacilities = List.from(_facilities);
          break;
        case 1: // Nearest - already sorted by distance
          _filteredFacilities = _facilities.take(5).toList();
          break;
        case 2: // Emergency
          _filteredFacilities = _facilities
              .where((f) => 
                  f.type == FacilityType.emergencyFacility || 
                  f.type == FacilityType.hospital && f.is24Hours)
              .toList();
          break;
        case 3: // 24/7
          _filteredFacilities = _facilities
              .where((f) => f.is24Hours)
              .toList();
          break;
        case 4: // Public - can be enhanced with actual facility data
          _filteredFacilities = _facilities
              .where((f) => 
                  f.type == FacilityType.barangayHealthCenter ||
                  f.name.toLowerCase().contains('government') ||
                  f.name.toLowerCase().contains('quezon city') ||
                  f.name.toLowerCase().contains('veterans'))
              .toList();
          break;
        default:
          _filteredFacilities = List.from(_facilities);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final String lang = Get.locale?.languageCode ?? 'en';
    
    return Scaffold(
      backgroundColor: ColorConstant.softWhite,
      appBar: AppBar(
        backgroundColor: ColorConstant.whiteBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorConstant.bluedark),
          onPressed: () => Get.back(),
        ),
        title: Text(
          lang == 'fil' ? 'Hanapin ang Facility' : 'Find Care',
          style: TextStyle(
            color: ColorConstant.bluedark,
            
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: ColorConstant.calmingBlue),
            onPressed: _loadFacilities,
            tooltip: lang == 'fil' ? 'I-refresh' : 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              ColorConstant.softWhite,
            ],
          ),
        ),
        child: Column(
          children: [
            // Breadcrumb trail
            CarePathBreadcrumb(
              steps: [
                lang == 'fil' ? 'Assessment' : 'Assessment',
                lang == 'fil' ? 'Rekomendasyon' : 'Recommendations',
                lang == 'fil' ? 'Facility' : 'Find Care',
              ],
              currentStep: 2,
              language: lang,
            ),
            
            Expanded(child: _buildBody(lang)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBody(String lang) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedHeartPulse(
              color: _recommendation?.indicatorColor ?? ColorConstant.calmingBlue,
              size: 48,
            ),
            const SizedBox(height: 24),
            Text(
              lang == 'fil'
                  ? 'Hinahanap namin ang pinakamalapit na tulong...'
                  : 'We\'re finding the nearest care for you...',
              style: JHTextStyles.h4.copyWith(
                fontSize: 17,
                color: ColorConstant.bluedark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lang == 'fil'
                  ? 'Sandali lang po...'
                  : 'Just a moment...',
              style: JHTextStyles.bodyBase.copyWith(
                color: ColorConstant.gentleGray,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_locationError) {
      return _buildErrorState(lang);
    }
    
    if (_facilities.isEmpty) {
      return _buildEmptyState(lang);
    }
    
    return Column(
      children: [
        // Permission denied banner
        if (_permissionDenied)
          _buildPermissionDeniedBanner(lang),

        // Urgency banner (if applicable)
        if (_recommendation?.isUrgent == true)
          _buildUrgencyBanner(lang),

        // Guidance message
        _buildGuidanceMessage(lang),
        
        const SizedBox(height: 12),
        
        // Filter chips
        FilterChipRow(
          filters: lang == 'fil' ? _filterOptionsFIL : _filterOptionsEN,
          selectedIndex: _selectedFilterIndex,
          onSelected: _applyFilter,
        ),
        
        const SizedBox(height: 12),
        
        // Facility count header
        _buildFacilityCountHeader(lang),
        
        // Facility list (with filtered results)
        Expanded(
          child: _filteredFacilities.isEmpty
              ? _buildNoResultsState(lang)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: _filteredFacilities.length,
                  itemBuilder: (context, index) {
                    final facility = _filteredFacilities[index];
                    final isRecommended = index < 3 && _selectedFilterIndex == 0;
                    
                    return EnhancedFacilityCard(
                      facility: facility,
                      language: lang,
                      isSelected: _selectedFacility?.id == facility.id,
                      showRecommendedBadge: isRecommended,
                      recommendationText: _getRecommendationText(facility, lang),
                      onTap: () {
                        setState(() {
                          _selectedFacility = 
                              _selectedFacility?.id == facility.id ? null : facility;
                        });
                      },
                      onCall: facility.primaryContact != null
                          ? () => _callFacility(facility)
                          : null,
                      onNavigate: () => _navigateToFacility(facility),
                    );
                  },
                ),
        ),
        
        // Generate referral summary button (if facility selected)
        if (_selectedFacility != null)
          _buildReferralSummaryButton(lang),
      ],
    );
  }
  
  /// Get contextual recommendation text for facility
  String? _getRecommendationText(HealthcareFacility facility, String lang) {
    if (_recommendation == null) return null;
    
    if (_recommendation!.isEmergency && facility.is24Hours) {
      return lang == 'fil' ? 'Emergency Ready' : 'Emergency Ready';
    } else if (_recommendation!.isUrgent && facility.distanceKm != null && facility.distanceKm! < 2) {
      return lang == 'fil' ? 'Malapit & Mabilis' : 'Near & Fast';
    } else if (facility.type == FacilityType.barangayHealthCenter) {
      return lang == 'fil' ? 'Community Partner' : 'Community Partner';
    }
    
    return null;
  }
  
  /// Guidance message based on recommendation
  Widget _buildGuidanceMessage(String lang) {
    if (_recommendation == null) return const SizedBox.shrink();
    
    String message;
    IconData icon;
    
    if (_recommendation!.isEmergency) {
      message = lang == 'fil'
          ? 'Pumili ng pinakamalapit na emergency facility. Tawagan din ang 911 kung kinakailangan.'
          : 'Choose the nearest emergency facility. Call 911 if needed.';
      icon = Icons.emergency;
    } else if (_recommendation!.isUrgent) {
      message = lang == 'fil'
          ? 'Maghanap ng facility na may available na appointment today o bukas.'
          : 'Look for a facility with available appointments today or tomorrow.';
      icon = Icons.event_available;
    } else {
      message = lang == 'fil'
          ? 'Pumili ng facility na komportable ka at malapit sa bahay mo.'
          : 'Choose a facility that\'s convenient and close to home.';
      icon = Icons.location_city;
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ReassuranceMessage(
        message: message,
        icon: icon,
      ),
    );
  }
  
  /// No results after filtering
  Widget _buildNoResultsState(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off,
              size: 64,
              color: ColorConstant.gentleGray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              lang == 'fil'
                  ? 'Walang nakitang facility sa filter na ito'
                  : 'No facilities found with this filter',
              textAlign: TextAlign.center,
              style: JHTextStyles.h4.copyWith(
                fontSize: 16,
                color: ColorConstant.bluedark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lang == 'fil'
                  ? 'Subukan ang ibang filter o tingnan ang lahat'
                  : 'Try a different filter or view all',
              textAlign: TextAlign.center,
              style: JHTextStyles.bodyBase.copyWith(
                color: ColorConstant.gentleGray,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => _applyFilter(0),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstant.calmingBlue,
                side: BorderSide(color: ColorConstant.calmingBlue, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              child: Text(lang == 'fil' ? 'Tingnan Lahat' : 'View All'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Permission denied warning banner
  Widget _buildPermissionDeniedBanner(String lang) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstant.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstant.warningColor,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_off,
            color: ColorConstant.warningColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == 'fil'
                      ? 'Location Permission Denied'
                      : 'Location Permission Denied',
                  style: JHTextStyles.button.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorConstant.bluedark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lang == 'fil'
                      ? 'Showing all facilities without distance sorting.'
                      : 'Showing all facilities without distance sorting.',
                  style: JHTextStyles.caption.copyWith(
                    color: ColorConstant.gentleGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_permissionDeniedForever)
            OutlinedButton(
              onPressed: () async {
                bool opened = await FacilityService.openLocationSettings();
                if (opened) {
                  // Wait for user to potentially enable permission
                  await Future.delayed(const Duration(seconds: 1));
                  // Recheck permission
                  _checkLocationPermissionAndLoad();
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstant.warningColor,
                side: BorderSide(color: ColorConstant.warningColor, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                lang == 'fil' ? 'I-enable' : 'Enable',
                style: JHTextStyles.label,
              ),
            )
          else
            OutlinedButton(
              onPressed: () {
                // Retry permission request
                _checkLocationPermissionAndLoad();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstant.calmingBlue,
                side: BorderSide(color: ColorConstant.calmingBlue, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                lang == 'fil' ? 'Subukan' : 'Retry',
                style: JHTextStyles.label,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUrgencyBanner(String lang) {
    if (_recommendation == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _recommendation!.indicatorColor.withValues(alpha: 0.15),
            _recommendation!.indicatorColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _recommendation!.indicatorColor,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _recommendation!.indicatorColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _recommendation!.urgencyIcon,
              color: _recommendation!.indicatorColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _recommendation!.isEmergency
                      ? (lang == 'fil' ? '⚠️ EMERGENCY' : '⚠️ EMERGENCY')
                      : (lang == 'fil' ? 'Urgent Care Needed' : 'Urgent Care Needed'),
                  style: JHTextStyles.button.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _recommendation!.indicatorColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _recommendation!.isEmergency
                      ? (lang == 'fil'
                          ? 'Pumili ng pinakamalapit na facility'
                          : 'Choose the nearest facility')
                      : _recommendation!.timeframe,
                  style: JHTextStyles.bodySmall.copyWith(
                    fontSize: 13,
                    color: ColorConstant.bluedark.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFacilityCountHeader(String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ColorConstant.calmingBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.local_hospital_outlined,
              color: ColorConstant.calmingBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            lang == 'fil'
                ? '${_filteredFacilities.length} facility'
                : '${_filteredFacilities.length} facilities',
            style: JHTextStyles.button.copyWith(
              fontSize: 15,
              color: ColorConstant.bluedark,
            ),
          ),
          Text(
            lang == 'fil' ? ' nakita malapit sa iyo' : ' found near you',
            style: JHTextStyles.button.copyWith(
              fontSize: 15,
              color: ColorConstant.gentleGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // Old facility card removed - now using EnhancedFacilityCard widget
  
  Widget _buildReferralSummaryButton(String lang) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: ColorConstant.cardShadowMedium,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected facility indicator
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorConstant.reassuringGreen.withValues(alpha: 0.08),
                    ColorConstant.reassuringGreen.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ColorConstant.reassuringGreen.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: ColorConstant.reassuringGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang == 'fil' ? 'Napili:' : 'Selected:',
                          style: JHTextStyles.caption.copyWith(
                            color: ColorConstant.gentleGray,
                          ),
                        ),
                        Text(
                          _selectedFacility!.name,
                          style: JHTextStyles.button.copyWith(
                            color: ColorConstant.bluedark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Continue button - Book Appointment or Generate Referral
            LargeAccessibleButton(
              label: _bookingIntent
                  ? (lang == 'fil'
                      ? 'Mag-book ng Appointment'
                      : 'Book Appointment')
                  : (lang == 'fil'
                      ? 'Ipagpatuloy sa Referral Summary'
                      : 'Continue to Referral Summary'),
              icon: _bookingIntent ? Icons.calendar_today : Icons.arrow_forward,
              backgroundColor: _bookingIntent
                  ? ColorConstant.trustBlue
                  : ColorConstant.calmingBlue,
              onPressed: _bookingIntent
                  ? _bookAppointmentWithFacility
                  : _generateReferralSummary,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorState(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorConstant.warmBeige,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off,
                size: 64,
                color: ColorConstant.gentleGray,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              lang == 'fil' ? 'Hindi ma-access ang location' : 'Location Access Needed',
              textAlign: TextAlign.center,
              style: JHTextStyles.h3.copyWith(
                color: ColorConstant.bluedark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: JHTextStyles.bodyBase.copyWith(
                fontSize: 15,
                color: ColorConstant.gentleGray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            LargeAccessibleButton(
              label: lang == 'fil' ? 'Subukan Muli' : 'Try Again',
              icon: Icons.refresh,
              backgroundColor: ColorConstant.calmingBlue,
              onPressed: _loadFacilities,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                // Show help dialog for location permissions
                Get.dialog(
                  AlertDialog(
                    title: Text(lang == 'fil' ? 'Paano i-enable ang Location?' : 'How to Enable Location?'),
                    content: Text(
                      lang == 'fil'
                          ? 'Pumunta sa Settings > Juan Heart > Location at piliin "While Using the App"'
                          : 'Go to Settings > Juan Heart > Location and select "While Using the App"',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.help_outline, size: 18),
              label: Text(lang == 'fil' ? 'Tulong' : 'Help'),
              style: TextButton.styleFrom(
                foregroundColor: ColorConstant.calmingBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorConstant.warmBeige,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: ColorConstant.gentleGray,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              lang == 'fil'
                  ? 'Walang nakitang facility'
                  : 'No Facilities Found',
              textAlign: TextAlign.center,
              style: JHTextStyles.h3.copyWith(
                color: ColorConstant.bluedark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              lang == 'fil'
                  ? 'Walang available na healthcare facility sa inyong area ngayon. Subukan ang mas malaking search radius o maghanap sa ibang lugar.'
                  : 'No healthcare facilities available in your area right now. Try a wider search radius or different location.',
              textAlign: TextAlign.center,
              style: JHTextStyles.bodyBase.copyWith(
                fontSize: 15,
                color: ColorConstant.gentleGray,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            LargeAccessibleButton(
              label: lang == 'fil' ? 'I-refresh' : 'Refresh',
              icon: Icons.refresh,
              backgroundColor: ColorConstant.calmingBlue,
              onPressed: _loadFacilities,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(lang == 'fil' ? 'Bumalik' : 'Go Back'),
              style: TextButton.styleFrom(
                foregroundColor: ColorConstant.gentleGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Action methods
  
  Future<void> _callFacility(HealthcareFacility facility) async {
    final String? phoneNumber = facility.primaryContact;
    if (phoneNumber == null) return;
    
    final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
    
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        _showError(Get.locale?.languageCode == 'fil'
            ? 'Hindi mabuksan ang phone dialer'
            : 'Cannot open phone dialer');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }
  
  Future<void> _navigateToFacility(HealthcareFacility facility) async {
    final Uri mapsUri = Uri.parse(facility.mapsUrl);
    
    try {
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      } else {
        _showError(Get.locale?.languageCode == 'fil'
            ? 'Hindi mabuksan ang maps'
            : 'Cannot open maps');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }
  
  void _generateReferralSummary() {
    if (_recommendation == null || _selectedFacility == null) return;

    Get.toNamed(
      AppRoutes.referralSummaryScreen,
      arguments: {
        'recommendation': _recommendation,
        'selectedFacility': _selectedFacility,
        'assessmentData': _assessmentData,
      },
    );
  }

  /// NEW: Navigate to booking screen with pre-selected facility
  void _bookAppointmentWithFacility() {
    if (_selectedFacility == null) return;

    // Navigate to BookAppointmentScreen with facility and assessment data
    Get.toNamed(
      AppRoutes.bookAppointmentScreen,
      arguments: {
        'selectedFacility': _selectedFacility,
        'assessmentData': _assessmentData,
        'recommendation': _recommendation,
        'fromAssessment': true, // Flag to indicate this booking is from assessment flow
      },
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: ColorConstant.redlight,
      colorText: ColorConstant.white,
      duration: const Duration(seconds: 3),
    );
  }
}


