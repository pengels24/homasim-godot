extends SceneTree

func _init():
    var cfg = ConfigFile.new()
    var err = cfg.load("C:/Users/angel/AppData/Roaming/Godot/app_userdata/HO·MA·SIM/hotels/hotel_43.cfg")
    if err != OK:
        print("Failed to load")
        quit()
        return
        
    var out = FileAccess.open("res://out_cfg.txt", FileAccess.WRITE)
    var plots = cfg.get_value("hotel", "plots", [])
    var found = false
    for p in plots:
        var rooms = p.get("rooms", [])
        for r in rooms:
            if r.get("room_number") == "P0001":
                out.store_line("CFG READ P0001 traits: " + str(r.get("acquired_traits")))
                found = true
    if not found:
        out.store_line("P0001 not found")
    out.close()
        
    quit()
