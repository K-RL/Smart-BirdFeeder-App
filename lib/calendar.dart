import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:smart_bird_feeder/birdfetchpictures.dart';
import 'package:smart_bird_feeder/database/db.dart';
import 'package:smart_bird_feeder/theme/styles.dart';
import 'package:smart_bird_feeder/theme/theme.dart';
import 'package:smart_bird_feeder/utils.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

final selectedDayProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

class CalendarDisplay extends ConsumerWidget {
  const CalendarDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateRangePickerController _controller = DateRangePickerController();
    return Expanded(
      child: Stack(children: [
        SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SfDateRangePicker(
                  controller: _controller,
                  onSelectionChanged: (date) {
                    ref.watch(selectedDayProvider.notifier).state = date.value;
                  },
                  cellBuilder: (BuildContext context,
                      DateRangePickerCellDetails cellDetails) {
                    if (_controller.view == DateRangePickerView.month) {
                      var isToday = DateUtils.dateOnly(cellDetails.date) ==
                          DateUtils.dateOnly(DateTime.now());
                      return Center(
                        child: Stack(
                          children: [
                            Container(
                              width: cellDetails.bounds.width * 0.92,
                              height: cellDetails.bounds.height * 0.92,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    _controller.selectedDate == cellDetails.date
                                        ? colorBlue.withOpacity(0.6)
                                        : null,
                                border: isToday &&
                                        cellDetails.date !=
                                            _controller.selectedDate
                                    ? Border.all(width: 1, color: colorBlue)
                                    : null,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                cellDetails.date.day.toString(),
                                style: TextStyle(
                                    fontSize: 13,
                                    color: cellDetails.date ==
                                            _controller.selectedDate
                                        ? Colors.white
                                        : isToday
                                            ? colorBlue
                                            : null),
                              ),
                            ),
                            DisplayNumberOfBirdPerDay(
                              cellData: cellDetails,
                            )
                          ],
                        ),
                      );
                    } else if (_controller.view == DateRangePickerView.year) {
                      return Container(
                        width: cellDetails.bounds.width,
                        height: cellDetails.bounds.height,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          color: _controller.selectedDate == cellDetails.date
                              ? colorBlue
                              : cellDetails.date == DateTime.now()
                                  ? colorBlue.withOpacity(0.6)
                                  : null,
                          border:
                              (cellDetails.date.month == DateTime.now().month)
                                  ? Border.all(width: 1, color: colorBlue)
                                  : null,
                        ),
                        child: Text(DateFormat.MMM().format(cellDetails.date)),
                      );
                    } else if (_controller.view == DateRangePickerView.decade) {
                      return Container(
                        width: cellDetails.bounds.width,
                        height: cellDetails.bounds.height,
                        alignment: Alignment.center,
                        child: Text(cellDetails.date.year.toString()),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          color: _controller.selectedDate == cellDetails.date
                              ? colorBlue
                              : cellDetails.date == DateTime.now()
                                  ? colorBlue.withOpacity(0.6)
                                  : null,
                          border: (cellDetails.date.year == DateTime.now().year)
                              ? Border.all(width: 1, color: colorBlue)
                              : null,
                        ),
                      );
                    } else {
                      final int yearValue = (cellDetails.date.year ~/ 10) * 10;
                      return Container(
                        width: cellDetails.bounds.width,
                        height: cellDetails.bounds.height,
                        alignment: Alignment.center,
                        child: Text(yearValue.toString() +
                            ' - ' +
                            (yearValue + 9).toString()),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          color: _controller.selectedDate == cellDetails.date
                              ? colorBlue
                              : cellDetails.date == DateTime.now()
                                  ? colorBlue.withOpacity(0.6)
                                  : null,
                          border: (yearValue == DateTime.now().year ~/ 10 * 10)
                              ? Border.all(width: 1, color: colorBlue)
                              : null,
                        ),
                      );
                    }
                  },
                  monthCellStyle: const DateRangePickerMonthCellStyle(
                      cellDecoration: BoxDecoration(color: Colors.transparent)),
                  selectionColor: Colors.white.withOpacity(0.0),
                  todayHighlightColor: colorBlue,
                  headerStyle: DateRangePickerHeaderStyle(
                      textAlign: TextAlign.center, textStyle: calendarTitle),
                  selectionTextStyle: calendarText,
                ),
              ),
              const BirdList(),
              const SizedBox(
                height: 100,
              )
            ],
          ),
        ),
        const AudioWrapper()
      ]),
    );
  }
}

