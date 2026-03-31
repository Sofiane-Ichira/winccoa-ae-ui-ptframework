// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @brief The dialog framework allows you to open standard dialogs.
  @details The information()/warning()/question() is displayed as a text and  
  0 or 1 is returned (depending on the pressed button),
  The general() method allows you to specify a reference panel. The panel is added 
  as the content of the dialog.
  The multiLanguages() dialog allows you to edit and return multi-language strings.
  If a user-specific reference content panel is used, the public function 
  public bool requestedCloseOk(int choice, anytype &returnValue)
  can be implemented to allow a return value and to cancel closing 
  (see ScobleLib of the panels/objects/dialogFramework/parts/dialog_subInput.pnl).

  @note The dialog parameters can be styled by specifying the stylesheet options 
  in the Dialog Framework section of the config/styelsheet.css
  for the shapes with a "DialogFramework" type name. The shapes names defined 
  in the stylesheet have the following definition:
  "Text" - is the shape of the label where the dialog text message is shown;
  "DialogTitle" - is the shape of the label where the dialog title is shown;
  "DialogTitleColored" - is the shape of the label where the dialog colored title is shown;
  "Backside" - is the dialog background shape.
  
  /// @cond ETM_Internal  
  @copyright Siemens AG 2020
  @author Markus Trummer, Grygorii Sokhrannyi
  /// @endcond 
