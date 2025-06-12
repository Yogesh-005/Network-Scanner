import 'package:flutter/material.dart';
import 'package:network_tools/network_tools.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

void main() {
  runApp(const NetworkScannerApp());
}

class NetworkScannerApp extends StatelessWidget {
  const NetworkScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Network Scanner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const NetworkScannerHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DeviceInfo {
  final String ip;
  final String? hostname;
  final String osType;
  final IconData icon;
  final Color color;
  final String? matchedKeyword;

  DeviceInfo({
    required this.ip,
    this.hostname,
    required this.osType,
    required this.icon,
    required this.color,
    this.matchedKeyword,
  });
}

class NetworkScannerHome extends StatefulWidget {
  const NetworkScannerHome({super.key});

  @override
  State<NetworkScannerHome> createState() => _NetworkScannerHomeState();
}

class _NetworkScannerHomeState extends State<NetworkScannerHome> {
  List<DeviceInfo> _devices = [];
  List<DeviceInfo> _allDevices = [];
  bool _scanning = false;
  String _status = 'Idle';
  String _networkInfo = '';
  List<String> _keywords = [];
  bool _filteringEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadKeywords();
  }

  Future<void> _loadKeywords() async {
    try {
      final String yamlString = await rootBundle.loadString('assets/keywords.yaml');
      final dynamic yamlMap = loadYaml(yamlString);
      
      List<String> keywords = [];
      
      if (yamlMap['keywords'] != null) {
        keywords = List<String>.from(yamlMap['keywords']);
      }
      
      setState(() {
        _keywords = keywords;
      });
    } catch (e) {
      // If config file doesn't exist or has errors, use default keywords
      setState(() {
        _keywords = ['camera', 'iot', 'sensor', 'smart', 'test'];
      });
      print('Error loading keywords: $e');
    }
  }

  String? _checkForKeywordMatch(String? hostname) {
    if (hostname == null || hostname.isEmpty || _keywords.isEmpty) {
      return null;
    }

    final host = hostname.toLowerCase();
    
    for (var keyword in _keywords) {
      if (host.contains(keyword.toLowerCase())) {
        return keyword;
      }
    }
    
    return null;
  }

  void _toggleFiltering() {
    setState(() {
      _filteringEnabled = !_filteringEnabled;
      if (_filteringEnabled) {
        // Show only devices with matching keywords
        _devices = _allDevices.where((device) => device.matchedKeyword != null).toList();
      } else {
        // Show all devices
        _devices = List.from(_allDevices);
      }
    });
  }

  String _classifyOS(String? hostname, String ip) {
    if (hostname == null || hostname.isEmpty) {
      return 'Unknown';
    }

    final host = hostname.toLowerCase();
    
    // Common patterns for different OS types
    if (host.contains('android') || host.contains('droid')) {
      return 'Android';
    } else if (host.contains('iphone') || host.contains('ipad') || 
               host.contains('apple') || host.contains('mac') || 
               host.contains('macbook')) {
      return 'macOS/iOS';
    } else if (host.contains('windows') || host.contains('pc') || 
               host.contains('desktop') || host.contains('laptop')) {
      return 'Windows';
    } else if (host.contains('linux') || host.contains('ubuntu') || 
               host.contains('debian') || host.contains('centos') || 
               host.contains('fedora') || host.contains('arch') ||
               host.contains('raspberry') || host.contains('pi')) {
      return 'Linux';
    } else if (host.contains('router') || host.contains('gateway') || 
               host.contains('modem') || host.contains('ap-') ||
               host.contains('access-point')) {
      return 'Router/Gateway';
    } else if (host.contains('printer') || host.contains('canon') || 
               host.contains('hp') || host.contains('epson') ||
               host.contains('brother')) {
      return 'Printer';
    } else if (host.contains('tv') || host.contains('smart') || 
               host.contains('roku') || host.contains('chromecast') ||
               host.contains('fire')) {
      return 'Smart TV/Media';
    }
    
    return 'Unknown';
  }

