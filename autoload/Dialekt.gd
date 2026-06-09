extends Node
## Tiroler-Dialekt-Sprüche für Sprechblasen. Augenzwinkernd, nie bösartig.

const SALVE_PERFEKT := [
	"Sauber, Madln! Wia a Uhrwerk!",
	"Des hat kracht wia's Donnerwetter!",
	"Ehrensalve! Da Herrgott hat's gheart!",
	"Zack! Olle gleichzeitig – Respekt, Madln!",
]

const SALVE_DANEBEN := [
	"Madl, des war nix!",
	"Des war koa Salve, des war a Klumpat!",
	"Habt's es Gwehr verkehrt ghaltn, oder wos?",
	"Mei, des klingt wia a Knallerbsn-Festl!",
	"Üben, üben, üben – und zwar gschwind!",
]

const BIER_PERFEKT := [
	"Ex und hopp! A gstandnes Madl!",
	"Koa Tropfn daneben – Prost di!",
	"De Maß war gschwinder leer als d'Salve!",
]

const BIER_VERSCHUETTET := [
	"Madl, des war nix! Halbe Maß am Jankerl!",
	"Du sollst es TRINKEN, net duschen damit!",
	"Schad um's guate Bier, sag i nur!",
]

const SCHNAPS_PERFEKT := [
	"Oanschenkn, net daneben, Bua!",
	"Brav eingschenkt, Bua – und jetzt: selber oan!",
	"Aufs Stamperl genau! Du kannst was!",
	"So gheart sich des! Zum Wohl!",
]

const SCHNAPS_DANEBEN := [
	"Bua! Da Schnaps gheart INS Glasl!",
	"Du zitterst ja wia a Espenlaub im Dirndl!",
	"Halb danebn – host schon zviel derwischt?",
	"Mei Schürzn! Du Patschn!",
]

const BETRUNKEN_KOMMENTARE := [
	"Hicks... wo... wo is'n des Glasl hin?",
	"I sig... zwoa Stamperl. Oder vier?",
	"Es Dirndl... dreht si...",
	"No a Stamperl, dann... dann is gnua. Vielleicht.",
]

const DURSTIGE_SCHUETZINNEN := [
	"He, Marketenderin! An Obstler, aber zackig!",
	"Nach so a Salve braucht's wos Hochprozentigs!",
	"Beim Einschenken net so zaghaft, Bua!",
	"Mir habn gschossn, ihr schenkt's ein – so is da Brauch!",
]

const VERSUS_ANSAGE := [
	"Frauen an d'Gwehre, Manda an d'Flaschn!",
	"Rollentausch is – und koa Widerred!",
]


func pick(pool: Array) -> String:
	return pool[randi() % pool.size()]
