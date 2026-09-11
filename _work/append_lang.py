import sys

def append():
    with open('d:/game-dev/homasim-godot/translations/language.csv', 'a', encoding='utf-8') as f:
        f.write('event.gourmet.stars_gained.desc,Glückwunsch! Der Inspektor war begeistert.,Congratulations! The inspector was thrilled.\n')
        f.write('event.gourmet.stars_lost.desc,Der Inspektor war enttäuscht. Ein Stern wurde abgezogen!,The inspector was disappointed. One star was revoked!\n')
        f.write('event.gourmet.max_stars,"Der Inspektor war da, aber es gibt keine weiteren Sterne zu vergeben.","The inspector visited, but no further stars can be awarded."\n')
        f.write('event.gourmet.gained_toast,Gourmet-Stern erhalten!,Gourmet Star achieved!\n')
        f.write('event.gourmet.lost_toast,"Der Inspektor war zutiefst enttäuscht. Das Hotel verliert einen Stern!","The inspector was deeply disappointed. The hotel loses a star!"\n')
        f.write('event.gourmet.failed_toast,"Der Inspektor war nicht vollends überzeugt. Verbessere den Service und die Sauberkeit!","The inspector wasn\'t fully convinced. Improve service and cleanliness!"\n')

append()
