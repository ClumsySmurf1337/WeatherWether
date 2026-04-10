Set-Location "D:\Agents\WeatherWether\wt-agent-cursor-lane-2"
git add -A
git status
git diff --cached --stat
git commit -m "WEA-549: Level Select world map with winding path nodes"
git push -u origin HEAD

$body = @"
Linear WEA-549

## Summary
- Level Select screen (Screen 4 from UI_SCREENS.md) with vertical scrollable world map
- 22 level nodes positioned from levels/worldN/path.json with completed/current/locked states
- Current level node pulses with alpha tween, locked nodes shake on tap
- Line2D path connects all nodes, camera auto-scrolls to current level
- World Select upgraded from stub to 2x3 grid of world cards navigating to Level Select
- UIManager updated with push_level_select() convenience method

## Test plan
- [ ] Verify level_select.tscn loads without parse errors in Godot editor
- [ ] Navigate Home -> World Select -> tap world -> Level Select appears with 22 nodes
- [ ] Verify path.json positions nodes correctly along winding path
- [ ] Verify locked nodes show lock icon and shake on tap
- [ ] Verify current node pulses with alpha animation
- [ ] Verify back button returns to World Select
- [ ] Run validate.ps1 to confirm green
"@

gh pr create --base main --title "WEA-549: Level Select world map with winding path nodes" --body $body
