import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:project_app/pages/auth_service.dart';
import 'package:project_app/pages/login.dart';
import 'package:project_app/pages/CarDetailPage.dart';

class Auction {
  final String id;
  final Car car;
  final DateTime startDate;
  final DateTime endDate;
  final double startingPrice;
  final double currentBid;
  final int bidCount;
  final List<String> bidders;

  Auction({
    required this.id,
    required this.car,
    required this.startDate,
    required this.endDate,
    required this.startingPrice,
    required this.currentBid,
    required this.bidCount,
    required this.bidders,
  });

  factory Auction.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) {
        return DateTime.now();
      }
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        print('Erreur lors du parsing de la date: $dateString, erreur: $e');
        return DateTime.now();
      }
    }

    return Auction(
      id: json['_id'] ?? 'N/A',
      car: Car.fromJson(json['carDetails'] ?? {}),
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      startingPrice: (json['startingPrice'] as num?)?.toDouble() ?? 0.0,
      currentBid: (json['currentBid'] as num?)?.toDouble() ?? 0.0,
      bidCount: json['bidCount'] ?? 0,
      bidders: List<String>.from(json['bidders'] ?? []),
    );
  }
}

class Car {
  final String brand;
  final String model;
  final int year;
  final String? image;
  final String power;
  final String licensePlate;

  Car({
    required this.brand,
    required this.model,
    required this.year,
    this.image,
    required this.power,
    required this.licensePlate,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      brand: json['brand'] ?? 'N/A',
      model: json['carModel'] ?? 'N/A',
      year: (json['year'] as num?)?.toInt() ?? 0,
      image: json['image'],
      power: json['power']?.toString() ?? 'N/A',
      licensePlate: json['licensePlate'] ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'carModel': model,
      'year': year,
      'image': image,
      'power': power,
      'licensePlate': licensePlate,
    };
  }
}

class AnimatedScaleCard extends StatefulWidget {
  final Widget child;

  const AnimatedScaleCard({super.key, required this.child});

  @override
  State<AnimatedScaleCard> createState() => _AnimatedScaleCardState();
}

class _AnimatedScaleCardState extends State<AnimatedScaleCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        child: widget.child,
      ),
    );
  }
}

class MyAuctionsPage extends StatefulWidget {
  const MyAuctionsPage({super.key});

  @override
  State<MyAuctionsPage> createState() => _MyAuctionsPageState();
}

class _MyAuctionsPageState extends State<MyAuctionsPage> {
  List<Auction> auctions = [];
  String errorMessage = '';
  bool isLoading = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchUserAuctions();
  }

  Future<void> _fetchUserAuctions() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
     final token = await _authService.getToken();
