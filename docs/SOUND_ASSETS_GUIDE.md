# QuietCheck Sound Assets

## Directory Structure

```
assets/sounds/
├── default/
│   ├── soft.mp3
│   ├── moderate.mp3
│   └── critical.mp3
├── nature/
│   ├── soft.mp3
│   ├── moderate.mp3
│   └── critical.mp3
└── ambient/
    ├── soft.mp3
    ├── moderate.mp3
    └── critical.mp3
```

## Sound Requirements

### Technical Specifications
- Format: MP3 (128kbps)
- Duration: <2 seconds
- Sample Rate: 44.1kHz
- Channels: Stereo
- Volume: Normalized to -3dB peak

### Sound Characteristics

#### Soft (Low Mental Load)
- Gentle bell or chime
- Frequency: 440-880 Hz
- Attack: Slow (200ms)
- Decay: Long (1.5s)
- Character: Calming, non-startling

#### Moderate (Medium Mental Load)
- Ambient pad or soft tone
- Frequency: 220-440 Hz
- Attack: Medium (100ms)
- Decay: Medium (1s)
- Character: Attention-getting but gentle

#### Critical (High Mental Load)
- Low-frequency calming tone
- Frequency: 110-220 Hz
- Attack: Immediate (50ms)
- Decay: Short (800ms)
- Character: Distinct but not alarming

## Sound Packs

### Default Pack
- Soft: Tibetan singing bowl (single strike)
- Moderate: Crystal bowl (medium tone)
- Critical: Deep gong (controlled strike)

### Nature Pack
- Soft: Wind chimes (gentle breeze)
- Moderate: Rain on leaves (medium intensity)
- Critical: Ocean wave (single wave)

### Ambient Pack
- Soft: Soft synth pad (rising tone)
- Moderate: Ambient bell (medium resonance)
- Critical: Deep bass tone (calming frequency)

## Licensing

All sounds must be:
- Royalty-free or properly licensed
- Cleared for commercial use
- Attributed if required by license

## Recommended Sources

1. **Freesound.org** (CC0 or CC-BY licensed)
2. **Zapsplat.com** (Free for commercial use)
3. **Soundbible.com** (Public domain)
4. **Custom creation** using tools like:
   - Audacity (free)
   - GarageBand (macOS/iOS)
   - FL Studio (paid)

## Implementation Notes

- Sounds are bundled with the app (no network required)
- Fallback to default pack if selected pack unavailable
- Volume controlled by user settings (0-100%)
- Respects system volume and Do Not Disturb settings
- Plays through notification audio channel

## Testing Checklist

- [ ] All sounds play correctly on Android
- [ ] All sounds play correctly on iOS
- [ ] Sounds respect user volume settings
- [ ] Sounds respect Do Not Disturb mode
- [ ] Sounds work offline
- [ ] Fallback to default pack works
- [ ] Sound duration <2 seconds
- [ ] No clipping or distortion
- [ ] Appropriate for mental wellness context

## Placeholder Instructions

Until actual sound files are created:

1. Create placeholder MP3 files (silent or simple tones)
2. Place in correct directory structure
3. Update pubspec.yaml to include assets
4. Test sound system with placeholders
5. Replace with final sounds before production release

## Asset Declaration (pubspec.yaml)

```yaml
flutter:
  assets:
    - assets/sounds/default/
    - assets/sounds/nature/
    - assets/sounds/ambient/
```