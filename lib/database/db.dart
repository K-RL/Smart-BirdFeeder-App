import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class Bird {
  String name;
  String latinName;
  double temperature; //°C
  double humidity; //%
  double pressure; //kPa
  String soundPath;
  DateTime date;

  Bird(this.name, this.latinName, this.temperature, this.humidity,
      this.pressure, this.soundPath, this.date);

  @override
  String toString() =>
      "Bird( name:$name; latinName:$latinName; temperature:$temperature; humidity:$humidity; pressure:$pressure; soundPath:$soundPath; date:$date)"; // Just for print()
}

Box<List<Bird>>? cachedDb;

//must be used only after future builder did first setup
final cachedDbProvider = StateProvider<Box<List<Bird>>>((ref) {
  return cachedDb!;
});

Future<Box<List<Bird>>> setupDatabase() async {
  final directory = await getApplicationDocumentsDirectory();
  Hive.init(directory.path + "/SmartBirdFeeder");

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(BirdAdapter());
  }
  var box = await Hive.openBox<List<Bird>>('birdsBox');
  // fill box for testing
  var now = DateTime.now();
  await box.clear();
  addToKey(box, now,
      Bird('Mésange', 'Paridae', 20.0, 58.0, 98.4, "", now));

  //loads audio test in android files.
  var appDirectory = await getApplicationDocumentsDirectory();
  final file1 = File('${appDirectory.path}/audio1.mp3');
    await file1.writeAsBytes(
        (await rootBundle.load('sounds/Rougegorge.mp3')).buffer.asUint8List());

  addToKey(
      box,
      now,
      Bird('Rouge-Gorge', 'Erithacus rubecula', 20, 58.0, 98.4,
          file1.path, now));
  var other = now.add(const Duration(days: 3, hours: 9));
  addToKey(
      box,
      other,
      Bird('Moineau', 'Passer domesticus', 20, 58.0, 98.4, "",
          other));

  var other2 = now.add(const Duration(days: 3, hours: 10));
  addToKey(box, other2,
      Bird('Merle', "Turdus merula", 21, 48.0, 60.4, "", other2));

  addToKey(
      box,
      other2,
      Bird('Rouge-Gorge', 'Erithacus rubecula', 10, 70.0, 50.4,
          "", other2));

  cachedDb = box;
  return cachedDb!;
}

Future<Box<List<Bird>>> getDatabase() async {
  return cachedDb == null ? await setupDatabase() : cachedDb!;
}

List<Bird> getBirds(WidgetRef ref, DateTime date) {
  return ref
      .watch(cachedDbProvider)
      .get(storeDate(date), defaultValue: List.empty())!;
}

void main() async {
  // Register Adapter
  Hive.registerAdapter(BirdAdapter());

  var box = await Hive.openBox<List<Bird>>('birdsBox');

  var now = DateTime.now();

  addToKey(box, now,
      Bird('name 1', 'latin 1', 20, 58.0, 98.4, "path/sound.ogg", now));
  addToKey(box, now,
      Bird('name 2', 'latin 2', 20, 58.0, 98.4, "path/sound.ogg", now));
  var other = now.add(const Duration(days: 3, hours: 9));
  addToKey(box, other,
      Bird('name 3', 'latin 3', 20, 58.0, 98.4, "path/sound.ogg", other));

  var other2 = now.add(const Duration(days: 3, hours: 10));
  addToKey(box, other2,
      Bird('name 4', 'latin 4', 20, 58.0, 98.4, "path/sound.ogg", other2));

  debugPrint(box.toMap().entries.toString());
}

int storeDate(DateTime date) {
  return (DateUtils.dateOnly(date).millisecondsSinceEpoch / 86400000).round();
}

void addToKey(Box<List<Bird>> box, DateTime date, Bird bird) {
  int dateInt = storeDate(date);
  if (box.containsKey(dateInt)) {
    box.get(dateInt)!.add(bird);
  } else {
    box.put(dateInt, List<Bird>.filled(1, bird, growable: true));
  }
}

// Can be generated automatically
class BirdAdapter extends TypeAdapter<Bird> {
  @override
  final typeId = 0;

  @override
  Bird read(BinaryReader reader) {
    return Bird(
        reader.readString(), //name
        reader.readString(), //latin
        reader.readDouble(), //temperature
        reader.readDouble(), //humidity
        reader.readDouble(), //pressure
        reader.readString(), //soundPath
        DateTime.parse(reader.readString())); //date
  }

  @override
  void write(BinaryWriter writer, Bird obj) {
    writer.writeString(obj.name);
    writer.writeString(obj.latinName);
    writer.writeDouble(obj.temperature);
    writer.writeDouble(obj.humidity);
    writer.writeDouble(obj.pressure);
    writer.writeString(obj.soundPath);
    writer.writeString(obj.date.toString());
  }
}
