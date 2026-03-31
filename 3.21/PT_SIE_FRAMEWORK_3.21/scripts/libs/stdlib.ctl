#uses "stdlib_hook_project.ctl"
#uses "stdlib_managehooks.ctl"
#uses "CtrlPv2Admin"
#uses "ac.ctl"
#uses "dpGetCache.ctl"

/*
** stdlib.ctl
** functions of standard library framework
*/

global bool DebugInfos = false;
global bool gbDirectInputIntoTextFields = false;
global bool gUseNotes = true;
global bool gFaceplateModal = false;
global int g_openFaceplateTriggerEvent = 0;
global string gStdLibName = "STDLIB";
global int gInfoAreaMax = 6;
global bool gInitState = false;
global bool gbLicenseMsgWasDisplayed = false;
global mapping mConfiguration;

int DPMONITOR         = 1,
    PARA              = 2,
    HELP              = 3,
    ALARMS            = 4,
    EVENTS            = 5,
    TREND             = 6;

mapping MSGCATPATH;
global mapping mModeValueIcon;

/*
@author Andreas Gruber
Initializes global variables for the stdlib and reads config file entries.
Real init is only once done per UI, independent, how often this function is called
*/
mapping initGlobals()
{
  if (!gInitState)  // if not initialized, first check outside of synchronized=faster
  {
    synchronized (gInitState)  // this code cannot run simultaniously
    {
      if (!gInitState)  // is really not initialized
      {
        // read config file entries
        string stemp = "";

        paCfgReadValue(PROJ_PATH + "config/config", "stdlib", "faceplateModal", stemp);
        if (stemp != "")
          gFaceplateModal=stemp;

        stemp = "";

        //to allow to open the faceplate by default in dock window (e.g. with PT Siemens framework)
        bool bDefault = 0;
        g_openFaceplateTriggerEvent = paCfgReadValueDflt(getPath(CONFIG_REL_PATH, "config"), "stdlib", "openFaceplaceTriggerEvent", 0, bDefault);

        for (int i = 1; i <= SEARCH_PATH_LEN && bDefault; i++)
        {
          string sCfgFile = getPath(CONFIG_REL_PATH, "config.level", -1, i);

          if (sCfgFile != "")
          {
            g_openFaceplateTriggerEvent = paCfgReadValueDflt(sCfgFile, "stdlib", "openFaceplaceTriggerEvent", 0, bDefault);
          }
        }

        stemp = "";
        paCfgReadValue(PROJ_PATH + "config/config", "stdlib", "directInputIntoTextFields", stemp);
        if (stemp != "")
          gbDirectInputIntoTextFields = stemp;

        stemp = "";
        paCfgReadValue(PROJ_PATH + "config/config", "stdlib", "useNotes", stemp);
        if (stemp != "")
          gUseNotes=stemp;

        stemp="";
        paCfgReadValue(PROJ_PATH + "config/config", "stdlib", "infoAreaMax", stemp);
        if (stemp != "")
          gInfoAreaMax=stemp;

        dyn_int modeValue;
        dyn_string modeIcon;
        for (int i = 1; i <= gInfoAreaMax; i++)
        {
          // read internal DPEs, Values and corresponding Icons
          dpGet("_" + gStdLibName + "_Modes_" + i + ".modeValue", modeValue,
                "_" + gStdLibName + "_Modes_" + i + ".modeIcon", modeIcon);
          mModeValueIcon[i + ".modeValue"] = modeValue;
          mModeValueIcon[i + ".modeIcon"] = modeIcon;
        }
        gInitState = true;  // now initializing is done
        //workaround for PocketClient
        mConfiguration["faceplateModal"]=gFaceplateModal;
        mConfiguration["directInputIntoTextFields"]=gbDirectInputIntoTextFields;
        mConfiguration["useNotes"]=gUseNotes;
        mConfiguration["infoAreaMax"]=gInfoAreaMax;
      }
    }
  }
  return mConfiguration;
}

/*
@author Andreas Gruber
Initializes the Elementary Symbol. Checks the given DPEs and connects to them
@param sDP ... Datapoint
@param sDPE ... DPE relative to sDP
@param sDPEVisible ... DPE used for set Elementary symbol visible (empty=not used), relative to sDP
@param sVisibleRules ... rule to manipulate visible result
@param sDPEEnable ... DPE used for set Elementary symbol enabled (empty=not used), relative to sDP
@param sEnableRules ... rule to manipulate enabled result
@param sDPEHighlight ... DPE used for set Elementary symbol highlighted (empty=not used), relative to sDP
@param sHighlightRules ... rule to manipulate highlighted result
@panelGlobal mLastState ... mapping used to store needed information in callback, defined in scopelib of elementary symbol
@return (string) ... complete path to DPE (sDP + sDPE)
*/
string initializeElementarySymbolView(string sDP, string sDPE, string sDPEVisible, string sVisibleRules,
                                                               string sDPEEnable, string sEnableRules,
                                                               string sDPEHighlight, string sHighlightRules)
{
  dyn_string dsConnDPEs;
  int i;
  if (strpos(sDP, ".") < 1)
    sDP += ".";
  initGlobals();

  sDP=stdlib_addTrailingDot(sDP);
  if (sDPE[0] == ".")  //remove beginning "."
    sDPE = substr(sDPE, 1);

  mLastState["firstRun"] = true;  // initialize mapping within elementary symbol

  // add DPE and corresponding invalid config (for display in the elementary symbol) to connection dyn_string and to the mapping

  // TFS 9606
  if ( sDPE != "" && dpExists(sDP + sDPE) )
  {
    dynAppend(dsConnDPEs, sDP + sDPE);
    dynAppend(dsConnDPEs, dpSubStr(sDP + sDPE, DPSUB_SYS_DP_EL) + ":_original.._invalid");

    mLastState["DPE"] = sDP + sDPE;
    mLastState["DPEInvalid"] = dpSubStr(sDP + sDPE, DPSUB_SYS_DP_EL) + ":_original.._invalid";


    // add visible DPE and rule to mapping and, if not empty, add the DPE and the dyn_string
    mLastState["DPEVisible"] = sDPEVisible;
    mLastState["visibleRules"] = sVisibleRules;

    if (strlen(sDPEVisible) > 0)
    {
      sDPEVisible = sDP + sDPEVisible;
      i = dynContains(dsConnDPEs, sDPEVisible);
      mLastState["DPEVisibleIndex"] = i;  // write found index to mapping to find the value in CB function if DPE is already within dyn_string
      if (i <= 0)  // if DPE is already within dyn_string, dont add it again, dpConnect cant connect more than 1 times to 1 DPE
        dynAppend(dsConnDPEs, sDPEVisible);
    }
    else
      mLastState["visibleValue"] = true;  // default, if no DPE entered

    // add enable DPE and rule to mapping and, if not empty, add the DPE and the dyn_string
    mLastState["DPEEnable"] = sDPEEnable;
    mLastState["enableRules"] = sEnableRules;
    if (strlen(sDPEEnable) > 0)
    {
      sDPEEnable = sDP + sDPEEnable;
      i = dynContains(dsConnDPEs, sDPEEnable);
      mLastState["DPEEnableIndex"] = i;  // write found index to mapping to find the value in CB function if DPE is already within dyn_string
      if (i <= 0)  // if DPE is already within dyn_string, dont add it again, dpConnect cant connect more than 1 times to 1 DPE
        dynAppend(dsConnDPEs, sDPEEnable);
    }
    else
      mLastState["enableValue"] = true;  // default, if no DPE entered

    // add highlight DPE and rule to mapping and, if not empty, add the DPE and the dyn_string
    mLastState["DPEHighlight"] = sDPEHighlight;
    mLastState["highlightRules"] = sHighlightRules;
    if (strlen(sDPEHighlight)>0)
    {
      sDPEHighlight = sDP + sDPEHighlight;
      i = dynContains(dsConnDPEs, sDPEHighlight);
      mLastState["DPEHighlightIndex"] = i;  // write found index to mapping to find the value in CB function if DPE is already within dyn_string
      if (i <= 0)  // if DPE is already within dyn_string, dont add it again, dpConnect cant connect more than 1 times to 1 DPE
        dynAppend(dsConnDPEs, sDPEHighlight);
    }
    else
      mLastState["highlightValue"] = false;  // default, if no DPE entered

    dyn_string ds;
    dyn_string otherConnDps;
    ds = hook_addEnableRuleDpes(sDP + sDPE);
    mLastState["LibEnableConnect"] = false;
    if (dynlen(ds) >= 1)
    {
      dynAppend(otherConnDps, ds);
      mLastState["LibEnableConnect"] = true;
    }
    ds = hook_addVisibleRuleDpes(sDP + sDPE);
    mLastState["LibVisibleConnect"] = false;
    if (dynlen(ds) >= 1)
    {
      dynAppend(otherConnDps, ds);
      mLastState["LibVisibleConnect"] = true;
    }
    ds = hook_addHighlightRuleDpes(sDP + sDPE);
    mLastState["LibHighlightConnect"] = false;
    if (dynlen(ds) >= 1)
    {
      dynAppend(otherConnDps, ds);
      mLastState["LibHighlightConnect"] = true;
    }

    for (int i= 1; i<=dynlen(otherConnDps); i++)
    {
      if (dynContains(dsConnDPEs, otherConnDps[i]) <= 0)  //ToDo: Better compare, check for config and systemname
        dynAppend(dsConnDPEs, otherConnDps[i]);
    }

    dpConnect("workInitializeElementarySymbolView", true, dsConnDPEs);
  }

  dyn_errClass err;
  err = getLastError(); // check for errors
  if (dynlen(err) > 0)
  {
    errorDialog(err); // Open a Dialog with error description
    throwError(err); // Write error on stderr
  }

  return sDP + sDPE;
}

