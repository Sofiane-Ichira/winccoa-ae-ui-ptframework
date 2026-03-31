// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author n.holzersoellner
*/

#uses "classes/GUI/GUINaviButton"

/**
 * @brief Represents a button for exiting the current module in the GUI.
 */
class GUINaviExitButton : GUINaviButton
{

  /**
   * @brief The Default Constructor.
   * @param textRef The reference to the text shape.
   * @param iconRef The reference to the icon shape.
   * @param frameSelector The reference to the frame selector shape.
   */
  public GUINaviExitButton(const shape &textRef, const shape &iconRef, const shape &frameSelector) : GUINaviButton(textRef, iconRef, frameSelector)
  {
  }

  /**
   * @brief Handles the button click event to close the current module.
   * It checks the current module name and closes the corresponding module.
   */
  public void Clicked()
  {
    dyn_string moduleSplit = strsplit(myModuleName(), "_");
    int moduleNumber = moduleSplit.at(dynlen(moduleSplit) - 1);

    dyn_string moduleNames = getVisionNames();

    if (dynContains(moduleNames, "Tunnel_Model_" + moduleNumber))
    {
      ModuleOff("Tunnel_Model_" + moduleNumber);
    }
    else if (dynContains(moduleNames, "Vision_" + moduleNumber))
    {
      ModuleOff("Vision_" + moduleNumber);
    }
    else if (dynContains(moduleNames, "WinCC_OA_" + moduleNumber))
    {
      ModuleOff("WinCC_OA_" + moduleNumber);
    }
  }
};
