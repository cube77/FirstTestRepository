# Automotive Voice Defect Reporter – Spezifikation Sprint 1.2

## Beschlossene Bedienung
- Dunkle iPhone-Oberfläche (System-Dunkelmodus als gewünschtes Design; die SwiftUI-Ansichten nutzen aktuell überwiegend Systemfarben).
- Getrennte Aktionen **Neuen Fehler erfassen** und **Aufnahme starten / stoppen**.
- Mehrere getrennte Sprachaufnahmen pro Fehler; bestehende Fehler wieder auswählbar.
- Keine Fehlerumschaltung während einer laufenden/pausierten Aufnahme.

## Neu in Sprint 1.2 implementiert
- **Aktive Trace-Session-ID** pro Testfahrt, manuell im Aufnahmebildschirm eingebbar und speicherbar.
- Beim Anlegen eines Fehlers wird die aktuell aktive Trace-ID als Snapshot gespeichert.
- Beim Beginn jeder Aufnahme wird die dann aktive Trace-ID mit dem tatsächlichen Aufnahmebeginn als Snapshot gespeichert. Ein späterer Trace-Wechsel verändert alte Zuordnungen nicht.
- Fehlerzeitpunkt ist das Anlegedatum des Fehlerreports; zusätzliche Beobachtungen besitzen eigene Aufnahmezeitpunkte.
- Anzeige im Format `yyyy-MM-dd (EEEE), HH:mm:ss`, Wochentag englisch (z. B. `2026-11-03 (Tuesday), 10:15:23`), Geräte-Zeitzone.
- Trace-ID des Fehlerreports kann in der Detailansicht bei Bedarf manuell korrigiert werden; Aufnahmen behalten ihre Zuordnung.
- Unterbrochene Aufnahmen übernehmen bei Wiederherstellung Trace-ID und ursprünglichen Aufnahmebeginn aus dem Wiederherstellungsmarker (sofern vorhanden).

## Geplant, noch nicht implementiert
- **Spracheingabe der Trace-Session-ID** und sichere Bestätigung erkannter IDs (Sprint 2).
- Lokale Transkription, automatische KI-Aktualisierung des Fehlerreports **nach jeder abgeschlossenen Aufnahme** (Sprint 2). Datum, Wochentag, Zeit und Trace-ID in der Fehlerbeschreibung berücksichtigen; keine erfundenen Daten.
- XLSX-Export mit Spalten `Fehler-ID`, `Fehlerdatum`, `Wochentag`, `Fehlerzeit`, `Trace-Session-ID` und restlichen Reportfeldern. Blatt `Beobachtungen` mit individuellen Trace-IDs und Zeitstempeln. Weitere Exportfunktionen in späterem Sprint.
- Fotos, PDF/ZIP, Face ID, vollständige Sicherheits-/Backup-Konfiguration, Benachrichtigungen.

## Sicherheit und Test
- Prototyp nicht auf macOS/Xcode kompiliert oder auf dem iPhone getestet. Noch keine vertraulichen Entwicklungsdaten verwenden.
- App auf iPhone nur durch Beifahrer oder im sicheren Stillstand bedienen.
- Bestehende SwiftData-Datenmodelle wurden erweitert; bei Installation über alte Prototypversion können Migrationsthemen auftreten. Vor Änderungen lokale Testdaten sichern.
