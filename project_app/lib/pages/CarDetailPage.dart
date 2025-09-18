/// The `CarDetailPage` class in Dart is a StatefulWidget that displays detailed information about a
/// car, including specifications, technical features, comfort amenities, seat conditions, and provides
/// a button to return to the previous page.
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:project_app/pages/home.dart'; // Pour AnimatedButton

class CarDetailPage extends StatefulWidget {
  final Map<String, dynamic> car;

  const CarDetailPage({super.key, required this.car});

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const defaultImage = 'assets/images/car_placeholder.png';
    final String? imageUrl = widget.car['image'];
    final validImageUrl = imageUrl != null && imageUrl.isNotEmpty ? imageUrl : null;
    final seatCondition = widget.car['seatCondition'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          '${widget.car['brand'] ?? 'N/A'} ${widget.car['carModel'] ?? 'N/A'}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre de la voiture centré
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  '${widget.car['brand'] ?? 'Voiture'} ${widget.car['carModel'] ?? 'inconnue'}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Section image
              Container(
                width: double.infinity,
                height: 250,
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: validImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: validImageUrl,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.indigo,
                            ),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            defaultImage,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 250,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        )
                      : Image.asset(
                          defaultImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 250,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 80,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                ),
              ),
              // Section Spécifications générales
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spécifications générales',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          icon: Icons.directions_car,
                          label: 'Marque',
                          value: widget.car['brand'] ?? 'N/A',
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: Icons.model_training,
                          label: 'Modèle',
                          value: widget.car['carModel'] ?? 'N/A',
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: Icons.event,
                          label: 'Année',
                          value: widget.car['year']?.toString() ?? 'N/A',
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: Icons.confirmation_number,
                          label: 'Immatriculation',
                          value: widget.car['licensePlate'] ?? 'N/A',
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: Icons.build,
                          label: 'Numéro de châssis',
                          value: widget.car['chassisNumber'] ?? 'N/A',
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: Icons.color_lens,
                          label: 'Couleur',
                          value: widget.car['currentCard'] ?? 'N/A',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Section Caractéristiques techniques
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Caractéristiques techniques',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          icon: Icons.settings,
                          label: 'Cylindres',
                          value: widget.car['cylinders']?.toString() ?? 'N/A',
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: Icons.speed,
                          label: 'Puissance',
                          value: '${widget.car['power'] ?? 'N/A'} HP',
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: Icons.speed,
                          label: 'Vitesse max',
                          value: '${widget.car['speed'] ?? 'N/A'} km/h',
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: Icons.lightbulb,
                          label: 'Phares',
                          value: widget.car['lights'] ?? 'N/A',
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: Icons.assistant,
                          label: 'Assistance',
                          value: widget.car['assistance'] ?? 'N/A',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Section Confort et équipements
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confort et équipements',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          icon: Icons.event_seat,
                          label: 'Sièges',
                          value: widget.car['seats']?.toString() ?? 'N/A',
                        ),
                        const Divider(),
                        _buildBoolRow(
                          icon: Icons.ac_unit,
                          label: 'Climatisation',
                          value: widget.car['airConditioning'] ?? false,
                        ),
                        const Divider(),
                        _buildBoolRow(
                          icon: Icons.tv,
                          label: 'Écran',
                          value: widget.car['screen'] ?? false,
                        ),
                        const Divider(),
                        _buildBoolRow(
                          icon: Icons.roofing,
                          label: 'Toit ouvrant',
                          value: widget.car['hasSunroof'] ?? false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Section État des sièges
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'État des sièges',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildBoolRow(
                          icon: Icons.cleaning_services,
                          label: 'Propre',
                          value: seatCondition['clean'] ?? false,
                        ),
                        const Divider(),
                        _buildBoolRow(
                          icon: Icons.water_drop,
                          label: 'Taché',
                          value: seatCondition['stained'] ?? false,
                        ),
                        const Divider(),
                        _buildBoolRow(
                          icon: Icons.broken_image,
                          label: 'Déchiré',
                          value: seatCondition['torn'] ?? false,
                        ),
                        const Divider(),
                        _buildBoolRow(
                          icon: Icons.local_fire_department,
                          label: 'Chauffant',
                          value: seatCondition['heated'] ?? false,
                        ),
                        const Divider(),
                        _buildBoolRow(
                          icon: Icons.electric_bolt,
                          label: 'Électrique',
                          value: seatCondition['electric'] ?? false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bouton Retour
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: AnimatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Retour',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.indigo[600],
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.indigo[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoolRow({
    required IconData icon,
    required String label,
    required bool value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.indigo[600],
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  value ? Icons.check_circle : Icons.cancel,
                  color: value ? Colors.green : Colors.red,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}