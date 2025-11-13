import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:juan_heart/bloc/home/get_user_data/fetch_bloc.dart';
import 'package:juan_heart/bloc/home/get_user_data/fetch_bloc_event.dart';
import 'package:juan_heart/bloc/home/get_user_data/fetch_bloc_state.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/helper/lang_controller.dart';
import 'package:juan_heart/models/user_model.dart';
import 'package:juan_heart/themes/app_decoration.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';
import 'package:juan_heart/presentation/pages/settings/privacy_preferences_screen.dart';
import 'package:juan_heart/presentation/pages/settings/debug_menu_screen.dart';
import 'package:juan_heart/presentation/pages/settings/conflict_resolution_screen.dart';
import 'package:juan_heart/presentation/widgets/cached_image.dart';
import 'package:juan_heart/services/background_sync_service.dart';
import 'package:juan_heart/services/conflict_resolver.dart';

const List<String> list = <String>['English', 'Filipino'];

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool isNotification = true;
  late FetchUserDataBloc fetchUserDataBloc;
  final BackgroundSyncService _syncService = BackgroundSyncService.instance;

  // Sync state
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  bool _backgroundSyncEnabled = true;
  int _pendingOperations = 0;
  int _conflictCount = 0;

  @override
  void initState() {
    super.initState();
    fetchUserDataBloc = FetchUserDataBloc();
    fetchUserDataBloc.add(const GetUserData());
    _loadSyncStatus();
  }

  /// Load current sync status
  Future<void> _loadSyncStatus() async {
    final lastSync = await _syncService.getLastSyncTimestamp();
    final isEnabled = await _syncService.isBackgroundSyncEnabled();
    final stats = await _syncService.getSyncStatistics();
    final conflictCount =
        await ConflictResolver.instance.getManualReviewCount();

    if (mounted) {
      setState(() {
        _lastSyncTime = lastSync;
        _backgroundSyncEnabled = isEnabled;
        _pendingOperations = stats['pendingOperations'] ?? 0;
        _conflictCount = conflictCount;
      });
    }
  }

  /// Trigger manual sync
  Future<void> _triggerManualSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      await _syncService.triggerManualSync();
      await _loadSyncStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Get.locale?.languageCode == 'fil'
                  ? 'Matagumpay na nag-sync ng data'
                  : 'Data synced successfully',
              style: const TextStyle(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Get.locale?.languageCode == 'fil'
                  ? 'Nabigo ang pag-sync. Subukang muli.'
                  : 'Sync failed. Please try again.',
              style: const TextStyle(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  /// Toggle background sync
  Future<void> _toggleBackgroundSync(bool enabled) async {
    setState(() {
      _backgroundSyncEnabled = enabled;
    });

    try {
      if (enabled) {
        await _syncService.enableBackgroundSync();
      } else {
        await _syncService.disableBackgroundSync();
      }
    } catch (e) {
      debugPrint('Error toggling background sync: $e');
      // Revert state on error
      setState(() {
        _backgroundSyncEnabled = !enabled;
      });
    }
  }

  /// Format last sync time for display
  String _getLastSyncText() {
    if (_lastSyncTime == null) {
      return Get.locale?.languageCode == 'fil'
          ? 'Hindi pa nag-sync'
          : 'Never synced';
    }

    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);

    if (difference.inMinutes < 1) {
      return Get.locale?.languageCode == 'fil' ? 'KakaSync lang' : 'Just now';
    } else if (difference.inMinutes < 60) {
      return Get.locale?.languageCode == 'fil'
          ? '${difference.inMinutes} minuto ang nakalipas'
          : '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return Get.locale?.languageCode == 'fil'
          ? '${difference.inHours} oras ang nakalipas'
          : '${difference.inHours} hr ago';
    } else {
      return Get.locale?.languageCode == 'fil'
          ? '${difference.inDays} araw ang nakalipas'
          : '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.whiteBackground,
      appBar: AppBar(
        backgroundColor: ColorConstant.whiteBackground,
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
        // Temporarily hidden since app doesn't have authentication yet
        // actions: [
        //   PopupMenuButton<String>(
        //     onSelected: (value) {
        //       if (value == "Logout") {
        //         removeItemFromSharedPreferences(AuthState.authToken.toString());
        //         removeItemFromSharedPreferences(
        //             AuthState.authenticated.toString());

        //         // Since we bypassed login, go back to home instead
        //         Get.offAllNamed(AppRoutes.home);
        //       }
        //     },
        //     icon: Icon(
        //       Icons.more_horiz,
        //       color: ColorConstant.bluedark,
        //       size: 30,
        //     ),
        //     itemBuilder: (BuildContext context) {
        //       return <PopupMenuEntry<String>>[
        //         const PopupMenuItem<String>(
        //           value: "Logout",
        //           child: Text(
        //             "Logout",
        //           ),
        //         )
        //       ];
        //     },
        //   )
        // ],
        title: Text(
          "profile".tr,
          style: JHTextStyles.h4.copyWith(
            color: ColorConstant.bluedark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          margin: const EdgeInsets.only(top: 22),
          child: BlocProvider(
            create: (_) => fetchUserDataBloc,
            child: BlocBuilder<FetchUserDataBloc, FetchUserDataBlocState>(
              builder: (context, state) {
                if (state is FetchingDataSuccess) {
                  return _profileContent(state.user);
                }

                return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height / 1.2,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: ColorConstant.bluedark,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileContent(UserModel userModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              child: Row(
                children: [
                  CachedAvatarImage.asset(
                    ImageConstant.imgMaleAvatar,
                    size: 60,
                  ),
                  const SizedBox(
                    width: 22,
                  ),
                  Text(
                    userModel.fullName!,
                    style: const TextStyle(
                      
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: MediaQuery.of(context).size.width / 4.5,
                height: 35,
                decoration: BoxDecoration(
                  color: ColorConstant.bluedark,
                  borderRadius: BorderRadiusStyle.roundedBorder15,
                ),
                child: Center(
                  child: Text(
                    "Edit",
                    style: TextStyle(
                      color: ColorConstant.whiteText,
                      
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ratingCard(
                userModel.height.toString(),
                "cm",
                "height".tr,
              ),
              _ratingCard(
                userModel.weight.toString(),
                "kg",
                "weight".tr,
              ),
              _ratingCard(
                "22",
                "yo",
                "age".tr,
              ),
            ],
          ),
        ),
        AccountWidget(
          onTapPersonalData: () {},
          onTapEmergencyContact: () {},
          onTapAcitvityHistory: () {},
          onTapSetRemainder: () {},
        ),
        const SizedBox(
          height: 22,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          decoration: AppDecoration.boxShadowWithWhiteFillAndBorderRadius15,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Preferences",
                style: JHTextStyles.h5.copyWith(color: ColorConstant.bluedark, fontWeight: FontWeight.w600),
              ),
              // Build mode indicator (only visible in debug builds)
              if (kDebugMode)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Build Mode: DEBUG ✓ (Debug Menu visible below)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[900],
                      
                    ),
                  ),
                ),
              const SizedBox(
                height: 22,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CachedIconImage(
                        assetPath: ImageConstant.iconOutlineNotification,
                        size: 24,
                      ),
                      const SizedBox(
                        width: 22,
                      ),
                      Text(
                        "Pop-up Notification",
                        style: TextStyle(
                          color: ColorConstant.bluedark.withValues(alpha: 0.7),
                          fontSize: 15.5,
                          
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    activeColor: ColorConstant.bluedark,
                    inactiveThumbColor: ColorConstant.bluedark.withValues(alpha: 0.8),
                    inactiveTrackColor: ColorConstant.bluedark.withValues(alpha: 0.5),
                    value: isNotification,
                    onChanged: (val) {
                      setState(() {
                        isNotification = !isNotification;
                      });
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        child: CachedIconImage(
                          assetPath: ImageConstant.iconLanguage,
                          size: 32,
                        ),
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Text(
                        "languages".tr,
                        style: TextStyle(
                          color: ColorConstant.bluedark.withValues(alpha: 0.7),
                          fontSize: 15.5,
                          
                        ),
                      ),
                    ],
                  ),
                  const CustomDropdownButton(),
                ],
              ),
              const SizedBox(height: 16),
              // Privacy & Data menu item
              GestureDetector(
                onTap: () {
                  Get.to(() => const PrivacyPreferencesScreen());
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: ColorConstant.trustBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.privacy_tip,
                            color: ColorConstant.trustBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          Get.locale?.languageCode == 'fil'
                              ? 'Privacy at Data'
                              : 'Privacy & Data',
                          style: TextStyle(
                            color: ColorConstant.bluedark.withValues(alpha: 0.7),
                            fontSize: 15.5,
                            
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: ColorConstant.bluedark.withValues(alpha: 0.5),
                      size: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Data Sync menu item
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorConstant.bluedark.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: ColorConstant.reassuringGreen
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.sync,
                                color: ColorConstant.reassuringGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              Get.locale?.languageCode == 'fil'
                                  ? 'Pag-sync ng Data'
                                  : 'Data Sync',
                              style: TextStyle(
                                color: ColorConstant.bluedark,
                                fontSize: 15.5,
                                
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        // Sync Now button
                        GestureDetector(
                          onTap: _isSyncing ? null : _triggerManualSync,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isSyncing
                                  ? Colors.grey[300]
                                  : ColorConstant.bluedark,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: _isSyncing
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        ColorConstant.bluedark,
                                      ),
                                    ),
                                  )
                                : Text(
                                    Get.locale?.languageCode == 'fil'
                                        ? 'Sync Ngayon'
                                        : 'Sync Now',
                                    style: TextStyle(
                                      color: ColorConstant.whiteText,
                                      fontSize: 12,
                                      
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Last sync time
                    Text(
                      '${Get.locale?.languageCode == 'fil' ? 'Huling sync' : 'Last sync'}: ${_getLastSyncText()}',
                      style: TextStyle(
                        color: ColorConstant.bluedark.withValues(alpha: 0.6),
                        fontSize: 12,
                        
                      ),
                    ),
                    // Pending operations count
                    if (_pendingOperations > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$_pendingOperations ${Get.locale?.languageCode == 'fil' ? 'nakabinbing operasyon' : 'pending operations'}',
                          style: TextStyle(
                            color: ColorConstant.warningColor,
                            fontSize: 12,
                            
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Background sync toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Get.locale?.languageCode == 'fil'
                              ? 'Awtomatikong Sync'
                              : 'Background Sync',
                          style: TextStyle(
                            color: ColorConstant.bluedark.withValues(alpha: 0.7),
                            fontSize: 14,
                            
                          ),
                        ),
                        Switch(
                          activeColor: ColorConstant.reassuringGreen,
                          value: _backgroundSyncEnabled,
                          onChanged: _toggleBackgroundSync,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Conflict Resolution (only show if conflicts exist)
              if (_conflictCount > 0) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    await Get.to(() => const ConflictResolutionScreen());
                    // Refresh conflict count after returning
                    await _loadSyncStatus();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  ColorConstant.warningColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.sync_problem,
                              color: ColorConstant.warningColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            Get.locale?.languageCode == 'fil'
                                ? 'Ayusin ang Salungatan'
                                : 'Resolve Conflicts',
                            style: TextStyle(
                              color: ColorConstant.bluedark.withValues(alpha: 0.7),
                              fontSize: 15.5,
                              
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ColorConstant.warningColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_conflictCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: ColorConstant.bluedark.withValues(alpha: 0.5),
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              // Debug Menu (temporarily enabled for all builds for testing)
              if (true) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Get.to(() => const DebugMenuScreen());
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  ColorConstant.warningColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.bug_report,
                              color: ColorConstant.warningColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Debug Menu',
                            style: TextStyle(
                              color: ColorConstant.bluedark.withValues(alpha: 0.7),
                              fontSize: 15.5,
                              
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: ColorConstant.bluedark.withValues(alpha: 0.5),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(
          height: 22,
        ),
        OtherWidget(
          onTapContactUs: () {},
        ),
      ],
    );
  }

  Widget _ratingCard(String rating, measure, title) {
    return Container(
      padding: const EdgeInsets.all(10),
      width: MediaQuery.of(context).size.width / 3.7,
      decoration: AppDecoration.boxShadowWithWhiteFillAndBorderRadius15,
      child: Column(
        children: [
          Text(
            "$rating $measure",
            style: TextStyle(
              color: ColorConstant.bluedark,
              
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            "$title",
            style: JHTextStyles.bodyBase.copyWith(color: ColorConstant.gray.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class CustomDropdownButton extends StatefulWidget {
  const CustomDropdownButton({super.key});

  @override
  State<CustomDropdownButton> createState() => _CustomDropdownButtonState();
}

class _CustomDropdownButtonState extends State<CustomDropdownButton> {
  String dropdownValue = list.first;
  LangController langController = Get.put(LangController());

  updateLocale(Locale locale, BuildContext context) {
    Get.updateLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: dropdownValue,
      icon: const Icon(Icons.arrow_drop_down),
      elevation: 16,
      style: TextStyle(color: ColorConstant.bluedark),
      onChanged: (String? value) {
        // This is called when the user selects an item.
        setState(() {
          dropdownValue = value!;
        });

        if (value == "English") {
          updateLocale(const Locale("en", "US"), context);
          langController.setLanguagecode("en");
        } else if (value == "Filipino") {
          updateLocale(const Locale("tl", "PH"), context);
          langController.setLanguagecode("tl");
        }
      },
      items: list.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: TextStyle(
              
              fontSize: 15.5,
              color: ColorConstant.bluedark.withValues(alpha: 0.7),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class OtherWidget extends StatelessWidget {
  final VoidCallback onTapContactUs;
  const OtherWidget({super.key, required this.onTapContactUs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      decoration: AppDecoration.boxShadowWithWhiteFillAndBorderRadius15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "other".tr,
            style: JHTextStyles.h5.copyWith(color: ColorConstant.bluedark, fontWeight: FontWeight.w600),
          ),
          const SizedBox(
            height: 22,
          ),
          ItemCardWidget(
            leadingIcon: const Icon(
              Icons.email_outlined,
            ),
            title: "contactUs".tr,
            onTap: onTapContactUs,
          ),
          ItemCardWidget(
            leadingIcon: const Icon(
              Icons.policy_outlined,
            ),
            title: "privacy".tr,
            onTap: onTapContactUs,
          ),
        ],
      ),
    );
  }
}

class AccountWidget extends StatelessWidget {
  final VoidCallback onTapPersonalData,
      onTapEmergencyContact,
      onTapAcitvityHistory,
      onTapSetRemainder;
  const AccountWidget(
      {super.key,
      required this.onTapPersonalData,
      required this.onTapEmergencyContact,
      required this.onTapAcitvityHistory,
      required this.onTapSetRemainder});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      decoration: AppDecoration.boxShadowWithWhiteFillAndBorderRadius15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "account".tr,
            style: JHTextStyles.h5.copyWith(color: ColorConstant.bluedark, fontWeight: FontWeight.w600),
          ),
          const SizedBox(
            height: 22,
          ),
          ItemCardWidget(
            leadingIcon: const Icon(
              Icons.person_outline_outlined,
            ),
            title: "data".tr,
            onTap: onTapPersonalData,
          ),
          ItemCardWidget(
            leadingIcon: CachedIconImage(
              assetPath: ImageConstant.iconContact,
              size: 32,
            ),
            title: "contacts".tr,
            onTap: onTapEmergencyContact,
          ),
          ItemCardWidget(
            leadingIcon: CachedIconImage(
              assetPath: ImageConstant.iconPieChart,
              size: 32,
            ),
            title: "history".tr,
            onTap: onTapAcitvityHistory,
          ),
          ItemCardWidget(
            leadingIcon: CachedIconImage(
              assetPath: ImageConstant.iconOutlineNotification,
              size: 32,
            ),
            title: "remainders".tr,
            onTap: onTapSetRemainder,
          ),
        ],
      ),
    );
  }
}

class ItemCardWidget extends StatelessWidget {
  final Widget leadingIcon;
  final String title;
  final VoidCallback onTap;
  const ItemCardWidget(
      {super.key,
      required this.leadingIcon,
      required this.title,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                leadingIcon,
                const SizedBox(
                  width: 22,
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: ColorConstant.bluedark.withValues(alpha: 0.7),
                    fontSize: 15.5,
                    
                  ),
                ),
              ],
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 22,
              color: ColorConstant.bluedark.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
