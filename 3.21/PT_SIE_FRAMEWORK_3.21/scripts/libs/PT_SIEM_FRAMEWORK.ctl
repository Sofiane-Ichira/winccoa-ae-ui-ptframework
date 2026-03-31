// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author z004u6jf
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)

//--------------------------------------------------------------------------------
// Variables and Constants


//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------


//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------
global dyn_dyn_string ddsNavibuttonsPerScreen;
global dyn_anytype daCollection; //shared_ptr<GUINaviButtonCollection>
global dyn_string tmp = makeDynString(); // temporary array
global bool g_hideSubMenuOnCollapse = FALSE;
global string g_textBeforeIcon = "     ";
global bool g_bShowTextBeforeIconOnlyOnce = FALSE;



public void Init_btns(dyn_anytype &daCollection)
{

  int iScreennumber = GetMyScreenNumber();

  daCollection[iScreennumber] = /*(shared_ptr<GUINaviButtonCollection>)*/ new GUINaviButtonCollection();


  dyn_string shapes = getShapes(myModuleName(), myPanelName(), "", true);

  dyn_string buttons;

  for (int i = 0; i < shapes.count(); i++)

  {

    if (!buttons.contains(shapes.at(i).split(".").at(0)) && shapes.at(i).split(".").at(0).contains("btn"))

    {

      buttons.append(shapes.at(i).split(".").at(0));

    }

  }

  for (int i = 0; i < buttons.count(); i++)

  {

    shape tmp = getShape(myModuleName(), myPanelName(), buttons.at(i));

    daCollection[iMyScreenNumber].Append(tmp.GetGUINaviButton());

  }

}



//ToDo: perhaps collection needs to be global?

public shared_ptr<GUINaviButtonCollection> GetGuiNaviButtonCollection()
{
  return ButtonCollection;
}


synchronized shape PT_SIEM_addNaviButton(string id, string parentId, string sModuleName = myModuleName(), bool bVisible = TRUE/*,shared_ptr<GUINaviButtonCollection> ButtonCollection*/,
    bool bUserNavibutton = FALSE, bool bQuickNaviButton = FALSE)
{
  string panelName = rootPanel(sModuleName);/*"Navi";*//*"para/PanelTopology/templates/SIE/naviPanel_1024_768_SIE.pnl";*/
  bool bParentNode, bSubNode;
//get my screen number

  int iScreennumber = GetMyScreenNumber();//Ahmed change the screen number

  if (dynlen(ddsNavibuttonsPerScreen) < iScreennumber)
  {
    ddsNavibuttonsPerScreen[iScreennumber] = makeDynString();
  }

  if (parentId == "1")
  {
    bParentNode = true;
    bSubNode = false;
  }

  else if (parentId == "0")
  {
    bParentNode = false;
    bSubNode = false;
  }
  else
  {
    bParentNode = false;
    bSubNode = true;
  }

  int iNewLayoutRow = dynContains(ddsNavibuttonsPerScreen[iScreennumber], parentId) + 1;
 
  if (bQuickNaviButton)
    iNewLayoutRow = daCollection[iScreennumber].Count() - 2  ;   // daCollection initially contains 4 buttons created by init_btns:
                                                                 // menu_btn, navi_btn, lang_btn, exist_btn.
                                                                 // These buttons are NOT part of the layout.

                                                                 // Buttons actually inside the layout:
                                                                 // daCollection[iScreenNumber].Count() - 4

                                                                 // LAYOUT_navi_buttons initially contains 2 fixed objects (circle + spacer).

                                                                 // Row index for inserting a new button:
                                                                 // iNewLayoutRow = daCollection[iScreenNumber].Count() - 4 + 2

                                                                 // If another fixed object is added to the layout,
                                                                 // increase the constant offset accordingly.

//perhaps +1 s require
  string sRefName = (bQuickNaviButton ? "quick_" : "") + "navi_btn_" + id;

  addSymbol(sModuleName, panelName, "objects/side_menu_buttons/generic.pnl", sRefName,
            iNewLayoutRow, sModuleName + "." + panelName + ":" + "LAYOUT_navi_buttons",
            makeDynString("$nodeId:" + id, "$bParentNode:" + bParentNode, "$bSubNode:" + bSubNode, "$bVisible:" + bVisible, "$bQuickNaviButton:" + bQuickNaviButton));

  shape shRef = getShape(sModuleName, panelName, sRefName);
  daCollection[iScreennumber].Append(shRef.GetGUINaviButton());
  return shRef;
}

