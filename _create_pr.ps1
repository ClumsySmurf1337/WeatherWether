Set-Location "D:\Agents\WeatherWether\wt-agent-cursor-lane-2"
git add -A
git status
git diff --stat origin/main...HEAD
gh pr create --base main --title "WEA-548: Level Complete, Level Failed, No Path, and Pause UI screens" --body @"
Linear WEA-548

## Summary
- Level Complete screen with star reveal animation, stats panel, and next/replay/world map navigation
- Level Failed modal overlay with death-cause-specific copy (drown/burn/fall/electrocute/freeze)
- No Path Forward soft-lose modal with undo and restart options
- Pause modal with resume, restart, settings, and quit options
- UIManager updated with dedicated modal CanvasLayer (layer 110) for overlay screens
- All screens follow UI_SCREENS.md spec with UITheme integration

## Test plan
- [ ] Verify all four scenes load without parse errors
- [ ] Confirm LevelCompleteScreen star reveal animation cycles correctly
- [ ] Confirm LevelFailedScreen shows correct copy for each DeathCause
- [ ] Confirm NoPathScreen signals fire on button press
- [ ] Confirm PauseScreen ESC key handling works
- [ ] Confirm UIManager show_modal/dismiss_modal lifecycle
"@
