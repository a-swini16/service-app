import 'package:flutter/material.dart';
import '../models/service_model.dart';

class ServiceProvider with ChangeNotifier {
  List<ServiceModel> _services = [];
  bool _isLoading = false;

  List<ServiceModel> get services => _services;
  bool get isLoading => _isLoading;

  ServiceProvider() {
    _loadDefaultServices();
  }

  void _loadDefaultServices() {
    _services = ServiceModel.getDefaultServices();
    notifyListeners();
  }

  ServiceModel? getServiceByName(String name) {
    try {
      return _services.firstWhere((service) => service.name == name);
    } catch (e) {
      return null;
    }
  }

  void updateService(ServiceModel service) {
    final index = _services.indexWhere((s) => s.id == service.id);
    if (index != -1) {
      _services[index] = service;
      notifyListeners();
    }
  }

  void addService(ServiceModel service) {
    _services.add(service);
    notifyListeners();
  }

  void removeService(String serviceId) {
    _services.removeWhere((service) => service.id == serviceId);
    notifyListeners();
  }
}
