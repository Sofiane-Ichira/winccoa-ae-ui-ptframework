// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author n.holzersoellner
*/

#uses "classes/GUI/GUINaviButton"

/**
 * @brief A button class for navigating to a specific panel in the GUI.
 */
class GUINaviPanelButton : GUINaviButton
{
  private string _childPanel; //!< The name of the child panel to navigate to when clicked.

  /**
   * @brief The Default Constructor.
   * @param textRef The reference to the text shape.
   * @param iconRef The reference to the icon shape.
   * @param frameSelector The reference to the frame selector shape.
   * @param childPanel The name of the child panel to navigate to when clicked.
   */
  public GUINaviPanelButton(const shape &textRef, const shape &iconRef, const shape &frameSelector, const string &childPanel) : GUINaviButton(textRef, iconRef, frameSelector)
  {
    _childPanel = childPanel;
  }

  /**
   * @brief Handles the button click event to navigate to the specified child panel.
   */
  public void Clicked()
  {
    ClickedEvent(1, _childPanel, GetPointer());
  }
};