PT_SIEM_removeNaviButton(dyn_int diPtIndexToRemove, string moduleName = myModuleName(), bool bQuickButtons = FALSE) synchronized(ddsNavibuttonsPerScreen)
{

  string panelName = rootPanel(moduleName);
  int iMyScreenNumber = GetMyScreenNumber();//Ahmed change the screen number
  string sButtonPrefix = bQuickButtons ? "quick_navi_btn_" : "navi_btn_";

  if (dynlen(daCollection) >= iMyScreenNumber)
  {
    for (int i = 0; i < daCollection[iMyScreenNumber].Count()  ; i++)
    {

      shared_ptr<GUINaviButton> obj = daCollection[iMyScreenNumber].GetByIndex(i);

      if (!bQuickButtons && getTypeName(obj) == "GUINaviPanelButton"  || bQuickButtons && getTypeName(obj) == "GUIQuickNaviPanelButton")
      {
        int iPtNodeId = obj.getChildPanelNumber(); //ddsNavibuttonsPerScreen[iMyScreenNumber][i+1];

        if (dynContains(diPtIndexToRemove, iPtNodeId) > 0)
        {
          removeSymbol(moduleName, panelName, sButtonPrefix + iPtNodeId);
          daCollection[iMyScreenNumber].RemoveByIndex(i);
          i--;
        }
      }
    }
  }
}


dyn_int GetChildIndecies(string parentId)
{
  int iScreennumber = GetMyScreenNumber();
  string strServerName = getSystemName();
  dyn_uint ParentNumbers;
  dyn_int childIds;
  dyn_int childINdeciesInLayout;

  dpGet(strServerName + "_PanelTopology.parentNumber", ParentNumbers);

  for (int i = 1; i <= dynlen(ParentNumbers); i++)
  {


    if (ParentNumbers[i] == parentId)
    {

      childIds.append(i);

    }

  }

  for (int i = 1; i <= dynlen(childIds); i++)
  {

    if (dynContains(ddsNavibuttonsPerScreen[iScreennumber], childIds[i]) != -1)
    {
      childINdeciesInLayout.append(dynContains(ddsNavibuttonsPerScreen[iScreennumber], childIds[i]));

    }

  }

  return childINdeciesInLayout;
}

dyn_int GetChildIDs(string parentId)
{
  int iScreennumber = GetMyScreenNumber();
  string strServerName = getSystemName();
  dyn_uint ParentNumbers;
  dyn_int childIds;
  dyn_int childINdeciesInLayout;
  dpGet(strServerName + "_PanelTopology.parentNumber", ParentNumbers);

  for (int i = 1; i <= dynlen(ParentNumbers); i++)
  {


    if (ParentNumbers[i] == parentId)
    {

      childIds.append(i);

    }

  }

  return childIds;

}



int GetMyScreenNumber()
{
  string moduleName = myModuleName();
  int iScreenNum = 0;
  iScreenNum = (int)moduleName.at(moduleName.length() - 1);

//  if (iScreenNum ==0)
//   {
//     DebugTN("the moduleName does not contain screen number");
//     return -1;
//   }
//   else*/
// DebugTN("iScreenNum",iScreenNum);
  return iScreenNum;

}

bool doIhaveAChild(int myID)
{
  bool Answer = false;

  string strServerName = getSystemName();
  dyn_uint ParentNumbers;
  dpGet(strServerName + "_PanelTopology.parentNumber", ParentNumbers);

  for (int i = 1; i <= dynlen(ParentNumbers); i++)
  {
    // DebugTN("i=", i);

    if (ParentNumbers[i] == myID)
    {

      Answer = true;

    }

  }

  return Answer;

}


bool firstTime;
dyn_int currentStatus ;


