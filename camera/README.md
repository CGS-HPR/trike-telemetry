# HPR Trike Camera System — Production As-Built Guide

Real-time video streaming from trike-mounted cameras to a Home Assistant dashboard, with remote viewing over Tailscale (including 5G mobile networks).

**Pipeline:**
```
Camera → Raspberry Pi → go2rtc → Network (Tailscale/WiFi) → Home Assistant Dashboard
```

---

## Hardware Requirements

- Raspberry Pi 4
- 2 x USB cameras (front and rear)
- USB hub (if required)
- Power supply
- Network connectivity (WiFi or mobile hotspot via Tailscale)

---

## Files

| File | Deployed path | Purpose |
|------|--------------|---------|
| `camera/go2rtc.yaml` | `/opt/go2rtc/go2rtc.yaml` | go2rtc stream config |
| `camera/home_assistant_cameras.yaml` | HA dashboard card | Camera iframe cards |

---

## Deployment

### 1. Identify camera device paths

```sh
ls -l /dev/v4l/by-path/
```

Example output:
```
usb-0:1.4:1.0-video-index0 → ../../video0   # Front camera
usb-0:1.3:1.0-video-index0 → ../../video2   # Rear camera
```

Always use the `by-path` symlinks to ensure stable mapping after reboot.

### 2. Validate camera capabilities

```sh
v4l2-ctl -d /dev/videoX --list-formats-ext
```

Current findings:
- Front camera: MJPEG at fixed 30fps
- Rear camera: MJPEG with selectable frame rates

### 3. Install go2rtc

```sh
cd /tmp
wget https://github.com/AlexxIT/go2rtc/releases/latest/download/go2rtc_linux_arm64
chmod +x go2rtc_linux_arm64
sudo mv go2rtc_linux_arm64 /usr/local/bin/go2rtc
go2rtc --version
```

### 4. Deploy config

```sh
sudo mkdir -p /opt/go2rtc
sudo cp camera/go2rtc.yaml /opt/go2rtc/go2rtc.yaml
```

### 5. Enable and start service

```sh
sudo systemctl enable go2rtc
sudo systemctl start go2rtc
```

### 6. Add Home Assistant dashboard cards

Add the contents of `camera/home_assistant_cameras.yaml` as a new card in your HA dashboard, replacing `PI_IP` with the Pi's IP or Tailscale address.

---

## Testing Streams

Open the go2rtc web UI:
```
http://PI_IP:1984
```

Direct stream test URLs:
```
http://PI_IP:1984/stream.html?src=trike1_front_camera&mode=mjpeg
http://PI_IP:1984/stream.html?src=trike1_rear_camera&mode=mjpeg
```

---

## Recording

Create the recordings directory:
```sh
sudo mkdir -p /opt/hpr/trike1/cameras/recordings
```

Record front camera in 15-minute segments:
```sh
ffmpeg -rtsp_transport tcp \
  -i rtsp://127.0.0.1:8554/trike1_front_camera \
  -c copy -f segment -segment_time 900 -strftime 1 \
  /opt/hpr/trike1/cameras/recordings/front_%Y%m%d_%H%M%S.mkv
```

---

## Network Behaviour

| Network | Latency |
|---------|---------|
| LAN (WiFi) | Near real-time |
| Mobile hotspot (5G) | High — MJPEG is not designed for unstable networks |

---

## Troubleshooting

**Black screen in HA mobile app:**
- Known iframe limitation in the HA mobile app; use a browser instead

**Stream not found:**
- Config mismatch — verify stream names in `go2rtc.yaml` match the URLs

**Device busy:**
- Another process is accessing the camera; check with `fuser /dev/videoX`

**High latency:**
- MJPEG over mobile networks buffers heavily; see Future Improvements

---

## Future Improvements

- Replace cameras with native H264/RTSP models
- Switch to WebRTC for low latency
- Add automatic recording services
