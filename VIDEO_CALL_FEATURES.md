# Video Call Features Documentation

## Overview
The voice call screen has been enhanced with full video calling capabilities, including self-view (picture-in-picture) functionality.

## New Features Added

### 1. Camera Integration
- **Front and Back Camera Support**: Automatically detects and initializes both front and back cameras
- **Camera Switching**: Toggle between front and back cameras during the call
- **Real-time Preview**: Live camera feed displayed during video calls

### 2. Video Call Interface
- **Main Video Feed**: Full-screen video display of the active camera
- **Self-View (Picture-in-Picture)**: Small preview window showing your own camera feed in the top-right corner
- **Video Toggle**: Enable/disable video during calls while keeping audio active

### 3. Enhanced Controls
New video-related buttons added to the control bar:
- **Video Button**: Toggle video on/off (videocam/videocam_off icons)
- **Camera Switch**: Button in the self-view to switch between front/back cameras

### 4. Visual Indicators
- **"You" Label**: Clearly marked self-view window
- **Camera Status**: Visual feedback for camera switching
- **Video State**: Clear indication when video is enabled/disabled

## Technical Implementation

### Dependencies Added
```yaml
camera: ^0.10.6
```

### Permissions Added
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.front" android:required="false" />
```

### Key Components

#### Camera Initialization
- Asynchronously initializes both front and back cameras
- Handles camera availability gracefully
- Supports fallback to audio-only mode when cameras aren't available

#### Self-View Window
- Positioned in top-right corner
- 120x160 pixels with rounded corners
- Includes camera switch button overlay
- Shows "You" label for clear identification

#### Video States
1. **Video Enabled**: Full camera preview with self-view overlay
2. **Video Disabled**: Falls back to original avatar-based interface
3. **Cameras Unavailable**: Graceful degradation to audio-only mode

## User Experience

### During Video Calls
- See yourself in the picture-in-picture window
- Switch cameras by tapping the camera icon in self-view
- Toggle video on/off using the video button
- Maintain all existing voice call features

### Camera Switching
- Tap the camera switch icon in the self-view window
- Smooth transition between front and back cameras
- Visual feedback during switching

### Fallback Behavior
- If cameras fail to initialize, the app continues as audio-only
- Video button allows switching between video and audio modes
- All existing call controls remain functional

## Files Modified

1. **`lib/screens/voice_call_screen.dart`** - Enhanced with video capabilities
2. **`pubspec.yaml`** - Added camera dependency
3. **`android/app/src/main/AndroidManifest.xml`** - Added camera permissions

## Usage Instructions

### Starting a Video Call
1. Navigate to the call screen
2. Video is enabled by default (if cameras are available)
3. Your camera feed appears as full background with self-view overlay

### Controlling Video
- **Toggle Video**: Press the video button (videocam icon)
- **Switch Cameras**: Tap the camera switch icon in your self-view
- **Mute Audio**: Use existing mute controls
- **End Call**: Press the red call end button

### Self-View Features
- Always shows your current camera feed
- Displays "You" label for identification
- Contains camera switching button
- Maintains aspect ratio of your video feed

## Error Handling

The implementation includes robust error handling:
- Camera initialization failures don't crash the app
- Falls back to audio-only mode gracefully
- Provides visual feedback for all states
- Maintains all existing functionality

## Performance Considerations

- Uses medium resolution preset for balanced quality/performance
- Efficient camera controller management
- Proper disposal of camera resources
- Smooth animations and transitions

This enhancement transforms the voice call into a full video calling experience while maintaining backward compatibility with audio-only scenarios.