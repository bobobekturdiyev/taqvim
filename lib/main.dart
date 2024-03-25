import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

main() {
  runApp(const MuslimCalendarApp());
}

class MuslimCalendarApp extends StatefulWidget {
  const MuslimCalendarApp({super.key});

  @override
  State<MuslimCalendarApp> createState() => _MuslimCalendarAppState();
}

class _MuslimCalendarAppState extends State<MuslimCalendarApp> {
  Future<Position> _detectPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return Future.error("Lokatsiya xizmati o'chirilgan");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return Future.error("Lokatsiyadan foydalanishga ruxsat berilmagan");
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<Map<String, dynamic>> fetchPrayerTimes(
      double latitude, double longitude) async {
    final dio = Dio();

    try {
      final response =
          await dio.get('http://api.aladhan.com/v1/calendar', queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        // 'method': 2,
        'month': DateTime.now().month, // 3
        'year': DateTime.now().year, // 2024
      });

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception("Xatolik sodir bo'ldi ma'lumotlarni yuklashda");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  List<dynamic> result = [];

  getData() async {
    print("check position");
    final Position position = await _detectPosition();
    print("fetching data...");
    final response =
        await fetchPrayerTimes(position.latitude, position.longitude);
    setState(() {
      result = response['data'];
      print(result);
    });
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orange,
          title: const Text("Ramazon Taqvim"),
        ),
        body: result.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.orange,
                ),
              )
            : ListView.builder(
                itemBuilder: (_, index) => Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16, top: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            result[index]['date']['readable'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Saharlik: ${result[index]['timings']['Imsak']}"),
                              Text(
                                  "Iftorlik: ${result[index]['timings']['Maghrib']}"),
                            ],
                          ),
                        ],
                      ),
                      const Divider(),
                    ],
                  ),
                ),
                itemCount: result.length,
              ),
      ),
    );
  }
}
