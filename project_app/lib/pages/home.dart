import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
// import 'package:intl/date_symbol_data_local.dart';
import 'package:project_app/pages/AddCar.dart';
import 'package:project_app/pages/CarDetailPage.dart';
import 'package:project_app/pages/EditProfilePage.dart';
import 'dart:convert';
import 'package:project_app/pages/auth_service.dart';
import 'package:project_app/pages/login.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:project_app/pages/my_auctions_page.dart'; // Nouvelle page
import 'package:socket_io_client/socket_io_client.dart' as IO;

// Widget pour une carte avec animation de mise à l'échelle
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

// Écran principal de l'application
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;

  // Méthode pour passer à la page des voitures
  void _onSeeMoreTapped(BuildContext context) {
    setState(() => _currentIndex = 1);
  }

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      HomePage(onSeeMoreTapped: _onSeeMoreTapped),
      const CarPage(),
      const BidPage(),
      const NotificationsPage(),
      const ProfilePage(),
    ]);
  }

  // Déconnexion de l'utilisateur
  void _logout(BuildContext context) async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Betta Auto',
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
        leading: IconButton(
          icon: const Icon(Icons.gavel, color: Colors.white),
          onPressed: () => setState(() => _currentIndex = 2),
        ),
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.indigo[200],
                border: Border(bottom: BorderSide(color: Colors.indigo[400]!)),
              ),
              child: const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildDrawerItem(Icons.home, 'Accueil', () {
              setState(() => _currentIndex = 0);
              Navigator.pop(context);
            }),
            _buildDrawerItem(Icons.directions_car, 'Voitures', () {
              setState(() => _currentIndex = 1);
              Navigator.pop(context);
            }),
            _buildDrawerItem(Icons.gavel, 'Enchères', () {
              setState(() => _currentIndex = 2);
              Navigator.pop(context);
            }),
            _buildDrawerItem(Icons.settings, 'Paramètres', () => Navigator.pop(context)),
            _buildDrawerItem(Icons.logout, 'Déconnexion', () => _logout(context)),
          ],
        ),
      ),
      body: Stack(
        children: [
          _pages[_currentIndex],
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddCar()),
                );
              },
              backgroundColor: Colors.indigo[600],
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ConvexAppBar(
        key: UniqueKey(),
        backgroundColor: Colors.indigo[600],
        color: Colors.white,
        activeColor: Colors.indigo[900],
        style: TabStyle.reactCircle,
        curveSize: 80,
        items: const [
          TabItem(icon: Icons.home, title: 'Accueil'),
          TabItem(icon: Icons.directions_car, title: 'Voiture'),
          TabItem(icon: Icons.gavel, title: 'Enchère'),
          TabItem(icon: Icons.notifications, title: 'Notifications'),
          TabItem(icon: Icons.person, title: 'Profil'),
        ],
        initialActiveIndex: _currentIndex,
        onTap: (int index) => setState(() => _currentIndex = index),
      ),
    );
  }

  // Construit un élément du menu déroulant
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo[600]),
        title: Text(
          title,
          style: TextStyle(color: Colors.indigo[800], fontWeight: FontWeight.w500),
        ),
        onTap: onTap,
        hoverColor: Colors.indigo[50],
      ),
    );
  }
}

// Page d'accueil
class HomePage extends StatefulWidget {
  final Function(BuildContext) onSeeMoreTapped;

