#!/usr/bin/env bash

sudo apt install -y ffmpeg libx264-dev

ffmpeg -encoders
ffmpeg -decoders

sudo apt-get update && sudo apt-get install --yes \
    gstreamer1.0-plugins-{good,bad,ugly} \
    gstreamer1.0-{libav,tools}

# Sending h264 rtp stream
ffmpeg \
    -re \
    -fflags +genpts \
    -f video4linux2 \
    -input_format mjpeg \
    -i /dev/video0 \
    -c:v libx264 \
    -an \
    -f rtp \
    -sdp_file video.sdp \
    'rtp://127.0.0.1:5004?pkt_size=1200'

# Sending vp8 rtp stream
ffmpeg \
    -re \
    -fflags +genpts \
    -f video4linux2 \
    -i /dev/video0 \
    -c:v vp8 \
    -an \
    -f rtp \
    -sdp_file video.sdp \
    'rtp://127.0.0.1:5004?pkt_size=1200'

ffmpeg \
    -re \
    -fflags +genpts \
    -f video4linux2 \
    -i /dev/video0 \
    -c:v vp8 \
    -an \
    -f rtp \
    -sdp_file video.sdp \
    'rtp://127.0.0.1:5004?pkt_size=1200'

ffmpeg \
    -re \
    -fflags +genpts \
    -f video4linux2 \
    -input_format mjpeg \
    -i /dev/video0 \
    -c:v vp8 \
    -an \
    -f rtp \
    -sdp_file video.sdp \
    'rtp://127.0.0.1:5004'

ffmpeg \
    -re \
    -f video4linux2 \
    -input_format mjpeg \
    -i /dev/video0 \
    -c:v libx264 \
    -an \
    -f rtp_mpegts \
    -fec prompeg=l=20:d=5 \
    -sdp_file video.sdp \
    'rtp://127.0.0.1:5004'

# Listen for h264 rtp stream
ffplay \
    -protocol_whitelist file,rtp,udp \
    -i video.sdp

ffmpeg -f video4linux2 -framerate 30 -s 1280x720 -i "0" -vcodec libx264 -an -preset veryfast -f rtp rtp://127.0.0.1:5004

# Sending vp8 rtp stream
ffmpeg -re -f lavfi -i testsrc=size=640x480:rate=30 -vcodec libvpx -cpu-used 5 -deadline 1 -g 10 -error-resilient 1 -auto-alt-ref 1 -f rtp 'rtp://127.0.0.1:5004?pkt_size=1200'

# Listen for h264 rtp stream
gst-launch-1.0 udpsrc port=5004 caps=application/x-rtp,encode-name=H264 \
    ! rtph264depay ! avdec_h264 ! videoconvert ! autovideosink

# Listen for vp8 rtp stream
gst-launch-1.0 udpsrc port=5004 caps=application/x-rtp,encode-name=VP8 \
    ! rtpvp8depay ! avdec_vp8 ! videoconvert ! autovideosink

gst-launch-1.0 v4l2src ! video/x-raw,width=1280,height=720 ! videoconvert ! queue ! x264enc bitrate=500 speed-preset=veryfast tune=zerolatency ! video/x-h264,profile=baseline,stream-format=avc ! rtph264pay ! multiudpsink clients=127.0.0.1:5701,127.0.0.1:5700

gst-launch-1.0 v4l2src ! video/x-raw,width=1280,height=720 ! videoconvert ! queue ! vp8enc ! video/vp8,profile=baseline,stream-format=avc ! rtpvp8pay ! udpsink host=127.0.0.1 port=5004

gst-launch-1.0 -v v4l2src ! video/x-raw-yuv,width=640,height=480 ! vp8enc ! rtpvp8pay ! udpsink host=127.0.0.1 port=5004

gst-launch-1.0 udpsrc port=5005 caps=application/x-rtp,encode-name=H264 \
    ! rtph264depay ! avdec_h264 ! videoconvert ! autovideosink