/*
@author Andreas Gruber
Callback from initializeElementarySymbolView
Evaluates the values from the dpConnect and initializes the Elementary Symbol.
@param dsDPE ... connected DPEs
@param daVal ... Values of the conncted DPEs
@panelGlobal mLastState ... mapping used to read needed information set from the initialize function
                            calculated states and values are also stored, defined in scopelib of elementary symbol
*/
workInitializeElementarySymbolView(dyn_string dsDPE, dyn_anytype daVal)
{
  anytype visibleValue, enableValue, highlightValue;
  bool visible, enable, highlight, invalid;
  anytype value;
  bool bExecScript;
  int i;
  bool bFirstRun = mLastState["firstRun"];  // is it the first call to the CB function?

  value = daVal[1];   // item 1 is always the DPE Value
  invalid = daVal[2]; // item 2 is always the DPE+Invalid

  // execute setValue function if its the first run of the CB function or if values changed
  bExecScript = false;
  if (bFirstRun)
    bExecScript = true;
  else if (mLastState["value"] != value || mLastState["invalid"] != invalid)
    bExecScript = true;

  // store values in mapping
  mLastState["value"] = value;
  mLastState["invalid"] = invalid;

  if (bExecScript)
  {
    if (DebugInfos) DebugN("value", value, "invalid", invalid);
    execScript("int main(anytype value) { panelSetValue(value); }", makeDynString(), value);  // execute the setValue function
  }

  i = 2;
  if (strlen(mLastState["DPEVisible"]) > 0 || bFirstRun || mLastState["LibVisibleConnect"])  // do something if first run or if there is an DPE given
  {
    if (strlen(mLastState["DPEVisible"]) == 0)  // use the default value if no DPE is given
      visibleValue=mLastState["visibleValue"];
    else
    {
      if (mLastState["DPEVisibleIndex"] <= 0)  // the used DPE is not referenced to another one within the dpConnect
      {
        i++;   // increase dyn-Value Index
        visibleValue = daVal[i];
      }
      else  // the used DPE was used more times within the dpConnect, get the value from a different index now
        visibleValue = daVal[mLastState["DPEVisibleIndex"]];
    }

    // execute setVisible function if its the first run of the CB function or if values changed
    bExecScript = false;                                          //ToDo: make a lastValueCompare if LibVisibleConnect
    if (bFirstRun || mLastState["LibVisibleConnect"])
      bExecScript = true;
    else if (mLastState["visibleValue"] != visibleValue)
      bExecScript = true;

    mLastState["visibleValue"] = visibleValue;  // store value in mapping
    if (bExecScript)
    {
      // get final result by interpret the rule and call an additional hook_function
      visible = interpretRuleExpression(visibleValue, mLastState["visibleRules"]) &&
                hook_visibleElementarySymbol(mLastState["DPE"]) &&
                hook_libVisibleElementarySymbol(mLastState["DPE"], dsDPE, daVal);
      mLastState["visible"] = visible;  // store final result in mapping
      if (DebugInfos) DebugN("visibleValue", visibleValue, "visible", visible);
      execScript("int main() { panelSetVisibility("+visible+"); }", makeDynString());  // execute the setVisibility function
    }
  }

  if (strlen(mLastState["DPEEnable"]) > 0 || bFirstRun || mLastState["LibEnableConnect"])  // do something if first run or if there is an DPE given
  {
    if (strlen(mLastState["DPEEnable"]) == 0)  // use the default value if no DPE is given
      enableValue = mLastState["enableValue"];
    else
    {
      if (mLastState["DPEEnableIndex"] <= 0)  // the used DPE is not referenced to another one within the dpConnect
      {
        i++;   // increase dyn-Value Index
        enableValue = daVal[i];
      }
      else  // the used DPE was used more times within the dpConnect, get the value from a different index now
        enableValue = daVal[mLastState["DPEEnableIndex"]];
    }

    // execute setEnable function if its the first run of the CB function or if values changed
    bExecScript = false;                                          //ToDo: make a lastValueCompare if LibEnableConnect
    if (bFirstRun || mLastState["LibEnableConnect"])
      bExecScript = true;
    else if (mLastState["enableValue"] != enableValue)
      bExecScript = true;

    mLastState["enableValue"] = enableValue;  // store value in mapping
    if (bExecScript)
    {
      // get final result by interpret the rule and call an additional hook_function
      enable = interpretRuleExpression(enableValue, mLastState["enableRules"]) &&
               hook_enableElementarySymbol(mLastState["DPE"]) &&
               hook_libEnableElementarySymbol(mLastState["DPE"], dsDPE, daVal);
      mLastState["enable"] = enable;  // store final result in mapping
      if (DebugInfos) DebugN("enableValue", enableValue, "enable", enable);
      execScript("int main() { panelSetEnabled("+enable+"); }", makeDynString());  // execute the setEnabled function
    }
  }

  if (strlen(mLastState["DPEHighlight"]) > 0 || bFirstRun || mLastState["LibHighlightConnect"])  // do something if first run or if there is an DPE given
  {
    if (strlen(mLastState["DPEHighlight"]) == 0)  // use the default value if no DPE is given
      highlightValue = mLastState["highlightValue"];
    else
    {
      if (mLastState["DPEHighlightIndex"] <= 0)  // the used DPE is not referenced to another one within the dpConnect
      {
        i++;   // increase dyn-Value Index
        highlightValue = daVal[i];
      }
      else  // the used DPE was used more times within the dpConnect, get the value from a different index now
        highlightValue = daVal[mLastState["DPEHighlightIndex"]];
    }

    // execute setHighlight function if its the first run of the CB function or if values changed
    bExecScript = false;                                          //ToDo: make a lastValueCompare if LibHighlightConnect
    if (bFirstRun || mLastState["LibHighlightConnect"])
      bExecScript = true;
    else if (mLastState["highlightValue"] != highlightValue)
      bExecScript = true;

    mLastState["highlightValue"] = highlightValue;  // store value in mapping
    if (bExecScript)
    {
      // get final result by interpret the rule and call an additional hook_function
      highlight = interpretRuleExpression(highlightValue, mLastState["highlightRules"]) ||
                  hook_highlightElementarySymbol(mLastState["DPE"]) ||
                  hook_libHighlightElementarySymbol(mLastState["DPE"], dsDPE, daVal);
      mLastState["highlight"] = highlight;  // store final result in mapping
      if (DebugInfos) DebugN("highlightValue", highlightValue, "highlight", highlight);
      execScript("int main() { panelSetHighlighting("+highlight+"); }", makeDynString());  // execute the setHighlighted function
    }
  }

  if (bFirstRun)
    mLastState["firstRun"] = false;   // reset firstRun flag
}

