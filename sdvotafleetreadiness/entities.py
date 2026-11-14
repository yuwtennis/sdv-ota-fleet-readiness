import datetime

from pydantic import BaseModel


class VehicleTelemetry(BaseModel):
    vehicle_id: str
    timestamp: str
    battery_soc: float
    speed_kph: float
    parking_brake_engaged: bool
    connectivity_online: bool
    signal_strength_dbm: float| None
    software_version: str
    ota_update_state: str
    region: str