print('Token utilisé : $token'); // Ajoutez ce log
if (token == null) {
  setState(() {
    isLoading = false;
    errorMessage = 'Veuillez vous connecter pour voir vos enchères';
  });
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const Login()),
  );
  return;
}

      final response = await http.get(
        Uri.parse('http://10.0.2.2:6006/auctions/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Statut de la réponse API: ${response.statusCode}');
      print('Corps de la réponse API: ${response.body}');

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData is List) {
          final allAuctions = decodedData.map((json) => Auction.fromJson(json)).toList();
          print('Enchères avant filtrage: ${allAuctions.map((a) => {'id': a.id, 'car': {'brand': a.car.brand, 'model': a.car.model}}).toList()}');
          final validAuctions = allAuctions; // Pas de filtrage pour déboguer
          print('Enchères valides après filtrage: ${validAuctions.map((a) => {'id': a.id, 'car': {'brand': a.car.brand, 'model': a.car.model}}).toList()}');
          setState(() {
            auctions = validAuctions;
            isLoading = false;
            errorMessage = validAuctions.isEmpty
                ? 'Aucune enchère trouvée pour vos voitures. Ajoutez une voiture ou créez une enchère.'
                : '';
          });
        }  else {
          setState(() {
            isLoading = false;
            errorMessage = 'Format de données inattendu';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Erreur HTTP: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération des enchères: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Erreur: $e';
      });
    }
  }

  String _calculateTimeRemaining(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) {
      return 'Enchère terminée';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    return days > 0
        ? '$days j ${hours}h'
        : hours > 0
            ? '${hours}h ${minutes}m'
            : '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy', 'fr_FR');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Mes enchères',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.indigo[600],
        elevation: 4,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo[700]!, Colors.indigo[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Vos enchères',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Consultez les enchères que vous avez créées',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
                  : errorMessage.isNotEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  errorMessage,
                                  style: const TextStyle(fontSize: 16, color: Colors.indigo),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchUserAuctions,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo[600],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.0)),
                                  ),
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchUserAuctions,
                          color: Colors.indigo,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: auctions.length,
                            itemBuilder: (context, index) {
                              final auction = auctions[index];
                              return _buildAuctionCard(
                                auction.id,
                                auction.car.brand,
                                auction.car.model,
                                auction.car.year.toString(),
                                auction.car.image,
                                auction.car.power,
                                auction.car.licensePlate,
                                auction.startingPrice,
                                auction.currentBid,
                                auction.startDate,
                                auction.endDate,
                                auction.car.toJson(),
                                auction.bidCount,
                                context,
                                dateFormatter,
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionCard(
    String auctionId,
    String brand,
    String carModel,
    String year,
    String? imageUrl,
    String power,
    String licensePlate,
    double startingPrice,
    double currentBid,
    DateTime startDate,
    DateTime endDate,
    Map<String, dynamic> carDetails,
    int bidCount,
    BuildContext context,
    DateFormat dateFormatter,
  ) {
    const defaultImage = 'assets/images/car_placeholder.png';
    final validImageUrl = imageUrl != null && imageUrl.isNotEmpty ? imageUrl : null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final auctionEndDate = DateTime(endDate.year, endDate.month, endDate.day);
    final isEnded = endDate.isBefore(now);
    final isNotStarted = startDate.isAfter(now);
    final isEndingToday = auctionEndDate.isAtSameMomentAs(today) && !isEnded;

    final formattedStartDate = dateFormatter.format(startDate);

    return AnimatedScaleCard(
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNotStarted) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'Enchère pas encore ouverte',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Text(
                  'Débute le : $formattedStartDate',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (isEndingToday)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'Se termine aujourd\'hui !',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              if (isEnded)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'Enchère terminée',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: validImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: validImageUrl,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator(color: Colors.indigo)),
                            errorWidget: (_, __, ___) => Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey[300],
                              child: Image.asset(
                                defaultImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.image_not_supported, color: Colors.grey)),
                              ),
                            ),
                          )
                        : Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[300],
                            child: Image.asset(
                              defaultImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.image_not_supported, color: Colors.grey)),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$brand $carModel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isEnded || isNotStarted ? Colors.grey : Colors.indigo,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Année: $year',
                          style: TextStyle(fontSize: 14, color: isEnded || isNotStarted ? Colors.grey : Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Immatriculation: $licensePlate',
                          style: TextStyle(fontSize: 12, color: isEnded || isNotStarted ? Colors.grey : Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Puissance: $power HP',
                          style: TextStyle(fontSize: 14, color: isEnded || isNotStarted ? Colors.grey : Colors.indigo),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Enchère actuelle: ${currentBid.toStringAsFixed(2)} €',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isEnded || isNotStarted ? Colors.grey : Colors.indigo,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Prix initial: ${startingPrice.toStringAsFixed(2)} €',
                style: TextStyle(fontSize: 14, color: isEnded || isNotStarted ? Colors.grey : Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: isEndingToday ? Colors.red : (isEnded || isNotStarted ? Colors.grey : Colors.indigo),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _calculateTimeRemaining(endDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: isEndingToday ? Colors.red : (isEnded || isNotStarted ? Colors.grey : Colors.indigo),
                      fontWeight: isEndingToday ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CarDetailPage(car: carDetails),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 3,
                      minimumSize: const Size(80, 36),
                    ),
                    child: Text(
                      isEnded ? 'Voir' : 'Détails',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
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
}
