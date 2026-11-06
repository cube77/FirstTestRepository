# Automotive Voice Defect Reporter – Spezifikation V1.1

Stand: 03.11.2026. Zielgerät: iPhone 16 Pro; native SwiftUI-App, deutsche Oberfläche, lokale Speicherung.

## Kernablauf
1. Nutzer legt eine Testfahrt mit Fahrzeug-ID/VIN, Softwarestand und Fahrer an.
2. Nutzer tippt auf **Neuen Fehler erfassen**. Die App erzeugt einen eigenen Fehlerreport als Entwurf und setzt ihn aktiv.
3. Nutzer tippt auf **Aufnahme starten**, beschreibt die Beobachtung und tippt auf **Aufnahme stoppen**.
4. Die App speichert die Original-Audiodatei mit Zeitpunkt und Zuordnung zum aktiven Fehlerreport.
5. Bei erneuter Beobachtung desselben Fehlers wählt der Nutzer diesen Report aus und nimmt eine weitere, separate Audio-Ergänzung auf.
6. Für einen anderen Fehler wird ein neuer Report erstellt. Eine Testfahrt kann viele Fehlerreports umfassen.
7. Titel und Beschreibung sind manuell editierbar.

## Datenmodell
- TestDrive: UUID, Fahrzeug-ID, Softwarestand, Fahrer, Start/Ende.
- DefectReport: UUID, TestDrive-UUID, laufende Fehlernummer pro Testfahrt, Titel, Beschreibung, Status, Erstellungs-/Änderungsdatum.
- DefectRecording: UUID, TestDrive-UUID, DefectReport-UUID, Audiodatei, Dauer, Aufnahmezeitpunkt, Status.
- Ein TestDrive hat 0..n DefectReports; ein DefectReport hat 0..n DefectRecordings.

## Regeln
- Kein Recorderstart ohne aktive Testfahrt und aktiven Fehlerreport.
- Kein Wechsel des aktiven Fehlers und keine Erstellung eines neuen Fehlers während einer laufenden oder pausierten Aufnahme.
- Beim Stoppen wird die Datei dem Fehler zugeordnet, der beim Start aktiv war.
- Original-Audio wird nicht durch Reportänderungen überschrieben.
- Aufnahmen bleiben nach einem Neustart lokal verfügbar; bestmögliche Wiederherstellung bei Unterbrechung.
- Keine erfundenen KI-Ergebnisse anzeigen.

## Sprint 1.1 – implementierter Umfang
Testfahrten, Fehlerreport-Erstellung und -Auswahl, getrennte Audioaufnahme pro Report, Wiedergabe, einfache manuelle Reportbearbeitung, lokale SwiftData-Metadaten und Audiodateien, Start/Stopp und rudimentäre Wiederherstellung.

## Sprint 2 – verbindliches Ziel, noch nicht implementiert
- Nach **jeder** abgeschlossenen Aufnahme automatisch lokale deutsche Spracherkennung starten.
- Vollständige Transkripte pro Aufnahme behalten.
- KI aktualisiert aus allen Aufnahmen desselben Fehlers einen sachlichen technischen Report (Titel, Beschreibung, Soll/Ist, Reproduktionsschritte, Häufigkeit/Kategorie, soweit tatsächlich belegt).
- Bestehende Informationen erhalten; Widersprüche kenntlich machen, keine Details erfinden.
- Fehlerbehandlung, Wiederholen und manuelle Freigabe/Bearbeitung.
- Ohne explizite Zustimmung keine vertraulichen Daten an Cloud-Dienste übertragen.

## Weitere geplante Funktionen aus V1.0
Bilder, PDF-/XLSX-/ZIP-Export, Face ID/Gerätecode, vollständiger Datenschutz/Backup-Ausschluss, Speicherwarnungen, Benachrichtigungen, Filter und umfangreiche Praxistests.

## Hinweis
Nicht auf macOS/Xcode kompiliert und nicht auf einem iPhone getestet. Noch nicht für vertrauliche Fahrzeugdaten oder produktiven Einsatz freigegeben.
