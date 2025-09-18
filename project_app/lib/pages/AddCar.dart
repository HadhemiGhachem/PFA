import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddCar extends StatefulWidget {
  const AddCar({super.key});

  @override
  State<AddCar> createState() => _AddCarState();
}

class _AddCarState extends State<AddCar> {
  int _currentStep = 0;
  final _formKeys = List.generate(7, (index) => GlobalKey<FormState>());
  String? _carId;
  File? _selectedImage;
  String? _imageUrl;
  String? _token;

  // Stepper controllers
  final _licensePlateController = TextEditingController();
  final _chassisNumberController = TextEditingController();
  final _brandController = TextEditingController();
  final _carModelController = TextEditingController();
  final _yearController = TextEditingController();
  final _cylindersController = TextEditingController();
  final _currentCardController = TextEditingController();
  final _powerController = TextEditingController();
  final _speedController = TextEditingController();
  final _lightsController = TextEditingController();
  final _assistanceController = TextEditingController();
  bool _hasSunroof = false;
  bool _screen = false;
  bool _airConditioning = false;
  final _seatsController = TextEditingController();
  bool _seatClean = false;
  bool _seatStained = false;
  bool _seatTorn = false;
  bool _seatHeated = false;
  bool _seatElectric = false;
  final _startingPriceController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('accessToken');
    });
    print('Token chargé: $_token');
    if (_token == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
    setState(() {
      _token = token;
    });
    print('Token sauvegardé: $token');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        print('Image sélectionnée: ${pickedFile.path}');
      });
    } else {
      print('Aucune image sélectionnée');
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null || !await _selectedImage!.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une image valide')),
      );
      return;
    }

    if (_token == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:6006/cars/uploadImage'),
    );
    request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
    print('Envoi de l\'image vers: http://10.0.2.2:6006/cars/uploadImage');
    try {
      var response = await request.send();
      print('Statut de la réponse: ${response.statusCode}');
      final responseData = await response.stream.bytesToString();
      print('Corps de la réponse: $responseData');
      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = jsonDecode(responseData);
        setState(() {
          _imageUrl = jsonData['url'];
          print('URL de l\'image stockée: $_imageUrl');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploadée avec succès')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'upload: ${response.statusCode} - $responseData')),
        );
      }
    } catch (e) {
      print('Exception lors de l\'upload: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _submitCarData() async {
    if (_token == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (_imageUrl == null || _imageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez uploader une image avant de continuer')),
      );
      return;
    }

    final carData = {
      'brand': _brandController.text,
      'carModel': _carModelController.text, // Changé de carModel à model
      'year': int.tryParse(_yearController.text) ?? 0,
      'licensePlate': _licensePlateController.text,
      'chassisNumber': _chassisNumberController.text,
      'cylinders': int.tryParse(_cylindersController.text) ?? 0,
      'currentCard': _currentCardController.text,
      'power': int.tryParse(_powerController.text) ?? 0,
      'speed': int.tryParse(_speedController.text) ?? 0,
      'lights': _lightsController.text,
      'assistance': _assistanceController.text,
      'hasSunroof': _hasSunroof,
      'screen': _screen,
      'airConditioning': _airConditioning,
      'seats': int.tryParse(_seatsController.text) ?? 0,
      'seatCondition': {
        'clean': _seatClean,
        'stained': _seatStained,
        'torn': _seatTorn,
        'heated': _seatHeated,
        'electric': _seatElectric,
      },
      'image': _imageUrl,
    };

    print('Envoi des données voiture: ${json.encode(carData)}');
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:6006/cars/createCar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(carData),
      );

      print('Statut de la réponse: ${response.statusCode}');
      print('Corps de la réponse: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _carId = responseData['_id'] ?? responseData['id'];
        if (_carId == null) {
          throw Exception('L\'ID de la voiture n\'a pas été renvoyé par le serveur');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voiture créée avec succès')),
        );
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Échec de la création: ${response.statusCode} - ${errorData['message'] ?? response.body}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Erreur dans _submitCarData: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _submitAuctionData() async {
    if (_carId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La voiture doit être créée d\'abord')),
      );
      return;
    }

    if (_token == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    final auctionData = {
      'carId': _carId,
      'startingPrice': double.tryParse(_startingPriceController.text) ?? 0.0,
      'currentBid': double.tryParse(_startingPriceController.text) ?? 0.0,
      'startDate': _startDateController.text,
      'endDate': _endDateController.text,
      'status': 'active',
    };

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:6006/auctions/createAuction'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(auctionData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enchère créée avec succès')),
        );
        Navigator.pop(context);
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Échec: ${errorData['messages']?.join(', ') ?? errorData['error'] ?? 'Erreur inconnue'}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Erreur dans _submitAuctionData: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _chassisNumberController.dispose();
    _brandController.dispose();
    _carModelController.dispose();
    _yearController.dispose();
    _cylindersController.dispose();
    _currentCardController.dispose();
    _powerController.dispose();
    _speedController.dispose();
    _lightsController.dispose();
    _assistanceController.dispose();
    _seatsController.dispose();
    _startingPriceController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une voiture'),
        backgroundColor: Colors.indigo.shade200,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          final formState = _formKeys[_currentStep].currentState;
          if (formState == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erreur: Formulaire non initialisé')),
            );
            return;
          }
          if (_currentStep == 4 && _selectedImage == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Veuillez sélectionner une image')),
            );
            return;
          }
          if (_currentStep < 4) {
            if (formState.validate()) {
              setState(() => _currentStep += 1);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veuillez remplir tous les champs requis')),
              );
            }
          } else if (_currentStep == 4) {
            _uploadImage().then((_) {
              if (_imageUrl != null) {
                setState(() => _currentStep += 1);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Échec de l\'upload de l\'image')),
                );
              }
            });
          } else if (_currentStep == 5) {
            if (formState.validate()) {
              _submitCarData().then((_) {
                if (_carId != null) {
                  setState(() => _currentStep += 1);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Échec de la création de la voiture')),
                  );
                }
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veuillez remplir tous les champs requis')),
              );
            }
          } else if (_currentStep == 6) {
            if (formState.validate()) {
              _submitAuctionData();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veuillez remplir tous les champs requis')),
              );
            }
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            Navigator.pop(context);
          }
        },
        steps: [
          Step(
            title: const Text('Identification'),
            content: Form(
              key: _formKeys[0],
              child: Column(
                children: [
                  TextFormField(
                    controller: _licensePlateController,
                    decoration: const InputDecoration(labelText: 'Plaque d\'immatriculation'),
                    validator: (value) => value!.isEmpty ? 'Requis' : null,
                  ),
                  TextFormField(
                    controller: _chassisNumberController,
                    decoration: const InputDecoration(labelText: 'Numéro de châssis'),
                    validator: (value) => value!.isEmpty ? 'Requis' : null,
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Caractéristiques'),
            content: Form(
              key: _formKeys[1],
              child: Column(
                children: [
                  TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(labelText: 'Marque'),
                    validator: (value) => value!.isEmpty ? 'Requis' : null,
                  ),
                  TextFormField(
                    controller: _carModelController,
                    decoration: const InputDecoration(labelText: 'Modèle'),
                    validator: (value) => value!.isEmpty ? 'Requis' : null,
                  ),
                  TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(labelText: 'Année'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requis';
                      if (int.tryParse(value) == null) return 'Doit être un nombre';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Motorisation'),
            content: Form(
              key: _formKeys[2],
              child: Column(
                children: [
                  TextFormField(
                    controller: _cylindersController,
                    decoration: const InputDecoration(labelText: 'Cylindres'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requis';
                      if (int.tryParse(value) == null) return 'Doit être un nombre';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _currentCardController,
                    decoration: const InputDecoration(labelText: 'Carte actuelle (Type de carburant)'),
                    validator: (value) => value!.isEmpty ? 'Requis' : null,
                  ),
                  TextFormField(
                    controller: _powerController,
                    decoration: const InputDecoration(labelText: 'Puissance (CV)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requis';
                      if (int.tryParse(value) == null) return 'Doit être un nombre';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _speedController,
                    decoration: const InputDecoration(labelText: 'Vitesse (km/h)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requis';
                      if (int.tryParse(value) == null) return 'Doit être un nombre';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Données extérieures'),
            content: Form(
              key: _formKeys[3],
              child: Column(
                children: [
                  TextFormField(
                    controller: _lightsController,
                    decoration: const InputDecoration(labelText: 'Feux'),
                    validator: (value) => value!.isEmpty ? 'Requis' : null,
                  ),
                  TextFormField(
                    controller: _assistanceController,
                    decoration: const InputDecoration(labelText: 'Assistance'),
                    validator: (value) => value!.isEmpty ? 'Requis' : null,
                  ),
                  CheckboxListTile(
                    title: const Text('Toit ouvrant'),
                    value: _hasSunroof,
                    onChanged: (value) {
                      setState(() => _hasSunroof = value!);
                    },
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Images'),
            content: Form(
              key: _formKeys[4],
              child: Column(
                children: [
                  _selectedImage == null
                      ? const Text('Aucune image sélectionnée')
                      : (_selectedImage!.existsSync()
                          ? Image.file(_selectedImage!, height: 200)
                          : const Text('Image invalide')),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('Choisir une image'),
                  ),
                  if (_selectedImage != null)
                    ElevatedButton(
                      onPressed: _uploadImage,
                      child: const Text('Uploader l\'image'),
                    ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Données intérieures'),
            content: Form(
              key: _formKeys[5],
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Écran'),
                    value: _screen,
                    onChanged: (value) {
                      setState(() => _screen = value!);
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Climatisation'),
                    value: _airConditioning,
                    onChanged: (value) {
                      setState(() => _airConditioning = value!);
                    },
                  ),
                  TextFormField(
                    controller: _seatsController,
                    decoration: const InputDecoration(labelText: 'Nombre de sièges'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requis';
                      if (int.tryParse(value) == null) return 'Doit être un nombre';
                      return null;
                    },
                  ),
                  const Text('État des sièges:'),
                  CheckboxListTile(
                    title: const Text('Propre'),
                    value: _seatClean,
                    onChanged: (value) {
                      setState(() => _seatClean = value!);
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Taché'),
                    value: _seatStained,
                    onChanged: (value) {
                      setState(() => _seatStained = value!);
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Déchiré'),
                    value: _seatTorn,
                    onChanged: (value) {
                      setState(() => _seatTorn = value!);
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Chauffant'),
                    value: _seatHeated,
                    onChanged: (value) {
                      setState(() => _seatHeated = value!);
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Réglage électrique'),
                    value: _seatElectric,
                    onChanged: (value) {
                      setState(() => _seatElectric = value!);
                    },
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Données de l\'enchère'),
            content: Form(
              key: _formKeys[6],
              child: Column(
                children: [
                  TextFormField(
                    controller: _startingPriceController,
                    decoration: const InputDecoration(labelText: 'Prix de départ (TND)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requis';
                      if (double.tryParse(value) == null) return 'Doit être un nombre';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _startDateController,
                    decoration: const InputDecoration(labelText: 'Date de début (AAAA-MM-JJ)'),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requis';
                      try {
                        final startDate = DateTime.parse(value);
                        final today = DateTime.now();
                        final startDateNormalized = DateTime(startDate.year, startDate.month, startDate.day);
                        final todayNormalized = DateTime(today.year, today.month, today.day);
                        if (startDateNormalized.isBefore(todayNormalized)) {
                          return 'La date doit être aujourd\'hui ou dans le futur';
                        }
                        return null;
                      } catch (e) {
                        return 'Format invalide (AAAA-MM-JJ)';
                      }
                    },
                  ),
                  TextFormField(
                    controller: _endDateController,
                    decoration: const InputDecoration(labelText: 'Date de fin (AAAA-MM-JJ)'),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requis';
                      try {
                        final endDate = DateTime.parse(value);
                        final startDate = DateTime.parse(_startDateController.text);
                        final endDateNormalized = DateTime(endDate.year, endDate.month, endDate.day);
                        final startDateNormalized = DateTime(startDate.year, startDate.month, startDate.day);
                        if (endDateNormalized.isBefore(startDateNormalized) ||
                            endDateNormalized.isAtSameMomentAs(startDateNormalized)) {
                          return 'La date de fin doit être postérieure à la date de début';
                        }
                        return null;
                      } catch (e) {
                        return 'Format invalide (AAAA-MM-JJ)';
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitAuctionData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text(
                      'Payer',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}