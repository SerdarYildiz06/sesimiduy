import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kartal/kartal.dart';
import 'package:sesimiduy/features/current_map/model/marker_models.dart';
import 'package:sesimiduy/features/current_map/provider/map_provider.dart';
import 'package:sesimiduy/features/current_map/view/action/poi_action_button.dart';
import 'package:sesimiduy/features/current_map/view/bottom_page_view.dart';
import 'package:sesimiduy/features/login/service/map_service.dart';
import 'package:sesimiduy/product/init/language/locale_keys.g.dart';
import 'package:sesimiduy/product/items/colors_custom.dart';
import 'package:sesimiduy/product/utility/constants/app_constants.dart';
import 'package:sesimiduy/product/utility/mixin/app_provider_mixin.dart';
import 'package:sesimiduy/product/utility/size/index.dart';

class CurrentMapView extends ConsumerStatefulWidget {
  const CurrentMapView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CurrentMapViewState();
}

class _CurrentMapViewState extends ConsumerState<CurrentMapView>
    with AppProviderMixin, _CurrentMapMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorsCustom.sambacus,
        title: SizedBox(
          width: context.dynamicWidth(0.4),
          child: FittedBox(child: Text(LocaleKeys.login_currentMap.tr())),
        ),
        titleSpacing: 0,
        centerTitle: false,
        actions: [
          PoiActionButton(
            onSelected: onPoiCategoryUpdate,
            onSelectedPolyLine: (value) {
              ref.read(mapProvider.notifier).setPolyLines(value);
            },
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Consumer(
            builder: (context, widgetRef, child) {
              final selectedCategoriesItems =
                  widgetRef.watch(mapProvider).selectedMarkers ?? {};
              final requestedMarkers =
                  widgetRef.watch(mapProvider).requestMarkers ?? {};

              return GoogleMap(
                polylines: widgetRef.watch(mapProvider).polylines ?? {},
                onMapCreated: (controller) {
                  widgetRef
                      .read(mapProvider.notifier)
                      .setController(controller);
                },
                markers: Set.from(
                  selectedCategoriesItems.toList() + requestedMarkers.toList(),
                ),
                initialCameraPosition: initialCameraPosition,
              );
            },
          ),
          Positioned(
            bottom: WidgetSizes.spacingL,
            right: 0,
            left: 0,
            height: WidgetSizes.spacingXxl8 * 3,
            child: SafeArea(
              child: BottomPageView(
                wantedItems: ref.watch(mapProvider).wanteds ?? [],
                mapProvider: ref.read(mapProvider.notifier),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

mixin _CurrentMapMixin on AppProviderMixin<CurrentMapView> {
  late final StateNotifierProvider<MapProvider, MapState> mapProvider;
  late final MapService service;

  CameraPosition get initialCameraPosition => const CameraPosition(
        target: AppConstants.defaultLocation,
        zoom: AppConstants.defaultMapZoom,
      );
  @override
  void initState() {
    super.initState();
    service = MapService();
    mapProvider = StateNotifierProvider((ref) => MapProvider(service: service));
    ref.read(mapProvider.notifier).init(context).whenComplete(
      () async {
        await ref.read(mapProvider.notifier).fetchRequestPOI(context);
        final position = appState.position;
        if (position == null) return;
        ref
            .read(mapProvider.notifier)
            .changeMapView(GeoPoint(position.latitude, position.longitude));
      },
    );
  }

  Future<void> onPoiCategoryUpdate(
    Set<ProductMarker> value,
  ) async {
    await ref.read(mapProvider.notifier).updatePoiWithIconCheck(
          value,
          context,
        );
    final position = value.firstOrNull?.position;

    if (position == null) return;

    ref.read(mapProvider.notifier).changeMapView(
          GeoPoint(
            position.latitude,
            position.longitude,
          ),
        );
  }
}
