### ORGANIZZAZIONE DELLA DIRECTORY DELLE FOTO

La directory Archivio contiene l'archivio delle foto di famiglia: i video andrebbero rimossi

La directory Archivio contiene sottodirectory corrispondenti ad eventi per cui sono state scattate delle foto.

Il nome delle directory ha un formato definito: yyyymmdd-titolo. La prima parte è la data associata all'evento, il secondo è un titolo descrittivo.
Nel titolo non va inserito il -, che è riservato a separatore tra data e titolo.

### PROCEDURA DI BACKUP della direcotry Archivio

Per gestire un backup si usano i comandi checkall.sh, renamedir.sh e backup.sh. Funzionano da qualunque directory, per esempio dalla home.

## backup.sh

Con il comando backup.sh si aggiorna il backup di una o più directory. Con l'opzione -n non viene aggiornato il backup, ma vengono effettuate le altre operazioni.

Dopo aver controllato che la directory esista ed abbia un nome lecito il comando si arresta e chiede conferma.

Poi vengono normalizzati i nomi dei file contenuti nella directory e nelle eventuali sottodirectory. Il formato finale è giorno-data-dispositivo.estensione.



## checkall.sh

Con il comando checkall.sh si verifica lo stato della directory Archivio e del backup. 

Al comando può essere passato come parametro che indica il numero di passi eseguiti. Il numero di passi di default è 3.

Ogni passo esegue un check diverso:
1. (DEFAULT) Verifica che i nomi delle directory in Archivio abbiano nomi ben formati (yyyymmdd-titolo), o da ridenominare con renamedir.sh
2. (DEFAULT) Sottodirectory di Archivio che non sono presenti sul backup
3. (dEFAULT) Sottodirectory del backup di Archivio che non sono presenti in Archivio
4. Opzionale: calcolo degli md5 dei file in Archivio. Il calcolo viene eseguito solo per le directory che non hanno un file md5 
5. Verifica della presenza di file duplicati nella directory Archivio
6. Verifica della presenza di file duplicati nella directory di backup di Archivio
7. Verifica file presenti solo nel backup della directory Archivio
8. Verifica file presenti solo nella directory Archivio

Nell'uso più semplice, si usa senza parametro e si ottiene l'elenco di tutti le directory da ridenominare e quelle di cui fare backup. La lista è simile a questa:

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

REFERENCE

backup.sh
^^^^^^^^^
Prende come parametri un numero di directory nell'archivio di lavoro e ne fa il backup.

renamedir.sh
^^^^^^^^^^^^
Rinomina una directory, mantenendo consistente il backup. ATTENZIONE: non funziona se le due directory non sono già consistenti.

checkall.sh
^^^^^^^^^^^
Esegue una serie di controlli. Opzionalmente, può ricalcolare gli md5 nella directory di lavoro e sul backup.

Da fare: backup deve calcolare le directory di cui fare backup.
