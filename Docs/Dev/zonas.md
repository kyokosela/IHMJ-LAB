# Sistema de zonas (cambios IA)

Status: En revisión
Assign: Sela (hecho con IA)

# 📘 `ZoneManager` (autoload)

```gdscript
enum ZONES { APARTMENT, LOBBY, OFFICE, COMMERCIAL, BATHROOM, BALCONY, HALLWAY }
signal zone_ready(zone_id)          # la escena ya cargó y Mayui está en ella
signal street_risk_triggered(chance, roll)
const HOME_ROOMS      # baño y balcón
const HOME_BUILDING   # casa, pasillo y recepción
```

⚠️ Zonas nuevas **al final** del enum (las escenas guardan el número) y su ruta en `zone_paths`, en el mismo orden.

### `change_zone(destino)`

1. Ignora si ya está cambiando.
2. Dentro del edificio de Mayui: **gratis** (ni tiempo ni energía). Fuera: bus (S/10) hacia oficina o comercial desde casa o
   recepción, o a pie con costo creciente.
3. Mayui queda quieta; fundido de 1 s; `release_player()`; cambia la escena.
4. En la calle puede haber un imprevisto (`PlayerManager.register_street_event`).
5. Seguro: si la zona no carga en 6 s, libera a Mayui.

# 📘 `World` (cambios)

- `default_camera_zoom` (5): crea cámara si la escena no trae una.
- Elige el `SpawnPoint` según la zona de origen (`from_zone`; −1 = general).
- `release_player()` **antes** de cerrar la escena (hacerlo en `_exit_tree` tumbaba el motor).

# 📘 `TransitionManager`

Un fundido a la vez; el que empieza cancela al anterior.

## Escenas nuevas (`Scenes/World/`)

| Escena | Notas |
|---|---|
| `Apartment.tscn` | Cuarto en L, cocina, armario, cama, calendario, escritorio. Raíz: `tutorial.gd` |
| `Bathroom.tscn` | Ducha y lavamanos |
| `Balcony.tscn` | Tendedero sin mecánica |
| `Hallway.tscn` | Escaleras y puertas M-21 a M-24 |
| `Lobby.tscn` | Recepción con rejilla, punto del casero, puerta a la calle |
| `Office.tscn` | Prototipo: fichar, PC, Madina |
| `Commercial.tscn` | Prototipo: arcade y mercado. **Hoy no se puede llegar** |

Los fondos y muebles son provisionales. Prueba: `Tools/probar_cuarto.gd` tiene un plano de cada cuarto; si se mueve un
mueble, hay que actualizarlo.
