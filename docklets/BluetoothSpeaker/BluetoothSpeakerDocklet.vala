public static void docklet_init (Plank.DockletManager manager) {
  manager.register_docklet (typeof (Docky.BluetoothSpeakerDocklet));
}

namespace Docky {
  public class BluetoothSpeakerDocklet : Object, Plank.Docklet {
    private const string ID = "bluetooth-speaker";
    private const string ICON = "audio-speakers";

    public unowned string get_id () { return ID; }
    public unowned string get_name () { return "Bluetooth Speaker"; }
    public unowned string get_description () { return "Connect/disconnect a Bluetooth speaker with status indicator"; }
    public unowned string get_icon () { return ICON; }
    public bool is_supported () { return true; }

    public Plank.DockElement make_element (string launcher, GLib.File file) {
      return new BluetoothSpeakerDockItem.with_dockitem_file (file);
    }
  }
}
