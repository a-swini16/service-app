import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/offline_data_provider.dart';
import '../models/service_model.dart';
import '../widgets/offline_status_widget.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<ServiceModel> services = ServiceModel.getDefaultServices();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  // Track which service icons are being pressed
  List<bool> serviceIconsPressed = [];
  // Track which service cards are being pressed
  List<bool> serviceCardsPressed = [];

  @override
  void initState() {
    super.initState();
    // Initialize the pressed state lists
    serviceIconsPressed = List.generate(services.length, (index) => false);
    serviceCardsPressed = List.generate(services.length, (index) => false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final offlineProvider =
          Provider.of<OfflineDataProvider>(context, listen: false);

      // Initialize offline data provider
      if (authProvider.user != null) {
        offlineProvider.initialize(authProvider.user!.id);
      }

      bookingProvider.initialize();
      bookingProvider.fetchUserBookings();

      if (authProvider.user != null) {
        notificationProvider.fetchUserNotifications(authProvider.user!.id,
            refresh: true);
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter services based on search query
    List<ServiceModel> filteredServices = services
        .where((service) => service.displayName
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60.0,
        backgroundColor: Colors.lightBlue[50]!,
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.deepPurple, Colors.blueAccent],
          ).createShader(bounds),
          child: const Text(
            "Om Enterprises",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: "Poppins",
              color: Colors.white,
            ),
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Container(); // Removed notification button
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.water_drop),
              title: const Text('Water Purifier'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/water-purifier');
              },
            ),
            ListTile(
              leading: const Icon(Icons.ac_unit),
              title: const Text('AC Service'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/ac-service');
              },
            ),
            ListTile(
              leading: const Icon(Icons.kitchen),
              title: const Text('Refrigerator Service'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/refrigerator-service');
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('DTDC'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/dtdc');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('My Account'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/user-menu');
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlue[50]!, Colors.deepPurple[700]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Text(
                    "Welcome to Om Enterprises, ${authProvider.user?.name ?? 'User'}!",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Poppins",
                      color: Colors.black87,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                "We provide reliable services for your needs.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins",
                ),
              ),
              const SizedBox(height: 20),

              // Offline Status Widget
              const OfflineStatusWidget(compact: true),
              const SizedBox(height: 10),

              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: "Search a Service",
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                    if (searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            searchController.clear();
                            searchQuery = "";
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Services Section (Horizontal Icons)
              const Text(
                "Services",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins",
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: GestureDetector(
                        onTapDown: (_) {
                          setState(() {
                            serviceIconsPressed[index] = true;
                          });
                        },
                        onTapUp: (_) {
                          setState(() {
                            serviceIconsPressed[index] = false;
                          });
                          _navigateToService(services[index].name);
                        },
                        onTapCancel: () {
                          setState(() {
                            serviceIconsPressed[index] = false;
                          });
                        },
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 60,
                              height: 60,
                              transform: Matrix4.translationValues(
                                0,
                                serviceIconsPressed[index] ? 4 : 0,
                                0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple[100],
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurple.withOpacity(
                                        serviceIconsPressed[index] ? 0.1 : 0.3),
                                    spreadRadius:
                                        serviceIconsPressed[index] ? 1 : 2,
                                    blurRadius:
                                        serviceIconsPressed[index] ? 3 : 5,
                                    offset: Offset(
                                        0, serviceIconsPressed[index] ? 1 : 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getServiceIcon(services[index].name),
                                color: Colors.deepPurple,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              services[index]
                                  .displayName
                                  .split(' ')[0], // First word only
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: "Poppins",
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),

              // Popular Services Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Popular Services",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Poppins",
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/user-menu');
                    },
                    child: const Text(
                      "See all",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurple,
                        fontFamily: "Poppins",
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Service Cards
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredServices.length,
                itemBuilder: (context, index) {
                  final service = filteredServices[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTapDown: (_) {
                        setState(() {
                          serviceCardsPressed[index] = true;
                        });
                      },
                      onTapUp: (_) {
                        setState(() {
                          serviceCardsPressed[index] = false;
                        });
                        _navigateToService(service.name);
                      },
                      onTapCancel: () {
                        setState(() {
                          serviceCardsPressed[index] = false;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        transform: Matrix4.translationValues(
                          0,
                          serviceCardsPressed[index] ? 4 : 0,
                          0,
                        ),
                        child: Card(
                          elevation: serviceCardsPressed[index] ? 2 : 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Service Image/Icon
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                ),
                                child: Container(
                                  height: 150,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.deepPurple[100]!,
                                        Colors.blue[100]!
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _getServiceIcon(service.name),
                                      size: 80,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.displayName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "Poppins",
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      service.description,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontFamily: "Poppins",
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              "4.5", // Default rating
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Recent Bookings Section
              const SizedBox(height: 20),
              Consumer<BookingProvider>(
                builder: (context, bookingProvider, child) {
                  final recentBookings =
                      bookingProvider.bookings.take(3).toList();

                  if (recentBookings.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Recent Bookings",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Poppins",
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...recentBookings
                            .map((booking) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          _getStatusColor(booking.status),
                                      child: Icon(
                                        _getStatusIcon(booking.status),
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(booking.serviceDisplayName),
                                    subtitle: Text(
                                      '${booking.customerName} • ${_formatDate(booking.preferredDate)}',
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(booking.status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        booking.status.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          _navigateToService(service.name);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getServiceIcon(service.name),
                size: 48,
                color: Colors.deepPurple,
              ),
              SizedBox(height: 12),
              Text(
                service.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                '₹${service.basePrice.toInt()}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Starting from',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToService(String serviceName) {
    switch (serviceName) {
      case 'water_purifier':
        Navigator.pushNamed(context, '/water-purifier');
        break;
      case 'ac_repair':
        Navigator.pushNamed(context, '/ac-service');
        break;
      case 'refrigerator_repair':
        Navigator.pushNamed(context, '/refrigerator-service');
        break;
      case 'dtdc_service':
        Navigator.pushNamed(context, '/dtdc');
        break;
    }
  }

  IconData _getServiceIcon(String serviceName) {
    switch (serviceName) {
      case 'water_purifier':
        return Icons.water_drop;
      case 'ac_repair':
        return Icons.ac_unit;
      case 'refrigerator_repair':
        return Icons.kitchen;
      case 'dtdc_service':
        return Icons.local_shipping;
      default:
        return Icons.build;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'assigned':
        return Icons.person;
      case 'in_progress':
        return Icons.build;
      case 'completed':
        return Icons.check;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
