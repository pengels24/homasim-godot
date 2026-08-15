extends SceneTree

func _init():
    var out = FileAccess.open("d:/game-dev/homasim-godot/test_split.txt", FileAccess.WRITE)
    var s = "wlan,klima"
    var arr = s.split(",")
    out.store_line("TYPEOF: " + str(typeof(arr)))
    out.store_line("TYPE_PACKED_STRING_ARRAY: " + str(TYPE_PACKED_STRING_ARRAY))
    
    var acquired = []
    if typeof(arr) == TYPE_ARRAY or typeof(arr) == TYPE_PACKED_STRING_ARRAY:
        for t in arr:
            acquired.append(str(t))
    out.store_line("ACQUIRED: " + str(acquired))
    
    # Test spaces
    var s2 = "wlan, klima"
    var arr2 = s2.split(",")
    out.store_line("SPLIT2: " + str(arr2))
    
    out.close()
    quit()
