import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryDataManager {
  final FirebaseFirestore _firestore;

  InventoryDataManager(this._firestore);

  // Enhanced default parts data with multiple suppliers per part (2-3 suppliers each)
  static final List<Map<String, dynamic>> defaultParts = [
    // Engine System
    {
      'name': 'Engine Oil (5W-30)',
      'category': 'Engine',
      'price': 120.0, // Primary supplier price
      'quantity': 50,
      'unit': 'Litre',
      'isLowStock': false,
      'lowStockThreshold': 15,
      'suppliers': [
        {
          'name': 'Shell',
          'email': 'info@shell.com',
          'price': 120.0,
          'leadTime': 3,
          'minOrderQty': 10,
          'reliabilityScore': 0.90,
          'isPrimary': true
        },
        {
          'name': 'Castrol',
          'email': 'info@castrol.com',
          'price': 118.0,
          'leadTime': 2,
          'minOrderQty': 12,
          'reliabilityScore': 0.90,
          'isPrimary': false
        },
        {
          'name': 'Mobil1',
          'email': 'info@mobil1.com',
          'price': 125.0,
          'leadTime': 4,
          'minOrderQty': 8,
          'reliabilityScore': 0.88,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Engine Oil (10W-40)',
      'category': 'Engine',
      'price': 110.0,
      'quantity': 50,
      'unit': 'Litre',
      'isLowStock': false,
      'lowStockThreshold': 15,
      'suppliers': [
        {
          'name': 'Castrol',
          'email': 'info@castrol.com',
          'price': 110.0,
          'leadTime': 2,
          'minOrderQty': 12,
          'reliabilityScore': 0.90,
          'isPrimary': true
        },
        {
          'name': 'Shell',
          'email': 'info@shell.com',
          'price': 115.0,
          'leadTime': 3,
          'minOrderQty': 10,
          'reliabilityScore': 0.90,
          'isPrimary': false
        },
        {
          'name': 'Valvoline',
          'email': 'info@valvoline.com',
          'price': 108.0,
          'leadTime': 5,
          'minOrderQty': 15,
          'reliabilityScore': 0.85,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Oil Filters',
      'category': 'Engine',
      'price': 25.0,
      'quantity': 30,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 10,
      'suppliers': [
        {
          'name': 'Bosch',
          'email': 'info@bosch.com',
          'price': 25.0,
          'leadTime': 2,
          'minOrderQty': 20,
          'reliabilityScore': 0.95,
          'isPrimary': true
        },
        {
          'name': 'Mann Filter',
          'email': 'info@mannfilter.com',
          'price': 23.0,
          'leadTime': 3,
          'minOrderQty': 25,
          'reliabilityScore': 0.88,
          'isPrimary': false
        },
        {
          'name': 'K&N',
          'email': 'info@knfilters.com',
          'price': 28.0,
          'leadTime': 4,
          'minOrderQty': 15,
          'reliabilityScore': 0.85,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Air Filters (Engine)',
      'category': 'Engine',
      'price': 30.0,
      'quantity': 30,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 10,
      'suppliers': [
        {
          'name': 'Denso',
          'email': 'info@denso.com',
          'price': 30.0,
          'leadTime': 2,
          'minOrderQty': 20,
          'reliabilityScore': 0.93,
          'isPrimary': true
        },
        {
          'name': 'Bosch',
          'email': 'info@bosch.com',
          'price': 28.0,
          'leadTime': 2,
          'minOrderQty': 25,
          'reliabilityScore': 0.95,
          'isPrimary': false
        },
        {
          'name': 'K&N',
          'email': 'info@knfilters.com',
          'price': 35.0,
          'leadTime': 4,
          'minOrderQty': 15,
          'reliabilityScore': 0.85,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Fuel Filters',
      'category': 'Engine',
      'price': 35.0,
      'quantity': 20,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 8,
      'suppliers': [
        {
          'name': 'Bosch',
          'email': 'info@bosch.com',
          'price': 35.0,
          'leadTime': 2,
          'minOrderQty': 15,
          'reliabilityScore': 0.95,
          'isPrimary': true
        },
        {
          'name': 'Mann Filter',
          'email': 'info@mannfilter.com',
          'price': 32.0,
          'leadTime': 3,
          'minOrderQty': 20,
          'reliabilityScore': 0.88,
          'isPrimary': false
        },
        {
          'name': 'Denso',
          'email': 'info@denso.com',
          'price': 36.0,
          'leadTime': 2,
          'minOrderQty': 18,
          'reliabilityScore': 0.93,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Spark Plugs',
      'category': 'Engine',
      'price': 18.0,
      'quantity': 40,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 15,
      'suppliers': [
        {
          'name': 'NGK',
          'email': 'info@ngk.com',
          'price': 18.0,
          'leadTime': 1,
          'minOrderQty': 50,
          'reliabilityScore': 0.92,
          'isPrimary': true
        },
        {
          'name': 'Denso',
          'email': 'info@denso.com',
          'price': 19.0,
          'leadTime': 2,
          'minOrderQty': 40,
          'reliabilityScore': 0.93,
          'isPrimary': false
        },
        {
          'name': 'Bosch',
          'email': 'info@bosch.com',
          'price': 20.0,
          'leadTime': 2,
          'minOrderQty': 45,
          'reliabilityScore': 0.95,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Serpentine Belts',
      'category': 'Engine',
      'price': 45.0,
      'quantity': 15,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 5,
      'suppliers': [
        {
          'name': 'Gates',
          'email': 'info@gates.com',
          'price': 45.0,
          'leadTime': 3,
          'minOrderQty': 10,
          'reliabilityScore': 0.89,
          'isPrimary': true
        },
        {
          'name': 'Dayco',
          'email': 'info@dayco.com',
          'price': 42.0,
          'leadTime': 4,
          'minOrderQty': 12,
          'reliabilityScore': 0.87,
          'isPrimary': false
        },
        {
          'name': 'Continental',
          'email': 'info@continental.com',
          'price': 47.0,
          'leadTime': 5,
          'minOrderQty': 8,
          'reliabilityScore': 0.86,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Timing Belts',
      'category': 'Engine',
      'price': 60.0,
      'quantity': 10,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 3,
      'suppliers': [
        {
          'name': 'Gates',
          'email': 'info@gates.com',
          'price': 60.0,
          'leadTime': 3,
          'minOrderQty': 8,
          'reliabilityScore': 0.89,
          'isPrimary': true
        },
        {
          'name': 'Dayco',
          'email': 'info@dayco.com',
          'price': 58.0,
          'leadTime': 4,
          'minOrderQty': 10,
          'reliabilityScore': 0.87,
          'isPrimary': false
        },
        {
          'name': 'Continental',
          'email': 'info@continental.com',
          'price': 62.0,
          'leadTime': 5,
          'minOrderQty': 6,
          'reliabilityScore': 0.86,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Coolant/Antifreeze',
      'category': 'Engine',
      'price': 40.0,
      'quantity': 25,
      'unit': 'Litre',
      'isLowStock': false,
      'lowStockThreshold': 10,
      'suppliers': [
        {
          'name': 'Prestone',
          'email': 'info@prestone.com',
          'price': 40.0,
          'leadTime': 2,
          'minOrderQty': 15,
          'reliabilityScore': 0.88,
          'isPrimary': true
        },
        {
          'name': 'Castrol',
          'email': 'info@castrol.com',
          'price': 38.0,
          'leadTime': 2,
          'minOrderQty': 20,
          'reliabilityScore': 0.90,
          'isPrimary': false
        },
        {
          'name': 'Shell',
          'email': 'info@shell.com',
          'price': 42.0,
          'leadTime': 3,
          'minOrderQty': 12,
          'reliabilityScore': 0.90,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Radiator Hoses',
      'category': 'Engine',
      'price': 22.0,
      'quantity': 20,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 8,
      'suppliers': [
        {
          'name': 'Dayco',
          'email': 'info@dayco.com',
          'price': 22.0,
          'leadTime': 4,
          'minOrderQty': 15,
          'reliabilityScore': 0.87,
          'isPrimary': true
        },
        {
          'name': 'Gates',
          'email': 'info@gates.com',
          'price': 24.0,
          'leadTime': 3,
          'minOrderQty': 12,
          'reliabilityScore': 0.89,
          'isPrimary': false
        },
        {
          'name': 'Continental',
          'email': 'info@continental.com',
          'price': 25.0,
          'leadTime': 5,
          'minOrderQty': 10,
          'reliabilityScore': 0.86,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Engine Gaskets (Valve cover, Oil pan)',
      'category': 'Engine',
      'price': 55.0,
      'quantity': 10,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 3,
      'suppliers': [
        {
          'name': 'Victor Reinz',
          'email': 'info@victorreinz.com',
          'price': 55.0,
          'leadTime': 4,
          'minOrderQty': 8,
          'reliabilityScore': 0.87,
          'isPrimary': true
        },
        {
          'name': 'Elring',
          'email': 'info@elring.com',
          'price': 52.0,
          'leadTime': 3,
          'minOrderQty': 10,
          'reliabilityScore': 0.85,
          'isPrimary': false
        },
        {
          'name': 'Bosch',
          'email': 'info@bosch.com',
          'price': 58.0,
          'leadTime': 2,
          'minOrderQty': 6,
          'reliabilityScore': 0.95,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Water Pumps (common models)',
      'category': 'Engine',
      'price': 120.0,
      'quantity': 8,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 2,
      'suppliers': [
        {
          'name': 'Aisin',
          'email': 'info@aisin.com',
          'price': 120.0,
          'leadTime': 5,
          'minOrderQty': 4,
          'reliabilityScore': 0.91,
          'isPrimary': true
        },
        {
          'name': 'Gates',
          'email': 'info@gates.com',
          'price': 115.0,
          'leadTime': 4,
          'minOrderQty': 5,
          'reliabilityScore': 0.89,
          'isPrimary': false
        },
        {
          'name': 'Bosch',
          'email': 'info@bosch.com',
          'price': 125.0,
          'leadTime': 3,
          'minOrderQty': 3,
          'reliabilityScore': 0.95,
          'isPrimary': false
        }
      ]
    },

    // Braking System
    {
      'name': 'Brake Pads (Front & Rear)',
      'category': 'Brakes',
      'price': 80.0,
      'quantity': 20,
      'unit': 'Set',
      'isLowStock': false,
      'lowStockThreshold': 8,
      'suppliers': [
        {
          'name': 'Brembo',
          'email': 'info@brembo.com',
          'price': 80.0,
          'leadTime': 3,
          'minOrderQty': 10,
          'reliabilityScore': 0.94,
          'isPrimary': true
        },
        {
          'name': 'Akebono',
          'email': 'info@akebono.com',
          'price': 75.0,
          'leadTime': 4,
          'minOrderQty': 12,
          'reliabilityScore': 0.89,
          'isPrimary': false
        },
        {
          'name': 'TRW',
          'email': 'info@trw.com',
          'price': 72.0,
          'leadTime': 3,
          'minOrderQty': 15,
          'reliabilityScore': 0.87,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Brake Discs/Rotors',
      'category': 'Brakes',
      'price': 150.0,
      'quantity': 10,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 3,
      'suppliers': [
        {
          'name': 'Brembo',
          'email': 'info@brembo.com',
          'price': 150.0,
          'leadTime': 4,
          'minOrderQty': 5,
          'reliabilityScore': 0.94,
          'isPrimary': true
        },
        {
          'name': 'Zimmermann',
          'email': 'info@zimmermann.com',
          'price': 145.0,
          'leadTime': 5,
          'minOrderQty': 6,
          'reliabilityScore': 0.86,
          'isPrimary': false
        },
        {
          'name': 'TRW',
          'email': 'info@trw.com',
          'price': 140.0,
          'leadTime': 3,
          'minOrderQty': 8,
          'reliabilityScore': 0.87,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Brake Fluid (DOT 3/DOT 4)',
      'category': 'Brakes',
      'price': 25.0,
      'quantity': 30,
      'unit': 'Litre',
      'isLowStock': false,
      'lowStockThreshold': 10,
      'suppliers': [
        {
          'name': 'Bosch',
          'email': 'info@bosch.com',
          'price': 25.0,
          'leadTime': 2,
          'minOrderQty': 20,
          'reliabilityScore': 0.95,
          'isPrimary': true
        },
        {
          'name': 'Castrol',
          'email': 'info@castrol.com',
          'price': 23.0,
          'leadTime': 2,
          'minOrderQty': 25,
          'reliabilityScore': 0.90,
          'isPrimary': false
        },
        {
          'name': 'Motul',
          'email': 'info@motul.com',
          'price': 27.0,
          'leadTime': 3,
          'minOrderQty': 15,
          'reliabilityScore': 0.88,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Brake Hoses',
      'category': 'Brakes',
      'price': 20.0,
      'quantity': 15,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 5,
      'suppliers': [
        {
          'name': 'TRW',
          'email': 'info@trw.com',
          'price': 20.0,
          'leadTime': 3,
          'minOrderQty': 12,
          'reliabilityScore': 0.87,
          'isPrimary': true
        },
        {
          'name': 'Continental',
          'email': 'info@continental.com',
          'price': 19.0,
          'leadTime': 4,
          'minOrderQty': 15,
          'reliabilityScore': 0.86,
          'isPrimary': false
        },
        {
          'name': 'Gates',
          'email': 'info@gates.com',
          'price': 22.0,
          'leadTime': 3,
          'minOrderQty': 10,
          'reliabilityScore': 0.89,
          'isPrimary': false
        }
      ]
    },

    // Electrical System
    {
      'name': 'Car Batteries (12V - common sizes)',
      'category': 'Electrical',
      'price': 250.0,
      'quantity': 10,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 3,
      'suppliers': [
        {
          'name': 'Amaron',
          'email': 'info@amaron.com',
          'price': 250.0,
          'leadTime': 2,
          'minOrderQty': 3,
          'reliabilityScore': 0.90,
          'isPrimary': true
        },
        {
          'name': 'Yuasa',
          'email': 'info@yuasa.com',
          'price': 240.0,
          'leadTime': 3,
          'minOrderQty': 4,
          'reliabilityScore': 0.88,
          'isPrimary': false
        },
        {
          'name': 'Bosch',
          'email': 'info@bosch.com',
          'price': 260.0,
          'leadTime': 2,
          'minOrderQty': 3,
          'reliabilityScore': 0.95,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Headlight Bulbs (H4, H7)',
      'category': 'Electrical',
      'price': 15.0,
      'quantity': 30,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 10,
      'suppliers': [
        {
          'name': 'Philips',
          'email': 'info@philips.com',
          'price': 15.0,
          'leadTime': 1,
          'minOrderQty': 50,
          'reliabilityScore': 0.91,
          'isPrimary': true
        },
        {
          'name': 'Osram',
          'email': 'info@osram.com',
          'price': 14.0,
          'leadTime': 2,
          'minOrderQty': 60,
          'reliabilityScore': 0.90,
          'isPrimary': false
        },
        {
          'name': 'Bosch',
          'email': 'info@bosch.com',
          'price': 16.0,
          'leadTime': 2,
          'minOrderQty': 40,
          'reliabilityScore': 0.95,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Tail Light Bulbs',
      'category': 'Electrical',
      'price': 10.0,
      'quantity': 30,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 10,
      'suppliers': [
        {
          'name': 'Osram',
          'email': 'info@osram.com',
          'price': 10.0,
          'leadTime': 2,
          'minOrderQty': 60,
          'reliabilityScore': 0.90,
          'isPrimary': true
        },
        {
          'name': 'Philips',
          'email': 'info@philips.com',
          'price': 11.0,
          'leadTime': 1,
          'minOrderQty': 50,
          'reliabilityScore': 0.91,
          'isPrimary': false
        },
        {
          'name': 'Bosch',
          'email': 'info@bosch.com',
          'price': 9.5,
          'leadTime': 2,
          'minOrderQty': 70,
          'reliabilityScore': 0.95,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Automotive Fuses (10A, 15A, 20A, 30A)',
      'category': 'Electrical',
      'price': 2.0,
      'quantity': 50,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 20,
      'suppliers': [
        {
          'name': 'Bosch',
          'email': 'info@bosch.com',
          'price': 2.0,
          'leadTime': 1,
          'minOrderQty': 100,
          'reliabilityScore': 0.95,
          'isPrimary': true
        },
        {
          'name': 'Littelfuse',
          'email': 'info@littelfuse.com',
          'price': 1.8,
          'leadTime': 2,
          'minOrderQty': 150,
          'reliabilityScore': 0.88,
          'isPrimary': false
        },
        {
          'name': 'Bussmann',
          'email': 'info@bussmann.com',
          'price': 2.2,
          'leadTime': 2,
          'minOrderQty': 80,
          'reliabilityScore': 0.85,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Relays (basic automotive relays)',
      'category': 'Electrical',
      'price': 8.0,
      'quantity': 20,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 5,
      'suppliers': [
        {
          'name': 'Bosch',
          'email': 'info@bosch.com',
          'price': 8.0,
          'leadTime': 2,
          'minOrderQty': 25,
          'reliabilityScore': 0.95,
          'isPrimary': true
        },
        {
          'name': 'Hella',
          'email': 'info@hella.com',
          'price': 7.5,
          'leadTime': 3,
          'minOrderQty': 30,
          'reliabilityScore': 0.89,
          'isPrimary': false
        },
        {
          'name': 'Standard Motor',
          'email': 'info@standardmotor.com',
          'price': 8.5,
          'leadTime': 4,
          'minOrderQty': 20,
          'reliabilityScore': 0.82,
          'isPrimary': false
        }
      ]
    },

    // Suspension & Steering
    {
      'name': 'Shock Absorbers (common sizes)',
      'category': 'Suspension',
      'price': 180.0,
      'quantity': 10,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 3,
      'suppliers': [
        {
          'name': 'KYB',
          'email': 'info@kyb.com',
          'price': 180.0,
          'leadTime': 5,
          'minOrderQty': 4,
          'reliabilityScore': 0.88,
          'isPrimary': true
        },
        {
          'name': 'Monroe',
          'email': 'info@monroe.com',
          'price': 175.0,
          'leadTime': 4,
          'minOrderQty': 5,
          'reliabilityScore': 0.86,
          'isPrimary': false
        },
        {
          'name': 'Bilstein',
          'email': 'info@bilstein.com',
          'price': 190.0,
          'leadTime': 6,
          'minOrderQty': 3,
          'reliabilityScore': 0.92,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Tie Rod Ends',
      'category': 'Suspension',
      'price': 35.0,
      'quantity': 15,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 5,
      'suppliers': [
        {
          'name': 'TRW',
          'email': 'info@trw.com',
          'price': 35.0,
          'leadTime': 3,
          'minOrderQty': 10,
          'reliabilityScore': 0.87,
          'isPrimary': true
        },
        {
          'name': 'Moog',
          'email': 'info@moog.com',
          'price': 33.0,
          'leadTime': 4,
          'minOrderQty': 12,
          'reliabilityScore': 0.88,
          'isPrimary': false
        },
        {
          'name': 'Lemforder',
          'email': 'info@lemforder.com',
          'price': 37.0,
          'leadTime': 5,
          'minOrderQty': 8,
          'reliabilityScore': 0.85,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Ball Joints',
      'category': 'Suspension',
      'price': 50.0,
      'quantity': 10,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 3,
      'suppliers': [
        {
          'name': 'Moog',
          'email': 'info@moog.com',
          'price': 50.0,
          'leadTime': 4,
          'minOrderQty': 8,
          'reliabilityScore': 0.88,
          'isPrimary': true
        },
        {
          'name': 'TRW',
          'email': 'info@trw.com',
          'price': 48.0,
          'leadTime': 3,
          'minOrderQty': 10,
          'reliabilityScore': 0.87,
          'isPrimary': false
        },
        {
          'name': 'Lemforder',
          'email': 'info@lemforder.com',
          'price': 52.0,
          'leadTime': 5,
          'minOrderQty': 6,
          'reliabilityScore': 0.85,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Control Arm Bushings',
      'category': 'Suspension',
      'price': 40.0,
      'quantity': 10,
      'unit': 'Set',
      'isLowStock': false,
      'lowStockThreshold': 3,
      'suppliers': [
        {
          'name': 'Energy Suspension',
          'email': 'info@energysuspension.com',
          'price': 40.0,
          'leadTime': 4,
          'minOrderQty': 8,
          'reliabilityScore': 0.85,
          'isPrimary': true
        },
        {
          'name': 'Prothane',
          'email': 'info@prothane.com',
          'price': 38.0,
          'leadTime': 5,
          'minOrderQty': 10,
          'reliabilityScore': 0.83,
          'isPrimary': false
        },
        {
          'name': 'Moog',
          'email': 'info@moog.com',
          'price': 42.0,
          'leadTime': 4,
          'minOrderQty': 6,
          'reliabilityScore': 0.88,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Steering Rack (reconditioned)',
      'category': 'Steering',
      'price': 300.0,
      'quantity': 5,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 2,
      'suppliers': [
        {
          'name': 'A1 Cardone',
          'email': 'info@a1cardone.com',
          'price': 300.0,
          'leadTime': 7,
          'minOrderQty': 2,
          'reliabilityScore': 0.84,
          'isPrimary': true
        },
        {
          'name': 'Bosch',
          'email': 'info@bosch.com',
          'price': 320.0,
          'leadTime': 6,
          'minOrderQty': 2,
          'reliabilityScore': 0.95,
          'isPrimary': false
        },
        {
          'name': 'TRW',
          'email': 'info@trw.com',
          'price': 310.0,
          'leadTime': 8,
          'minOrderQty': 3,
          'reliabilityScore': 0.87,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Power Steering Pumps',
      'category': 'Steering',
      'price': 250.0,
      'quantity': 10,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 3,
      'suppliers': [
        {
          'name': 'Aisin',
          'email': 'info@aisin.com',
          'price': 250.0,
          'leadTime': 5,
          'minOrderQty': 4,
          'reliabilityScore': 0.91,
          'isPrimary': true
        },
        {
          'name': 'Bosch',
          'email': 'info@bosch.com',
          'price': 260.0,
          'leadTime': 4,
          'minOrderQty': 3,
          'reliabilityScore': 0.95,
          'isPrimary': false
        },
        {
          'name': 'A1 Cardone',
          'email': 'info@a1cardone.com',
          'price': 240.0,
          'leadTime': 6,
          'minOrderQty': 5,
          'reliabilityScore': 0.84,
          'isPrimary': false
        }
      ]
    },

    // Exhaust System
    {
      'name': 'Mufflers (universal fit)',
      'category': 'Exhaust',
      'price': 100.0,
      'quantity': 15,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 5,
      'suppliers': [
        {
          'name': 'Walker',
          'email': 'info@walker.com',
          'price': 100.0,
          'leadTime': 4,
          'minOrderQty': 8,
          'reliabilityScore': 0.86,
          'isPrimary': true
        },
        {
          'name': 'Bosal',
          'email': 'info@bosal.com',
          'price': 95.0,
          'leadTime': 5,
          'minOrderQty': 10,
          'reliabilityScore': 0.84,
          'isPrimary': false
        },
        {
          'name': 'MagnaFlow',
          'email': 'info@magnaflow.com',
          'price': 110.0,
          'leadTime': 3,
          'minOrderQty': 6,
          'reliabilityScore': 0.88,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Exhaust Pipes (aluminized steel)',
      'category': 'Exhaust',
      'price': 70.0,
      'quantity': 20,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 8,
      'suppliers': [
        {
          'name': 'Dynomax',
          'email': 'info@dynomax.com',
          'price': 70.0,
          'leadTime': 4,
          'minOrderQty': 10,
          'reliabilityScore': 0.83,
          'isPrimary': true
        },
        {
          'name': 'Walker',
          'email': 'info@walker.com',
          'price': 68.0,
          'leadTime': 4,
          'minOrderQty': 12,
          'reliabilityScore': 0.86,
          'isPrimary': false
        },
        {
          'name': 'Bosal',
          'email': 'info@bosal.com',
          'price': 72.0,
          'leadTime': 5,
          'minOrderQty': 8,
          'reliabilityScore': 0.84,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Catalytic Converters (universal fit)',
      'category': 'Exhaust',
      'price': 200.0,
      'quantity': 10,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 3,
      'suppliers': [
        {
          'name': 'MagnaFlow',
          'email': 'info@magnaflow.com',
          'price': 200.0,
          'leadTime': 6,
          'minOrderQty': 3,
          'reliabilityScore': 0.88,
          'isPrimary': true
        },
        {
          'name': 'Walker',
          'email': 'info@walker.com',
          'price': 195.0,
          'leadTime': 5,
          'minOrderQty': 4,
          'reliabilityScore': 0.86,
          'isPrimary': false
        },
        {
          'name': 'Bosal',
          'email': 'info@bosal.com',
          'price': 205.0,
          'leadTime': 7,
          'minOrderQty': 2,
          'reliabilityScore': 0.84,
          'isPrimary': false
        }
      ]
    },

    // Body Parts
    {
      'name': 'Bumpers (Front and Rear)',
      'category': 'Body',
      'price': 250.0,
      'quantity': 5,
      'unit': 'Set',
      'isLowStock': false,
      'lowStockThreshold': 2,
      'suppliers': [
        {
          'name': 'Replace',
          'email': 'info@replace.com',
          'price': 250.0,
          'leadTime': 7,
          'minOrderQty': 2,
          'reliabilityScore': 0.82,
          'isPrimary': true
        },
        {
          'name': 'Sherman',
          'email': 'info@sherman.com',
          'price': 240.0,
          'leadTime': 8,
          'minOrderQty': 3,
          'reliabilityScore': 0.80,
          'isPrimary': false
        },
        {
          'name': 'Goodmark',
          'email': 'info@goodmark.com',
          'price': 260.0,
          'leadTime': 6,
          'minOrderQty': 2,
          'reliabilityScore': 0.81,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Fenders',
      'category': 'Body',
      'price': 150.0,
      'quantity': 10,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 3,
      'suppliers': [
        {
          'name': 'Replace',
          'email': 'info@replace.com',
          'price': 150.0,
          'leadTime': 6,
          'minOrderQty': 4,
          'reliabilityScore': 0.82,
          'isPrimary': true
        },
        {
          'name': 'Sherman',
          'email': 'info@sherman.com',
          'price': 145.0,
          'leadTime': 7,
          'minOrderQty': 5,
          'reliabilityScore': 0.80,
          'isPrimary': false
        },
        {
          'name': 'Goodmark',
          'email': 'info@goodmark.com',
          'price': 155.0,
          'leadTime': 5,
          'minOrderQty': 3,
          'reliabilityScore': 0.81,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Hoods',
      'category': 'Body',
      'price': 300.0,
      'quantity': 5,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 2,
      'suppliers': [
        {
          'name': 'Replace',
          'email': 'info@replace.com',
          'price': 300.0,
          'leadTime': 8,
          'minOrderQty': 2,
          'reliabilityScore': 0.82,
          'isPrimary': true
        },
        {
          'name': 'Sherman',
          'email': 'info@sherman.com',
          'price': 290.0,
          'leadTime': 9,
          'minOrderQty': 3,
          'reliabilityScore': 0.80,
          'isPrimary': false
        },
        {
          'name': 'Goodmark',
          'email': 'info@goodmark.com',
          'price': 310.0,
          'leadTime': 7,
          'minOrderQty': 2,
          'reliabilityScore': 0.81,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Trunks',
      'category': 'Body',
      'price': 350.0,
      'quantity': 5,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 2,
      'suppliers': [
        {
          'name': 'Replace',
          'email': 'info@replace.com',
          'price': 350.0,
          'leadTime': 8,
          'minOrderQty': 2,
          'reliabilityScore': 0.82,
          'isPrimary': true
        },
        {
          'name': 'Sherman',
          'email': 'info@sherman.com',
          'price': 340.0,
          'leadTime': 9,
          'minOrderQty': 2,
          'reliabilityScore': 0.80,
          'isPrimary': false
        },
        {
          'name': 'Goodmark',
          'email': 'info@goodmark.com',
          'price': 360.0,
          'leadTime': 7,
          'minOrderQty': 2,
          'reliabilityScore': 0.81,
          'isPrimary': false
        }
      ]
    },

    // Interior Parts
    {
      'name': 'Seat Covers (Universal)',
      'category': 'Interior',
      'price': 100.0,
      'quantity': 20,
      'unit': 'Set',
      'isLowStock': false,
      'lowStockThreshold': 8,
      'suppliers': [
        {
          'name': 'Covercraft',
          'email': 'info@covercraft.com',
          'price': 100.0,
          'leadTime': 3,
          'minOrderQty': 10,
          'reliabilityScore': 0.85,
          'isPrimary': true
        },
        {
          'name': 'FIA',
          'email': 'info@fia.com',
          'price': 95.0,
          'leadTime': 4,
          'minOrderQty': 12,
          'reliabilityScore': 0.83,
          'isPrimary': false
        },
        {
          'name': 'CalTrend',
          'email': 'info@caltrend.com',
          'price': 105.0,
          'leadTime': 3,
          'minOrderQty': 8,
          'reliabilityScore': 0.84,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Floor Mats (Universal)',
      'category': 'Interior',
      'price': 50.0,
      'quantity': 30,
      'unit': 'Set',
      'isLowStock': false,
      'lowStockThreshold': 10,
      'suppliers': [
        {
          'name': 'WeatherTech',
          'email': 'info@weathertech.com',
          'price': 50.0,
          'leadTime': 2,
          'minOrderQty': 15,
          'reliabilityScore': 0.90,
          'isPrimary': true
        },
        {
          'name': 'Husky Liners',
          'email': 'info@huskyliners.com',
          'price': 48.0,
          'leadTime': 3,
          'minOrderQty': 18,
          'reliabilityScore': 0.87,
          'isPrimary': false
        },
        {
          'name': 'Lloyd Mats',
          'email': 'info@lloydmats.com',
          'price': 52.0,
          'leadTime': 2,
          'minOrderQty': 12,
          'reliabilityScore': 0.85,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Steering Wheel Covers',
      'category': 'Interior',
      'price': 25.0,
      'quantity': 40,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 15,
      'suppliers': [
        {
          'name': 'Pilot',
          'email': 'info@pilot.com',
          'price': 25.0,
          'leadTime': 2,
          'minOrderQty': 20,
          'reliabilityScore': 0.82,
          'isPrimary': true
        },
        {
          'name': 'Bell Automotive',
          'email': 'info@bellautomotive.com',
          'price': 23.0,
          'leadTime': 3,
          'minOrderQty': 25,
          'reliabilityScore': 0.80,
          'isPrimary': false
        },
        {
          'name': 'Momo',
          'email': 'info@momo.com',
          'price': 28.0,
          'leadTime': 4,
          'minOrderQty': 15,
          'reliabilityScore': 0.88,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Gear Shift Knobs',
      'category': 'Interior',
      'price': 15.0,
      'quantity': 50,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 20,
      'suppliers': [
        {
          'name': 'Blox Racing',
          'email': 'info@bloxracing.com',
          'price': 15.0,
          'leadTime': 3,
          'minOrderQty': 30,
          'reliabilityScore': 0.83,
          'isPrimary': true
        },
        {
          'name': 'Sparco',
          'email': 'info@sparco.com',
          'price': 18.0,
          'leadTime': 4,
          'minOrderQty': 25,
          'reliabilityScore': 0.87,
          'isPrimary': false
        },
        {
          'name': 'Momo',
          'email': 'info@momo.com',
          'price': 20.0,
          'leadTime': 4,
          'minOrderQty': 20,
          'reliabilityScore': 0.88,
          'isPrimary': false
        }
      ]
    },
    // --- MISSING PARTS ADDED BELOW ---
    {
      'name': 'Automotive Fuses (10A, 15A, 20A, 30A)',
      'category': 'Electrical',
      'price': 2.0,
      'quantity': 50,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 20,
      'suppliers': [
        {
          'name': 'Bosch',
          'email': 'info@bosch.com',
          'price': 2.0,
          'leadTime': 1,
          'minOrderQty': 100,
          'reliabilityScore': 0.95,
          'isPrimary': true
        },
        {
          'name': 'Littelfuse',
          'email': 'info@littelfuse.com',
          'price': 1.8,
          'leadTime': 2,
          'minOrderQty': 150,
          'reliabilityScore': 0.88,
          'isPrimary': false
        },
        {
          'name': 'Bussmann',
          'email': 'info@bussmann.com',
          'price': 2.2,
          'leadTime': 2,
          'minOrderQty': 80,
          'reliabilityScore': 0.85,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Relays (basic automotive relays)',
      'category': 'Electrical',
      'price': 8.0,
      'quantity': 20,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 5,
      'suppliers': [
        {
          'name': 'Bosch',
          'email': 'info@bosch.com',
          'price': 8.0,
          'leadTime': 2,
          'minOrderQty': 25,
          'reliabilityScore': 0.95,
          'isPrimary': true
        },
        {
          'name': 'Hella',
          'email': 'info@hella.com',
          'price': 7.5,
          'leadTime': 3,
          'minOrderQty': 30,
          'reliabilityScore': 0.89,
          'isPrimary': false
        },
        {
          'name': 'Standard Motor',
          'email': 'info@standardmotor.com',
          'price': 8.5,
          'leadTime': 4,
          'minOrderQty': 20,
          'reliabilityScore': 0.82,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Ball Joints',
      'category': 'Suspension',
      'price': 50.0,
      'quantity': 10,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 3,
      'suppliers': [
        {
          'name': 'Moog',
          'email': 'info@moog.com',
          'price': 50.0,
          'leadTime': 4,
          'minOrderQty': 8,
          'reliabilityScore': 0.88,
          'isPrimary': true
        },
        {
          'name': 'TRW',
          'email': 'info@trw.com',
          'price': 48.0,
          'leadTime': 3,
          'minOrderQty': 10,
          'reliabilityScore': 0.87,
          'isPrimary': false
        },
        {
          'name': 'Lemforder',
          'email': 'info@lemforder.com',
          'price': 52.0,
          'leadTime': 5,
          'minOrderQty': 6,
          'reliabilityScore': 0.85,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Control Arm Bushings',
      'category': 'Suspension',
      'price': 40.0,
      'quantity': 10,
      'unit': 'Set',
      'isLowStock': false,
      'lowStockThreshold': 3,
      'suppliers': [
        {
          'name': 'Energy Suspension',
          'email': 'info@energysuspension.com',
          'price': 40.0,
          'leadTime': 4,
          'minOrderQty': 8,
          'reliabilityScore': 0.85,
          'isPrimary': true
        },
        {
          'name': 'Prothane',
          'email': 'info@prothane.com',
          'price': 38.0,
          'leadTime': 5,
          'minOrderQty': 10,
          'reliabilityScore': 0.83,
          'isPrimary': false
        },
        {
          'name': 'Moog',
          'email': 'info@moog.com',
          'price': 42.0,
          'leadTime': 4,
          'minOrderQty': 6,
          'reliabilityScore': 0.88,
          'isPrimary': false
        }
      ]
    },
    {
      'name': 'Trunks',
      'category': 'Body',
      'price': 350.0,
      'quantity': 5,
      'unit': 'Piece',
      'isLowStock': false,
      'lowStockThreshold': 2,
      'suppliers': [
        {
          'name': 'Replace',
          'email': 'info@replace.com',
          'price': 350.0,
          'leadTime': 8,
          'minOrderQty': 2,
          'reliabilityScore': 0.82,
          'isPrimary': true
        },
        {
          'name': 'Sherman',
          'email': 'info@sherman.com',
          'price': 340.0,
          'leadTime': 9,
          'minOrderQty': 2,
          'reliabilityScore': 0.80,
          'isPrimary': false
        },
        {
          'name': 'Goodmark',
          'email': 'info@goodmark.com',
          'price': 360.0,
          'leadTime': 7,
          'minOrderQty': 2,
          'reliabilityScore': 0.81,
          'isPrimary': false
        }
      ]
    },
  ];

  // Get supplier price comparison for procurement
  static List<Map<String, dynamic>> getSupplierPriceComparison(String partName,
      int requestedQuantity) {
    final part = defaultParts.firstWhere(
          (p) => p['name'] == partName,
      orElse: () => {},
    );

    if (part.isEmpty) return [];

    final suppliers = List<Map<String, dynamic>>.from(part['suppliers']);

    // Calculate total costs and actual quantities for each supplier
    for (var supplier in suppliers) {
      final price = supplier['price'] as double;
      final minOrderQty = supplier['minOrderQty'] as int;
      final actualQuantity = requestedQuantity < minOrderQty
          ? minOrderQty
          : requestedQuantity;

      supplier['requestedQuantity'] = requestedQuantity;
      supplier['actualQuantity'] = actualQuantity;
      supplier['totalCost'] = price * actualQuantity;
      supplier['unitPrice'] = price;
      supplier['excessQuantity'] = actualQuantity - requestedQuantity;
    }

    // Sort by total cost (cheapest first)
    suppliers.sort((a, b) =>
        (a['totalCost'] as double).compareTo(b['totalCost'] as double));

    return suppliers;
  }

  // Get procurement recommendation based on cost, lead time, and reliability
  static Map<String, dynamic> getProcurementRecommendation(String partName,
      int requestedQuantity, {
        double costWeight = 0.5,
        double leadTimeWeight = 0.3,
        double reliabilityWeight = 0.2,
      }) {
    final suppliers = getSupplierPriceComparison(partName, requestedQuantity);
    if (suppliers.isEmpty) return {};

    // Calculate scores for each supplier
    final maxCost = suppliers.map((s) => s['totalCost'] as double).reduce((a,
        b) => a > b ? a : b);
    final maxLeadTime = suppliers.map((s) => s['leadTime'] as int).reduce((a,
        b) => a > b ? a : b);

    for (var supplier in suppliers) {
      final costScore = maxCost > 0 ? 1 -
          ((supplier['totalCost'] as double) / maxCost) : 0.0;
      final leadTimeScore = maxLeadTime > 0 ? 1 -
          ((supplier['leadTime'] as int) / maxLeadTime) : 0.0;
      final reliabilityScore = supplier['reliabilityScore'] as double;

      supplier['costScore'] = costScore;
      supplier['leadTimeScore'] = leadTimeScore;
      supplier['overallScore'] = (costScore * costWeight) +
          (leadTimeScore * leadTimeWeight) +
          (reliabilityScore * reliabilityWeight);
    }

    // Sort by overall score (highest first)
    suppliers.sort((a, b) =>
        (b['overallScore'] as double).compareTo(a['overallScore'] as double));

    return {
      'partName': partName,
      'requestedQuantity': requestedQuantity,
      'supplierOptions': suppliers,
      'recommendedSupplier': suppliers.first,
      'costSavings': suppliers.length > 1
          ? (suppliers.last['totalCost'] - suppliers.first['totalCost'])
          : 0.0,
    };
  }

  // Generate procurement report for multiple parts
  static Map<String, dynamic> generateProcurementReport(
      Map<String, int> partRequests) {
    final recommendations = <String, dynamic>{};
    double totalCost = 0.0;
    final supplierBreakdown = <String, double>{};
    final consolidatedOrders = <String, List<Map<String, dynamic>>>{};

    partRequests.forEach((partName, quantity) {
      final recommendation = getProcurementRecommendation(partName, quantity);
      if (recommendation.isNotEmpty) {
        recommendations[partName] = recommendation;

        final recommendedSupplier = recommendation['recommendedSupplier'];
        final cost = recommendedSupplier['totalCost'] as double;
        final supplierName = recommendedSupplier['name'] as String;

        totalCost += cost;
        supplierBreakdown[supplierName] =
            (supplierBreakdown[supplierName] ?? 0.0) + cost;

        // Group by supplier for consolidated ordering
        consolidatedOrders.putIfAbsent(supplierName, () => []);
        consolidatedOrders[supplierName]!.add({
          'partName': partName,
          'quantity': recommendedSupplier['actualQuantity'],
          'unitPrice': recommendedSupplier['unitPrice'],
          'totalCost': cost,
          'leadTime': recommendedSupplier['leadTime'],
        });
      }
    });

    return {
      'recommendations': recommendations,
      'totalCost': totalCost,
      'supplierBreakdown': supplierBreakdown,
      'consolidatedOrders': consolidatedOrders,
      'totalParts': partRequests.length,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  // Fetches all inventory parts from Firestore
  Future<List<Map<String, dynamic>>> fetchAllInventoryParts() async {
    final snapshot = await _firestore.collection('inventory_parts').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Deletes all inventory parts for the given categories
  Future<void> deleteAllInventoryParts(List<String> categories) async {
    for (final category in categories) {
      await _firestore.collection('inventory_parts').doc(category).delete();
    }
  }

  // Upload enhanced parts with multiple suppliers to Firestore
  Future<void> uploadDefaultParts(
      List<Map<String, dynamic>> partsWithIds) async {
    // Group parts by category
    final Map<String, Map<String, dynamic>> categoryData = {};
    for (final part in partsWithIds) {
      final category = part['category'] as String;
      final partId = part['id'] as String;
      // Ensure 'name' field is always present in Firestore data
      final partData = Map<String, dynamic>.from(part);
      if (!partData.containsKey('name') || partData['name'] == null || partData['name'].toString().isEmpty) {
        partData['name'] = partId; // fallback to partId if name is missing
      }
      categoryData.putIfAbsent(category, () => {});
      categoryData[category]![partId] = partData;
    }

    // Upload each category document
    for (final entry in categoryData.entries) {
      await _firestore.collection('inventory_parts').doc(entry.key).set(
          entry.value);
    }
  }

  // Returns default parts with unique IDs
  static List<Map<String, dynamic>> getDefaultPartsWithIds() {
    int counter = 1;
    return defaultParts.map((part) {
      final newPart = Map<String, dynamic>.from(part);
      newPart['id'] = 'PRT${counter.toString().padLeft(3, '0')}';
      counter++;
      return newPart;
    }).toList();
  }

  // Get part details by ID including all supplier options
  static Map<String, dynamic>? getPartById(String partId) {
    final partsWithIds = getDefaultPartsWithIds();
    try {
      return partsWithIds.firstWhere((part) => part['id'] == partId);
    } catch (e) {
      return null;
    }
  }

  // Get parts that are low in stock for procurement planning
  static List<Map<String, dynamic>> getLowStockParts() {
    return getDefaultPartsWithIds().where((part) {
      final quantity = part['quantity'] as int;
      final threshold = part['lowStockThreshold'] as int;
      return quantity <= threshold;
    }).toList();
  }

  // Calculate optimal order quantities based on current stock and usage patterns
  static Map<String, int> calculateOptimalOrderQuantities(
      List<Map<String, dynamic>> lowStockParts) {
    final orderQuantities = <String, int>{};

    for (final part in lowStockParts) {
      final partName = part['name'] as String;
      final currentStock = part['quantity'] as int;
      final threshold = part['lowStockThreshold'] as int;
      final suppliers = List<Map<String, dynamic>>.from(part['suppliers']);

      // Find minimum order quantity among all suppliers
      final minOrderQtys = suppliers
          .map((s) => s['minOrderQty'] as int)
          .toList();
      final lowestMinOrder = minOrderQtys.reduce((a, b) => a < b ? a : b);

      // Calculate recommended order quantity (2x threshold or min order qty, whichever is higher)
      final recommendedQty = (threshold * 2 - currentStock);
      orderQuantities[partName] =
      recommendedQty > lowestMinOrder ? recommendedQty : lowestMinOrder;
    }

    return orderQuantities;
  }
}
