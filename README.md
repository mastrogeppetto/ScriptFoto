Per fare un backup si useno i comandi checkall.sh e backup-single.sh. Funzonano da qualunque directory, per esempio dalla home.

Con la chackall si ottiene l'elenco di tutti le directory di cui fare backup. La lista è simile a questa:

[no-backup] ./20211123-MercatiniTrento
[no-backup] ./20211127-5Terre
[no-backup] ./20211200-Avvento_S.Lucia
[no-backup] ./20211212-BallettiRussi
[no-backup] ./20211215-Booster_varieCapelli
[no-backup] ./20211216-TormentoneFiorentino
[no-backup] ./20211219-Polsa
[no-backup] ./20211221-SabriVR
[no-backup] ./20211224-NataleTrento

Si copia la lista e la si passa in un comando di questo genere:

$ cat | cut -f2 -d/ | tr "\n" " "

Si ottiene l'elenco delle directory, a cui si può applicare backup-single.sh:

backup-single.sh 20210800-varie 20210802-SuturaIsa 20210803-RichiamoVaccES 20210806-Terlago 20210811-Chieti 20210816-Puglia 20210900-varie 20210906-Vittoriale 20210909-CapelliSabri_pre-post 20210910-EuropeiCiclismo 20210914-CapelliIsaBlu 20211000-varie 20211002-CompleannoCris 20211010-FestaZucaPergine 20211017-CastelloPergine 20211022-Autolavaggio 20211030-Praga 20211100-varie 20211111-AmiciBina 20211113-EmanulelTN 20211113-PinoTerlago