/*
@author Andreas Gruber
Interprets a Rule and returns the result
@param aValue ... value to be used within the rule
@param sRule ... rule to be interpreted
@return (bool) ... result of the interpreted rule or, if no rule given, aValue
                   false if there was an error within the rule
*/
private bool interpretRuleExpression(anytype aValue, string sRule)
{
  string stemp;
  bool bRet;

  if (strlen(sRule) == 0)  // return aValue if there is no rule
    return aValue;
  else
  {
    if (ruleCheck(sRule, stemp))  // convert the rule to an expression check it for errors (expression is returned in 2nd parameter)
    {
      // execute expression and return its result
      evalScript(bRet, stemp, makeDynString(), aValue);
      return bRet;
    }
    else
    {
      // expression has an error, return false
      errClass retError; //  errClass-Variable for makeError-Function
      retError=makeError("stdlib", PRIO_SEVERE, ERR_PARAM, 1001, sRule+"\n"+stemp);
      throwError(retError); //Gibt den Fehler
      return false;
    }
  }
}

/*
@author Andreas Gruber
Checks a Rule for syntactical errors
@param sRule ... rule to be interpreted
@refparam &sScript ... CTRL function code including the converted expression from the rule
@return (bool) ... true if the rule is OK
                   false if there was an error within the rule
*/
bool ruleCheck(string sRule, string &sScript)
{
  string stemp;
  int i;
  bool bRet = false;

  stemp = ruleGetIfFromRule(sRule);  // get expression from rule

  // put expression into a function and run checkScript with it
  sScript = "bool main(anytype aValue)" +
            "{" +
            "return ("+stemp+");" +
            "}";

  bRet = checkScript(sScript);

  // check if there are function calls or string delimiters
  if (bRet)
  {
    if (strpos(sRule, "()") >= 0)
      bRet = false;
    else if (strpos(sRule, "\"") >= 0)
      bRet = false;
  }

  // if theres no error, return the function with the expression with the reference parameter &sScript
  if (!bRet)
    sScript = stemp;

  return bRet;
}

/*
@author Andreas Gruber
Converts a Rule to a CTRL expression
@param sRule ... rule to be converted
@return (string) ... converted CTRL expression from the given rule
*/
string ruleGetIfFromRule(string sRule)
{
  string stemp;
  int found1, found2, found3, found4, charCnt;  // reused variables for results of strpos and strtok

  if (DebugInfos) DebugN(sRule);

  // remove all spaces and replace ',' by '|' to avoid conflicts wit the getBit function
  strreplace(sRule, " ", "");
  strreplace(sRule, ",", "|");

  // change a !value into a !(value)
  found1 = strpos(sRule, "!");  // find first '!'
  stemp = "";  // init temporary string
  while (found1 >= 0)  // as long as there are '!' found
  {
    found1++;

    // move all before and including the '!' to the temp string
    stemp += substr(sRule, 0, found1);
    sRule = substr(sRule, found1);

    if (sRule[0] != "(")  // if the is no '(' after the '!', insert a '(' and after the value a ')'
    {
      stemp += "(";
      found2 = ruleGetEndIndexOfNextValue(sRule);
      if (found2 == -1)  // end of value could not have been found, take the whole rest of the string
      {
        stemp += sRule + ")";
        sRule = "";
      }
      else  // move the value to the temp string
      {
        stemp += substr(sRule, 0, found2) + ")";
        sRule = substr(sRule, found2);
      }
    }
    found1 = strpos(sRule, "!");  // find next '!' within the rule
  }
  sRule = stemp + sRule;  // add the modified parts (stemp) before the not modified ones (sRule)

  found1 = ruleGetBeginIndexOfNextValue(sRule);  // get the index of the first value
  stemp = "";  // init temporary string
  while (found1 >= 0)  // as long as values are found
  {
    // search for "<=", ">=", "<", ">", as in that case, its not needed to insert a "=="
    found2 = strpos(sRule, "<=");
    found3 = strpos(sRule, ">=");
    found4 = strtok(sRule, "<>");

    if (sRule[found1] == "b")  // check if found value is a 'b' ( b? -> getBit(aValue, ?) )
    {
      // move all before the 'b' to stemp and add the getBit call
      stemp += substr(sRule, 0, found1) + "getBit(aValue, ";
      found1++;
      sRule = substr(sRule, found1);

      found2 = ruleGetEndIndexOfNextValue(sRule);  // get end of the found 'b'-value
      if (found2 == -1)  // end of value could not have been found, take the whole rest of the string and add the ')' as end of the getBit function
      {
        stemp += sRule + ")";
        sRule = "";
      }
      else  // move the value to the temp string and add the ')' as end of the getBit function
      {
        stemp += substr(sRule, 0, found2) + ")";
        sRule = substr(sRule, found2);
      }
    }
    else  // no bit comparisson
    {
      // if "<=", ">=", "<", ">" are found, dont insert "=="
      if ((found2 >= 0 && found2 < found1) ||
          (found3 >= 0 && found3 < found1) ||
          (found4 >= 0 && found4 < found1))
      {
        charCnt = 1;
        // insert the "aValue" to stemp and move the comparisson char(s) and value to stemp
        stemp += substr(sRule, 0, found1 - charCnt) + "aValue" + substr(sRule, found1 - charCnt, charCnt);
        sRule = substr(sRule, found1);
      }
      else
      {
        // insert the "aValue==" to stemp and move the value to stemp
        stemp += substr(sRule, 0, found1) + "aValue==";
        sRule = substr(sRule, found1);
      }
      found2 = ruleGetEndIndexOfNextValue(sRule);
      if (found2 == -1)  // end of value could not have been found, take the whole rest of the string
      {
        stemp += sRule;
        sRule = "";
      }
      else  // move the value to the temp string
      {
        stemp += substr(sRule, 0, found2);
        sRule = substr(sRule, found2);
      }
    }
    found1 = ruleGetBeginIndexOfNextValue(sRule);  // get the index of the next value
  }
  sRule = stemp + sRule;  // add the modified parts (stemp) before the not modified ones (sRule)

  // finally for a CTRL expression replace "|" by " || " and "&" by " && "
  strreplace(sRule, "|", " || ");
  strreplace(sRule, "&", " && ");

  if (DebugInfos) DebugN("coverted rule to expression", sRule);

  return sRule;
}

/*
@author Andreas Gruber
Finds the End of the first value within a Rule
@param sRule ... rule to be searched
@return (int) ... index
*/
int ruleGetEndIndexOfNextValue(string sRule)
{
  int found = strtok(sRule, "|&)");
  return found;
}

/*
@author Andreas Gruber
Finds the Begin of the first value within a Rule
@param sRule ... rule to be searched
@return (int) ... index
*/
int ruleGetBeginIndexOfNextValue(string sRule)
{
  int found = strtok(sRule, "()|&!<>");  // find one of the chars, that are not possible values;
  int iRet = 0;

  while (found == 0)  // as long as one is found on pos 0, repeat
  {
    iRet++;  // add 1 to char counter
    sRule = substr(sRule, 1);  // remove one char
    found = strtok(sRule, "()|&!<>");  // and search again
  }
  if (strlen(sRule) == 0)  // if there is no next value return -1
    iRet = -1;

  return iRet;
}

