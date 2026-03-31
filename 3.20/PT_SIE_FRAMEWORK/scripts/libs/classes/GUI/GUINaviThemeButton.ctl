// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author n.holzersoellner
*/

#uses "classes/GUI/GUINaviButton"

class GUINaviThemeButton : GUINaviButton
{
  private const string darkTheme = "Siemens_Dark"; //!< The dark theme name.
  private const string lightTheme = "Siemens_Light"; //!< The light theme name.

  /**
   * The Default Constructor.
   */
  public GUINaviThemeButton(const shape &textRef, const shape &iconRef, const shape &frameSelector) : GUINaviButton(textRef, iconRef, frameSelector)
  {
  }

  /**
   * @brief Handles the button click event to toggle between dark and light themes.
   */
  public void Clicked()
  {
    string activeTheme = colorGetActiveScheme();
    colorSetActiveScheme((activeTheme != darkTheme) ? darkTheme : lightTheme);
    setActiveIconTheme((activeTheme != darkTheme) ? darkTheme : lightTheme);
    setApplicationProperty("styleSheet", getApplicationProperty("styleSheet"));
    triggerGlobalEvent("ColorSchemeChanged");
  }
};
