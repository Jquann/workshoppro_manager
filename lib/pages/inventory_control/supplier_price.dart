import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierPricingManager {
  final FirebaseFirestore _firestore;

  SupplierPricingManager(this._firestore);

  // Enhanced supplier data with multiple suppliers per part
  static final Map<String, Map<String, dynamic>> enhancedSupplierPricing = {
    // Engine System
    'PRT001': { // Engine Oil (5W-30)
      'name': 'Engine Oil (5W-30)',
      'category': 'Engine',
      'unit': 'Litre',
      'suppliers': {
        'Shell': {'price': 120.0, 'email': 'info@shell.com', 'leadTime': 3, 'minOrderQty': 10},
        'Castrol': {'price': 118.0, 'email': 'info@castrol.com', 'leadTime': 2, 'minOrderQty': 12},
        'Mobil1': {'price': 125.0, 'email': 'info@mobil1.com', 'leadTime': 4, 'minOrderQty': 8},
      }
    },
    'PRT002': { // Engine Oil (10W-40)
      'name': 'Engine Oil (10W-40)',
      'category': 'Engine',
      'unit': 'Litre',
      'suppliers': {
        'Castrol': {'price': 110.0, 'email': 'info@castrol.com', 'leadTime': 2, 'minOrderQty': 12},
        'Shell': {'price': 115.0, 'email': 'info@shell.com', 'leadTime': 3, 'minOrderQty': 10},
        'Valvoline': {'price': 108.0, 'email': 'info@valvoline.com', 'leadTime': 5, 'minOrderQty': 15},
      }
    },
    'PRT003': { // Oil Filters
      'name': 'Oil Filters',
      'category': 'Engine',
      'unit': 'Piece',
      'suppliers': {
        'Bosch': {'price': 25.0, 'email': 'info@bosch.com', 'leadTime': 2, 'minOrderQty': 20},
        'Mann Filter': {'price': 23.0, 'email': 'info@mannfilter.com', 'leadTime': 3, 'minOrderQty': 25},
        'K&N': {'price': 28.0, 'email': 'info@knfilters.com', 'leadTime': 4, 'minOrderQty': 15},
      }
    },
    'PRT004': { // Air Filters (Engine)
      'name': 'Air Filters (Engine)',
      'category': 'Engine',
      'unit': 'Piece',
      'suppliers': {
        'Denso': {'price': 30.0, 'email': 'info@denso.com', 'leadTime': 2, 'minOrderQty': 20},
        'Bosch': {'price': 28.0, 'email': 'info@bosch.com', 'leadTime': 2, 'minOrderQty': 25},
        'K&N': {'price': 35.0, 'email': 'info@knfilters.com', 'leadTime': 4, 'minOrderQty': 15},
      }
    },
    'PRT005': { // Fuel Filters
      'name': 'Fuel Filters',
      'category': 'Engine',
      'unit': 'Piece',
      'suppliers': {
        'Bosch': {'price': 35.0, 'email': 'info@bosch.com', 'leadTime': 2, 'minOrderQty': 15},
        'Mann Filter': {'price': 32.0, 'email': 'info@mannfilter.com', 'leadTime': 3, 'minOrderQty': 20},
        'Denso': {'price': 36.0, 'email': 'info@denso.com', 'leadTime': 2, 'minOrderQty': 18},
      }
    },
    'PRT006': { // Spark Plugs
      'name': 'Spark Plugs',
      'category': 'Engine',
      'unit': 'Piece',
      'suppliers': {
        'NGK': {'price': 18.0, 'email': 'info@ngk.com', 'leadTime': 1, 'minOrderQty': 50},
        'Denso': {'price': 19.0, 'email': 'info@denso.com', 'leadTime': 2, 'minOrderQty': 40},
        'Bosch': {'price': 20.0, 'email': 'info@bosch.com', 'leadTime': 2, 'minOrderQty': 45},
      }
    },
    'PRT007': { // Serpentine Belts
      'name': 'Serpentine Belts',
      'category': 'Engine',
      'unit': 'Piece',
      'suppliers': {
        'Gates': {'price': 45.0, 'email': 'info@gates.com', 'leadTime': 3, 'minOrderQty': 10},
        'Dayco': {'price': 42.0, 'email': 'info@dayco.com', 'leadTime': 4, 'minOrderQty': 12},
        'Continental': {'price': 47.0, 'email': 'info@continental.com', 'leadTime': 5, 'minOrderQty': 8},
      }
    },
    'PRT008': { // Timing Belts
      'name': 'Timing Belts',
      'category': 'Engine',
      'unit': 'Piece',
      'suppliers': {
        'Gates': {'price': 60.0, 'email': 'info@gates.com', 'leadTime': 3, 'minOrderQty': 8},
        'Dayco': {'price': 58.0, 'email': 'info@dayco.com', 'leadTime': 4, 'minOrderQty': 10},
        'Continental': {'price': 62.0, 'email': 'info@continental.com', 'leadTime': 5, 'minOrderQty': 6},
      }
    },
    'PRT009': { // Coolant/Antifreeze
      'name': 'Coolant/Antifreeze',
      'category': 'Engine',
      'unit': 'Litre',
      'suppliers': {
        'Prestone': {'price': 40.0, 'email': 'info@prestone.com', 'leadTime': 2, 'minOrderQty': 15},
        'Castrol': {'price': 38.0, 'email': 'info@castrol.com', 'leadTime': 2, 'minOrderQty': 20},
        'Shell': {'price': 42.0, 'email': 'info@shell.com', 'leadTime': 3, 'minOrderQty': 12},
      }
    },
    'PRT010': { // Radiator Hoses
      'name': 'Radiator Hoses',
      'category': 'Engine',
      'unit': 'Piece',
      'suppliers': {
        'Dayco': {'price': 22.0, 'email': 'info@dayco.com', 'leadTime': 4, 'minOrderQty': 15},
        'Gates': {'price': 24.0, 'email': 'info@gates.com', 'leadTime': 3, 'minOrderQty': 12},
        'Continental': {'price': 25.0, 'email': 'info@continental.com', 'leadTime': 5, 'minOrderQty': 10},
      }
    },

    // Braking System
    'PRT013': { // Brake Pads
      'name': 'Brake Pads (Front & Rear)',
      'category': 'Brakes',
      'unit': 'Set',
      'suppliers': {
        'Brembo': {'price': 80.0, 'email': 'info@brembo.com', 'leadTime': 3, 'minOrderQty': 10},
        'Akebono': {'price': 75.0, 'email': 'info@akebono.com', 'leadTime': 4, 'minOrderQty': 12},
        'TRW': {'price': 72.0, 'email': 'info@trw.com', 'leadTime': 3, 'minOrderQty': 15},
      }
    },
    'PRT014': { // Brake Discs/Rotors
      'name': 'Brake Discs/Rotors',
      'category': 'Brakes',
      'unit': 'Piece',
      'suppliers': {
        'Brembo': {'price': 150.0, 'email': 'info@brembo.com', 'leadTime': 4, 'minOrderQty': 5},
        'Zimmermann': {'price': 145.0, 'email': 'info@zimmermann.com', 'leadTime': 5, 'minOrderQty': 6},
        'TRW': {'price': 140.0, 'email': 'info@trw.com', 'leadTime': 3, 'minOrderQty': 8},
      }
    },
    'PRT015': { // Brake Fluid
      'name': 'Brake Fluid (DOT 3/DOT 4)',
      'category': 'Brakes',
      'unit': 'Litre',
      'suppliers': {
        'Bosch': {'price': 25.0, 'email': 'info@bosch.com', 'leadTime': 2, 'minOrderQty': 20},
        'Castrol': {'price': 23.0, 'email': 'info@castrol.com', 'leadTime': 2, 'minOrderQty': 25},
        'Motul': {'price': 27.0, 'email': 'info@motul.com', 'leadTime': 3, 'minOrderQty': 15},
      }
    },

    // Electrical System
    'PRT017': { // Car Batteries
      'name': 'Car Batteries (12V - common sizes)',
      'category': 'Electrical',
      'unit': 'Piece',
      'suppliers': {
        'Amaron': {'price': 250.0, 'email': 'info@amaron.com', 'leadTime': 2, 'minOrderQty': 3},
        'Yuasa': {'price': 240.0, 'email': 'info@yuasa.com', 'leadTime': 3, 'minOrderQty': 4},
        'Bosch': {'price': 260.0, 'email': 'info@bosch.com', 'leadTime': 2, 'minOrderQty': 3},
      }
    },
    'PRT018': { // Headlight Bulbs
      'name': 'Headlight Bulbs (H4, H7)',
      'category': 'Electrical',
      'unit': 'Piece',
      'suppliers': {
        'Philips': {'price': 15.0, 'email': 'info@philips.com', 'leadTime': 1, 'minOrderQty': 50},
        'Osram': {'price': 14.0, 'email': 'info@osram.com', 'leadTime': 2, 'minOrderQty': 60},
        'Bosch': {'price': 16.0, 'email': 'info@bosch.com', 'leadTime': 2, 'minOrderQty': 40},
      }
    },
    'PRT019': { // Tail Light Bulbs
      'name': 'Tail Light Bulbs',
      'category': 'Electrical',
      'unit': 'Piece',
      'suppliers': {
        'Osram': {'price': 10.0, 'email': 'info@osram.com', 'leadTime': 2, 'minOrderQty': 60},
        'Philips': {'price': 11.0, 'email': 'info@philips.com', 'leadTime': 1, 'minOrderQty': 50},
        'Bosch': {'price': 9.5, 'email': 'info@bosch.com', 'leadTime': 2, 'minOrderQty': 70},
      }
    },
    'PRT011': { // Engine Gaskets
      'name': 'Engine Gaskets (Valve cover, Oil pan)',
      'category': 'Engine',
      'unit': 'Piece',
      'suppliers': {
        'Victor Reinz': {'price': 55.0, 'email': 'info@victorreinz.com', 'leadTime': 4, 'minOrderQty': 8},
        'Elring': {'price': 52.0, 'email': 'info@elring.com', 'leadTime': 3, 'minOrderQty': 10},
        'Bosch': {'price': 58.0, 'email': 'info@bosch.com', 'leadTime': 2, 'minOrderQty': 6},
      }
    },
    'PRT012': { // Water Pumps
      'name': 'Water Pumps (common models)',
      'category': 'Engine',
      'unit': 'Piece',
      'suppliers': {
        'Aisin': {'price': 120.0, 'email': 'info@aisin.com', 'leadTime': 5, 'minOrderQty': 4},
        'Gates': {'price': 115.0, 'email': 'info@gates.com', 'leadTime': 4, 'minOrderQty': 5},
        'Bosch': {'price': 125.0, 'email': 'info@bosch.com', 'leadTime': 3, 'minOrderQty': 3},
      }
    },


    // Suspension System
    'PRT022': { // Shock Absorbers
      'name': 'Shock Absorbers (common sizes)',
      'category': 'Suspension',
      'unit': 'Piece',
      'suppliers': {
        'KYB': {'price': 180.0, 'email': 'info@kyb.com', 'leadTime': 5, 'minOrderQty': 4},
        'Monroe': {'price': 175.0, 'email': 'info@monroe.com', 'leadTime': 4, 'minOrderQty': 5},
        'Bilstein': {'price': 190.0, 'email': 'info@bilstein.com', 'leadTime': 6, 'minOrderQty': 3},
      }
    },
    'PRT023': { // Tie Rod Ends
      'name': 'Tie Rod Ends',
      'category': 'Suspension',
      'unit': 'Piece',
      'suppliers': {
        'TRW': {'price': 35.0, 'email': 'info@trw.com', 'leadTime': 3, 'minOrderQty': 10},
        'Moog': {'price': 33.0, 'email': 'info@moog.com', 'leadTime': 4, 'minOrderQty': 12},
        'Lemforder': {'price': 37.0, 'email': 'info@lemforder.com', 'leadTime': 5, 'minOrderQty': 8},
      }
    },
    'PRT024': { // Ball Joints
      'name': 'Ball Joints',
      'category': 'Suspension',
      'unit': 'Piece',
      'suppliers': {
        'Moog': {'price': 50.0, 'email': 'info@moog.com', 'leadTime': 4, 'minOrderQty': 8},
        'TRW': {'price': 48.0, 'email': 'info@trw.com', 'leadTime': 3, 'minOrderQty': 10},
        'Lemforder': {'price': 52.0, 'email': 'info@lemforder.com', 'leadTime': 5, 'minOrderQty': 6},
      }
    },
    'PRT025': { // Control Arm Bushings
      'name': 'Control Arm Bushings',
      'category': 'Suspension',
      'unit': 'Set',
      'suppliers': {
        'Energy Suspension': {'price': 40.0, 'email': 'info@energysuspension.com', 'leadTime': 4, 'minOrderQty': 8},
        'Prothane': {'price': 38.0, 'email': 'info@prothane.com', 'leadTime': 5, 'minOrderQty': 10},
        'Moog': {'price': 42.0, 'email': 'info@moog.com', 'leadTime': 4, 'minOrderQty': 6},
      }
    },
    'PRT026': { // Steering Rack
      'name': 'Steering Rack (reconditioned)',
      'category': 'Steering',
      'unit': 'Piece',
      'suppliers': {
        'A1 Cardone': {'price': 300.0, 'email': 'info@a1cardone.com', 'leadTime': 7, 'minOrderQty': 2},
        'Bosch': {'price': 320.0, 'email': 'info@bosch.com', 'leadTime': 6, 'minOrderQty': 2},
        'TRW': {'price': 310.0, 'email': 'info@trw.com', 'leadTime': 8, 'minOrderQty': 3},
      }
    },
    'PRT027': { // Power Steering Pumps
      'name': 'Power Steering Pumps',
      'category': 'Steering',
      'unit': 'Piece',
      'suppliers': {
        'Aisin': {'price': 250.0, 'email': 'info@aisin.com', 'leadTime': 5, 'minOrderQty': 4},
        'Bosch': {'price': 260.0, 'email': 'info@bosch.com', 'leadTime': 4, 'minOrderQty': 3},
        'A1 Cardone': {'price': 240.0, 'email': 'info@a1cardone.com', 'leadTime': 6, 'minOrderQty': 5},
      }
    },

    // Exhaust System
    'PRT028': { // Mufflers
      'name': 'Mufflers (universal fit)',
      'category': 'Exhaust',
      'unit': 'Piece',
      'suppliers': {
        'Walker': {'price': 100.0, 'email': 'info@walker.com', 'leadTime': 4, 'minOrderQty': 8},
        'Bosal': {'price': 95.0, 'email': 'info@bosal.com', 'leadTime': 5, 'minOrderQty': 10},
        'MagnaFlow': {'price': 110.0, 'email': 'info@magnaflow.com', 'leadTime': 3, 'minOrderQty': 6},
      }
    },
    'PRT029': { // Exhaust Pipes
      'name': 'Exhaust Pipes (aluminized steel)',
      'category': 'Exhaust',
      'unit': 'Piece',
      'suppliers': {
        'Dynomax': {'price': 70.0, 'email': 'info@dynomax.com', 'leadTime': 4, 'minOrderQty': 10},
        'Walker': {'price': 68.0, 'email': 'info@walker.com', 'leadTime': 4, 'minOrderQty': 12},
        'Bosal': {'price': 72.0, 'email': 'info@bosal.com', 'leadTime': 5, 'minOrderQty': 8},
      }
    },
    'PRT030': { // Catalytic Converters
      'name': 'Catalytic Converters (universal fit)',
      'category': 'Exhaust',
      'unit': 'Piece',
      'suppliers': {
        'MagnaFlow': {'price': 200.0, 'email': 'info@magnaflow.com', 'leadTime': 6, 'minOrderQty': 3},
        'Walker': {'price': 195.0, 'email': 'info@walker.com', 'leadTime': 5, 'minOrderQty': 4},
        'Bosal': {'price': 205.0, 'email': 'info@bosal.com', 'leadTime': 7, 'minOrderQty': 2},
      }
    },

    // Body Parts
    'PRT031': { // Bumpers
      'name': 'Bumpers (Front and Rear)',
      'category': 'Body',
      'unit': 'Set',
      'suppliers': {
        'Replace': {'price': 250.0, 'email': 'info@replace.com', 'leadTime': 7, 'minOrderQty': 2},
        'Sherman': {'price': 240.0, 'email': 'info@sherman.com', 'leadTime': 8, 'minOrderQty': 3},
        'Goodmark': {'price': 260.0, 'email': 'info@goodmark.com', 'leadTime': 6, 'minOrderQty': 2},
      }
    },
    'PRT032': { // Fenders
      'name': 'Fenders',
      'category': 'Body',
      'unit': 'Piece',
      'suppliers': {
        'Replace': {'price': 150.0, 'email': 'info@replace.com', 'leadTime': 6, 'minOrderQty': 4},
        'Sherman': {'price': 145.0, 'email': 'info@sherman.com', 'leadTime': 7, 'minOrderQty': 5},
        'Goodmark': {'price': 155.0, 'email': 'info@goodmark.com', 'leadTime': 5, 'minOrderQty': 3},
      }
    },
    'PRT033': { // Hoods
      'name': 'Hoods',
      'category': 'Body',
      'unit': 'Piece',
      'suppliers': {
        'Replace': {'price': 300.0, 'email': 'info@replace.com', 'leadTime': 8, 'minOrderQty': 2},
        'Sherman': {'price': 290.0, 'email': 'info@sherman.com', 'leadTime': 9, 'minOrderQty': 3},
        'Goodmark': {'price': 310.0, 'email': 'info@goodmark.com', 'leadTime': 7, 'minOrderQty': 2},
      }
    },
    'PRT034': { // Trunks
      'name': 'Trunks',
      'category': 'Body',
      'unit': 'Piece',
      'suppliers': {
        'Replace': {'price': 350.0, 'email': 'info@replace.com', 'leadTime': 8, 'minOrderQty': 2},
        'Sherman': {'price': 340.0, 'email': 'info@sherman.com', 'leadTime': 9, 'minOrderQty': 2},
        'Goodmark': {'price': 360.0, 'email': 'info@goodmark.com', 'leadTime': 7, 'minOrderQty': 2},
      }
    },

    // Interior Parts
    'PRT035': { // Seat Covers
      'name': 'Seat Covers (Universal)',
      'category': 'Interior',
      'unit': 'Set',
      'suppliers': {
        'Covercraft': {'price': 100.0, 'email': 'info@covercraft.com', 'leadTime': 3, 'minOrderQty': 10},
        'FIA': {'price': 95.0, 'email': 'info@fia.com', 'leadTime': 4, 'minOrderQty': 12},
        'CalTrend': {'price': 105.0, 'email': 'info@caltrend.com', 'leadTime': 3, 'minOrderQty': 8},
      }
    },
    'PRT036': { // Floor Mats
      'name': 'Floor Mats (Universal)',
      'category': 'Interior',
      'unit': 'Set',
      'suppliers': {
        'WeatherTech': {'price': 50.0, 'email': 'info@weathertech.com', 'leadTime': 2, 'minOrderQty': 15},
        'Husky Liners': {'price': 48.0, 'email': 'info@huskyliners.com', 'leadTime': 3, 'minOrderQty': 18},
        'Lloyd Mats': {'price': 52.0, 'email': 'info@lloydmats.com', 'leadTime': 2, 'minOrderQty': 12},
      }
    },
    'PRT037': { // Steering Wheel Covers
      'name': 'Steering Wheel Covers',
      'category': 'Interior',
      'unit': 'Piece',
      'suppliers': {
        'Pilot': {'price': 25.0, 'email': 'info@pilot.com', 'leadTime': 2, 'minOrderQty': 20},
        'Bell Automotive': {'price': 23.0, 'email': 'info@bellautomotive.com', 'leadTime': 3, 'minOrderQty': 25},
        'Momo': {'price': 28.0, 'email': 'info@momo.com', 'leadTime': 4, 'minOrderQty': 15},
      }
    },
    'PRT038': { // Gear Shift Knobs
      'name': 'Gear Shift Knobs',
      'category': 'Interior',
      'unit': 'Piece',
      'suppliers': {
        'Blox Racing': {'price': 15.0, 'email': 'info@bloxracing.com', 'leadTime': 3, 'minOrderQty': 30},
        'Sparco': {'price': 18.0, 'email': 'info@sparco.com', 'leadTime': 4, 'minOrderQty': 25},
        'Momo': {'price': 20.0, 'email': 'info@momo.com', 'leadTime': 4, 'minOrderQty': 20},
      }
    },
  };

  // Get price comparison for a specific part
  static Map<String, dynamic>? getPartPriceComparison(String partId) {
    return enhancedSupplierPricing[partId];
  }

  // Get all suppliers for a specific part with sorted prices (cheapest first)
  static List<Map<String, dynamic>> getSupplierQuotes(String partId) {
    final partData = enhancedSupplierPricing[partId];
    if (partData == null) return [];

    final suppliers = partData['suppliers'] as Map<String, dynamic>;
    final quotes = <Map<String, dynamic>>[];

    suppliers.forEach((supplierName, details) {
      quotes.add({
        'supplier': supplierName,
        'price': details['price'],
        'email': details['email'],
        'leadTime': details['leadTime'],
        'minOrderQty': details['minOrderQty'],
        'totalCost': 0.0, // Will be calculated when quantity is known
      });
    });

    // Sort by price (cheapest first)
    quotes.sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));
    return quotes;
  }

  // Calculate total cost for each supplier based on quantity needed
  static List<Map<String, dynamic>> calculateSupplierCosts(String partId, int quantity) {
    final quotes = getSupplierQuotes(partId);

    for (var quote in quotes) {
      final price = quote['price'] as double;
      final minOrderQty = quote['minOrderQty'] as int;
      final actualQuantity = quantity < minOrderQty ? minOrderQty : quantity;

      quote['actualQuantity'] = actualQuantity;
      quote['totalCost'] = price * actualQuantity;
      quote['excessQuantity'] = actualQuantity - quantity;
    }

    // Re-sort by total cost
    quotes.sort((a, b) => (a['totalCost'] as double).compareTo(b['totalCost'] as double));
    return quotes;
  }

  // Get procurement recommendation based on cost, lead time, and reliability
  static Map<String, dynamic> getProcurementRecommendation(String partId, int quantity, {
    double costWeight = 0.6,
    double leadTimeWeight = 0.3,
    double reliabilityWeight = 0.1,
  }) {
    final quotes = calculateSupplierCosts(partId, quantity);
    if (quotes.isEmpty) return {};

    // Calculate scores for each supplier
    final maxCost = quotes.map((q) => q['totalCost'] as double).reduce((a, b) => a > b ? a : b);
    final maxLeadTime = quotes.map((q) => q['leadTime'] as int).reduce((a, b) => a > b ? a : b);

    for (var quote in quotes) {
      final costScore = 1 - ((quote['totalCost'] as double) / maxCost);
      final leadTimeScore = 1 - ((quote['leadTime'] as int) / maxLeadTime);
      final reliabilityScore = _getSupplierReliabilityScore(quote['supplier']);

      quote['overallScore'] = (costScore * costWeight) +
          (leadTimeScore * leadTimeWeight) +
          (reliabilityScore * reliabilityWeight);
    }

    // Sort by overall score (highest first)
    quotes.sort((a, b) => (b['overallScore'] as double).compareTo(a['overallScore'] as double));

    return {
      'partId': partId,
      'partName': enhancedSupplierPricing[partId]?['name'],
      'quantity': quantity,
      'recommendations': quotes,
      'bestChoice': quotes.first,
    };
  }

  // Simple reliability scoring (in real system, this would use historical data)
  static double _getSupplierReliabilityScore(String supplier) {
    final reliabilityScores = {
      'Bosch': 0.95,
      'Denso': 0.93,
      'NGK': 0.92,
      'Castrol': 0.90,
      'Shell': 0.90,
      'Brembo': 0.94,
      'KYB': 0.88,
      'TRW': 0.87,
      'Gates': 0.89,
      'Philips': 0.91,
      'Osram': 0.90,
      'Monroe': 0.86,
      'Moog': 0.88,
    };
    return reliabilityScores[supplier] ?? 0.75;
  }

  // Upload enhanced supplier pricing to Firestore
  Future<void> uploadEnhancedSupplierPricing() async {
    await _firestore.collection('enhanced_supplier_pricing').doc('parts_pricing').set({
      'partsPricing': enhancedSupplierPricing,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Fetch enhanced supplier pricing from Firestore
  Future<Map<String, dynamic>?> fetchEnhancedSupplierPricing() async {
    final doc = await _firestore.collection('enhanced_supplier_pricing').doc('parts_pricing').get();
    return doc.data();
  }

  // Generate procurement report for multiple parts
  static Map<String, dynamic> generateProcurementReport(Map<String, int> partQuantities) {
    final recommendations = <String, dynamic>{};
    double totalCost = 0.0;
    final supplierBreakdown = <String, double>{};

    partQuantities.forEach((partId, quantity) {
      final recommendation = getProcurementRecommendation(partId, quantity);
      if (recommendation.isNotEmpty) {
        recommendations[partId] = recommendation;

        final bestChoice = recommendation['bestChoice'];
        final cost = bestChoice['totalCost'] as double;
        final supplier = bestChoice['supplier'] as String;

        totalCost += cost;
        supplierBreakdown[supplier] = (supplierBreakdown[supplier] ?? 0.0) + cost;
      }
    });

    return {
      'recommendations': recommendations,
      'totalCost': totalCost,
      'supplierBreakdown': supplierBreakdown,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }
}