//List of birds displayed under the calendar
class BirdList extends ConsumerWidget {
  const BirdList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentlySelectedDay = ref.watch(selectedDayProvider);
    return Flexible(
        fit: FlexFit.loose,
        child: Column(
            children: getBirds(ref, currentlySelectedDay).map((bird) {
          return GestureDetector(
              onTap: () => ref
                  .watch(selectedBirdSongPathProvider.notifier)
                  .state = bird.soundPath,
              child: BirdCard(bird: bird));
        }).toList()));
  }
}

class BirdCard extends StatelessWidget {
  const BirdCard({Key? key, required this.bird}) : super(key: key);
  final Bird bird;

  Widget birdIcon(context) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colorGolden.withOpacity(0.4),
        ),
        width: MediaQuery.of(context).size.width * 0.16,
        height: MediaQuery.of(context).size.width * 0.16,
        child: Center(
            child: FaIcon(
          FontAwesomeIcons.dove,
          color: harmonizedRandomColor(seed: bird.name.hashCode),
          size: MediaQuery.of(context).size.width * 0.1,
        )));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SizedBox(
        height: MediaQuery.of(context).size.width * 0.18,
        child: Card(
          color: colorGolden.withOpacity(0.2),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              FutureBuilder(
                initialData: null,
                future: getBirdImage(bird, birdIcon(context)),
                builder: (context, AsyncSnapshot<Image?> snapshot) {
                  var notReady = !snapshot.hasData ||
                      snapshot.data == null ||
                      snapshot.connectionState != ConnectionState.done;
                  return Stack(children: [
                    birdIcon(context),
                    AnimatedOpacity(
                        curve: Curves.easeOut,
                        opacity: notReady ? 0.0 : 1.0,
                        duration: !notReady
                            ? const Duration(seconds: 1)
                            : const Duration(),
                        child: snapshot.data)
                  ]);
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      bird.name,
                      style: titleText,
                    ),
                    Text(bird.latinName, style: subtitleText)
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "${bird.date.hour} : ${bird.date.minute}",
                  style: text.copyWith(color: colorGolden),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class DisplayNumberOfBirdPerDay extends ConsumerWidget {
  const DisplayNumberOfBirdPerDay({Key? key, required this.cellData})
      : super(key: key);
  final DateRangePickerCellDetails cellData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Bird> birds = getBirds(ref, cellData.date);
    if (birds.isNotEmpty) {
      return Positioned(
          bottom: cellData.bounds.height * 0.01,
          right: cellData.bounds.width * 0.1,
          child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: colorGolden,
              ),
              child: Text(
                birds.length.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: colorWhite),
              )));
    }
    return const SizedBox.shrink();
  }
}

final selectedBirdSongPathProvider = StateProvider<String>((ref) {
  return "";
});

class AudioWrapper extends ConsumerWidget {
  const AudioWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String path = ref.watch(selectedBirdSongPathProvider);
    return AudioPlayer(
          path: path,
          totalSize: 160,
          buttonsSize: 80,
          bordersSize: 2,
          sidesMultiplier: 0.75,
          spacing: 10,
        );
  }
}

class AudioPlayer extends ConsumerStatefulWidget {
  const AudioPlayer(
      {Key? key,
      required this.buttonsSize,
      required this.totalSize,
      required this.path,
      this.bordersSize = 1.0,
      this.sidesMultiplier = 1.0,
      this.spacing = 20})
      : super(key: key);

  final double buttonsSize;
  final double totalSize;
  final double bordersSize;
  final double sidesMultiplier;
  final double spacing;
  final String path;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AudioPlayer();
}

