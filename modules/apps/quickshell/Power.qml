pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
  id: power

  readonly property var device: UPower.displayDevice
  readonly property bool hasBattery: device !== null && device.ready && device.isLaptopBattery
  // UPowerDevice.percentage is a 0-1 fraction (energy / energyCapacity), so it
  // is scaled here: every consumer treats this value as 0-100.
  readonly property real percent: power.hasBattery ? device.percentage * 100 : 0

  property bool awake: false
  property int awakeMinutes: 60
  property double awakeUntil: 0
  property double now: Date.now()

  readonly property bool awakeActive: power.awake && (power.awakeMinutes === 0 || power.now < power.awakeUntil)

  readonly property string awakeSummary: {
    if (!power.awakeActive)
      return "Off";
    if (power.awakeMinutes === 0)
      return "Until turned off";
    const remaining = Math.max(0, power.awakeUntil - power.now);
    const minutes = Math.floor(remaining / 60000);
    const hours = Math.floor(minutes / 60);
    const rest = minutes % 60;
    if (hours > 0)
      return rest > 0 ? hours + " h " + rest + " min left" : hours + " h left";
    return rest + " min left";
  }

  readonly property string batteryState: {
    if (!power.hasBattery)
      return "No battery";
    switch (device.state) {
    case UPowerDeviceState.Charging:
      return "Charging";
    case UPowerDeviceState.Discharging:
      return "On battery";
    case UPowerDeviceState.Empty:
      return "Battery empty";
    case UPowerDeviceState.FullyCharged:
      return "Fully charged";
    case UPowerDeviceState.PendingCharge:
      return "Waiting to charge";
    case UPowerDeviceState.PendingDischarge:
      return "Waiting to discharge";
    default:
      return "Battery state unknown";
    }
  }

  readonly property string batteryTime: {
    if (!power.hasBattery)
      return "";
    const seconds = device.state === UPowerDeviceState.Charging ? device.timeToFull : device.timeToEmpty;
    if (!isFinite(seconds) || seconds <= 0)
      return "";
    const total = Math.round(seconds / 60);
    const hours = Math.floor(total / 60);
    const minutes = total % 60;
    if (hours > 0)
      return minutes > 0 ? "About " + hours + " h " + minutes + " min" : "About " + hours + " h";
    return "About " + minutes + " min";
  }

  readonly property bool charging: power.hasBattery && device.state === UPowerDeviceState.Charging
  // UPower reports this for the whole system, so it is only meaningful as a
  // "connected to DC" signal once a battery has been found.
  readonly property bool pluggedIn: power.hasBattery && !UPower.onBattery

  readonly property bool performanceAvailable: PowerProfiles.hasPerformanceProfile
  readonly property int profile: PowerProfiles.profile
  readonly property int degradationReason: PowerProfiles.degradationReason

  // On a desktop without a battery the bar entry still has to communicate
  // power-profile control rather than charge.
  readonly property string indicatorIcon: {
    if (power.hasBattery) {
      if (power.charging)
        return "batteryCharging";
      return power.pluggedIn ? "plug" : "battery";
    }
    switch (power.profile) {
    case PowerProfile.Performance:
      return "profilePerformance";
    case PowerProfile.PowerSaver:
      return "profilePowerSaver";
    default:
      return "profileBalanced";
    }
  }

  function setProfile(profile) {
    PowerProfiles.profile = profile;
  }

  function setAwake(enabled, minutes) {
    power.awake = enabled;
    power.awakeMinutes = minutes;
    power.now = Date.now();
    power.awakeUntil = enabled && minutes > 0 ? power.now + minutes * 60000 : 0;
  }

  function profileName(profile) {
    switch (profile) {
    case PowerProfile.PowerSaver:
      return "Power saver";
    case PowerProfile.Performance:
      return "Performance";
    default:
      return "Balanced";
    }
  }

  Timer {
    interval: 15000
    running: true
    repeat: true
    onTriggered: {
      power.now = Date.now();
      if (power.awake && power.awakeMinutes > 0 && power.now >= power.awakeUntil)
        power.awake = false;
    }
  }
}