/*
@author Andreas Gruber
Checks for authorization via the _auth config
@param DPE ... DPE to check
@param userName ... PVSS username
@return (bool) ... is authorized?
*/
bool hasUserAuthorization(string DPE, string userName)
{
  int iAuth;
  bool bRet;
  int iTmp;

  DPE = dpSubStr(DPE, DPSUB_SYS_DP_EL); //because the ElementarySymbol could be connected to *:_original.._text

  iTmp = hook_hasUserAuthorization(DPE, userName);  // call the hook function, returns 0 or 1 if implemented
  if (iTmp >= 0)
    bRet = iTmp;
  else  // if hook function not implemented
  {
    dpGet(DPE + ":_auth.._type", iAuth);
    if (iAuth==0)
      bRet = hasUserAuthorizationFromLeaf(DPE, userName);  // if there is not _auth config, check the authorization via leaf names
    else
    {
      dpGet(DPE + ":_auth._original._write", iAuth);  // get the bit needed
      if (iAuth == 0)
        bRet = true; // if no bit needed, authorized
      else
        bRet = getUserPermission(iAuth, getUserId(userName)); // check if user has set the needed bit
    }
  }

  return bRet;
}

/*
@author Andreas Gruber
Checks for authorization via a leaf name
@param DPE ... DPE to check
@param userName ... PVSS username
@return (bool) ... is authorized?
*/
bool hasUserAuthorizationFromLeaf(string DPE, string userName)
{
  bool bRet;
  int iBit = -1;
  dyn_string dstemp;

  dstemp = strsplit(DPE, ".");  // split the DPE name into its sub leafs

  for (int i = dynlen(dstemp); i >= 2 && iBit == -1; i--)  // go through the leafs in descending order
  {
    switch (dstemp[i])
    {
      case "ALM":
      case "alarm": iBit = 5; break;  // for ALM or Alert, Bit 5 is needed
      case "STA":
      case "state": iBit = 2; break;  // for STA or State, Bit 2 is needed
      case "CMD":
      case "command": iBit = 2; break;  // for CMD or Command, Bit 2 is needed
      case "PAR":
      case "para": iBit = 3; break;  // for PAR or Para, Bit 3 is needed
      default: break;
    }
  }
  if (iBit == -1) // if no leaf found, return true
    bRet = true;
  else
    bRet = getUserPermission(iBit, getUserId(userName)); // check if user has set the needed bit

  return bRet;
}

/*
@author Andreas Gruber
does a connect for all necessary DPEs for a symbol
@param dp ... DP of the symbol
*/
void makeInfoAreaDisplayConnection(string dp)
{
  dyn_string dsDPE, dstemp;

  initGlobals();

  for (int i = 1; i <= gInfoAreaMax; i++)  // go once through all infoAreas
  {
    dstemp = hook_getInfoAreaDPEs(dp, i);  // get DPEs for this infoArea
    dynAppend(diInfoAreaIndex, dynlen(dstemp));  //diInfoAreaIndex defined in Scope of info_area.pnl Referencepanel
    if (DebugInfos) DebugTN("Corner", i);
    if (DebugInfos) DebugN(dstemp);
    dynAppend(dsDPE, dstemp);  // add DPEs to connect to a dyn_string
  }
  if (DebugInfos) DebugN(diInfoAreaIndex);
  if (dynlen(dsDPE) > 0)
  {
    // do one connect for all DPEs for all infoAreas of this symbol
    dpConnect("workInfoAreaDisplay", true, dsDPE);
    dyn_errClass err;
    err = getLastError(); // check for errors
    if (dynlen(err) > 0)
    {
      errorDialog(err); // Open a Dialog with error description
      throwError(err); // Write error on stderr
    }
  }
}

/*
@author Andreas Gruber
work function of makeInfoAreaDisplayConnection, calls the display routine for the infoAreas
@param dsDPE ... DPEs of the connect
@param daVal ... Values of the connect
*/
workInfoAreaDisplay(dyn_string dsDPE, dyn_anytype daVal)
{
  int dpeCount=0;
  mapping m;
  bool bRefresh;
  if (DebugInfos) DebugTN("workInfoAreaDisplay");

  for (int i = 1; i <= gInfoAreaMax; i++)  // go once through all infoAreas
  {
    bRefresh = false;
    mappingClear(m);
    for (int j = 1; j <= diInfoAreaIndex[i]; j++)
    {
      m[dsDPE[dpeCount + j]] = daVal[dpeCount + j];
      if (!bRefresh)
        if (bFirstRun)
          bRefresh = true;
        else
          if (daOldVal[dpeCount + j] != daVal[dpeCount + j])
            bRefresh = true;
    }

    if (diInfoAreaIndex[i] > 0 && bRefresh)
    {
      hook_displayInfoAreaIcon(i, m);
    }

    dpeCount += diInfoAreaIndex[i];
  }
  daOldVal = daVal;
  bFirstRun = false;
}

/*
@author Andreas Gruber
returns the relative element of a DPE (without Systemname and DP)
also removes ":_online.._value", since its added by default in a dpConnect
done without dpSubStr to avoid access to database (Performance!)
@param sDPE ... Datapoint Element
@return (string) ... relative element
*/
string getRelativeElementFromDPE(string sDPE)
{
  string ret = "";
  int i;

  i = strpos(sDPE, ".");  // find end of DP
  if (i >= 0)
  {
    ret = substr(sDPE, i);  // remove DP so only Element, config and attribute are in the string
    strreplace(ret, ":_online.._value", "");  // remove online value, since its added by default in dpConnect
  }

  if (DebugInfos) DebugTN("getRelativeElementFromDPE", sDPE, ret);
  return ret;
}

/*
@author Andreas Gruber
Changes all mapping keys from DP+Element to Element only, with getRelativeElementFromDPE function
@param m ... mapping with DPEs as keys
*/
void mappingSetRelativeElementKeys(mapping &m)
{
  mapping m_new;
  dyn_string daKeys;

  daKeys=mappingKeys(m);  // get all DPEs stored in the mapping

  for (int i = 1; i <= dynlen(daKeys); i++)
  {
    m_new[getRelativeElementFromDPE(daKeys[i])] = m[daKeys[i]];  // set new (relative Element) Keys to new mapping with the values from the old mapping
  }
  mappingClear(m);  // clear old mapping
  m = m_new;  // set new mapping onto the old one, will be returned as reference parameter
}

/*
@author Andreas Gruber
returns the path of an icon depending on infoarea and iconID
@param InfoAreaNr ... # of the infoArea
@param iconID ... ID of the icon of the infoArea
@return (string) ... path to an icon or empty string, if no icon should be displayed
*/
string getIconFromMode(int InfoAreaNr, int iconID)
{
  string sRet = "";
  dyn_int modeValue;
  dyn_string modeIcon;
  int i;

  if (iconID != 0)  // if 0, no icon should be displayed
  {
    i = dynContains(mModeValueIcon[InfoAreaNr + ".modeValue"], iconID);  // search ID within Values
    if (i <= 0)
    {
      errClass retError; //  errClass-Variable for makeError-Function
      retError = makeError("stdlib", PRIO_WARNING, ERR_PARAM, 1002, "Icon #" + iconID + ", Infoarea #" + InfoAreaNr);
      throwError(retError); //Gibt den Fehler
    }
    else
    {
      if (i > dynlen(mModeValueIcon[InfoAreaNr + ".modeIcon"]))
      {
        errClass retError; //  errClass-Variable for makeError-Function
        retError=makeError("stdlib", PRIO_WARNING, ERR_PARAM, 1003, "Icon #" + iconID + ", Infoarea #" + InfoAreaNr + ", Index #" + i);
        throwError(retError); //Gibt den Fehler
      }
      else
        sRet = mModeValueIcon[InfoAreaNr + ".modeIcon"][i];  // icon found, put it in return string
    }
  }

  return sRet;
}