class _AudioPlayer extends ConsumerState<AudioPlayer>
    with WidgetsBindingObserver {
  late final PlayerController birdSongController;
  @override
  void initState() {
    super.initState();
    birdSongController = PlayerController();
    birdSongController.onPlayerStateChanged.listen((state) {
        ref.watch(currentPlayerState.notifier).state = state;
    });
  }

  @override
  void dispose() {
    birdSongController.stopAllPlayers();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      birdSongController.stopAllPlayers();
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> preparePlayer() async {
    String path = ref.watch(selectedBirdSongPathProvider);

    if(Platform.isAndroid) {
      if(birdSongController.playerState != PlayerState.stopped) {
        await birdSongController.stopPlayer();
      }
    }
    else {
      birdSongController.setPlayerState(PlayerState.stopped);
    }
    if (path.isNotEmpty) {
      if(Platform.isAndroid) {
        await birdSongController.preparePlayer(path);
      }
      else {
        await birdSongController.preparePlayer(path);
        birdSongController.setPlayerState(PlayerState.initialized);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future:
          preparePlayer(), //in future builder because ref.watch during initstate causes issues
      builder: (context, snapshot) {
        var ready = (birdSongController.playerState != PlayerState.stopped);
        return Column(
          //making sure the widgets go to the
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SafeArea(
              child: AnimatedSlide(
                offset: ready ? Offset.zero : const Offset(0.0, 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                child: SizedBox(
                    height: widget.totalSize,
                    child: Stack(alignment: Alignment.bottomCenter, children: [
                      SizedBox(
                        height: widget.totalSize -
                            widget.buttonsSize / 2 +
                            widget.bordersSize,
                        child: Stack(children: [
                          //frost/transparent music player background
                          Blur(
                              blur: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.4)),
                              )),
                          Container(
                            decoration: BoxDecoration(
                                border: Border(
                                    top: BorderSide(
                                        color: colorGolden.withOpacity(0.6),
                                        width: widget.bordersSize))),
                          ),
                          Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (birdSongController.playerState !=
                                    PlayerState.stopped) ...[
                                  Padding(
                                    padding: const EdgeInsets.all(5)
                                        .add(const EdgeInsets.only(top: 10)),
                                    child: Center(
                                      child: AudioFileWaveforms(
                                        density: 3,
                                        size: Size(
                                            MediaQuery.of(context).size.width *
                                                0.65,
                                            90),
                                        playerController: birdSongController,
                                        playerWaveStyle: PlayerWaveStyle(
                                          fixedWaveColor: colorGolden,
                                          seekLineColor: colorGoldenAccent,
                                          scaleFactor: 0.4,
                                          waveThickness: 6,
                                          liveWaveColor: colorGoldenAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]
                              ]),
                        ]),
                      ),
                      Positioned(
                          top: 0.0,
                          child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: widget.spacing,
                              children: [
                                Padding(
                                    padding: EdgeInsets.only(
                                        top: widget.buttonsSize *
                                            (1.0 - widget.sidesMultiplier) /
                                            2),
                                    child: PlayerButton(
                                      birdSongController: birdSongController,
                                      bordersSize: widget.bordersSize,
                                      buttonsSize: widget.buttonsSize *
                                          widget.sidesMultiplier,
                                      icon: FontAwesomeIcons.backward,
                                      onPressed: () async {
                                        //5 seconds back
                                        await birdSongController.seekTo(
                                            await birdSongController
                                                    .getDuration(
                                                        DurationType.current) -
                                                5000);
                                      },
                                    )),
                                ConsumerPlayerButton(
                                  birdSongController: birdSongController,
                                  bordersSize: widget.bordersSize,
                                  buttonsSize: widget.buttonsSize,
                                  buildIcon: (playerstate) {
                                    switch (playerstate) {
                                      case PlayerState.playing:
                                        return FontAwesomeIcons.pause;
                                      default:
                                        return FontAwesomeIcons.play;
                                    }
                                  },
                                  onPressed: () async {
                                    if (birdSongController.playerState ==
                                        PlayerState.playing) {
                                          if(Platform.isAndroid) {
                                            await birdSongController.pausePlayer();
                                          } else {
                                            birdSongController.setPlayerState(PlayerState.paused);
                                          }
                                    } else {
                                      if(Platform.isAndroid) {
                                        await birdSongController.startPlayer(
                                            finishMode: FinishMode.loop);
                                      } else {
                                        birdSongController.setPlayerState(PlayerState.playing);
                                      }
                                    }
                                  },
                                ),
                                Padding(
                                    padding: EdgeInsets.only(
                                        top: widget.buttonsSize *
                                            (1.0 - widget.sidesMultiplier) /
                                            2),
                                    child: PlayerButton(
                                      birdSongController: birdSongController,
                                      bordersSize: widget.bordersSize,
                                      buttonsSize: widget.buttonsSize *
                                          widget.sidesMultiplier,
                                      icon: FontAwesomeIcons.forward,
                                      onPressed: () async {
                                        //add 5 seconds
                                        await birdSongController.seekTo(
                                            await birdSongController
                                                    .getDuration(
                                                        DurationType.current) +
                                                5000);
                                      },
                                    )),
                              ])),
                    ])),
              ),
            ),
          ],
        );
      },
    );
  }
}