collapseMenu(int currentState)
{
  bool bDefault = 0;

  string moduleName =  myModuleName(); /*"naviModule_1";*/ /*"_QuickTest_";*/
  strreplace(moduleName, "naviModule", "naviModuleA");
  string panelName = rootPanel(moduleName); // rootPanel(moduleName);/*"Navi";*//*"para/PanelTopology/templates/SIE/naviPanel_1024_768_SIE.pnl";*/
  dyn_string allButtons;
  allButtons = getShapes(moduleName, panelName, "", true);

  for (int i = 0 ; i < daCollection[iMyScreenNumber].Count(); i++)
  {

    shared_ptr<GUINaviButton> obj = daCollection[iMyScreenNumber].GetByIndex(i);

    if (getTypeName(obj) != "GUINaviPanelButton")
      continue;


    int parentID = getLevel(obj.getChildPanelNumber());
    shape shChildNavi =  obj.getChildNavi();


    if (currentState == 1 && ! firstTime) //hive the original tree by removing the spaces before everything
    {

      setValue(obj.getChildNavi(), "visible", false);


      if (g_hideSubMenuOnCollapse && parentID > 1)
      {
        obj.SetRefVisible(FALSE);

      }
      else if (g_hideSubMenuOnCollapse && parentID == 1)
        setValue(obj.getParentNavi(), "text", "+ ");

    }

    else if (currentState == 0 && ! firstTime) //show the original tree that was before collapsing
    {
      string  correctText;

      if (parentID > 1) // one of the sub nodes
      {

        addSpaceBetween(parentID, shChildNavi, correctText);

        if (g_hideSubMenuOnCollapse)  //true
        {
          string sText;
          getValue(obj.getParentNavi(), "text", sText);

          setValue(obj.getChildNavi(), "visible", correctText != "");

          if (sText == "- " || sText == "-")
          {
            obj.SetRefVisible(correctText != "");
            setValue(obj.getParentNavi(), "text", "- ");
          }
        }
      }

      else //start node
      {

        setValue(obj.getChildNavi(), "visible", false);
      }
    }


  }


}


int getLevel(int myID)
{
  if (myID == 0)
    return 1;

  string strServerName = getSystemName();
  dyn_uint parentNumbers;
  dpGet(strServerName + "_PanelTopology.parentNumber", parentNumbers);

  int level = 0;
  int currentID = myID;

  while (1)
  {
    int parentID = parentNumbers[currentID];

    // Top-level panel has parentNumber 1 (or 0 depending on your topology)
    if (parentID <= 1)
    {
      level += 1;  // count this level
      break;
    }

    // Move up to parent
    currentID = parentID;
    level += 1;
  }

  return level;
}

void addSpaceBetween(int parentID, shape objectName, string &finalText_1, string spaceOrText = g_textBeforeIcon, bool bShowTextBeforeIconOnlyOnce = g_bShowTextBeforeIconOnlyOnce)  //parentID is the node ID
{

  char clastCharacter;
  string sTemp, finalText;
  string SpaceOrTextToSpaces;

  for (int i = 2 ; i <= parentID; i++)
  {
    finalText = finalText + spaceOrText;
    ///sTemp   =  sTemp + spaceOrText;
    //finalText_1 = finalText_1 + spaceOrText;   //remove this line to get the last character ** Sofiane **
  }

  clastCharacter = finalText[uniStrLen(finalText) - 1];

  if (bShowTextBeforeIconOnlyOnce)
  {
    for (int i = 0 ; i < spaceOrText.length(); i ++)
    {
      SpaceOrTextToSpaces = SpaceOrTextToSpaces + " ";
    }

    for (int i = 1 ; i <=  uniStrLen(finalText) / uniStrLen(spaceOrText) ; i ++) // i*= spaceOrText.length())
    {
      {
        if (i != uniStrLen(finalText) / uniStrLen(spaceOrText))
        {
          sTemp = sTemp + SpaceOrTextToSpaces + "   ";
        }
        else if (i == uniStrLen(finalText) / uniStrLen(spaceOrText))
        {
          sTemp = sTemp + spaceOrText;
        }
      }
    }
  }
  else
  {
    for (int i = 2 ; i <= parentID; i++)
    {
      sTemp = sTemp + spaceOrText;
    }
  }

  finalText_1 = sTemp;
  setValue(objectName, "text", finalText_1);
  setValue(objectName, "visible", true);

}


anytype searchConfigInAllLevels(string configFile, string configSection, string searchedConfigEntry, anytype defaultConfigValue)
{
  anytype l_configResult;
  bool bDefault = 0;

  if (configFile != "config")
  {
    l_configResult = paCfgReadValueDflt("config", configSection, searchedConfigEntry, defaultConfigValue, bDefault);
  }
  else
  {
    bDefault = 1;
  }

  for (int i = 1; i <= SEARCH_PATH_LEN && bDefault; i++)
  {
    string sCfgFile = getPath(CONFIG_REL_PATH, configFile, -1, i);

    if (sCfgFile != "")
      l_configResult = paCfgReadValueDflt(sCfgFile, configSection, searchedConfigEntry, defaultConfigValue, bDefault);

  }

  return l_configResult;
}





