#!/usr/bin/env python3
import json,time,datetime,gps
import paho.mqtt.client as mqtt

MQTT_HOST="100.109.71.98"
MQTT_PORT=1883
MQTT_USER="mqtt_hpv"
MQTT_PASS="mqtt_hpv"
MQTT_TOPIC="hpr/trike1/nav"

session=gps.gps(mode=gps.WATCH_ENABLE|gps.WATCH_NEWSTYLE)
client=mqtt.Client()
client.username_pw_set(MQTT_USER,MQTT_PASS)

mqtt_connected=False
last_publish=0

def on_connect(c,u,f,rc):
    global mqtt_connected
    mqtt_connected=(rc==0)

def on_disconnect(c,u,rc):
    global mqtt_connected
    mqtt_connected=False

client.on_connect=on_connect
client.on_disconnect=on_disconnect

def ensure_mqtt():
    global mqtt_connected
    while not mqtt_connected:
        try:
            client.connect(MQTT_HOST,1883,60)
            client.loop_start()
            time.sleep(2)
        except:
            time.sleep(5)

while True:
    try:
        if not mqtt_connected:
            ensure_mqtt()

        r=session.next()
        now=time.time()

        if r["class"]=="TPV":
            if now-last_publish>=0.1:
                payload={
                    "ts":datetime.datetime.now(datetime.UTC).isoformat(),
                    "lat":getattr(r,"lat",None),
                    "lon":getattr(r,"lon",None),
                    "speed_kmh":round(getattr(r,"speed",0)*3.6,2)
                }
                client.publish(MQTT_TOPIC,json.dumps(payload))
                last_publish=now
    except:
        time.sleep(1)
