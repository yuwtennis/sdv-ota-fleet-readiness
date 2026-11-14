import os
import time

from google.cloud import pubsub_v1, bigquery

from sdvotafleetreadiness.entities import VehicleTelemetry


def test_pubsub_bq_subscription(cloud_dev_env_settings):
    msg = VehicleTelemetry(
        vehicle_id="1234567890",
        timestamp="2023-01-01T00:00:00Z",
        battery_soc=100,
        speed_kph=100,
        parking_brake_engaged=False,
        connectivity_online=True,
        signal_strength_dbm=None,
        software_version="2.3.0",
        ota_update_state="idle",
        region="Tokyo").model_dump_json().encode("utf-8")

    pubsub_client = pubsub_v1.PublisherClient()
    topic_path = pubsub_client.topic_path(
        os.environ['GOOGLE_PROJECT'],
        os.environ['PUBSUB_TOPIC_NAME'])

    pubsub_client.publish(topic_path, msg)
    time.sleep(10)
    bq_client = bigquery.Client()

    QUERY = f'SELECT vehicle_id FROM {os.environ["BQ_TABLE_ID"]} LIMIT 1'

    assert len([row  for row in bq_client.query(QUERY).result()]) > 0
