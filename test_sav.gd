extends SceneTree

func _init():
    var f = FileAccess.open("C:/Users/angel/AppData/Roaming/Godot/app_userdata/HO·MA·SIM/saves/hotel_43_auto_0.sav", FileAccess.READ)
    if not f:
        print("Could not open file")
        quit()
        return
        
    var data = f.get_var()
    if typeof(data) != TYPE_DICTIONARY:
        print("Data is not dictionary")
        quit()
        return
        
    var out = FileAccess.open("user://test_sav_out.txt", FileAccess.WRITE)
    var plots = data.get("plots", [])
    for p in plots:
        var rooms = p.get("rooms", [])
        for r in rooms:
            var rn = r.get("room_number", "Unknown")
            var traits = r.get("acquired_traits", "None")
            out.store_line("Room " + str(rn) + ": " + str(traits) + " (type: " + str(typeof(traits)) + ")")
            
    out.close()
    quit()
