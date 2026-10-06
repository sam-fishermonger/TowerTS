# Polices

- `OpenSans_SemiBold.woff2` : Open Sans SemiBold, la police par défaut de Godot (copiée de `thirdparty/fonts/` dans les sources de Godot 4.7.2). Licence SIL Open Font License 1.1 : https://openfontlicense.org
- `symboles.ttf` : les caractères ★ ☆ ✕ ● → ♥ ♛ ⚙ ✪ ✠ ▲ ◆ ☠ ◎ ✖ ✦ ❦ (les derniers pour les succès) extraits de DejaVu Sans Bold. Licence libre DejaVu (dérivée de Bitstream Vera) : https://dejavu-fonts.github.io/License.html

`police_interface.tres` utilise Open Sans pour le texte et `symboles.ttf` pour les caractères qu'elle n'a pas. Sans elle, ces symboles s'affichent en carrés dans la version web, où il n'y a pas de police système de secours. Pour ajouter un symbole, regénérer le sous-ensemble (paquet Python `fonttools`) :

```
pyftsubset DejaVuSans-Bold.ttf --text="★☆✕●→♥♛⚙✪✠▲◆☠◎✖✦❦" --output-file=assets/fonts/symboles.ttf --no-hinting
```