  const HomePage({super.key, required this.onSeeMoreTapped});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> cars = [];
  List<Map<String, dynamic>> filteredCars = [];
  String errorMessage = '';
  String selectedFilter = 'Tout';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCars();
  }

  // Récupère la liste des voitures depuis le backend
  Future<void> _fetchCars() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:6006/cars/getAllCars'));
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData is List) {
          setState(() {
            cars = List<Map<String, dynamic>>.from(decodedData);
            filteredCars = cars;
            errorMessage = cars.isEmpty ? 'Aucune voiture trouvée' : '';
          });
        } else {
          setState(() => errorMessage = 'Format de données inattendu');
        }
      } else {
        setState(() => errorMessage = 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => errorMessage = 'Erreur: $e');
    }
  }

  // Filtre les voitures selon la catégorie
  void filterCars(String filter) {
    setState(() {
      selectedFilter = filter;
      filteredCars = cars.where((car) {
        String brand = car['brand']?.toLowerCase() ?? '';
        String model = car['carModel']?.toLowerCase() ?? '';
        bool matchesSearch = searchQuery.isEmpty ||
            brand.contains(searchQuery.toLowerCase()) ||
            model.contains(searchQuery.toLowerCase());
        if (filter == 'Tout') return matchesSearch;
        bool matchesFilter = false;
        if (filter == 'SUV') {
          matchesFilter = brand.contains('bmw') || brand.contains('toyota');
        } else if (filter == 'Berline') {
          matchesFilter = brand.contains('mercedes') || brand.contains('honda');
        } else if (filter == 'Sport') {
          matchesFilter = brand.contains('ferrari') || brand.contains('porsche');
        }
        return matchesFilter && matchesSearch;
      }).toList();
      errorMessage = filteredCars.isEmpty ? 'Aucune voiture trouvée' : '';
    });
  }

  // Recherche parmi les voitures
  void searchCars(String query) {
    setState(() {
      searchQuery = query;
      filterCars(selectedFilter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Trouvez votre voiture idéale',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Explorez notre sélection exclusive',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une marque ou un modèle...',
                prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.indigo),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                            filterCars(selectedFilter);
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.indigo[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: const BorderSide(color: Colors.indigo, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: const BorderSide(color: Colors.indigo, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
              ),
              onChanged: searchCars,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: const Text(
            'Filtrer par catégorie',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo),
          ),
        ),
        SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilterButton('Tout', context),
              _buildFilterButton('SUV', context),
              _buildFilterButton('Berline', context),
              _buildFilterButton('Sport', context),
            ],
          ),
        ),
        Expanded(
          child: filteredCars.isEmpty
              ? Center(
                  child: errorMessage.isNotEmpty
                      ? Text(errorMessage, style: const TextStyle(color: Colors.indigo))
                      : const CircularProgressIndicator(),
                )
              : RefreshIndicator(
                  onRefresh: _fetchCars,
                  color: Colors.indigo,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: min(filteredCars.length, 3) + (filteredCars.length > 3 ? 1 : 0) + 1,
                    itemBuilder: (context, index) {
                      if (index < min(filteredCars.length, 3)) {
                        final car = filteredCars[index];
                        return _buildCarCard(
                          car['licensePlate'] ?? 'N/A',
                          car['brand'] ?? 'N/A',
                          car['carModel'] ?? 'N/A',
                          car['year']?.toString() ?? 'N/A',
                          car['image'],
                          car['power']?.toString() ?? 'N/A',
                          car,
                          context,
                        );
                      } else if (index == min(filteredCars.length, 3) && filteredCars.length > 3) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: GestureDetector(
                            onTap: () => widget.onSeeMoreTapped(context),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: const Text(
                                'Voir plus...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo,
                                  decoration: TextDecoration.underline,
                                ),
                                textAlign: TextAlign.center

),
                            ),
                          ),
                        );
                      } else {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                          margin: const EdgeInsets.only(top: 16.0),
                          color: Colors.indigo[50],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Betta Auto',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Votre partenaire automobile',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildFooterLink('Contact', () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Page Contact en développement')),
                                    );
                                  }),
                                  const SizedBox(width: 16),
                                  _buildFooterLink('À propos', () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Page À propos en développement')),
                                    );
                                  }),
                                  const SizedBox(width: 16),
                                  _buildFooterLink('Enchères', () {
                                    _HomeScreenState? state =
                                        context.findAncestorStateOfType<_HomeScreenState>();
                                    if (state != null) {
                                      state.setState(() => state._currentIndex = 2);
                                    }
                                  }),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '© 2025 Betta Auto',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // Construit un lien dans le pied de page
  Widget _buildFooterLink(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.indigo,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  // Construit un bouton de filtre
  Widget _buildFilterButton(String label, BuildContext context) {
    bool isActive = selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: () => filterCars(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? Colors.indigo[900] : Colors.indigo[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: isActive ? 6 : 4,
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // Construit une carte de voiture
  Widget _buildCarCard(
    String licensePlate,
    String brand,
    String carModel,
    String year,
    String? imageUrl,
    String power,
    Map<String, dynamic> car,
    BuildContext context,
  ) {
    const defaultImage = 'assets/images/car_placeholder.png';
    final validImageUrl = imageUrl != null && imageUrl.isNotEmpty ? imageUrl : null;

    return AnimatedScaleCard(
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: validImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: validImageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: Image.asset(
                            defaultImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                          ),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: Image.asset(
                          defaultImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Année: $year',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Immatriculation: $licensePlate',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Puissance: $power HP',
                      style: const TextStyle(fontSize: 14, color: Colors.indigo),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CarDetailPage(car: car)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 3,
                    minimumSize: const Size(80, 36),
                  ),
                  child: const Text(
                    'Détails',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Page des voitures
class CarPage extends StatefulWidget {
  const CarPage({super.key});

  @override
  State<CarPage> createState() => _CarPageState();
}

class _CarPageState extends State<CarPage> {
  List<Map<String, dynamic>> cars = [];
  List<Map<String, dynamic>> filteredCars = [];
  String errorMessage = '';
  String searchQuery = '';
  String selectedFilter = 'Tout';

  @override
  void initState() {
    super.initState();
    _fetchCars();
  }

  // Récupère la liste des voitures depuis le backend
  Future<void> _fetchCars() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:6006/cars/getAllCars'));
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData is List) {
          setState(() {
            cars = List<Map<String, dynamic>>.from(decodedData);
            filteredCars = cars;
            errorMessage = cars.isEmpty ? 'Aucune voiture trouvée' : '';
          });
        } else {
          setState(() => errorMessage = 'Format de données inattendu');
        }
      } else {
        setState(() => errorMessage = 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => errorMessage = 'Erreur: $e');
    }
  }

  // Filtre les voitures selon la catégorie
  void filterCars(String filter) {
    setState(() {
      selectedFilter = filter;
      filteredCars = cars.where((car) {
        String brand = car['brand']?.toLowerCase() ?? '';
        String model = car['carModel']?.toLowerCase() ?? '';
        bool matchesSearch = searchQuery.isEmpty ||
            brand.contains(searchQuery.toLowerCase()) ||
            model.contains(searchQuery.toLowerCase());
        if (filter == 'Tout') return matchesSearch;
        bool matchesFilter = false;
        if (filter == 'SUV') {
          matchesFilter = brand.contains('bmw') || brand.contains('toyota');
        } else if (filter == 'Berline') {
          matchesFilter = brand.contains('mercedes') || brand.contains('honda');
        } else if (filter == 'Sport') {
          matchesFilter = brand.contains('ferrari') || brand.contains('porsche');
        }
        return matchesFilter && matchesSearch;
      }).toList();
      errorMessage = filteredCars.isEmpty ? 'Aucune voiture trouvée' : '';
    });
  }

  // Recherche parmi les voitures
  void searchCars(String query) {
    setState(() {
      searchQuery = query;
      filterCars(selectedFilter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher une marque ou un modèle...',
                    prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.indigo),
                            onPressed: () {
                              setState(() {
                                searchQuery = '';
                                filterCars(selectedFilter);
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.indigo[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: const BorderSide(color: Colors.indigo, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: const BorderSide(color: Colors.indigo, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                  ),
                  onChanged: searchCars,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Voitures disponibles',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilterButton('Tout'),
              _buildFilterButton('SUV'),
              _buildFilterButton('Berline'),
              _buildFilterButton('Sport'),
            ],
          ),
        ),
        Expanded(
          child: filteredCars.isEmpty
              ? Center(
                  child: errorMessage.isNotEmpty
                      ? Text(errorMessage, style: const TextStyle(color: Colors.indigo))
                      : const CircularProgressIndicator(),
                )
              : RefreshIndicator(
                  onRefresh: _fetchCars,
                  color: Colors.indigo,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredCars.length,
                    itemBuilder: (context, index) {
                      final car = filteredCars[index];
                      return _buildCarCard(
                        car['licensePlate'] ?? 'N/A',
                        car['brand'] ?? 'N/A',
                        car['carModel'] ?? 'N/A',
                        car['year']?.toString() ?? 'N/A',
                        car['image'],
                        car['power']?.toString() ?? 'N/A',
                        car,
                        context,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // Construit un bouton de filtre
  Widget _buildFilterButton(String label) {
    bool isActive = selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: () => filterCars(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? Colors.indigo[900] : Colors.indigo[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: isActive ? 6 : 4,
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // Construit une carte de voiture
  Widget _buildCarCard(
    String licensePlate,
    String brand,
    String carModel,
    String year,
    String? imageUrl,
    String power,
    Map<String, dynamic> car,
    BuildContext context,
  ) {
    const defaultImage = 'assets/images/car_placeholder.png';
    final validImageUrl = imageUrl != null && imageUrl.isNotEmpty ? imageUrl : null;

    return AnimatedScaleCard(
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: validImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: validImageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: Image.asset(
                            defaultImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                          ),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: Image.asset(
                          defaultImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Année: $year',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Immatriculation: $licensePlate',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Puissance: $power HP',
                      style: const TextStyle(fontSize: 14, color: Colors.indigo),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CarDetailPage(car: car)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 3,
                    minimumSize: const Size(80, 36),
                  ),
                  child: const Text(
                    'Détails',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

class BidPage extends StatefulWidget {
  const BidPage({super.key});

  @override
  State<BidPage> createState() => _BidPageState();
}

class _BidPageState extends State<BidPage> {
  List<Auction> auctions = [];
  String errorMessage = '';
  bool isLoading = true;
  String _sortOption = 'Date de fin (proche)';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchAuctions();
  }

  void _debugAuctions() {
    print('=== DÉBOGAGE DES ENCHÈRES ===');
    print('Nombre total d\'enchères: ${auctions.length}');

    final now = DateTime.now();
    print('Date actuelle: $now');

    for (var auction in auctions) {
      final timeRemaining = auction.endDate.difference(now);
      final isEnded = timeRemaining.isNegative;

      print('Enchère ID: ${auction.id}');
      print('  - Date de début: ${auction.startDate}');
      print('  - Date de fin: ${auction.endDate}');
      print('  - Statut: ${isEnded ? "Terminée" : "En cours"}');
      print('  - Temps restant: ${_calculateTimeRemaining(auction.endDate)}');
      print('---');
    }
    print('=== FIN DÉBOGAGE ===');
  }

  void _sortAuctions(String option) {
    setState(() {
      _sortOption = option;

      switch (option) {
        case 'Date de fin (proche)':
          auctions.sort((a, b) => a.endDate.compareTo(b.endDate));
          break;
        case 'Prix (croissant)':
          auctions.sort((a, b) => a.currentBid.compareTo(b.currentBid));
          break;
        case 'Prix (décroissant)':
          auctions.sort((a, b) => b.currentBid.compareTo(a.currentBid));
          break;
        case 'Popularité':
          auctions.sort((a, b) => b.bidCount.compareTo(a.bidCount));
          break;
        default:
          auctions.sort((a, b) => a.endDate.compareTo(b.endDate));
      }
    });
  }

  Future<void> _fetchAuctions() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:6006/auctions/all'),
      );
      print('Statut de la réponse API: ${response.statusCode}');
      print('Corps de la réponse API: ${response.body}');

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData is List) {
          setState(() {
            auctions = decodedData.map((json) => Auction.fromJson(json)).toList();
            isLoading = false;
            errorMessage = auctions.isEmpty
                ? 'Aucune enchère trouvée dans la base de données'
                : '';
          });

          _debugAuctions();
        } else {
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

  Future<void> _submitBid(String auctionId, double bidAmount) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous connecter pour enchérir')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
        );
        return;
      }

      final userId = await _authService.getUserId();
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur : ID utilisateur non trouvé')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('http://10.0.2.2:6006/auctions/$auctionId/bid'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'bidAmount': bidAmount,
          'userId': userId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enchère soumise avec succès')),
        );
        await _fetchAuctions();
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Impossible de soumettre l\'enchère';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $errorMessage')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  void _showBidDialog(String auctionId, double currentBid) {
    final TextEditingController bidController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Placer une enchère'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enchère actuelle: ${currentBid.toStringAsFixed(2)} €'),
              const SizedBox(height: 16),
              TextField(
                controller: bidController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Votre enchère (€)',
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setDialogState(() {
                    errorText = null;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final bidText = bidController.text.trim();
                final bidAmount = double.tryParse(bidText);

                if (bidAmount == null) {
                  setDialogState(() {
                    errorText = 'Veuillez entrer un montant valide';
                  });
                } else if (bidAmount <= currentBid) {
                  setDialogState(() {
                    errorText = 'L\'enchère doit être supérieure à ${currentBid.toStringAsFixed(2)} €';
                  });
                } else {
                  FocusScope.of(context).unfocus();
                  Navigator.pop(context);
                  _submitBid(auctionId, bidAmount);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Enchérir'),
            ),
          ],
        ),
      ),
    );
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
                    'Toutes les enchères',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Découvrez toutes nos enchères',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    'Trier par: ',
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.indigo.shade300),
                      ),
                      child: DropdownButton<String>(
                        value: _sortOption,
                        isExpanded: true,
                        underline: Container(),
                        style: TextStyle(color: Colors.indigo[800], fontSize: 14),
                        items: <String>[
                          'Date de fin (proche)',
                          'Prix (croissant)',
                          'Prix (décroissant)',
                          'Popularité',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            _sortAuctions(newValue);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                                  onPressed: _fetchAuctions,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
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
                          onRefresh: _fetchAuctions,
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
  ) {
    const defaultImage = 'assets/images/car_placeholder.png';
    final validImageUrl = imageUrl != null && imageUrl.isNotEmpty ? imageUrl : null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final auctionEndDate = DateTime(endDate.year, endDate.month, endDate.day);
    final isEnded = endDate.isBefore(now);
    final isNotStarted = startDate.isAfter(now);
    final isEndingToday = auctionEndDate.isAtSameMomentAs(today) && !isEnded;

    // Formater la date de début avec localisation fr_FR
    final dateFormatter = DateFormat('dd/MM/yyyy', 'fr_FR');
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
                    onPressed: isEnded || isNotStarted
                        ? null
                        : () => _showBidDialog(auctionId, currentBid),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEnded || isNotStarted ? Colors.grey : Colors.indigo[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 3,
                      minimumSize: const Size(80, 36),
                    ),
                    child: const Text(
                      'Enchérir',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                      backgroundColor: isEnded || isNotStarted ? Colors.grey : Colors.indigo[600],
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

// Modèle pour une notification
class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String auctionId;
  final String type;
  final DateTime updatedAt;

AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.auctionId,
    required this.type,
    required this.updatedAt,
  }); 

factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      auctionId: json['carId'] ?? '',
      type: json['type'] ?? '',
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Page des notifications
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<AppNotification> notifications = [];
  String errorMessage = '';
  bool isLoading = true;
  final AuthService _authService = AuthService();
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    print('[DEBUG] Initializing NotificationsPage');
    _fetchNotifications();
    _connectToWebSocket();
  }

  Future<void> _connectToWebSocket() async {
    print('[DEBUG] Connecting to WebSocket');
    final token = await _authService.getToken();
    if (token == null) {
      print('[DEBUG] No token found, redirecting to Login');
      setState(() {
        errorMessage = 'Veuillez vous connecter pour recevoir les notifications';
        isLoading = false;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
      );
      return;
    }

    print('[DEBUG] WebSocket token sent: $token');
    socket = IO.io('http://10.0.2.2:6006', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'token': token},
    });

    socket.onConnect((_) {
      print('[DEBUG] WebSocket connected');
    });

    socket.on('newNotification', (data) {
      print('[DEBUG] New notification received: $data');
      setState(() {
        notifications.insert(0, AppNotification.fromJson(data));
        errorMessage = notifications.isEmpty ? 'Aucune notification disponible' : '';
      });
    });

    socket.onDisconnect((_) {
      print('[DEBUG] WebSocket disconnected');
    });

    socket.onConnectError((error) {
      print('[DEBUG] WebSocket connection error: $error');
      setState(() {
        errorMessage = 'Erreur WebSocket: $error';
      });
    });

    socket.onError((error) {
      print('[DEBUG] WebSocket error: $error');
    });

    socket.connect();
  }

  @override
  void dispose() {
    print('[DEBUG] Disposing NotificationsPage');
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    print('[DEBUG] Fetching notifications');
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await _authService.getToken();
      print('[DEBUG] Token: $token');
      if (token == null) {
        print('[DEBUG] No token found, redirecting to Login');
        setState(() {
          isLoading = false;
          errorMessage = 'Veuillez vous connecter pour voir les notifications';
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
        );
        return;
      }

      // Décoder le token pour afficher le payload
      if (token != null) {
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
            print('[DEBUG] Token payload: $payload');
          }
        } catch (e) {
          print('[DEBUG] Error decoding token: $e');
        }
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:6006/notifications/getUserNotifications'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('[DEBUG] HTTP Status: ${response.statusCode}');
      print('[DEBUG] HTTP Response: ${response.body}');

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        print('[DEBUG] Decoded data: $decodedData');
        if (decodedData is List) {
          setState(() {
            notifications = decodedData
                .map((json) {
                  print('[DEBUG] Parsing notification JSON: $json');
                  return AppNotification.fromJson(json);
                })
                .toList();
            isLoading = false;
            errorMessage = notifications.isEmpty ? 'Aucune notification disponible' : '';
            print('[DEBUG] Notifications loaded: ${notifications.length}');
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = 'Format de données inattendu';
            print('[DEBUG] Invalid data format');
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Erreur HTTP: ${response.statusCode}';
          print('[DEBUG] HTTP error: ${response.statusCode}');
        });
      }
    } catch (e) {
      print('[DEBUG] Error fetching notifications: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Erreur: $e';
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    print('[DEBUG] Marking notification as read: $notificationId');
    try {
      final token = await _authService.getToken();
      if (token == null) {
        print('[DEBUG] No token found for markAsRead');
        return;
      }

      final response = await http.patch(
        Uri.parse('http://10.0.2.2:6006/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('[DEBUG] Mark as read response: ${response.statusCode}');
      if (response.statusCode == 200) {
        setState(() {
          notifications = notifications.map((notif) {
            if (notif.id == notificationId) {
              return AppNotification(
                id: notif.id,
                title: notif.title,
                message: notif.message,
                timestamp: notif.timestamp,
                isRead: true,
                auctionId: notif.auctionId,
                type: notif.type,
                updatedAt: DateTime.now(),
              );
            }
            return notif;
          }).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur HTTP: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('[DEBUG] Error marking as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du marquage comme lu: $e')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    print('[DEBUG] Marking all notifications as read');
    try {
      final token = await _authService.getToken();
      if (token == null) {
        print('[DEBUG] No token found for markAllAsRead');
        return;
      }

      final response = await http.patch(
        Uri.parse('http://10.0.2.2:6006/notifications/markAllAsRead'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('[DEBUG] Mark all as read response: ${response.statusCode}');
      if (response.statusCode == 200) {
        setState(() {
          notifications = notifications.map((notif) {
            return AppNotification(
              id: notif.id,
              title: notif.title,
              message: notif.message,
              timestamp: notif.timestamp,
              isRead: true,
              auctionId: notif.auctionId,
              type: notif.type,
              updatedAt: DateTime.now(),
            );
          }).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur HTTP: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('[DEBUG] Error marking all as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    print('[DEBUG] Deleting notification: $notificationId');
    try {
      final token = await _authService.getToken();
      if (token == null) {
        print('[DEBUG] No token found for deleteNotification');
        return;
      }

      final response = await http.delete(
        Uri.parse('http://10.0.2.2:6006/notifications/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('[DEBUG] Delete notification response: ${response.statusCode}');
      if (response.statusCode == 200) {
        setState(() {
          notifications = notifications.where((notif) => notif.id != notificationId).toList();
          errorMessage = notifications.isEmpty ? 'Aucune notification disponible' : '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur HTTP: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('[DEBUG] Error deleting notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }

  Future<void> _deleteAllNotifications() async {
    print('[DEBUG] Deleting all notifications');
    try {
      final token = await _authService.getToken();
      if (token == null) {
        print('[DEBUG] No token found for deleteAllNotifications');
        return;
      }

      final response = await http.delete(
        Uri.parse('http://10.0.2.2:6006/notifications/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('[DEBUG] Delete all notifications response: ${response.statusCode}');
      if (response.statusCode == 200) {
        setState(() {
          notifications = [];
          errorMessage = 'Aucune notification disponible';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur HTTP: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('[DEBUG] Error deleting all notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[DEBUG] Building NotificationsPage, isLoading: $isLoading, errorMessage: $errorMessage');
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications, size: 80, color: Colors.indigo),
                  const SizedBox(height: 16),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notifications.any((n) => !n.isRead)
                        ? '${notifications.where((n) => !n.isRead).length} non lues'
                        : 'Aucune nouvelle notification',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (notifications.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _markAllAsRead,
                      icon: const Icon(Icons.mark_email_read, size: 18, color: Colors.white),
                      label: const Text(
                        'Tout marquer comme lu',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _deleteAllNotifications,
                      icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                      label: const Text(
                        'Tout supprimer',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
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
                                if (errorMessage != 'Aucune notification disponible')
                                  ElevatedButton(
                                    onPressed: _fetchNotifications,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo[600],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                    ),
                                    child: const Text('Réessayer'),
                                  ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchNotifications,
                          color: Colors.indigo,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final notification = notifications[index];
                              return _buildNotificationCard(
                                notification,
                                dateFormatter,
                                context,
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

  Widget _buildNotificationCard(
    AppNotification notification,
    DateFormat dateFormatter,
    BuildContext context,
  ) {
    print('[DEBUG] Building notification card: ${notification.id}');
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      color: notification.isRead ? Colors.grey[200] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              notification.type == 'car_added'
                  ? Icons.car_rental
                  : notification.type == 'bid_placed'
                      ? Icons.gavel
                      : notification.type == 'auction_ending'
                          ? Icons.timer
                          : Icons.notifications,
              color: notification.isRead ? Colors.grey : Colors.indigo[600],
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      color: notification.isRead ? Colors.grey[800] : Colors.indigo[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: notification.isRead ? Colors.grey : Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormatter.format(notification.timestamp),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (notification.auctionId.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        await _markAsRead(notification.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BidPage(), // Remplacez par la page appropriée
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 3,
                        minimumSize: const Size(80, 36),
                      ),
                      child: const Text(
                        'Voir',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteNotification(notification.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Page du profil
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  AuthService _authService = AuthService();
  Map<String, dynamic>? userData;
  String? userId;
  String errorMessage = '';
  bool isLoading = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => isLoading = true);
    try {
      final token = await _authService.getToken();
      if (token == null) {
        setState(() {
          errorMessage = 'Aucun token trouvé. Veuillez vous reconnecter.';
          isLoading = false;
        });
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Login()),
          );
        }
        return;
      }
      final response = await http.get(
        Uri.parse('http://10.0.2.2:6006/users/profile'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['id'] == null || data['email'] == null) {
          throw Exception('Données utilisateur incomplètes');
        }
        setState(() {
          userId = data['id'].toString();
          userData = {
            'firstname': data['firstname'] ?? 'N/A',
            'lastname': data['lastname'] ?? 'N/A',
            'email': data['email'] ?? 'N/A',
          };
          isLoading = false;
        });
      } else {
        String message;
        try {
          final errorData = json.decode(response.body);
          message = errorData['message'] ?? 'Erreur lors de la récupération du profil';
        } catch (_) {
          message = 'Erreur serveur (Code: ${response.statusCode})';
        }
        setState(() {
          errorMessage = message;
          isLoading = false;
        });
        if (response.statusCode == 401 && mounted) {
          await _authService.logout();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Login()),
          );
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur: $e';
        isLoading = false;
      });
    }
  }

  void _logout(BuildContext context) async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchUserProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[600],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.indigo[200],
                          child: Text(
                            userData?['firstname'] != 'N/A' ? userData!['firstname'][0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userData != null ? '${userData!['firstname']} ${userData!['lastname']}' : 'Utilisateur inconnu',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userData?['email'] ?? 'N/A',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Détails du profil',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                                ),
                                const SizedBox(height: 16),
                                _buildProfileItem(
                                  icon: Icons.person,
                                  label: 'Prénom',
                                  value: userData?['firstname'] ?? 'N/A',
                                ),
                                const Divider(),
                                _buildProfileItem(
                                  icon: Icons.person_outline,
                                  label: 'Nom',
                                  value: userData?['lastname'] ?? 'N/A',
                                ),
                                const Divider(),
                                _buildProfileItem(
                                  icon: Icons.email,
                                  label: 'Email',
                                  value: userData?['email'] ?? 'N/A',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        AnimatedButton(
                          onPressed: () async {
                            if (userId == null || userData == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Erreur : Données utilisateur manquantes')),
                              );
                              return;
                            }
                            final updatedData = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfilePage(userData: userData!, userId: userId!),
                              ),
                            );
                            if (updatedData != null) {
                              setState(() => userData = updatedData);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profil mis à jour avec succès')),
                              );
                            }
                          },
                          child: const Text(
                            'Modifier le profil',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MyAuctionsPage()),
                            );
                          },
                          child: const Text(
                            'Mes enchères',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => _logout(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.indigo),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: const Text(
                            'Déconnexion',
                            style: TextStyle(color: Colors.indigo, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileItem({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo[600], size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// Bouton animé
class AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const AnimatedButton({super.key, required this.onPressed, required this.child});

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              _controller.reverse();
              widget.onPressed!();
            }
          : null,
      onTapCancel: widget.onPressed != null ? () => _controller.reverse() : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.onPressed != null ? Colors.indigo[600] : Colors.grey,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}