final currentPlayerState = StateProvider<PlayerState>((ref) {
  return PlayerState.stopped;
});

class ConsumerPlayerButton extends ConsumerWidget {
  const ConsumerPlayerButton({
    Key? key,
    required this.buttonsSize,
    required this.bordersSize,
    required this.birdSongController,
    required this.buildIcon,
    required this.onPressed,
  }) : super(key: key);

  final double buttonsSize;
  final double bordersSize;
  final PlayerController birdSongController;
  final IconData Function(PlayerState) buildIcon;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var currentState = ref.watch(currentPlayerState);
    return PlayerButton(
        buttonsSize: buttonsSize,
        bordersSize: bordersSize,
        birdSongController: birdSongController,
        icon: buildIcon(currentState),
        onPressed: onPressed);
  }
}

class PlayerButton extends StatelessWidget {
  const PlayerButton({
    Key? key,
    required this.buttonsSize,
    required this.bordersSize,
    required this.birdSongController,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  final double buttonsSize;
  final double bordersSize;
  final PlayerController birdSongController;
  final IconData icon;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    double iconSize = buttonsSize * 0.6;
    return IconButton(
            iconSize: iconSize,
            color: colorGoldenAccent,
            onPressed: onPressed,
            icon: FaIcon(
              icon,
              size: iconSize,
              color: colorGolden,
            ))
        .customfrosted(
            height: buttonsSize,
            width: buttonsSize,
            borderRadius: BorderRadius.circular(100),
            blur: 2,
            frostOpacity: 0.4,
            borderSize: bordersSize);
  }
}

class CustomHalfCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.lineTo(0.0, size.height / 2);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}

extension FrostExtension on Widget {
  Stack customfrosted({
    double blur = 5,
    Color frostColor = Colors.white,
    AlignmentGeometry alignment = Alignment.center,
    double? height,
    double? width,
    double frostOpacity = 0.0,
    BorderRadius? borderRadius,
    double borderSize = 1.0,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    BoxDecoration? decoration,
  }) {
    return Stack(alignment: Alignment.center, children: [
      ClipPath(
          //blurred semi circle
          clipper: CustomHalfCircleClipper(),
          child: Blur(
            blur: blur,
            blurColor: frostColor,
            borderRadius: borderRadius,
            child: Container(
              height: height,
              width: width,
              padding: padding,
              child: height == null || width == null
                  ? this
                  : const SizedBox.shrink(),
              color: decoration == null
                  ? frostColor.withOpacity(frostOpacity)
                  : null,
              decoration: decoration,
            ),
            alignment: alignment,
          )),
      //CustomPaint(painter: BorderPaint(), child: Padding(padding: padding, child: this,),),
      ClipPath(
          //borders
          clipper: CustomHalfCircleClipper(),
          child: Container(
            height: height,
            width: width,
            padding: padding,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                    color: colorGolden.withOpacity(0.6), width: borderSize)),
          )),
      Padding(
        padding: padding,
        child: this,
      ) //button
    ]);
  }
}
