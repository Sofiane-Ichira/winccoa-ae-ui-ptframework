// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author n.holzersoellner
*/

#uses "classes/GUI/GUINaviButton"

/**
 * @brief A button class for navigating through a menu in the GUI.
 */
class GUINaviMenuButton : GUINaviButton
{
  private const string openedFillString = "[pattern,[fit,any,white/double-chevron-left.svg]]"; //!< The icon displayed when the menu is open.
  private const string closedFillString = "[pattern,[fit,any,white/double-chevron-right.svg]]"; //!< The icon displayed when the menu is closed.

  /**
  * @brief The Default Constructor.
  * @param textRef The reference to the text shape.
  * @param iconRef The reference to the icon shape.
  * @param frameSelector The reference to the frame selector shape.
  */
  public GUINaviMenuButton(const shape &textRef, const shape &iconRef, const shape &frameSelector) : GUINaviButton(textRef, iconRef, frameSelector)
  {
    SetOpen(FALSE);
  }

  /**
   * @brief Handles the button click event to toggle the menu state.
   */
  public void Clicked()
  {
    ClickedEvent(2, "", nullptr);
  }

  /**
   * @brief Sets the icon based on the menu state.
   * @param icon The icon to set for the button.
   */
  public void SetOpen(bool open)
  {
    SetIcon((open) ? openedFillString : closedFillString);
  }
};
