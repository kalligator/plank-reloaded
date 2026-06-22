using Plank;

namespace Docky {
  public class BluetoothSpeakerPreferences : DockItemPreferences {
    [Description (nick = "device-mac", blurb = "Bluetooth MAC address of the speaker (e.g. 50:1B:6A:AC:A1:20).")]
    public string DeviceMAC { get; set; default = ""; }

    [Description (nick = "device-name", blurb = "Display name for the speaker.")]
    public string DeviceName { get; set; default = "Bluetooth Speaker"; }

    [Description (nick = "pulse-sink", blurb = "PulseAudio/PipeWire sink name (e.g. bluez_output.50_1B_6A_AC_A1_20.1). Leave empty for auto-detect.")]
    public string PulseSink { get; set; default = ""; }

    [Description (nick = "auto-play", blurb = "Automatically resume media playback after connecting.")]
    public bool AutoPlay { get; set; default = true; }

    public BluetoothSpeakerPreferences.with_file (GLib.File file) {
      base.with_file (file);
    }

    protected override void reset_properties () {
      DeviceMAC = "";
      DeviceName = "Bluetooth Speaker";
      PulseSink = "";
      AutoPlay = true;
    }
  }
}
