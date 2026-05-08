## D-A-CH Namensdatenbank für die Gast-Generierung.
## Quelle: _dev/docs/wiki/data/guests/Namensgebung/
class_name NameDatabase

const FIRST_NAMES_M: Array[String] = [
	"Paul", "Leon", "Finn", "Luca", "Elias", "Ben", "Felix", "Maximilian",
	"Julian", "Tim", "Noah", "Jonas", "David", "Simon", "Jan", "Niklas",
	"Moritz", "Alexander", "Fabian", "Daniel", "Samuel", "Lukas", "Adrian",
	"Anton", "Benedikt", "Christian", "Dominik", "Florian", "Johannes",
	"Manuel", "Matthias", "Raphael", "Sebastian", "Tobias", "Valentin",
	"Klaus", "Thomas", "Andreas", "Christoph", "Franz", "Helmut", "Josef",
	"Karl", "Martin", "Peter", "Robert", "Stefan", "Werner", "Jens",
	"Marco", "Marc", "Nico", "Oliver", "Pascal", "Robin", "Sven", "Timo",
	"Dennis", "Frederik", "Georg", "Kai", "Lennart", "Marcel", "Marius",
	"Nils", "Roman", "Sascha", "Vincent", "Kevin", "Lars", "Joel", "Levin",
	"Philip", "Arthur", "Aaron", "Konrad", "Oskar", "Quentin", "Theodor",
	"Wilhelm", "Yannick", "Bernhard", "Eberhard", "Manfred", "Norbert",
	"Rainer", "Siegfried", "Volker", "Wolfgang", "Beat", "Damian", "Janick",
	"Silvan", "Benno", "Fabio", "Gian", "Timon", "Dario", "Fabrizio",
	"Sandro", "Bruno", "Cornelius", "Enrico", "Hannes", "Ingmar", "Kilian",
	"Ole", "Thore", "Wenzel", "Armin",
]

const FIRST_NAMES_W: Array[String] = [
	"Anna", "Lena", "Sophie", "Marie", "Laura", "Hanna", "Lisa", "Julia",
	"Mia", "Emma", "Lea", "Sarah", "Pia", "Lina", "Nele", "Clara",
	"Johanna", "Theresa", "Isabelle", "Pauline", "Charlotte", "Amelie",
	"Frieda", "Greta", "Ida", "Mathilda", "Ella", "Marlene", "Helena",
	"Victoria", "Antonia", "Carla", "Luisa", "Magdalena", "Franziska",
	"Katharina", "Sabine", "Ursula", "Cornelia", "Diana", "Ingrid",
	"Miriam", "Patricia", "Tamara", "Veronika", "Yvonne", "Jasmin",
	"Elena", "Chiara", "Isabella", "Jana", "Larissa", "Melina", "Nadia",
	"Stella", "Vanessa", "Daniela", "Leonie", "Sandra", "Stefanie",
	"Michelle", "Jessica", "Nicole", "Bianca", "Celine", "Fiona", "Kira",
	"Nadine", "Ramona", "Sabrina", "Astrid", "Beatrix", "Cecilia",
	"Dorothea", "Eleonore", "Friederike", "Hedwig", "Irmgard", "Luise",
	"Rosalie", "Sibylle", "Agnes", "Barbara", "Esther", "Gloria", "Judith",
	"Klara", "Lydia", "Naomi", "Olga", "Rahel", "Wanda", "Aurora",
	"Delia", "Elisa", "Gina", "Ophelia", "Rebecca", "Tabea", "Zelda",
	"Alina", "Carolin", "Denise", "Hannah", "Isabell", "Jennifer", "Nadine",
]

const LAST_NAMES: Array[String] = [
	"Müller", "Schmidt", "Schneider", "Fischer", "Weber", "Meyer", "Wagner",
	"Becker", "Schulz", "Hoffmann", "Schäfer", "Koch", "Bauer", "Richter",
	"Klein", "Wolf", "Schröder", "Neumann", "Schwarz", "Braun", "Hofmann",
	"Zimmermann", "Werner", "Hartmann", "Lange", "Schmitt", "Krause",
	"Lehmann", "Frank", "Jäger", "Stein", "Otto", "Sommer", "Simon",
	"Graf", "Heinrich", "Vogel", "Keller", "Walter", "Friedrich", "Brandt",
	"Martin", "Herrmann", "Kaiser", "Lang", "Schubert", "Vogt", "Bergmann",
	"Dietrich", "Jung", "Arnold", "Schreiber", "Engel", "Roth", "Haas",
	"Winkler", "Voigt", "Beck", "Ludwig", "Lorenz", "Baumann", "Huber",
	"Brunner", "Moser", "Steiner", "Egger", "Fuchs", "Mayr", "Berger",
	"Wimmer", "Pichler", "Leitner", "Binder", "Mayer", "Kirchner", "Bachmann",
	"Pfeiffer", "Ritter", "Seifert", "Fröhlich", "Hahn", "Kunz", "Marx",
	"Meier", "Schmid", "Ulrich", "Näf", "Kröger", "Thiel", "Pohl",
	"Förster", "Kern", "Hamann", "Janssen", "Kuhlmann", "Linke", "Menzel",
	"Nickel", "Sauer", "Vetter", "Wenzel", "Zander", "Beyer", "Dittrich",
	"Ernst", "Irmscher", "Reimann", "Schenk", "Tietz", "Ullrich", "Hesse",
	"Götz", "Kramer", "Michel", "Nowak", "Paul", "Böhme", "Grimm",
	"Hildebrandt", "Lindner", "Scholz", "Urban", "Wagenknecht", "Büttner",
	"Drewes", "Eckstein", "Grosse", "Hinz", "Kalb", "Kühn", "Lohse",
	"Nitschke", "Pätzold", "Rösler", "Thomsen", "Zinke", "Bach", "Busch",
	"Ehlers", "Günther", "Jürgens", "Kunkel", "Tiedemann", "Voss",
]

const CHILD_NAMES: Array[String] = [
	"Luca", "Leon", "Finn", "Ben", "Felix", "Noah", "Jonas", "Tim",
	"Paul", "Luis", "Elias", "Moritz", "Samuel", "Jakob", "Lukas",
	"Anna", "Lena", "Sophie", "Marie", "Mia", "Emma", "Lea", "Nele",
	"Clara", "Ida", "Ella", "Lilly", "Lina", "Maja", "Paula", "Theo",
	"Oskar", "Anton", "Emil", "Matteo", "Amelie", "Finja", "Merle", "Juna",
]


static func random_male() -> String:
	return FIRST_NAMES_M[randi() % FIRST_NAMES_M.size()]


static func random_female() -> String:
	return FIRST_NAMES_W[randi() % FIRST_NAMES_W.size()]


static func random_last() -> String:
	return LAST_NAMES[randi() % LAST_NAMES.size()]


static func random_child() -> String:
	return CHILD_NAMES[randi() % CHILD_NAMES.size()]
