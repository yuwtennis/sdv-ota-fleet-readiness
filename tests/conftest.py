import os

import pytest

@pytest.fixture
def cloud_dev_env_settings(monkeypatch: pytest.MonkeyPatch):
    monkeypatch.setenv("GOOGLE_PROJECT", os.getenv("GOOGLE_PROJECT", "default"))
    monkeypatch.setenv("PUBSUB_TOPIC_NAME",'vehicle-state-topic')
    monkeypatch.setenv("BQ_TABLE_ID", f"{os.environ['GOOGLE_PROJECT']}.sdv_ota_fleet_readiness.vehicle_telemetry")