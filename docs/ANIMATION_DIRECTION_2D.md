# 2D Animation Direction

## Motion Goals

- Reinforce game state changes.
- Keep puzzle board legible during effects.
- Provide satisfying but brief feedback loops.

## Timing Defaults

- Card hover: `120ms`
- Card place: `180ms`
- Tile state transition: `180-260ms`
- Major weather impact: `240-320ms`
- Level complete flourish: `450-700ms`

## Easing Suggestions

- UI movement: `easeOutCubic`
- Impact flashes: `easeOutExpo`
- Fog transitions: `easeInOutSine`
- Looping ambient particles: linear + low amplitude variance

## Effect Rules by Weather

- Rain: downward streaks plus short ripple ring.
- Sun: radial pulse, warm bloom with strict cap on brightness.
- Frost: crystalline edge growth with snapping highlights.
- Wind: directional streak arcs, avoid screen clutter.
- Lightning: single sharp strike with very short afterglow.
- Fog: layered opacity field with directional drift.

## Performance Guardrails

- Keep mobile baseline at 60 FPS target.
- Use low-overdraw particles for frequent effects.
- Provide low-fx fallback setting.

