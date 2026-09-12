class_name StoneGolem
extends Boss

## Stenen Golem — eindbaas van Wereld 3 (Grot). Zelfde gedrag als de andere
## bosses (Boss.gd: loopt op je af, slaat met een arm, in fase 2 vallen er
## "stenen" van het plafond), maar de tekening kijkt standaard naar LINKS
## (omgekleurde Frost Guardian), dus de flip is andersom.

func _face(direction: float) -> void:
	if _sprite != null and direction != 0.0:
		_sprite.flip_h = direction > 0.0