*/
class DialogFramework
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

  //--------------------------------------------------------------------------------
  /**
    @brief A function for opening a generic dialog, which displays content via 
    a given panel reference (dialog sub panel).
    @param options A mapping with the dialog properties. 
    The following keys are supported:
    + text - A text to display in the dialog.
    + title - A title to show in the dialog header. 
    When NULL or an empty string is specified, a title is not shown. 
    Default value: an empty string.
    + refFile - The file name of the dialog sub panel. Default value: 
    objects/dialogFramework/parts/dialog_subText.pnl.
    + buttonTextOk - A message catalog key of the general.cat file for the 
    1 (OK) button text. 
    When NULL or an empty string is specified, the button is invisible.
    If the message catalog key is not found, the text of the button is used
    as specified. Default value: an empty string.
    + buttonTextNOk - A message catalog key of general.cat for 
    the 0 (Cancel) button text. 
    When NULL or an empty string is specified, the button is invisible.
    If the message catalog key is not found, the buttons text is used. 
    Default value: close.
    + icon - File name of an icon file to be shown in the dialog header. 
    When NULL or an empty string is specified, an icon is not shown.
    The icon file name can be specified as a full path or as a relative path. 
    Default value: an empty string.
    + titleColor - Color of the dialog header background. When NULL or an empty string is 
    specified, the title does not have a background color.
    Default value: an empty string.
    + helpLink - The help page which will be opened by clicking on a Help button. 
    When NULL or an empty string is specified, then the help button is not shown.
    This parameter is a file name: helpNote.txt for the file 
    project_path/help/lang/helpNote.txt. Default value: an empty string.
    + dollars - Additional dollar parameters for the dialog sub panel.
    @return int button The selected button: 0 = Cancel button, 1 = OK button.
  */
  public static int general(const mapping &options)
  {
    anytype returnValue;
    dyn_string params = makeDynString("$TEXT:" + options["text"]);
    if ( mappingHasKey(options, "dollars") )
      dynAppend(params, options["dollars"]);

    return returnValueDialog(params,
                             mappingHasKey(options, "refFile") ? options["refFile"] : "objects/dialogFramework/parts/dialog_subText.pnl",
                             mappingHasKey(options, "title") ? options["title"] : "",
                             returnValue,
                             mappingHasKey(options, "buttonTextOk") ? options["buttonTextOk"] : "",
                             mappingHasKey(options, "buttonTextNOk") ? options["buttonTextNOk"] : "close",
                             mappingHasKey(options, "icon") ? options["icon"] : "",
                             mappingHasKey(options, "titleColor") ? options["titleColor"] : "",
                             mappingHasKey(options, "helpLink") ? options["helpLink"] : "");
  }

  //--------------------------------------------------------------------------------
  /**
    @brief A function for opening a dialog with information text.
    @param options Mapping with dialog properties. 
    The following keys are supported:
    + text - Text to display in the dialog.
    + title - Title to show in the dialog header. When NULL or an empty string 
    is specified, a title is not shown. Default value: Information.
    + refFile - File name of the dialog sub panel. Default value: 
    objects/dialogFramework/parts/dialog_subText.pnl.
    + buttonTextOk A message catalog key of the file general.cat for the 
    1 (OK) button text. 
    When a NULL or an empty string is specified, then the button is invisible.
    If the message catalog key is not found, then the buttons text is used as specified. 
    Default value: an empty string.
    + buttonTextNOk - A message catalog key of the file general.cat for the 
    0 (Cancel) button text. 
    When NULL or an empty string is given, the button is invisible.
    If the message catalog key is not found, the text of the button is used as specified. 
    Default value: close.
    + icon - A file name of an icon file to be shown in the dialog header. When NULL or an empty 
    string is given, an icon is not shown.
    The icon file name could specified as a full path or as a relative path. Default value: 
    dialogFramework/dialogInformation.svg.
    + titleColor - Color of the dialog header background. When NULL or an empty string is specified, 
    the default value for the color will be used.
    Default value: SiemensNaturalGreenLight.
    + helpLink - The help page opened by pressing on a Help button. 
    When NULL or an empty string is specified, a help button is not shown.
    This parameter is a file name: helpNote.txt for the file 
    project_path/help/lang/helpNote.txt. Default value: an empty string.
    + dollars - Additional dollar parameters for the dialog sub panel.
    
    @return int button Selected button: 0 = Cancel button, 1 = OK button.
  */
  public static int information(const mapping &options)
  {
    mapping _options = options;
    if ( !mappingHasKey(_options, "buttonTextNOk") )
      _options["buttonTextNOk"] = "close";

    if ( !mappingHasKey(_options, "titleColor") )
      _options["titleColor"] = "SiemensNaturalGreenLight";

    if ( !mappingHasKey(_options, "title") )
      _options["title"] = getCatStr("general", "information");

    if ( !mappingHasKey(_options, "icon") )
      _options["icon"] = "dialogFramework/dialogInformation.svg";

    return general(_options);
  }

  //--------------------------------------------------------------------------------
  /**
    @brief A function for opening a dialog with a warning text.
    @param options - Mapping with the dialog properties. The following keys are 
    supported:
    + text - Text to display in the dialog.
    + title - A title to show in the dialog header. When NULL or an empty string 
    is specified, a title is not shown. Default value: Warning.
    + refFile - A file name of the dialog sub panel. Default value: 
    objects/dialogFramework/parts/dialog_subText.pnl.
    + buttonTextOk - a message catalog key of general.cat for the 1 (OK) button text. 
    When NULL or an empty string is specified, the button is invisible.
    If the message catalog key is not found, then the text of the button is used as 
    specified. 
    Default value: empty string.
    + buttonTextNOk - message catalogue key of general.cat for the 0 (Cancel) button text. 
    When NULL or an empty string is given, the button is invisible.
    If the message catalog key is not found, then the buttons text will be used as given. 
    Default value: close.
    + icon - File name of an icon file to be shown in the dialog header. 
    When NULL or an empty string is specified, an icon is not shown.
    The icon file name could be specified as a full path or as a relative path. 
    Default value: dialogFramework/dialogWarning.svg.
    + titleColor - Color of the dialog header background. When NULL or an empty string 
    is specified, the default color is used.
    Default color: SiemensNaturalRedLight.
    + helpLink - The help page which is opened by clicking on a Help button. 
    When NULL or an empty string is specified, a help button is not shown.
    This parameter specifies the file name: helpNote.txt for the file 
    project_path/help/lang/helpNote.txt. Default value: an empty string.
    + dollars - Additional dollar parameters for the dialog sub panel.
    @return int button The selected button: 0 = Cancel button, 1 = OK button.
  */
  public static int warning(const mapping &options)
  {
    mapping _options = options;
    if ( !mappingHasKey(_options, "buttonTextNOk") )
      _options["buttonTextNOk"] = "close";

    if ( !mappingHasKey(_options, "titleColor") )
      _options["titleColor"] = "SiemensNaturalRedLight";

    if ( !mappingHasKey(_options, "title") )
      _options["title"] = getCatStr("general", "warning");

    if ( !mappingHasKey(_options, "icon") )
      _options["icon"] = "dialogFramework/dialogWarning.svg";

    return general(_options);
  }

  //--------------------------------------------------------------------------------
  /**
    @brief A function for opening a dialog with text and two options for selecting 
    and answer.
    @param options - Mapping with the dialog properties. The following keys are 
    supported:
    + text - Text to display in the dialog.
    + title - Title to be shown in the dialog header. When NULL or an empty string 
    is given, a title is not shown. Default value: Question.
    + refFile - File name of the dialog sub panel. Default value: 
    objects/dialogFramework/parts/dialog_subText.pnl.
    + buttonTextOk - Message catalog key of general.cat for the 1 (OK) button text. 
    When NULL or an empty string is specified, the button is invisible.
    If the message catalog key is not found, the text of the button is used as 
    specified. Default value: yes.
    + buttonTextNOk - Message catalog key of general.cat for the 0 (Cancel) 
    button text. When NULL or an empty string is specified, the button is 
    invisible.
    If the message catalog key is not found, the text of the button is used 
    as specified. Default value: no.
    + icon - File name of an icon file to be shown in the dialog header. 
    When NULL or an empty string is specified, an icon is not shown.
    The icon file name could specified as a full path or as a relative path. 
    Default value: dialogFramework/dialogQuestion.svg.
    + titleColor - color of the dialog header background. When NULL or 
    an empty string is specified, the default color is used.
    Default value: SiemensNaturalYellowLight.
    + helpLink - The help page which is opened by clicking on a Help button. 
    When NULL or an empty string is specified, no help button is shown.
    This parameter specifies the file name: helpNote.txt for the file 
    project_path/help/lang/helpNote.txt. Default value: an empty string.
    + dollars - Additional dollar parameters for the dialog sub panel.
    return int button The selected button: 0 = Cancel button, 1 = OK button.
  */
  public static int question(const mapping &options)
  {
    mapping _options = options;
    if ( !mappingHasKey(_options, "buttonTextOk") )
      _options["buttonTextOk"] = "yes";

    if ( !mappingHasKey(_options, "buttonTextNOk") )
      _options["buttonTextNOk"] = "no";

    if ( !mappingHasKey(_options, "titleColor") )
      _options["titleColor"] = "SiemensNaturalYellowLight";

    if ( !mappingHasKey(_options, "title") )
      _options["title"] = getCatStr("general", "question");

    if ( !mappingHasKey(_options, "icon") )
      _options["icon"] = "dialogFramework/dialogQuestion.svg";

    return general(_options);
  }

  //--------------------------------------------------------------------------------
  /**
    @brief The function opens a dialog with text and two options for selecting 
    an answer.
    @param[out] value - Diplayed and return value.
    @param options - Mapping with the dialog properties. The following keys 
    are supported:
    + text - A text displayed in the dialog.
    + title - A ttle shown in the dialog header. When NULL or an empty string is 
    specified, a title. Default value: empty string.
    + units - A text displayed after the value (e.g. the unit). When NULL or an empty 
    string is specified, a title is not shown. Default value: an empty string.
    + refFile - A file name of the dialog sub panel. 
    Default value: objects/dialogFramework/parts/dialog_subInput.pnl.
    If a user-defined reference content panel is used, the public function 
    public bool requestedCloseOk(int choice, anytype &returnValue)
    can be implemented to allow a return value and to cancel closing 
    (see ScobleLib of the panels/objects/dialogFramework/parts/dialog_subInput.pnl).
    + buttonTextOk - A message catalog key of the general.cat file for the 1 (OK) button text. 
    When NULL or an empty string is specified, the button is invisible.
    If the message catalog key is not found, the text of the button is used as specified. 
    Default value: apply.
    + buttonTextNOk - A message catalog key of the general.cat file for the 
    0 (Cancel) button text. When NULL or an empty string is specified, the button is invisible.
    If the message catalog key is not found, the text of the button is used as specified. Default value: cancel.
    + icon - The file name of an icon file to be shown in the dialog header. 
    When NULL or an empty string is specified, an icon is not shown.
    The icon file name can be specified as a full path or as a relative path. 
    Default value: dialogFramework/dialogEdit.svg.
    + titleColor - The color of the dialog header background. When a NULL or an empty string is specified,
    the default color is used.
    Default value: SiemensNaturalBlueLight.
    + helpLink - The help page which is opened by clicking on a Help button. 
    When NULL or an empty string is specified, no help button is shown.
    This parameter specifies the file name: helpNote.txt for the file 
    project_path/help/lang/helpNote.txt. Default value: an empty string.
    + enableAllButtons - An option for enabling all buttons (otherwise button 1 is disabled 
    as long the value does not differ from the start value).
    Default value: False.
    + dollars - Additional dollar parameters for the dialog sub panel.
    @return int button Selected button: 0 = Cancel button, 1 = OK button.
  */
  public static int input(anytype &value, const mapping &options)
  {
    mapping values = makeMapping("value", value, "type", getType(value)); //use mapping to transfer correct datatype
    dyn_string params = makeDynString("$TEXT:" + options["text"],
                                      "$TEXT2:" + (mappingHasKey(options, "units") ? options["units"] : ""),
                                      "$VALUE:" + jsonEncode(values));

    if ( mappingHasKey(options, "dollars") )
      dynAppend(params, options["dollars"]);

    int answer = returnValueDialog(params,
                                   mappingHasKey(options, "refFile") ? options["refFile"] : "objects/dialogFramework/parts/dialog_subInput.pnl",
                                   mappingHasKey(options, "title") ? options["title"] : "",
                                   values,
                                   mappingHasKey(options, "buttonTextOk") ? options["buttonTextOk"] : "apply",
                                   mappingHasKey(options, "buttonTextNOk") ? options["buttonTextNOk"] : "cancel",
                                   mappingHasKey(options, "icon") ? options["icon"] : "dialogFramework/dialogEdit.svg",
                                   mappingHasKey(options, "titleColor") ? options["titleColor"] : "SiemensNaturalBlueLight",
                                   mappingHasKey(options, "helpLink") ? options["helpLink"] : "",
                                   mappingHasKey(options, "enableAllButtons") ? options["enableAllButtons"] : FALSE);

    if ( answer )
      value = values["value"];

    return answer;
  }

  //--------------------------------------------------------------------------------
  /**
    @brief The function opens a dialog for editing a multi-lingual string.
    @param langText Multi-lingual text which should be edited.
    @param title The dialog title, if an empty string is specified "", a title is not 
    shown. The default value is "".
    @param extraTitle The second colored dialog title, if an empty string is specified "", 
    a title is not shown. The default value is "".
    @return int button The function returns 0, when the Cancel button is clicked and
    1, when the OK button is clicked
  */
  public static int multiLanguages(langString &langText, string title = "", string extraTitle = "")
  {
    // The return value is always a decoded json string, so make sure the provided value has the right type
    string langJson = jsonEncode(langText);
    dyn_mapping results = jsonDecode(langJson);

    int answer = returnValueDialog(makeDynString("$TEXT:" + langJson, "$TITLE:" + title, "$TITLECOL:" + extraTitle),
                                   "objects/dialogFramework/parts/multiLangEditor.pnl", "", results);
    langText = mappingToLangString(results[1]);

    return answer;
  }

  //--------------------------------------------------------------------------------
  //@private members
  //--------------------------------------------------------------------------------

  //--------------------------------------------------------------------------------
  /**
    @brief The function opens a generic dialog, which displays content via 
    a specified panel reference (dialog sub panel) and returns an anytype 
    value via a reference parameter.
    @param params Dollar parameters for the dialog sub panel.
    @param panelRefFile A file name of the dialog sub panel. Iif the function 
    public bool requestedCloseOk(int iChoice, anytype &aRetValue) exists,
    the function is executed before finishing. The default value is 
    "objects/dialogFramework/parts/dialog_subText.pnl".
    @param title A title shown in the dialog header. The default value is "".
    @param returnValue An anytype reference parameter used in the function
    public bool requestedCloseOk(int iChoice, anytype &aRetValue) in the
    dialog sub panel.
    @param buttonTextOk A yes/no/ok/cancel/close message catalog key for a button.
    1 (OK) text from the message catalog general.cat is used.
    If a catalog key is not being used "", the button is invisible. 
    The default value is "".
    @param buttonTextNOk yes/no/ok/cancel/close message catalog key for a button.
    0 (Cancel) text from the message catalog general.cat is used.
    If a catalog key is not being used "", the button is invisible. 
    The default value is "".
    @note If the message catalog key is not found, the button texts are 
    used as specified.
    @param icon Optional file name of an icon file. If an empty string is specified "", 
    an icon is not shown. The default value is "".
    @param titleColor Optional color for the header background. If an empty string is 
    specified "", the default color is used. The default value is "".
    @param helpLink Option for defining a help page, which can be opened as a popup.
    If an empty string is specified "", a help button is not shown. 
    The default value is "". The specified help page path must 
    be relative to the help/lang/ directory. The page can be an arbitrary HTML page or 
    a text file.
    @note This parameter is a file name: helpNote.txt for the file project_path/help/lang/helpNote.txt.
    @param enableAllButtons An option for enabling all buttons (otherwise the button 1 is disabled). 
    The default value is TRUE.
    @return int button The selected button: 0 = Cancel button, 1 = OK button.
  */
  private static int returnValueDialog(dyn_string params,
                                       string panelRefFile = "objects/dialogFramework/parts/dialog_subText.pnl",
                                       string title = "",
                                       anytype &returnValue,
                                       string buttonTextOk = "",
                                       string buttonTextNOk = "",
                                       string icon = "",
                                       string titleColor = "",
                                       string helpLink = "",
                                       bool enableAllButtons = TRUE)
  {
    string key = buttonTextOk;

    if ( buttonTextOk != "" )
      buttonTextOk = getCatStr("general", strtolower(buttonTextOk));

    if ( dynlen(getLastError()) > 0 )
      buttonTextOk = key;

    key = buttonTextNOk;
    if ( buttonTextNOk != "" )
      buttonTextNOk = getCatStr("general", strtolower(buttonTextNOk));

    if ( dynlen(getLastError()) > 0 )
      buttonTextNOk = key;

    dynAppend(params, "$Btn0:"             + buttonTextNOk);
    dynAppend(params, "$Btn1:"             + buttonTextOk);
    dynAppend(params, "$TitleText:"        + title);
    dynAppend(params, "$PanelRef:"         + panelRefFile);
    dynAppend(params, "$ICON:"             + icon);
    dynAppend(params, "$TITLECOLOR:"       + titleColor);
    dynAppend(params, "$HelpLink:"         + helpLink);      //If help is set, the dollar parameter activates (shows) the help button.
    dynAppend(params, "$EnableAllButtons:" + enableAllButtons); //If help is set, the dollar parameter activates (shows) the help button.

    int answer; //The default value is "cancel".

    // Allows a dialog to be started from a dialog. The panel name must be unique.
    string panelDefault = "dialog";
    string panel = panelDefault;
    int count = 0;

    while ( isPanelOpen(panel) )
    {
      count++;
      panel = panelDefault + "_" + count;
    }

    mapping options = makeMapping("makeVisible", FALSE);
    dyn_anytype da = makeDynAnytype(myModuleName(), "objects/dialogFramework/parts/dialog.pnl", myPanelName(), panel, 50, 50, 1.0, FALSE, params, FALSE, options);
    anytype daReturn;
    childPanel(da, daReturn);
    if ( dynlen(daReturn) > 0 ) // ALT + F4 was not pressed
    {
      answer = daReturn[1];
    }

    if ( (dynlen(daReturn) > 1) && (strlen(daReturn[2]) > 0) && (answer != 0) ) //Ok button pressed, 
     //otherwise do not modify the return value.
    {
      returnValue = jsonDecode(daReturn[2]);
    }

    return answer; //Button number
  }

  //--------------------------------------------------------------------------------
  /**
    @brief Converts a mapping to a langString.
    @details The mapping must be the language string used in a project.
    All non-mapping variables return an empty language string.
    @param mappingValue Mapping containing a langString or an empty string.
    @return langString The converted langString.
  */
  private static langString mappingToLangString(const anytype &mappingValue)
  {
    langString text;
    if ( getType(mappingValue) == MAPPING_VAR )
    {
      dyn_string keys = mappingKeys(mappingValue);
      for (int i = 1; i <= dynlen(keys); i++)
        setLangString(text, getLangIdx(keys[i]), mappingValue[keys[i]]);
    }
    else if ( getType(mappingValue) == STRING_VAR )
    {
      text = mappingValue;
    }

    return text;
  }
};
