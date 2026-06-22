using Plank;

namespace Docky {
  public class BluetoothSpeakerDockItem : DockletItem {
    private const string ICON_CONNECTED = "audio-speakers";
    private const string ICON_DISCONNECTED = "audio-volume-muted-blocking-symbolic";
    private const uint POLL_INTERVAL = 3000000; // 3 seconds

    private bool disposed = false;
    private bool connected = false;

    private unowned BluetoothSpeakerPreferences prefs {
      get { return (BluetoothSpeakerPreferences) Prefs; }
    }

    public BluetoothSpeakerDockItem.with_dockitem_file (GLib.File file) {
      GLib.Object (Prefs: new BluetoothSpeakerPreferences.with_file (file));
    }

    construct {
      Icon = ICON_DISCONNECTED;
      Text = "Bluetooth Speaker (not configured)";
      start_monitor ();
    }

    ~BluetoothSpeakerDockItem () {
      disposed = true;
    }

    private string get_sink () {
      if (prefs.PulseSink != "")
        return prefs.PulseSink;
      // Auto-derive sink name from MAC: 50:1B:6A:AC:A1:20 -> bluez_output.50_1B_6A_AC_A1_20.1
      return "bluez_output." + prefs.DeviceMAC.replace (":", "_") + ".1";
    }

    private void start_monitor () {
      new Thread<void*> ("bt-speaker-monitor", () => {
        while (!disposed) {
          if (prefs.DeviceMAC != "")
            check_status ();
          Thread.usleep (POLL_INTERVAL);
        }
        return null;
      });
    }

    private void check_status () {
      try {
        string stdout_buf, stderr_buf;
        int exit_status;
        Process.spawn_command_line_sync (
          "bluetoothctl info " + prefs.DeviceMAC,
          out stdout_buf, out stderr_buf, out exit_status
        );
        var is_connected = stdout_buf.contains ("Connected: yes");

        Idle.add (() => {
          if (disposed) return false;
          if (connected != is_connected) {
            connected = is_connected;
            Icon = connected ? ICON_CONNECTED : ICON_DISCONNECTED;
            Text = connected
              ? "%s (Connected)".printf (prefs.DeviceName)
              : "%s (Disconnected)".printf (prefs.DeviceName);
            reset_icon_buffer ();
          }
          return false;
        });
      } catch (SpawnError e) {
        warning ("BT speaker status check failed: %s", e.message);
      }
    }

    private void run_command (string cmd) {
      new Thread<void*> ("bt-speaker-cmd", () => {
        try {
          string stdout_buf, stderr_buf;
          int exit_status;
          Process.spawn_command_line_sync (
            "bash -c '%s'".printf (cmd),
            out stdout_buf, out stderr_buf, out exit_status
          );
          check_status ();
        } catch (SpawnError e) {
          warning ("BT speaker command failed: %s", e.message);
        }
        return null;
      });
    }

    private string connect_cmd () {
      var sink = get_sink ();
      var cmd = "bluetoothctl connect " + prefs.DeviceMAC
        + " && for i in $(seq 20); do pactl list short sinks | grep -q " + sink + " && break; sleep 0.2; done"
        + " && pactl set-default-sink " + sink;
      if (prefs.AutoPlay)
        cmd += " && playerctl play";
      return cmd;
    }

    protected override AnimationType on_clicked (PopupButton button, Gdk.ModifierType mod, uint32 event_time) {
      if (button == PopupButton.LEFT && prefs.DeviceMAC != "") {
        if (connected) {
          run_command ("bluetoothctl disconnect " + prefs.DeviceMAC);
        } else {
          run_command (connect_cmd ());
        }
        return AnimationType.BOUNCE;
      }
      return AnimationType.NONE;
    }

    public override Gee.ArrayList<Gtk.MenuItem> get_menu_items () {
      var items = new Gee.ArrayList<Gtk.MenuItem> ();

      if (prefs.DeviceMAC == "") {
        var hint = new Gtk.MenuItem.with_label ("Edit ~/.config/plank/dock1/launchers/bluetooth-speaker.dockitem to configure");
        hint.sensitive = false;
        items.add (hint);
        return items;
      }

      if (connected) {
        var disconnect_item = create_menu_item ("Disconnect", "network-disconnect");
        disconnect_item.activate.connect (() => {
          run_command ("bluetoothctl disconnect " + prefs.DeviceMAC);
        });
        items.add (disconnect_item);

        var reconnect_item = create_menu_item ("Reconnect", "view-refresh");
        reconnect_item.activate.connect (() => {
          run_command ("bluetoothctl disconnect " + prefs.DeviceMAC + " && sleep 1 && " + connect_cmd ());
        });
        items.add (reconnect_item);
      } else {
        var connect_item = create_menu_item ("Connect", "network-wireless");
        connect_item.activate.connect (() => {
          run_command (connect_cmd ());
        });
        items.add (connect_item);
      }

      return items;
    }

    private Gtk.MenuItem create_menu_item (string label, string icon_name) {
      var item = new Gtk.ImageMenuItem.with_label (label);
      item.set_image (new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.MENU));
      item.always_show_image = true;
      return item;
    }
  }
}