/*
Author: Michael Schmit
Opens the PopUpMenu for Datapoint
@param dp...Datapoint
*/
void openPopUpMenuForDP(string dp)
{
  dyn_string menueEntry;
  dyn_string functions;
  openPopUpMenu(dp, menueEntry, functions);
}

/*
Author: Michael Schmit
Opens the PopUpMenu for Datapointelement
@param dpe...Datapointelement
*/
void openPopUpMenuForDPE(string dpe)
{
  dyn_string menueEntry;
  dyn_string functions;
  openPopUpMenu(dpe, menueEntry, functions);
}

/*
Author: Michael Schmit
Opens the PopUpMenu
@param  sDp...Datapoint
@param  dsMenueEntry...Menue Entry
@param  dsFunction...Functions
*/
void openPopUpMenu(string sDp, dyn_string dsMenueEntry, dyn_string dsFunction)
{
  int iAnswer;

  hook_projectFillPopUpMenu(sDp, dsMenueEntry,dsFunction);  //fill with entries of project
  hook_fillPopUpMenu(sDp,dsMenueEntry,dsFunction);          //fill with entries of specific library
  popupMenu(dsMenueEntry, iAnswer);
  if (iAnswer != 0)
  {
    string sMain =  "main()"+
                     "{"+dsFunction[iAnswer]+"}";
    execScript(sMain, makeDynString());
  }

  //opens a popUp and call function of selected entry
}

/*
@author Walter Gernedl, Andreas Gruber
Opens an alert screen prefiltered with the DP/DPE
@param dp ... DP/DPE to use for the filter. If it is a DP, the last char must be a "."
*/
public int OpenAlerts(string dp)
{
  dp = stdlib_addTrailingDot(dp);
  return stdlib_OpenAlertEvents(dp, true);
}

/*
@author Walter Gernedl, Andreas Gruber
Opens an event screen prefiltered with the DP/DPE
@param dp ... DP/DPE to use for the filter. If it is a DP, the last char must be a "."
*/
public int OpenEvents(string dp)
{
  dp = stdlib_addTrailingDot(dp);
  return stdlib_OpenAlertEvents(dp, false);
}

private int stdlib_OpenAlertEvents(string dp, bool alertScreen)
{
  time timeout = 10L;
  int ret;
  string screenConfig = alertScreen?"aes_stdlibalerts":"aes_stdlibevents";
  string sProp = alertScreen?"stdlibAlerts":"stdlibEvents";

  if (!getUserPermission(2))
  {
    throwError(makeError("", PRIO_SEVERE, ERR_PARAM, 0, "User is not allowed to open the AES", "User need permission '2'"));
    return -1;
  }

  if (dp[strlen(dp)-1] == ".")
    dp += "**";
  dyn_string dsFilter = makeDynString(dp);

  dyn_string dsSystems;
  for(int i = 1; i <= dynlen(dsFilter); i++)
  {
    if(!dynContains(dsSystems, strrtrim(dpSubStr(dsFilter[i], DPSUB_SYS), ":")))
      dynAppend(dsSystems, strrtrim(dpSubStr(dsFilter[i], DPSUB_SYS), ":"));
  }
  string propDp = getSystemName()+"_AESProperties_"+sProp;

  if (dpExists(propDp + ".Alerts.Filter.DpList"))
  {
    //set filter on runtime DP and set AES in Run mode
    if (alertScreen)
    {
      dpSetCache(propDp + ".Both.Systems.Selections", dsSystems,
                 propDp + ".Alerts.Filter.DpList", dsFilter,
                 propDp + ".Both.Timerange.Type", 0,
                 propDp + ".Settings.Config", "");
    }
    else
    {
      dpSetCache(propDp + ".Both.Systems.Selections", dsSystems,
                 propDp + ".Events.Filter.DpList", dsFilter);//Event
    }
  }

  //Start the AES wiht right screen configuration
  openAES(screenConfig,"WinCC_OA-AES",1);

  return 0;
}

/*
@author Andreas Gruber
Gets the Library Name from a DP
@param DP ... Datapoint
@return (string) ... Library Name
*/
string getLibNameFromDP(string dp)
{
  return getLibNameFromDPT(stdlib_dpTypeName(dp));
}

/*
@author Andreas Gruber
Gets the Library Name from a DPT
@param sDpt ... Datapoint Type
@return (string) ... Library Name
*/
string getLibNameFromDPT(string sDpt)
{
  dyn_string dsTemp = strsplit(sDpt, "_");

  return (dynlen(dsTemp))?dsTemp[1]:makeDynString();
}

/*
@author Andreas Gruber
Sets the rotation for a shape called "symbol"
@param sAngle ... angle to rotate the symbol
*/
rotateSymbol(string sAngle)
{
//   float fAngle;
//   if (sAngle=="")
//     fAngle=0;
//   else
//     fAngle=sAngle;
//
//   if (shapeExists("symbol") && fAngle!=0)
//     setValue("symbol", "rotation", fAngle);
}

