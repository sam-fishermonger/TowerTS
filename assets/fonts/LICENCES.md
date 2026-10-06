# Polices

- `Rajdhani_SemiBold.ttf` : Rajdhani SemiBold (Indian Type Foundry), la police du texte de l'interface. Licence SIL Open Font License 1.1 : https://openfontlicense.org
- `Oxanium.ttf` : Oxanium (Severin Meyer), police variable des titres, utilisée en graisse 700. Licence SIL Open Font License 1.1.
- `OpenSans_SemiBold.woff2` : Open Sans SemiBold, la police par défaut de Godot (copiée de `thirdparty/fonts/` dans les sources de Godot 4.7.2), gardée en secours pour les caractères absents des deux premières. Licence SIL Open Font License 1.1.

Rajdhani et Oxanium viennent du dépôt Google Fonts (https://github.com/google/fonts, dossiers `ofl/rajdhani` et `ofl/oxanium`).
- `symboles.ttf` : les caractères ★ ☆ ✕ ● → ♥ ♛ ⚙ ✪ ✠ ▲ ◆ ☠ ◎ ✖ ✦ ❦ (les derniers pour les succès) extraits de DejaVu Sans Bold. Licence libre DejaVu (dérivée de Bitstream Vera) : https://dejavu-fonts.github.io/License.html

`police_interface.tres` (texte) utilise Rajdhani et `police_titres.tres` (titres d'écran) Oxanium ; les deux se rabattent sur Open Sans puis sur `symboles.ttf` pour les caractères qu'elles n'ont pas. Sans elle, ces symboles s'affichent en carrés dans la version web, où il n'y a pas de police système de secours. Pour ajouter un symbole, regénérer le sous-ensemble (paquet Python `fonttools`) :

```
pyftsubset DejaVuSans-Bold.ttf --text="★☆✕●→♥♛⚙✪✠▲◆☠◎✖✦❦" --output-file=assets/fonts/symboles.ttf --no-hinting
```
