// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author n.holzersoellner
*/

#uses "classes/ContextMenu/ContextMenuCustom"
#uses "classes/GUI/GUINaviButton"

/**
 * @brief A button class for changing the language in the GUI.
 */
class GUINaviLanguageButton : GUINaviButton
{

  /**
   * @brief The Default Constructor.
   * @param textRef The reference to the text shape.
   * @param iconRef The reference to the icon shape.
   * @param frameSelector The reference to the frame selector shape.
   */
  public GUINaviLanguageButton(const shape &textRef, const shape &iconRef, const shape &frameSelector) : GUINaviButton(textRef, iconRef, frameSelector)
  {
  }

  /**
   * @brief Handles the button click event to open a language selection menu.
   */
  public void Clicked()
  {
    int answer;
    shared_ptr<ContextMenuCustom> languageMenu = new ContextMenuCustom();
    languageMenu.Clear();

    dyn_string dsLangs;

    for (int i = 0; i < getNoOfLangs(); i++)
    {
      string locale = getLocale(i);
      languageMenu.AddPushButton(getCatStr("trans", locale), i + 1, 1, "");
      dsLangs.append(locale);
    }

    answer = languageMenu.Open();

    if (answer > 0)
    {
      changeLang(dsLangs[answer]);
    }
  }
};
