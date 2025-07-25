# qadr-safe

**qadr-safe** ist ein Mini-Spiel, bei dem man einen Tresor aufbricht.  
Dabei wird eine Tresorgrafik eingeblendet und die Codescheibe gedreht.  
An der passenden Stelle ertönt ein Klick-Sound – hier loggt der Spieler ein, um den Tresor zu öffnen.

Dieses Mini-Spiel ist eines von zwei möglichen Scripts, die von `mms-treasure` genutzt werden, um dem Spieler das Öffnen einer gefundenen Truhe zu ermöglichen. In diesem Fall nutzt `mms-treasure` das `qadr-safe`-Script.

---

## ⛏️ Steuerung

| Taste       | Funktion                                      |
|-------------|-----------------------------------------------|
| `A`         | Codescheibe nach links drehen                 |
| `D`         | Codescheibe nach rechts drehen                |
| `W`         | PIN einrasten (aktuellen Code bestätigen)     |
| `Backspace` | Minispiel aufgeben                            |

---

## 💡 Tipps
Initial muss die Wählscheibe nach rechts gedreht werden. Nur wenn man nach rechts laufend an die richtige Stelle kommt, kommt das Klick-Geräusch, welches die korrekte Stelle verrät. Im Zweifelsfall nochmal ein paar Positionen nach links zurück und wieder vorsichtig nach rechts drehen bis man an der passenden Stelle ankommt.  
Anschließend den Prozess spiegelverkehrt (also nach links) wiederholen.  
Anschließend noch einmal nach rechts um auch den dritten PIN erfolgreich einzurasten.

---

## 🚀 Installation
Den Ordner in den resource-Ordner ziehen. ensure qadr-safe in der server.cfg hinzufügen. Keine Abhängigkeiten.

---

## ⚙️ Konfiguration
Direkt in der client.lua, hier kann die Drehgeschwindigkeit (ROTATION_DELAY) sowie die Keys eingestellt werden. Sollten die Keys verändert werden, müssen sie auch in html/index.html umbeschriftet werden.

---

## 🚧 Eigene Anpassungen
- Spieleranimation (bücken und Scheibe drehen) startet nun bereits zu Beginn des Mini-Spiels
- Spieler versucht nicht mehr sich während des Mini-Spiels zu bewegen, was zu zittern führte
- HUD hinzugefügt, welches anzeigt, welche Tasten zu drücken sind um das Mini-Spiel zu spielen
- Command mit variablen Argumenten hinzugefügt:: /createSafe (0 arguments: creates a 3 pin safe), /createSafe 5 (1 argument: creates a 5 pin safe), /createSafe 12 42 9 1 (> 1 argument: creates a safe with [argc] pins with the given combination)
- API-Call mit möglich, z.B. createSafe({math.random(0, 99), math.random(0, 99), math.random(0, 99)})
- Code-Scheibe von 360 Nummern zu 100 Nummern verteilt auf 360° angepasst
- Konfigurierbare Verzögerung beim Code-Scheibe Drehen eingeführt, da sonst bei hohen FPS die Wählscheibe mehrere Schritte weiter sprang
div. Code-Cleanups (Refactoring, Entfernung ungenutzter Codezeilen, Whitespaces und Einrückungen gleichgezogen, MagicNumbers entfernt)

---

## 📜 Originalversion
- Previous version probably by [abdulkadiraktas](https://github.com/abdulkadiraktas/qadr-safe) and other authors.
- *This code was originally developed in C#. You can access the original repository by clicking on the [following link](https://github.com/TimothyDexter/FiveM-SafeCrackingMiniGame)*
- [Fivem Lua version](https://github.com/VHall1/pd-safe)
- [Sample Video](https://www.youtube.com/watch?v=bmsPNMACUsY)
