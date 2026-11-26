"""
Edge telemetry simulator for the OTA eligibility / fleet readiness demo (#3).

Generates realistic vehicle-state payloads (VSS-inspired schema) for a
simulated fleet, mimicking what a TCU/gateway would publish from the edge.

Usage:
    python edge_telemetry_simulator.py --mode file --count 500
    python edge_telemetry_simulator.py --mode pubsub --project my-gcp-project --topic vehicle-telemetry --interval 2

Output modes:
    file   -> writes newline-delimited JSON (JSONL) to sample_telemetry.jsonl
    stdout -> prints JSON payloads, one per line
    pubsub -> publishes to a GCP Pub/Sub topic (requires google-cloud-pubsub)
"""

import argparse
import json
import random
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import paho.mqtt.client as client
from sdvotafleetreadiness.entities import VehicleTelemetry

sys.path.append(f"{Path(__file__).parent.parent}/sdvotafleetreadiness")


REGIONS = ["JP-13", "JP-27", "JP-01", "JP-40"]
SOFTWARE_VERSIONS = ["2.3.0", "2.4.0", "2.4.1"]
VEHICLE_ID = "vehicle-ebd0f954-082a-438d-beea-0850826d5908"


def make_vehicle_fleet(size: int) -> list[dict[str, Any]]:
    """Create a fixed fleet of vehicle IDs with stable baseline characteristics."""
    fleet = []
    for _ in range(size):
        fleet.append({
            "vehicle_id": VEHICLE_ID,
            "region": random.choice(REGIONS),
            "software_version": random.choice(SOFTWARE_VERSIONS),
            # each vehicle has a "personality" affecting how likely it is to be eligible
            "battery_bias": random.uniform(-15, 15),
            "connectivity_reliability": random.uniform(0.6, 0.99),
        })
    return fleet


def generate_reading(vehicle: dict) -> VehicleTelemetry:
    """Generate one telemetry payload for a vehicle at the current moment."""
    battery_soc = max(5, min(100, 60 + vehicle["battery_bias"] + random.uniform(-10, 10)))
    is_parked = random.random() < 0.4  # most snapshots: vehicle is in use
    speed_kph = 0 if is_parked else round(random.uniform(5, 100), 1)
    is_online = random.random() < vehicle["connectivity_reliability"]
    signal_strength = round(random.uniform(-95, -50), 1) if is_online else None

    # OTA update state transitions loosely based on eligibility
    if is_parked and is_online and battery_soc > 40:
        ota_state = random.choices(
            ["idle", "downloading", "staged", "verifying"],
            weights=[0.7, 0.15, 0.1, 0.05],
        )[0]
    else:
        ota_state = "idle"

    return VehicleTelemetry(
        vehicle_id=vehicle["vehicle_id"],
        timestamp=datetime.now(timezone.utc).isoformat(),
        battery_soc=round(battery_soc, 1),
        speed_kph=speed_kph,
        parking_brake_engaged=is_parked,
        connectivity_online=is_online,
        signal_strength_dbm=signal_strength,
        software_version=vehicle["software_version"],
        ota_update_state=ota_state,
        region=vehicle["region"],
    )


def run_file(fleet: list[dict[str, Any]], count, path="sample_telemetry.jsonl"):
    with open(path, "w") as f:
        for _ in range(count):
            vehicle = random.choice(fleet)
            f.write(generate_reading(vehicle).model_dump_json() + "\n")
            print(f"Wrote {count} readings to {path}")


def run_stdout(fleet: list[dict[str, Any]], count, interval):
    for _ in range(count):
        vehicle = random.choice(fleet)
        print(generate_reading(vehicle).model_dump_json())
        if interval:
            time.sleep(interval)


def run_pubsub(
        fleet: list[dict[str, Any]],
        count: int,
        interval: int,
        host: str,
        topic: str):

    mqttc = client.Client()

    for _ in range(count):
        vehicle = random.choice(fleet)
        payload: VehicleTelemetry = generate_reading(vehicle)
        mqttc.connect(
            host,
            1883,
            60)
        mqttc.publish(topic, payload.model_dump_json())
        print(f"Published: {payload.vehicle_id} @ {payload.timestamp}")
        if interval:
            time.sleep(interval)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Simulate OTA eligibility telemetry from a vehicle fleet")
    parser.add_argument("--mode", choices=["file", "stdout", "mqtt"], default="file")
    parser.add_argument("--fleet-size", type=int, default=25)
    parser.add_argument("--count", type=int, default=200, help="number of readings to generate")
    parser.add_argument("--interval", type=float, default=0, help="seconds between readings (stdout/pubsub)")
    parser.add_argument("--host", type=str, help="Mosquitto host")
    args = parser.parse_args()

    fleet = make_vehicle_fleet(args.fleet_size)

    if args.mode == "file":
        run_file(fleet, args.count)
    elif args.mode == "stdout":
        run_stdout(fleet, args.count, args.interval)
    elif args.mode == "mqtt":
        run_pubsub(fleet, args.count, args.interval, args.host, f"out/state")