/*
Author: Markus Trummer
get the Faceplate tab panels for the given datapoint
@param  dp...Datapoint
@param  dsPanels...Panel file names
@param  dsPaths...Paths of the panels
*/
void faceplateTabsForDp(string dp, dyn_string &dsPanels, dyn_string &dsPaths)
{
  bool bDebug = false;
  dyn_dyn_string dds_panels, dds_std_panels;
  bool btest = false;
  dyn_string ds_split, dsFinPath;
  string sLibNameFromDP = getLibNameFromDP(dp);
  dynClear(dsPanels);
  dynClear(dsPaths);

  dp = stdlib_addTrailingDot(dp);
  string sDPT = stdlib_dpTypeName(dp);
  int i_pos, iType, iPos;

  // reversed order of path priorities
  const dyn_string dsPathPriorities = makeDynString(getLibNameFromDP(dp) + "_Generic", sDPT);

  // get faceplate tabs for DPT, gernal faceplates and generic of WinCC OA version, Stdlib and own library
  dyn_string dsRemotePanels = getFileNamesRemote(
      makeDynString(
          "panels/objects_parts/faceplates/" + sDPT + "/",
          "panels/objects_parts/faceplates/" + getLibNameFromDP(dp) + "_Generic/",
          "panels/objects_parts/faceplates/"),
      "*.[px][nm][l]",
      makeDynString(
          "/" + PROJ,
          "/" + sLibNameFromDP,
          "/" + gStdLibName,
          "/" + VERSION)
  );

  // split up in path and panel file name
  for (int i = 1; i <= dynlen(dsRemotePanels); i++)
  {
    strreplace(dsRemotePanels[i], "//", "/");
    dyn_string dsSplit = strsplit(dsRemotePanels[i], "/");
    string sPanel = dsSplit[dynlen(dsSplit)];
    string sPath;

    // do not start with panels but first subfolder, and also exclude file name
    for (int j = 2; j < dynlen(dsSplit); j++)
    {
      if (j != 2)
        sPath += "/";

      sPath += dsSplit[j];
    }

    // ignore backup files
    if (strpos(strtoupper(sPanel), ".BAK") >= 0)
      continue;

    // check if DPT has a more specific panel
    iPos = dynContains(dsPanels, sPanel);
    if (iPos > 0)
    {
      // ignore if paths are equal
      if (dsPaths[iPos] == sPath)
        continue;

      // compare paths and check which one is more specific
      dyn_string dsPathOrig = strsplit(dsPaths[iPos], "/");
      dyn_string dsPathNew = strsplit(sPath, "/");

      int iOrigPriority = dynContains(dsPathPriorities, dsPathOrig[dynlen(dsPathOrig)]);
      int iNewPriority = dynContains(dsPathPriorities, dsPathNew[dynlen(dsPathNew)]);

      // use the path with higher priority
      if (iNewPriority > iOrigPriority)
        dsPaths[iPos] = sPath;

      continue;
    }

    dynAppend(dsPanels, sPanel);
    dynAppend(dsPaths, sPath);
  }

  // mzoerfuss: sort panels and associated paths using dynDynSort
  dyn_dyn_string ddsPanelPaths = makeDynAnytype(dsPanels, dsPaths);
  dynDynTurn(ddsPanelPaths);
  dynDynSort(ddsPanelPaths, 1, true);
  dynDynTurn(ddsPanelPaths);

  dsPanels = ddsPanelPaths[1];
  dsPaths = ddsPanelPaths[2];

  bool bXML = false;

  i_pos = dynContains(dsPanels, "notes.pnl");

  if ( i_pos <= 0 )
  {
    i_pos = dynContains(dsPanels, "notes.xml");
    bXML = true;
  }

  //if the panel notes.pnl exist and gUseNotes is true the panel notes.pnl will moved to the last position
  if (gUseNotes && (dpExists(dp + "GEN.note") || dpExists(dp + "general.note")))
  {
    if ( bXML )
      dynAppend(dsPanels, "notes.xml");
    else
      dynAppend(dsPanels, "notes.pnl");

    dynRemove(dsPanels, i_pos);
    dynAppend(dsPaths, dsPaths[i_pos]);
    dynRemove(dsPaths, i_pos);
  }
  else
  {
    dynRemove(dsPanels, i_pos);
    dynRemove(dsPaths, i_pos);
  }
  //if the panel control.pnl exist the panel control.pnl will moved to the first position
  if (dynContains(dsPanels, "control.pnl") > 0 || dynContains(dsPanels, "control.xml") > 0)
  {
    bXML = false;
    i_pos = dynContains(dsPanels, "control.pnl");

    if ( i_pos <= 0 )
    {
      i_pos = dynContains(dsPanels, "control.xml");
      bXML = true;
    }

    if (i_pos>1)
    {
      dynRemove(dsPanels,i_pos);
      if ( bXML )
        dynInsertAt(dsPanels, "control.xml", 1);
      else
        dynInsertAt(dsPanels, "control.pnl", 1);
      dynInsertAt(dsPaths, dsPaths[i_pos], 1);
      dynRemove(dsPaths, i_pos+1);
    }
  }
  if (bDebug) DebugN("PANELS", dsPanels);
  if (bDebug) DebugN("PFAD", dsPaths);

  iType = 0;
  if (dpExists(dp + hook_getAlertElement(dp)))
    dpGet(dp + hook_getAlertElement(dp) + ":_alert_hdl.._type", iType);

  if (iType == 0)
  {
    iPos = dynContains(dsPanels, "alarms.pnl");
    dynRemove(dsPanels, iPos);
    dynRemove(dsPaths, iPos);
  }
  //remove main.pnl because this is displayed in the collapsed panel
  int iMainPanel = dynContains(dsPanels, "main.pnl");

  if ( iMainPanel <= 0 )
    iMainPanel = dynContains(dsPanels, "main.xml");

  if (iMainPanel > 0)
  {
    dynRemove(dsPanels, iMainPanel);
    dynRemove(dsPaths, iMainPanel);
  }
}

/*
Author: Michael Schmit
controll the dollar Parameter
Return: returns an integer
@param  sDollarParameter...$Parameter
*/
int DollarTypeGet(string sDollarParameter)
{
  return paDollarTypeGet(sDollarParameter);
}

/*
Author: Michael Schmit
cut the dollar Parameters
Return: returns the cutted dollar Parameter
@param  sDollarParameter...$Parameter
*/
string cutDollarString(string sDollarParameter)
{
  return paCutDollarString(sDollarParameter);
}
/*
Author: Michael Schmit
get the Message Cat Files
@param  fileNames...fileName of the Messgae Cat
@param  filePaths...pathname of the Message Cat
*/
void getMessageCatFiles(dyn_string &fileNames, dyn_string &filePaths)
{
  paGetMessageCatFiles(fileNames, filePaths);
}

/*
@author Andreas Gruber
Opens a para prefiltered with the DP/DPE.
@param dp ... DP/DPE to use for the filter.
*/
void OpenPara(string dp = "")
{
  if (isModeExtended() && getUserPermission(32))  // open only, when -extend and UserBit 32 is set
    ChildPanelOnCentral("para.pnl", "Para", makeDynString("$Filter_DPE:" + dp));
}

/*
Author: Michael Schmit
opens the Dp Monitor
@param  dp...Datapoint
*/
void OpenDpMonitor(string dp)
{
  dp = stdlib_removeTrailingDot(dp);

  ChildPanelOnCentral("vision/dp_monitor.pnl",
                      "",
                      makeDynString("$b_editable:" + TRUE, "$dp:" + dp));
}

/*
Author: Michael Schmit
opens the Help
@param  dp...Datapoint
*/
void OpenHelp(string dp)
{
  string sDPT;
  sDPT = stdlib_dpTypeName(dp);
  std_help(sDPT, false, getLibNameFromDPT(sDPT) + ".chm");
}

/*
Author: Lichtenberger Christian
opens the Trend
@param  sDp...Datapoint
*/
void OpenTrend(string sDp)
{
  dyn_string dsDptTrendCurves;
  dyn_string dsDollarTrendCurves;
  string sDpRef;
  string sSys = dpSubStr(sDp, DPSUB_SYS);
  string sDpt = stdlib_getDpElemRefType(sDp, sDpRef);  // get reference type of sDp

  if ( sDpRef == "" )
    sDpRef = dpSubStr(sDp, DPSUB_SYS_DP);

  sDpRef = stdlib_removeTrailingDot(sDpRef);

  if (dpExists(sSys+"_ds_" + sDpt + ".trendElements"))
    dpGet(sSys+"_ds_" + sDpt + ".trendElements", dsDptTrendCurves);

  for (int i = 1; i <= dynlen(dsDptTrendCurves); i++)
  {
    string sTemp = dsDptTrendCurves[i];
    strreplace(sTemp, sDpt, sDpRef);

    if (strpos(sTemp, ".")<0)
      sTemp += ".";

    dsDollarTrendCurves[i] = "$CURVE" + i + ":" + sTemp;
  }
  openTrendCurves("_VarTrend_STDLIB_general", -1, dsDollarTrendCurves);
}

/*
@author Markus Trummer
built up hook function name for library specific hook functions: "hook_<LibName>_Function"
@return name of library hook function
@param sDp ... DP name
@param sFunctionName ... name of hook function
*/
string builtHookName(string sDp, string sFunctionName)
{
  string sLibName = strtolower(getLibNameFromDP(sDp));
  strreplace(sFunctionName, "hook_", "");
  return "hook_" + sLibName + "_" + sFunctionName;
}

/*
@author Markus Trummer
execute a library specific hook function: called with "hook_Function" executes "hook_<LibName>_Function"
@return the result of the called hook function
@param sFunctionName ... name of function (without library prefix)
@param sDp ... datapoint for which the hook function is called
*/
anytype callLibHookFunctionReturn(string sFunctionName, mixed &sParameters, string sDp)
{
  anytype ret;

  string sMain =  "anytype main(anytype aParams)"+
                  "{"+
                    "return "+builtHookName(sDp, sFunctionName) + "(aParams);"+
                  "}";
  evalScript(ret, sMain, makeDynString(), sParameters);
  return ret;
}

