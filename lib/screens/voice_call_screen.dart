import 'dart:async';
import 'dart:math';
import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class VoiceCallScreen extends StatefulWidget {
  final bool isVideoCall;
  const VoiceCallScreen({super.key, this.isVideoCall = false});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with SingleTickerProviderStateMixin {
  // Camera controllers
  CameraController? _frontCameraController;
  CameraController? _backCameraController;
  bool _camerasInitialized = false;
  bool _isUsingFrontCamera = true;
  late bool _videoEnabled;

  // Participants (mock)
  final List<Participant> _participants = [
    Participant(id: 'p1', name: 'You', color: Colors.teal),
    Participant(id: 'p2', name: 'Alex', color: Colors.blueGrey),
  ];

  String _mainParticipantId = 'p2'; // focused participant
  bool _focusMode = false; // focus toggle

  // Controls
  bool _speakerOn = true;

  // Reactions
  final List<_ReactionData> _reactions = [];

  // Animation controller for pulses
  late final AnimationController _pulseController;
  late final Timer _audioSimTimer;
  double _simulatedLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _videoEnabled = widget.isVideoCall;
    _initializeCameras();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _audioSimTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          _simulatedLevel = (0.2 + Random().nextDouble() * 0.8).clamp(0.0, 1.0);
        });
      }
    });
  }

  Future<void> _initializeCameras() async {
    try {
      final cameras = await availableCameras();

      // Find front and back cameras
      CameraDescription? frontCamera;
      CameraDescription? backCamera;

      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
        } else if (camera.lensDirection == CameraLensDirection.back) {
          backCamera = camera;
        }
      }

      // Initialize front camera first
      if (frontCamera != null) {
        _frontCameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _frontCameraController!.initialize();
      }

      // Initialize back camera
      if (backCamera != null) {
        _backCameraController = CameraController(
          backCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _backCameraController!.initialize();
      }

      if (mounted) {
        setState(() {
          _camerasInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing cameras: $e');
      // Even if cameras fail, we KEEP video enabled if it's a video call
      // as we want to show the PiP fallback UI.
      if (mounted) {
        setState(() {
          _camerasInitialized = false;
        });
      }
    }
  }

  Future<void> _retryCameraInitialization() async {
    // Dispose existing controllers first
    await _frontCameraController?.dispose();
    await _backCameraController?.dispose();
    _frontCameraController = null;
    _backCameraController = null;

    // Try to initialize again
    await _initializeCameras();

    if (_camerasInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera initialized successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _audioSimTimer.cancel();
    _pulseController.dispose();
    _frontCameraController?.dispose();
    _backCameraController?.dispose();
    super.dispose();
  }

  Participant get _mainParticipant =>
      _participants.firstWhere((p) => p.id == _mainParticipantId);

  CameraController? get _activeCameraController =>
      _isUsingFrontCamera ? _frontCameraController : _backCameraController;

  // Participant management
  void _addParticipant() async {
    final availableUsers = List.generate(
      10,
      (i) => 'User ${i + 1}',
    ).where((name) => !_participants.any((p) => p.name == name)).toList();

    if (availableUsers.isEmpty) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => ListView.builder(
        shrinkWrap: true,
        itemCount: availableUsers.length,
        itemBuilder: (ctx, i) {
          final name = availableUsers[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.primaries[i % Colors.primaries.length],
              child: Text(name[0]),
            ),
            title: Text(name),
            onTap: () => Navigator.pop(ctx, name),
          );
        },
      ),
    );

    if (selected != null) {
      final newP = Participant(
        id: 'p${_participants.length + 1}',
        name: selected,
        color: Colors
            .primaries[Random().nextInt(Colors.primaries.length)]
            .shade600,
      );
      setState(() {
        _participants.add(newP);
        _mainParticipantId = newP.id;
      });
    }
  }

  // Camera controls
  void _toggleCamera() {
    setState(() {
      _isUsingFrontCamera = !_isUsingFrontCamera;
    });
  }

  void _toggleVideo() {
    if (!_camerasInitialized) {
      // If cameras failed to initialize, show a message or try to re-initialize
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera not available. Check permissions or device compatibility.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _videoEnabled = !_videoEnabled;
    });
  }

  // Mute controls
  void _toggleSpeaker() => setState(() => _speakerOn = !_speakerOn);
  void _toggleSelfMute() {
    final p = _participants.firstWhere((p) => p.id == 'p1'); // self
    setState(() => p.mutedSelf = !p.mutedSelf);
  }

  void _adminToggleMute(String id) {
    if (id == 'p1') return; // cannot admin-mute self
    final p = _participants.firstWhere((p) => p.id == id);
    setState(() => p.mutedByAdmin = !p.mutedByAdmin);
  }

  void _toggleFocusMode() => setState(() => _focusMode = !_focusMode);

  void _sendReaction(String emoji) {
    final r = _ReactionData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      emoji: emoji,
      start: const Offset(0.85, 0.78),
      dxJitter: (Random().nextDouble() - 0.5) * 0.12,
    );
    setState(() => _reactions.add(r));
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() => _reactions.removeWhere((x) => x.id == r.id));
      }
    });
  }

  void _selectParticipant(String id) => setState(() => _mainParticipantId = id);

  @override
  Widget build(BuildContext context) {
    final main = _mainParticipant;
    final shortName = main.name.split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium Dark Navy
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.5),
                Colors.transparent,
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ColorFilter.mode(Colors.white.withOpacity(0.05), BlendMode.lighten),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: main.color,
                    child: Text(
                      shortName[0],
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        main.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Secure Connection',
                        style: TextStyle(color: Colors.cyanAccent, fontSize: 10, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                '00:12',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF071018),
                  Colors.blueGrey.shade900.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Video background (Remote Participant Mock)
          if (widget.isVideoCall)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E1E2E), // Modern Slate
                      Color(0xFF0F172A), // Deep Navy
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: main.color.withOpacity(0.3), width: 4),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: main.color.withOpacity(0.2),
                          child: Text(
                            shortName[0],
                            style: TextStyle(fontSize: 48, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        main.name,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w200, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 8,
                              height: 8,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.cyanAccent),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Waiting for video feed...',
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // Voice call background - Premium Gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      Color(0xFF1E293B),
                      Color(0xFF020617),
                    ],
                  ),
                ),
              ),
            ),

          // Local Self-view (picture-in-picture) - ALWAYS for video calls
          if (widget.isVideoCall)
            Positioned(
              top: 100, // Adjusted for AppBar
              right: 16,
              child: Hero(
                tag: 'self_view',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 130,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_videoEnabled &&
                              _camerasInitialized &&
                              _activeCameraController != null &&
                              _activeCameraController!.value.isInitialized)
                            FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width:
                                    _activeCameraController!.value.previewSize?.width ?? 100,
                                height:
                                    _activeCameraController!.value.previewSize?.height ?? 100,
                                child: CameraPreview(_activeCameraController!),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.teal.shade900, Colors.black],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _videoEnabled ? Icons.videocam_off : Icons.visibility_off,
                                      color: Colors.white38,
                                      size: 30,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('Me', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ),
                          
                          // Self indicator label - Glassy
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          // Camera switch button (only if video on and cameras ready)
                          if (_videoEnabled && _camerasInitialized)
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: _toggleCamera,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white12,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.cameraswitch_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // pulses/avatar for voice
          if (!widget.isVideoCall)
            Align(
              alignment: const Alignment(0, -0.12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        for (int i = 0; i < 3; i++)
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final t = _pulseController.value;
                              final phase = (i / 3 + t) % 1.0;
                              final base =
                                  1.0 +
                                  ((_mainParticipantMuted(main)
                                          ? 0.0
                                          : _simulatedLevel) *
                                      0.35);
                              final scale = base + phase * (0.9 + i * 0.2);
                              final opacity =
                                  (1.0 - phase).clamp(0.0, 1.0) * 0.25;
                              return Transform.scale(
                                scale: scale,
                                child: Opacity(
                                  opacity: opacity,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: main.color.withOpacity(0.9),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        // Main avatar
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: main.color,
                            boxShadow: [
                              BoxShadow(
                                color: main.color.withOpacity(0.25),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              shortName[0],
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // mic badge
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _mainParticipantMuted(main)
                                  ? Colors.redAccent
                                  : Colors.white12,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _mainParticipantMuted(main)
                                      ? Icons.mic_off
                                      : Icons.mic,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _mainParticipantMuted(main) ? 'Muted' : 'On',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Name + small status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        main.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _speakerOn ? Icons.volume_up : Icons.volume_off,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _speakerOn ? 'Speaker' : 'Earpiece',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Participants strip
          Positioned(
            left: 12,
            right: 12,
            bottom: 140,
            child: SizedBox(
              height: 110, // Increased height to prevent overflow
              child: Card(
                color: Colors.white12,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _participants.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final p = _participants[i];
                      final isMain = p.id == _mainParticipantId;
                      return GestureDetector(
                        onTap: () => _selectParticipant(p.id),
                        onLongPress: () {
                          if (p.id != 'p1') _adminToggleMute(p.id);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: isMain ? 90 : 80, // Slightly wider
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isMain
                                  ? Colors.cyanAccent
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  CircleAvatar(
                                    radius: isMain ? 22 : 20,
                                    backgroundColor: p.color,
                                    child: Text(
                                      p.name[0],
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (p.mutedByAdmin)
                                    const CircleAvatar(
                                      radius: 7,
                                      backgroundColor: Colors.redAccent,
                                      child: Icon(Icons.mic_off, size: 10),
                                    ),
                                  if (p.mutedSelf)
                                    const Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: CircleAvatar(
                                        radius: 7,
                                        backgroundColor: Colors.yellow,
                                        child: Icon(Icons.mic, size: 10),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 10, // Slightly smaller font to save space
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Reactions
          ..._reactions.map((r) {
            return _FloatingReactionWidget(key: ValueKey(r.id), data: r);
          }).toList(),

          // Bottom controls - Floating Glassy Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 30, left: 16, right: 16),
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ControlButton(
                                icon: _participants.first.mutedSelf
                                    ? Icons.mic_off_rounded
                                    : Icons.mic_rounded,
                                label: _participants.first.mutedSelf
                                    ? 'Unmute'
                                    : 'Mute',
                                onPressed: _toggleSelfMute,
                                active: _participants.first.mutedSelf,
                              ),
                              _ControlButton(
                                icon: _videoEnabled
                                    ? Icons.videocam_rounded
                                    : Icons.videocam_off_rounded,
                                label: _videoEnabled ? 'Video' : 'Off',
                                onPressed: _toggleVideo,
                                active: _videoEnabled,
                              ),
                              _ControlButton(
                                icon: _speakerOn
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                                label: 'Speaker',
                                onPressed: _toggleSpeaker,
                                active: _speakerOn,
                              ),
                            ],
                          ),
                        ),
                        // End Call Button - Standout
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Material(
                            color: Colors.redAccent.withOpacity(0.9),
                            shape: const CircleBorder(),
                            elevation: 8,
                            shadowColor: Colors.redAccent.withOpacity(0.5),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.of(context).pop(),
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Icon(
                                  Icons.call_end_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ControlButton(
                                icon: Icons.emoji_emotions_rounded,
                                label: 'React',
                                onPressed: () => _showReactionPicker(context),
                              ),
                              _ControlButton(
                                icon: Icons.group_add_rounded,
                                label: 'Add',
                                onPressed: _addParticipant,
                              ),
                              _ControlButton(
                                icon: _focusMode
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                label: 'Focus',
                                onPressed: _toggleFocusMode,
                                active: _focusMode,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _mainParticipantMuted(Participant p) => p.mutedByAdmin || p.mutedSelf;

  void _showReactionPicker(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) {
        final emojis = ['👍', '❤️', '😂', '🔥', '👏', '😮'];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: emojis.map((e) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _sendReaction(e);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class Participant {
  final String id;
  final String name;
  final Color color;
  bool mutedByAdmin;
  bool mutedSelf;

  Participant({
    required this.id,
    required this.name,
    required this.color,
    this.mutedByAdmin = false,
    this.mutedSelf = false,
  });
}

/// Small control button
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool active;
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active ? Colors.cyanAccent.withOpacity(0.14) : Colors.white10;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}

/// Reaction model
class _ReactionData {
  final String id;
  final String emoji;
  final Offset start;
  final double dxJitter;
  _ReactionData({
    required this.id,
    required this.emoji,
    required this.start,
    required this.dxJitter,
  });
}

class _FloatingReactionWidget extends StatefulWidget {
  final _ReactionData data;
  const _FloatingReactionWidget({required Key key, required this.data})
    : super(key: key);

  @override
  State<_FloatingReactionWidget> createState() =>
      _FloatingReactionWidgetState();
}

class _FloatingReactionWidgetState extends State<_FloatingReactionWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _dy;
  late final Animation<double> _opacity;
  late final double _startXFraction;

  @override
  void initState() {
    super.initState();
    _startXFraction = widget.data.start.dx + widget.data.dxJitter;

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _dy = Tween<double>(
      begin: 0,
      end: -180,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0)));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final startX = screen.width * _startXFraction;
    final startY = screen.height * widget.data.start.dy;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Positioned(
          left: startX,
          top: startY + _dy.value,
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.rotate(
              angle: (1 - _ctrl.value) * 0.12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.data.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Simulated camera preview for when real cameras aren't available
class _SimulatedCameraPreview extends StatefulWidget {
  final VoidCallback? onRetry;

  const _SimulatedCameraPreview({this.onRetry});

  @override
  State<_SimulatedCameraPreview> createState() =>
      _SimulatedCameraPreviewState();
}

class _SimulatedCameraPreviewState extends State<_SimulatedCameraPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _colorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF071018),
            Colors.blueGrey.shade900.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Simulated camera frame
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated waves
                      AnimatedBuilder(
                        animation: _colorAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 120 + (_colorAnimation.value * 40),
                            height: 120 + (_colorAnimation.value * 40),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.cyan.withOpacity(
                                  0.3 + _colorAnimation.value * 0.4,
                                ),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      ),
                      // User avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.teal,
                        ),
                        child: const Center(
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                      ),
                      // Recording indicator
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Camera Unavailable',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Showing simulated preview',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white12,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
