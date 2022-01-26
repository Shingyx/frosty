import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:frosty/screens/home/stores/list_store.dart';
import 'package:frosty/screens/home/widgets/stream_card.dart';
import 'package:frosty/screens/settings/stores/settings_store.dart';
import 'package:frosty/widgets/loading_indicator.dart';
import 'package:frosty/widgets/scroll_to_top_button.dart';
import 'package:provider/provider.dart';

class CategoryStreams extends StatelessWidget {
  final ListStore store;

  const CategoryStreams({Key? key, required this.store}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    final artWidth = (size.width * pixelRatio).toInt();
    final artHeight = (artWidth * (4 / 3)).toInt();

    final thumbnailWidth = (size.width * pixelRatio) ~/ 3;
    final thumbnailHeight = (thumbnailWidth * (9 / 16)).toInt();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          await store.refreshStreams();

          if (store.error != null) {
            final snackBar = SnackBar(
              content: Text(store.error!),
              behavior: SnackBarBehavior.floating,
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        },
        child: Observer(
          builder: (context) {
            if (store.streams.isEmpty && store.isLoading && store.error == null) {
              return const LoadingIndicator(subtitle: Text('Loading streams...'));
            }
            return Stack(
              alignment: AlignmentDirectional.bottomCenter,
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  controller: store.scrollController,
                  slivers: [
                    SliverAppBar(
                      stretch: true,
                      pinned: true,
                      expandedHeight: MediaQuery.of(context).size.height / 3,
                      flexibleSpace: FlexibleSpaceBar(
                        stretchModes: const [
                          StretchMode.fadeTitle,
                          StretchMode.zoomBackground,
                        ],
                        centerTitle: true,
                        title: Text(
                          store.categoryInfo!.name,
                          style: Theme.of(context).textTheme.headline6?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        background: CachedNetworkImage(
                          imageUrl: store.categoryInfo!.boxArtUrl.replaceRange(
                            store.categoryInfo!.boxArtUrl.lastIndexOf('-') + 1,
                            null,
                            '${artWidth}x$artHeight.jpg',
                          ),
                          placeholder: (context, url) => const LoadingIndicator(),
                          color: const Color.fromRGBO(255, 255, 255, 0.5),
                          colorBlendMode: BlendMode.modulate,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SliverSafeArea(
                      top: false,
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index > store.streams.length / 2 && store.hasMore) {
                              store.getStreams();
                            }
                            return Observer(
                              builder: (context) => StreamCard(
                                streamInfo: store.streams[index],
                                width: thumbnailWidth,
                                height: thumbnailHeight,
                                showUptime: context.read<SettingsStore>().showThumbnailUptime,
                              ),
                            );
                          },
                          childCount: store.streams.length,
                        ),
                      ),
                    ),
                  ],
                ),
                SafeArea(
                  child: Observer(
                    builder: (context) => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: store.showJumpButton ? ScrollToTopButton(scrollController: store.scrollController) : null,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}