/*
void callHookFunction(string sFunctionName, anytype &sParameters, string sDp)
{
  anytype ret;
  string sLibName = strtolower(getLibNameFromDP(sDp));
  string sTmpFunctionName = sFunctionName;
  strreplace(sTmpFunctionName, "hook_", "");

  string sLibHook = "hook_" + sLibName + "_" + sTmpFunctionName;

  string sMain =  "anytype main(anytype aParams)"+
                  "{"+
                    "return "+builtHookName(sDp, sFunctionName) + "(aParams);"+
                  "}";
  DebugN("to eval:", sMain);
  evalScript(ret, sMain, makeDynString(), sParameters);
  sParameters = ret;
//  return ret;
}
*/

/*
@author Markus Trummer
check if the dpt has a configurated trend
@return hasDptATrendConfiguration
@param sDpt ... datapointtpye for which the trendcheck is done
*/
  // IM 115240 - modification for call of function stdlib_hasDptTrendConfiguration to pass the datapoint
bool stdlib_hasDptTrendConfiguration(string sDpt, string sDp = "")
{
  string s_systemName;

  // IM 115240 - get system name for the datapoint defined for $DP
  s_systemName = dpSubStr(sDp, DPSUB_SYS);

  //DebugTN(__FILE__,__LINE__,__FUNCTION__,"s_systemName",s_systemName);

  // check if trending elements are defined on dynamicDatapointTypeSettings
  if (dpExists(s_systemName + "_ds_" + sDpt + ".trendElements"))
  {
    dyn_string dsTrendElements;
    dpGet(s_systemName + "_ds_" + sDpt + ".trendElements", dsTrendElements);
    if (dynlen(dsTrendElements) > 0)
      return true;
  }
  return false;
}

/*
@author Andreas Gruber
Gets the Global Reference Name of the current shape.
This can be used in setValue or getValue
@return (string) ... Global Shape Name
*/
string stdlib_getGlobalRefName()
{
  string sRefPath = this.namePath;
  return myModuleName() + "." + myPanelName() + ":" + sRefPath; // get own module-, panel- and reference name
}

// TODO: for refactoring/code-cleanup later on: replace if (DebugInfos) DebugTN(...) calls with stdlib_DebugTN(...)
private stdlib_DebugTN(string name, string value = "")
{
  if (!DebugInfos)
    return;

  if (value != "")
    DebugTN(name, value);
  else
    DebugTN(name);
}

/*
@author Andreas Gruber
Sets the Global Reference Name of the current shape to an invisible  Textfield in its sub reference "infoArea".
This will be read later at the click event of an object and passed to the faceplate.
With this Information the elementary symbol "object reference" can read the dollar parameters in a faceplate
from object of origin.
*/
void stdlib_setGlobalRefNameToInfoArea()
{
  // get own module-, panel- and reference name
  string sGlobalRefName = stdlib_getGlobalRefName();

  // check if shape really exists in this constellation, maybe not if object is used within a reference
  if (shapeExists(sGlobalRefName + ".infoArea.TEXT_PARENT_REF_NAME"))
  {
    // TFS 27259: do not cache reference
    // set global ref name to textfield in sub reference
    setValue(sGlobalRefName + ".infoArea.TEXT_PARENT_REF_NAME", "text", sGlobalRefName);
    stdlib_DebugTN(__FUNCTION__, "found " + sGlobalRefName + ".infoArea.TEXT_PARENT_REF_NAME and set it to " + sGlobalRefName);
  }
  else
  {
    stdlib_DebugTN(__FUNCTION__, "NOT found " + sGlobalRefName + ".infoArea.TEXT_PARENT_REF_NAME");
  }
}

string removeLastLevel(string sDp)
{
  int pos;
  int lastPos = -1;

  pos = strpos(sDp, ":");

  while ( (pos = strpos(sDp, ".", pos + 1)) != -1 )
  {
    lastPos = pos;
  }

  if ( lastPos != -1 )
    return substr(sDp, 0, lastPos);

  return "";
}


// returns highest embedded datapointType of given sDP using
// dpTypeRefName or dpTypeName
// internal types (starting with "_") are ignored
string stdlib_dpTypeName(string sDP)
{
  string ref;
  return stdlib_getDpElemRefType(sDP, ref);
}

string stdlib_getDpElemRefType(string sDP, string &sDpRef)
{
  sDP = stdlib_removeTrailingDot(sDP);

  sDpRef = sDP;
  string stemp = "";

  while ( (sDpRef != "") && (stemp == "") )
  {
    stemp = dpTypeRefName(sDpRef);

    if ( (strlen(stemp) > 0) && (substr(stemp, 0, 1) == "_") ) // if type is derived from internal type, return the type that is one level above...
    {
      stemp = "";
    }

    if ( stemp == "" )
    {
      sDpRef = removeLastLevel(sDpRef);
    }
  }

  if ( stemp == "" )
    if ( dpExists(sDP) )
      stemp = dpTypeName(sDP);

  return stemp;
}


/*
@author Michael Schmit
opens a childpanel with the message invalid license
@param bForceOpen ... if it is true it will always show the childpanel
*/
void stdlib_openPanelInvalidLicense(bool bForceOpen)
{
  string sNoLicense = getCatStr("stdlib", "noLicense");
  if(!gbLicenseMsgWasDisplayed || !bForceOpen) //if bForceOpen is true it will always show the childpanel
  {
    ChildPanelOnCentral("/vision/MessageWarning", "Warning",makeDynString("$1:" + sNoLicense));
    gbLicenseMsgWasDisplayed = TRUE;
  }

}

/*
beautify dp/dpe names.
*/
string stdlib_addTrailingDot(string sDpe)
{
  if (strlen(sDpe)>0)
    if ("." != sDpe[strlen(sDpe)-1])
      sDpe += ".";
  return sDpe;
}

/*
beautify dp/dpe names.
*/
string stdlib_removeTrailingDot(string sDpe)
{
  if (strlen(sDpe)>0)
    if ("." == sDpe[strlen(sDpe)-1])
      sDpe = substr(sDpe,0, strlen(sDpe)-1);
  return sDpe;
}

/*
ensure that there is at least 1 dot in sDpe
*/
string stdlib_normalizeDots(string sDpe)
{
  if (strlen(sDpe)>0) {
    sDpe=stdlib_removeTrailingDot(sDpe);
    if (0>strpos(sDpe,".")) {
      sDpe += ".";
    }
  }
  return sDpe;
}


