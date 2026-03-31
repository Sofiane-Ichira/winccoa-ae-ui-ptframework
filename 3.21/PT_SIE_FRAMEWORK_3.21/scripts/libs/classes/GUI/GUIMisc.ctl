// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author n.holzersoellner
*/

/**
 * @brief A class for miscellaneous GUI-related functions.
 */
class GUIMisc
{
  /**
   * @brief The Default Constructor.
   */
  public GUIMisc()
  {
  }

  /**
   * @brief Gets the number of screens available.
   * @return The number of screens.
   */
  public mapping GetScreenSizeForAllScreens()
  {
    mapping screenValues;

    for (int i = 0; i <= getScreenCount() - 1; i++)
    {
      int w, h, x, y;
      getScreenSize(w, h, x, y, i);
      screenValues.insert(i + 1, makeMapping("W", w,
                                             "H", h,
                                             "X", x,
                                             "Y", y));
    }

    return screenValues;
  }

  /**
   * @brief Gets the CSS string for styling GUI components.
   * @return A string containing the CSS styles.
   */
  public string GetCssString()
  {
    string cssCode;
    string tooltipStyle = "QToolTip { background-color: oa-color(color-2); color: oa-color(color-std-text); border: none; border-radius: 4px; padding: 4px; font-family: 'Siemens Sans'; font-style: normal; font-weight: 700; font-size: 16px;}";

    string tableHeaderStyle = "QHeaderView::section {background-color: oa-color(color-2); color: oa-color(color-std-text); padding: 4px; border: none;} QTableCornerButton::section { background-color:oa-color(color-2); } QHeaderView{background-color: oa-color(color-2); } QHeaderView::section:hover {background: oa-color(color-ghost--hover); }";

    string aesRowStyle = ("QTableView[type=\"alert_row\"] {font-family: \"Siemens Sans\", sans-serif;font-size: 14px;color: oa-color(color-std-text);background-color: oa-color(color-ghost);border: none;}"
                          "QTableView[type=\"alert_row\"]::item {border: none;padding-left: 10px;line-height: 20px;height: 20px;text-align: center;background-color: oa-color(color-ghost);}"
                          "QTableView[type=\"alert_row\"]::item:hover {background-color: oa-color(color-ghost--hover);}"
                          "QLineEdit[type=\"alert_row\"] {background-color: oa-color(color-ghost);color: oa-color(color-std-text);border: none;}"
                          "QPushButton[type=\"alert_row_up\"],QPushButton[type=\"alert_row_down\"] {background-position: center;border: none;padding: 4px;}"
                          "QPushButton[type=\"alert_row_up\"]:hover {background-color: oa-color(color-ghost--hover);}"
                          "QPushButton[type=\"alert_row_down\"]:hover {background-color: oa-color(color-ghost--hover);}");

    string scrollbarStyle = ("QScrollBar:vertical {width: 8px; margin: 0px; border-radius: 4px;background: oa-color(color-2);}"
                             "QScrollBar:horizontal {height: 8px; margin: 0px; background: oa-color(color-2);}"
                             "QScrollBar:vertical:hover {background: oa-color(color-3);}"
                             "QScrollBar:horizontal:hover {background: oa-color(color-3);}"
                             "QScrollBar::handle:vertical {min-height: 20;border-radius: 4px;background: oa-color(color-5);}"
                             "QScrollBar::handle:horizontal {min-width: 20;border-radius: 4px;background: oa-color(color-5);}"
                             "QScrollBar::handle:vertical:hover {background: oa-color(color-7);}"
                             "QScrollBar::handle:horizontal:hover {background: oa-color(color-7);}"
                             "QScrollBar::add-line:vertical,QScrollBar::sub-line:vertical {background: none;}"
                             "QScrollBar::add-line:horizontal,QScrollBar::sub-line:horizontal {background: none;}"
                             "QScrollBar::add-page:vertical,QScrollBar::sub-page:vertical {background: none;}"
                             "QScrollBar::add-page:horizontal,QScrollBar::sub-page:horizontal {background: none;}");

    string chipStyle = ("QLineEdit[type^=\"fchip_\"] { color: oa-color(color-inv-contrast-text); border: none; border-radius: 12px; font-family: 'Siemens Sans'; font-style: normal; font-weight: 400; font-size: 14px; }"
                        "QLineEdit[type=\"fchip_primary\"] { border-color: oa-color(color-primary); background-color: oa-color(color-primary); }"
                        "QLineEdit[type=\"fchip_alarm\"] { border-color: oa-color(color-alarm); background-color: oa-color(color-alarm); }"
                        "QLineEdit[type=\"fchip_alarm_ref\"] { background-color: oa-color(color-alarm); }"
                        "QLineEdit[type=\"fchip_critical\"] { border-color: oa-color(color-critical); background-color: oa-color(color-critical); }"
                        "QLineEdit[type=\"fchip_warning\"] { border-color: oa-color(color-warning); background-color: oa-color(color-warning); }"
                        "QLineEdit[type=\"fchip_info\"] { border-color: oa-color(color-info); background-color: oa-color(color-info); }"
                        "QLineEdit[type=\"fchip_neutral\"] { border-color: oa-color(color-neutral); background-color: oa-color(color-neutral); }"
                        "QLineEdit[type=\"fchip_success\"] { border-color: oa-color(color-success); background-color: oa-color(color-success); }"
                        "QLineEdit[type=\"fchip_primary\"]:hover { border-color: oa-color(color-primary--hover); background-color: oa-color(color-primary--hover); }"
                        "QLineEdit[type=\"fchip_alarm\"]:hover { border-color: oa-color(color-alarm--hover); background-color: oa-color(color-alarm--hover); }"
                        "QLineEdit[type=\"fchip_critical\"]:hover { border-color: oa-color(color-critical--hover); background-color: oa-color(color-critical--hover); }"
                        "QLineEdit[type=\"fchip_warning\"]:hover { border-color: oa-color(color-warning--hover); background-color: oa-color(color-warning--hover); }"
                        "QLineEdit[type=\"fchip_info\"]:hover { border-color: oa-color(color-info--hover); background-color: oa-color(color-info--hover); }"
                        "QLineEdit[type=\"fchip_neutral\"]:hover { border-color: oa-color(color-neutral--hover); background-color: oa-color(color-neutral--hover); }"
                        "QLineEdit[type=\"fchip_success\"]:hover { border-color: oa-color(color-success--hover); background-color: oa-color(color-success--hover); }");

    string trendStyle = "TrendQT[type=\"primary\"]{border:none;}";

    string splitterStyle = ("QSplitter[type=\"primary\"]::handle { border: 1px solid oa-color(color-4); border-radius: 5px; color: oa-color(color-ghost); background-color: oa-color(color-ghost); }"
                            "QSplitter[type=\"primary\"]::handle:hover { background-color: oa-color(color-ghost--hover); }");

    cssCode = tooltipStyle + tableHeaderStyle + aesRowStyle + scrollbarStyle + chipStyle + trendStyle + splitterStyle;
    return cssCode;
  }
};