  IconData _getOSIcon(String osType) {
    switch (osType) {
      case 'Windows':
        return Icons.desktop_windows;
      case 'macOS/iOS':
        return Icons.laptop_mac;
      case 'Linux':
        return Icons.terminal;
      case 'Android':
        return Icons.phone_android;
      case 'Router/Gateway':
        return Icons.router;
      case 'Printer':
        return Icons.print;
      case 'Smart TV/Media':
        return Icons.tv;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getOSColor(String osType) {
    switch (osType) {
      case 'Windows':
        return Colors.blue;
      case 'macOS/iOS':
        return Colors.grey;
      case 'Linux':
        return Colors.orange;
      case 'Android':
        return Colors.green;
      case 'Router/Gateway':
        return Colors.purple;
      case 'Printer':
        return Colors.brown;
      case 'Smart TV/Media':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _scanNetwork() async {
    setState(() {
      _devices.clear();
      _scanning = true;
      _status = 'Scanning...';
    });

    final info = NetworkInfo();
    final String? address = await info.getWifiIP();
    final String? wifiName = await info.getWifiName();
    final String? gatewayIP = await info.getWifiGatewayIP();
    
    if (address == null) {
      setState(() {
        _status = 'Unable to detect local IP!';
        _scanning = false;
      });
      return;
    }

    setState(() {
      _networkInfo = 'Network: ${wifiName ?? 'Unknown'}\n'
          'Your IP: $address\n'
          'Gateway: ${gatewayIP ?? 'Unknown'}';
    });

    final String subnet = address.substring(0, address.lastIndexOf('.'));

    final stream = HostScanner.getAllPingableDevices(
      subnet,
      firstHostId: 1,
      lastHostId: 254,
      progressCallback: (progress) {
        setState(() {
          _status = 'Scanning: $progress%';
        });
      },
    );

    List<DeviceInfo> devices = [];
    await for (final host in stream) {
      final hostName = await host.hostName;
      final osType = _classifyOS(hostName, host.address);
      final matchedKeyword = _checkForKeywordMatch(hostName);
      
      final deviceInfo = DeviceInfo(
        ip: host.address,
        hostname: hostName,
        osType: osType,
        icon: _getOSIcon(osType),
        color: _getOSColor(osType),
        matchedKeyword: matchedKeyword,
      );
      devices.add(deviceInfo);
    }

    // Sort devices by OS type and then by IP
    devices.sort((a, b) {
      int osCompare = a.osType.compareTo(b.osType);
      if (osCompare != 0) return osCompare;
      return a.ip.compareTo(b.ip);
    });

    setState(() {
      _allDevices = devices;
      if (_filteringEnabled) {
        _devices = devices.where((device) => device.matchedKeyword != null).toList();
      } else {
        _devices = devices;
      }
      _scanning = false;
      final totalDevices = _allDevices.length;
      final matchedDevices = _allDevices.where((d) => d.matchedKeyword != null).length;
      _status = 'Scan complete: $totalDevices device(s) found${matchedDevices > 0 ? ', $matchedDevices matching keywords' : ''}';
    });
  }

  Map<String, List<DeviceInfo>> _groupDevicesByOS() {
    Map<String, List<DeviceInfo>> grouped = {};
    for (var device in _devices) {
      if (!grouped.containsKey(device.osType)) {
        grouped[device.osType] = [];
      }
      grouped[device.osType]!.add(device);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedDevices = _groupDevicesByOS();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('LAN Scanner'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Network Info Card
            if (_networkInfo.isNotEmpty)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Network Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_networkInfo),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // Scan Button and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _scanning ? null : _scanNetwork,
                      icon: _scanning 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(_scanning ? 'Scanning...' : 'Scan Network'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _allDevices.isEmpty ? null : _toggleFiltering,
                      icon: Icon(_filteringEnabled ? Icons.filter_alt : Icons.filter_alt_off),
                      label: Text(_filteringEnabled ? 'Show All' : 'Filter Keywords'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _filteringEnabled ? Colors.orange : null,
                        foregroundColor: _filteringEnabled ? Colors.white : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showKeywordsConfig(context),
                      icon: const Icon(Icons.settings),
                      tooltip: 'Keywords Settings',
                    ),
                  ],
                ),
                if (_allDevices.where((d) => d.matchedKeyword != null).isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.search, size: 16),
                    label: Text('${_allDevices.where((d) => d.matchedKeyword != null).length} matches'),
                    backgroundColor: Colors.green.withOpacity(0.2),
                  ),
              ],
            ),
            Text(_status),
            const SizedBox(height: 16),

            // Devices List
            Expanded(
              child: _devices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _filteringEnabled ? Icons.filter_alt : Icons.devices, 
                            size: 64, 
                            color: Colors.grey
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filteringEnabled 
                                ? 'No devices found with matching keywords.\nTry "Show All" to see all devices.'
                                : 'No devices found.\nTap "Scan Network" to start.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: groupedDevices.length,
                      itemBuilder: (context, index) {
                        final osType = groupedDevices.keys.elementAt(index);
                        final devices = groupedDevices[osType]!;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // OS Category Header
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    _getOSIcon(osType),
                                    color: _getOSColor(osType),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$osType (${devices.length})',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _getOSColor(osType),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Devices in this category
                            ...devices.map((device) => Card(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              elevation: device.matchedKeyword != null ? 4 : 1,
                              color: device.matchedKeyword != null 
                                  ? Colors.green.withOpacity(0.05)
                                  : null,
                              child: Container(
                                decoration: device.matchedKeyword != null
                                    ? BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.green,
                                          width: 1,
                                        ),
                                      )
                                    : null,
                                child: ListTile(
                                  leading: Stack(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: device.color.withOpacity(0.1),
                                        child: Icon(
                                          device.icon,
                                          color: device.color,
                                        ),
                                      ),
                                      if (device.matchedKeyword != null)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 1),
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              size: 10,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          device.ip,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                      if (device.matchedKeyword != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'MATCH: ${device.matchedKeyword?.toUpperCase()}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        device.hostname?.isNotEmpty == true
                                            ? device.hostname!
                                            : 'Unknown hostname',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      if (device.matchedKeyword != null)
                                        Text(
                                          'Contains keyword: ${device.matchedKeyword}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Chip(
                                    label: Text(
                                      device.osType,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: device.color.withOpacity(0.1),
                                    side: BorderSide(color: device.color),
                                  ),
                                ),
                              ),
                            )).toList(),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showKeywordsConfig(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keywords Configuration'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Current keywords to search for:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (_keywords.isEmpty)
                const Text('No keywords configured.', style: TextStyle(color: Colors.grey))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _keywords.map((keyword) => Chip(
                    label: Text(keyword),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    side: const BorderSide(color: Colors.blue),
                  )).toList(),
                ),
              const SizedBox(height: 16),
              const Text(
                'Devices containing these keywords in their hostname will be displayed when filtering is enabled.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'To customize keywords, edit the assets/keywords.yaml file and restart the app.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}