import 'package:flutter/material.dart';
import '../constants/service_pricing.dart';

class PaymentAmountDisplayWidget extends StatelessWidget {
  final String serviceType;
  final String paymentMethod;
  final Map<String, dynamic>? additionalCharges;
  final bool showDetails;

  const PaymentAmountDisplayWidget({
    Key? key,
    required this.serviceType,
    required this.paymentMethod,
    this.additionalCharges,
    this.showDetails = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final servicePrice = ServicePricing.getServicePrice(serviceType);
    if (servicePrice == null) {
      return const SizedBox.shrink();
    }

    final totalAmount = ServicePricing.calculateTotalPrice(
      serviceType,
      additionalCharges: additionalCharges,
    );

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  paymentMethod == 'cash_on_service' 
                      ? Icons.payments 
                      : Icons.qr_code,
                  color: paymentMethod == 'cash_on_service' 
                      ? Colors.green 
                      : Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    paymentMethod == 'cash_on_service'
                        ? 'Amount to Pay Worker'
                        : 'Online Payment Amount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Service details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ServicePricing.getServiceName(serviceType),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ServicePricing.formatPrice(servicePrice['basePrice'].toDouble()),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  if (showDetails) ...[
                    const SizedBox(height: 8),
                    Text(
                      ServicePricing.getServiceDescription(serviceType),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    const Text(
                      'Service Includes:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...ServicePricing.getServiceIncludes(serviceType).map(
                      (include) => Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                include,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Duration: ${ServicePricing.getServiceDuration(serviceType)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  // Additional charges if any
                  if (additionalCharges != null && additionalCharges!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const Text(
                      'Additional Charges:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...additionalCharges!.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatChargeName(entry.key),
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              ServicePricing.formatPrice(entry.value.toDouble()),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Total amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: paymentMethod == 'cash_on_service' 
                    ? Colors.green[50] 
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: paymentMethod == 'cash_on_service' 
                      ? Colors.green[200]! 
                      : Colors.blue[200]!,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paymentMethod == 'cash_on_service'
                            ? 'Pay to Technician:'
                            : 'Pay Online:',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        paymentMethod == 'cash_on_service'
                            ? 'After service completion'
                            : 'Before service starts',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    ServicePricing.formatPrice(totalAmount),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: paymentMethod == 'cash_on_service' 
                          ? Colors.green[700] 
                          : Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            
            // Payment method specific note
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      paymentMethod == 'cash_on_service'
                          ? 'Please keep exact cash ready. Our technician will collect payment after completing the service to your satisfaction.'
                          : 'Complete online payment to confirm your booking. Service will be scheduled after payment verification.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatChargeName(String key) {
    switch (key) {
      case 'partsCharge':
        return 'Parts & Components';
      case 'emergencyCharge':
        return 'Emergency Service';
      case 'travelCharge':
        return 'Travel Charge';
      default:
        return key.replaceAll('Charge', '').replaceAll('_', ' ');
    }
  }
}