/*
@author Markus Trummer
find the infoarea icon Id
@param InfoAreaNr ... number of infoarea, for which to find the icon
@param dpesForInfoArea ... mapping with all Infoarea DPs of the connection
@param iInfoAreaUseDefault ... optional int, if Default behavior of Infoarea should be used (workaround for AjaxWebUi, cannot use panel global variables)
*/
string stdlib_getInfoAreaIconFile(int InfoAreaNr, mapping dpesForInfoArea, int iInfoAreaUseDefault=-1)
{
  int iconID = 0, i, j;
  string sOperationMode="", stemp;
  dyn_anytype daKeys;

  bool bInfoAreaUseDefault;

  if (iInfoAreaUseDefault==-1)
    bInfoAreaUseDefault = dbInfoAreaUseDefault[InfoAreaNr];
  else
    bInfoAreaUseDefault = iInfoAreaUseDefault;

  daKeys=mappingKeys(dpesForInfoArea);  // get all DPEs stored in the mapping

  if (DebugInfos)
  {
    for (i=1; i<=dynlen(daKeys); i++)
    {
      DebugN("Value of " + daKeys[i], dpesForInfoArea[daKeys[i]]);
    }
    DebugN("------");
  }

  if (mappinglen(dpesForInfoArea)>0)
    iconID=hook_alterInfoAreaDisplay(daKeys[1], InfoAreaNr, dpesForInfoArea);  // call userDefined hook function for the infoArea
  if (iconID==-1)  // if -1 user defined hook is not implemented
  {
    iconID=0;
    if (bInfoAreaUseDefault == true)  // check for usage of default behaviour
    {
      if (mappinglen(dpesForInfoArea)>0)
         iconID=mappingGetValue(dpesForInfoArea, 1);
    }
    else
    {
      switch (InfoAreaNr)
      {
        case 1:
        case 2:
        case 3: if (mappinglen(dpesForInfoArea)>0)  // display note info
                  if (mappingGetValue(dpesForInfoArea, 1)=="")
                    iconID=1;
                  else
                    iconID=2;
                break;
        case 4: if (mappinglen(dpesForInfoArea)>0)  // display operation mode info
                {
                  sOperationMode=hook_getOperationModeElement(daKeys[1]);
                  stemp="";
                  for (i=1; i<=dynlen(daKeys); i++)
                  {
                    j=strpos(daKeys[i], "."+sOperationMode+".");
                    if (j>=0)
                    {
                      stemp=substr(daKeys[i], 0, j);
                      i=dynlen(daKeys);
                    }
                  }
                  iconID=1; // error

                  if (dpesForInfoArea[stemp+"."+sOperationMode+".auto:_online.._value"]==0 && dpesForInfoArea[stemp+"."+sOperationMode+".manual:_online.._value"]==1 &&
                      dpesForInfoArea[stemp+"."+sOperationMode+".local:_online.._value"]==0 && dpesForInfoArea[stemp+"."+sOperationMode+".remote:_online.._value"]==0)
                    iconID=2; // manual
                  else if (dpesForInfoArea[stemp+"."+sOperationMode+".auto:_online.._value"]==1 && dpesForInfoArea[stemp+"."+sOperationMode+".manual:_online.._value"]==0 &&
                           dpesForInfoArea[stemp+"."+sOperationMode+".local:_online.._value"]==0 && dpesForInfoArea[stemp+"."+sOperationMode+".remote:_online.._value"]==1)
                    iconID=3; // auto
                  else if (dpesForInfoArea[stemp+"."+sOperationMode+".auto:_online.._value"]==0 && dpesForInfoArea[stemp+"."+sOperationMode+".manual:_online.._value"]==1 &&
                           dpesForInfoArea[stemp+"."+sOperationMode+".local:_online.._value"]==1 && dpesForInfoArea[stemp+"."+sOperationMode+".remote:_online.._value"]==0)
                    iconID=4; // local
                  else if (dpesForInfoArea[stemp+"."+sOperationMode+".auto:_online.._value"]==1 && dpesForInfoArea[stemp+"."+sOperationMode+".manual:_online.._value"]==0 &&
                           dpesForInfoArea[stemp+"."+sOperationMode+".local:_online.._value"]==1 && dpesForInfoArea[stemp+"."+sOperationMode+".remote:_online.._value"]==0)
                    iconID=4; // local
                }
                break;
        case 5: if (mappinglen(dpesForInfoArea)>0)  // display invalid info
                  if (mappingGetValue(dpesForInfoArea, 1)==false)
                    iconID=1;
                  else
                    iconID=2;
                break;
        case 6: break;  // no icon to be displayed for _alert_hdl, just the color
        default: break;
      }
    }
  }
  return getIconFromMode(InfoAreaNr, iconID);
}

/*
@author Markus Trummer
function for PocktClient: making automatically dpConnects and reakt with a special CallBack
@param refClass ... name/type of the reference
@return dyn_mapping ... name of dp, name of DPE, name of function to call on value change, name of a tranformation function
*/
dyn_mapping stdlib_dpsToReact(string refClass)
{
  dyn_mapping dm;

  //"dp"  = the name of the property in xhtmlref file which represents the Datapoint
  //"dpe" = the name of the property in xhtmlref file which represents the relative DPE
  //"propName" = name of the property - the function Set+<propName> will be called on value change
  //"transFuncName" = the name of a tranformation function (which can modify the value before the the propName-Function is called
  // and other depending properties for one setting
  if (refClass == "stdlib_boolObject_1")
  {
    dm[1]["dp"] = "DP";
    dm[1]["dpe"] = "DPE";
    dm[1]["propName"] = "Value";
    dm[1]["extra"] = "_BOOL_SHOWALARM";
//    dm[1]["transFuncName"] = "stdlib_boolObject_1.transValue";
//    dm[1]["rule"] = "_BOOL_SHOWALARM";
  }
  if (refClass == "stdlib_numText")
  {
    dm[1]["dp"] = "DP";
    dm[1]["dpe"] = "DPE";
    dm[1]["propName"] = "Value";
//    dm[1]["transFuncName"] = "stdlib_boolObject_1.transValue";
//    dm[1]["rule"] = "_BOOL_SHOWALARM";
  }
  else if (strpos(refClass, "stdlib_")==0)
  {
//    case :
    dm[1]["dp"] = "DP";
    dm[1]["dpe"] = "DPE";
    dm[1]["propName"] = "Value";

    dm[2]["dp"] = "DP";
    dm[2]["dpe"] = "_DPE_Enable";
    dm[2]["propName"] = "Enable";
    dm[2]["transFuncName"] = "stdlib.checkEnabled";
    dm[2]["rule"] = "_RULE_Enable";

    dm[3]["dp"] = "DP";
    dm[3]["dpe"] = "_DPE_Visible";
    dm[3]["propName"] = "Visible";
    dm[3]["transFuncName"] = "stdlib.checkVisible";
    dm[3]["rule"] = "_RULE_Visible";

    dm[4]["dp"] = "DP";
    dm[4]["dpe"] = "_DPE_Highlight";
    dm[4]["propName"] = "Highlight";
    dm[4]["transFuncName"] = "stdlib.checkHighlight";
    dm[4]["rule"] = "_RULE_Highlight";
//    break;
  }

  return dm;
}

dyn_mapping stdlib_dpesToReact(string refClass, dyn_mapping input)
{
  dyn_mapping ret;

  switch(refClass)
  {
  case "info_area":

    for (int i=1; i<=dynlen(input); i++)
    {
      int areaId = (int)substr(input[i]["propName"],strlen(input[i]["propName"])-1);
      string sDP;
      sDP = dpSubStr(input[i]["dpe"], DPSUB_SYS_DP_EL); //remove config

      //get DPEs for one InfoArea
      dyn_string ds;
      if(areaId!=6)  //for info area Icons
      {
        ds = hook_getInfoAreaDPEs(sDP, areaId, 0); //input[i]["dpe"] = wert vom Property
        dynRemove(ds ,dynlen(ds)); //remove nr at the end (=using default or not)
      }
      else //for alarm frame
      {
        ds[1] = sDP;
        if (strpos(sDP,".")<1)
          ds[1]+=".";
        ds[1]+=hook_getAlertElement(sDP)+":_alert_hdl.._act_state_color";
      }

      for (int j=1; j<=dynlen(ds); j++)
      {
        mapping m;
        if (strpos(ds[j], ":", strpos(ds[j], ":")+1)<0)  //no config given
          m["dpe"] =  ds[j] + ":_online.._value";
        else
          m["dpe"] =  ds[j];
        m["propName"] = input[i]["propName"];
        m["transFuncName"] = input[i]["transFuncName"];
        dynAppend(ret, m);
      }
    }
    break;
  case "stdlib_boolObject_1":

    for (int i=1; i<=dynlen(input); i++)
    {
      mapping m;
      if((bool)input[i]["extra"]==true)
      {
        m["dpe"] =  input[i]["dpe"]+":_alert_hdl.._act_state_color";
        m["propName"] = "AlarmValue";
      }
      else
      {
        m["dpe"] =  input[i]["dpe"];
        m["propName"] = "Value";
      }

      dynAppend(ret, m);
    }
    break;
  }

  return ret;
}
