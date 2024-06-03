#!/bin/bash

# Konfiguration
FIREFOX_PROFILE_DIR="$HOME/.mozilla/firefox"                       # Verzeichnis mit den Firefox-Profilen
NAS_DESTINATION="/home/user/remotedestionation/backupfolder/"                         # Zielverzeichnis auf dem NAS
ENCRYPT_PASSWORD="1234"                         # Passwort für die Verschlüsselung



# Aktuelles Datum und Uhrzeit
DATE=$(date +"%Y_%m_%d_%H_%M")

# Heutiges Datum
TODAY=$(date +"%Y_%m_%d")

# Prüfe, ob heute bereits ein Backup gemacht wurde
if ls -d "$NAS_DESTINATION/firefox_backup_encrypted_$TODAY"* > /dev/null 2>&1; then
    echo "Heute wurde bereits ein Backup durchgeführt. Das Skript wird beendet."
    exit 0
fi

# Zielverzeichnis auf dem NAS
REMOTE_DIR="$NAS_DESTINATION"

# Überprüfe, ob Firefox läuft
if ps aux | grep -v grep | grep firefox > /dev/null; then
    echo "Firefox läuft. Das Backup wird nicht durchgeführt."
else
    # Suche nach dem Profilordner mit "default-release" im Namen
    PROFILE_FOLDER=$(find "$FIREFOX_PROFILE_DIR" -type d -name "*default-release*")

    # Überprüfe, ob ein passender Profilordner gefunden wurde
    if [ -z "$PROFILE_FOLDER" ]; then
        echo "Es wurde kein Profilordner gefunden, der 'default-release' im Namen hat. Das Backup wird nicht durchgeführt."
    else
        # Archiviere und verschlüssele den Backup-Ordner -mx= kompression, 9 höchste,1 geringeste
        7z a -p"$ENCRYPT_PASSWORD" -mhe=on -mx=2 -mmt=on -ssc- -t7z "$HOME/firefox_backup_encrypted_$DATE.7z" "$PROFILE_FOLDER"

        # Kopiere die neuesten Backup-Dateien auf das NAS
                rsync -avh --progress "$HOME/firefox_backup_encrypted_$DATE.7z" "$REMOTE_DIR"

        # Protokolliere die Aktion
       # echo "Firefox-Backups wurden am $DATE auf das NAS kopiert." >> "$HOME/firefox_backup.log"
	rm "$HOME/firefox_backup_encrypted_$DATE.7z"

        # Zähle die Anzahl der Backups auf dem NAS
        BACKUPS_COUNT=$(find "$NAS_DESTINATION" -type f -name "firefox_backup_encrypted_*" | wc -l)


        # Lösche ältere Backups auf dem NAS, wenn mehr als 4 vorhanden sind
        if [ "$BACKUPS_COUNT" -gt 4 ]; then
            OLDEST_BACKUPS=$(find "$NAS_DESTINATION" -type f -name "firefox_backup_encrypted_*" -printf '%T@ %p\n' | sort -n | head -n -4 | awk '{print $2}')
            rm -r $OLDEST_BACKUPS
            echo "Ältere Backups wurden gelöscht, um sicherzustellen, dass mindestens 4 Backups vorhanden sind."
        fi
        
        # Überprüfe, ob das letzte Backup vor mehr als 30 Tagen durchgeführt wurde
        LAST_BACKUP=$(find "$NAS_DESTINATION" -type f -name "firefox_backup_encrypted_*" -printf "%T+\t%p\n" | sort -r | head -n 1 | cut -f 1)
        LAST_BACKUP_DATE=$(date -d "$(echo $LAST_BACKUP | cut -d '+' -f 1)" +%s)
        CURRENT_DATE=$(date +%s)
        DAYS_DIFF=$(( ($CURRENT_DATE - $LAST_BACKUP_DATE) / (60*60*24) ))

        if [ "$DAYS_DIFF" -gt 30 ]; then
            zenity --warning --text="WARNUNG: Das letzte Firefox-Backup wurde vor mehr als 30 Tagen durchgeführt! Firefox muss geschlossen sein. Manuelles antriggern in Konsole ./.profile_backup_ff.sh"
        fi        
    fi
fi
