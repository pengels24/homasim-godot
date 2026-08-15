extends SceneTree

func _init():
    var cfg = ConfigFile.new()
    cfg.set_value("test", "arr", [{"acquired_traits": JSON.stringify(["wlan", "klima"])}])
    cfg.save("user://test_cfg.ini")
    
    var cfg2 = ConfigFile.new()
    cfg2.load("user://test_cfg.ini")
    var arr = cfg2.get_value("test", "arr")
    var s = arr[0]["acquired_traits"]
    
    var out = FileAccess.open("res://out_json.txt", FileAccess.WRITE)
    out.store_line("STRING: " + s)
    var p = JSON.parse_string(s)
    out.store_line("PARSED TYPE: " + str(typeof(p)))
    out.store_line("PARSED: " + str(p))
    out.close()
    
    quit()
