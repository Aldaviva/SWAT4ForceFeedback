class CustomScenario_NotesTabPanel extends CustomScenarioTabPanel;

var(SWATGui) private EditInline Config GUIEditBox   txt_notes;
var(SWATGui) private EditInline Config GUIScrollTextBox   scroll_notes;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    Data = CustomScenarioPage.CustomScenarioCreatorData;
    
    txt_notes.OnChange=txt_notes_OnChange;
}


function txt_notes_OnChange( GUIComponent Sender )
{
    scroll_notes.SetContent( txt_notes.GetText() );
}

// CustomScenarioTabPanel overrides

function PopulateFieldsFromScenario(bool NewScenario)
{
    local CustomScenario Scenario;

    Scenario = CustomScenarioPage.GetCustomScenario();

    txt_notes.SetText(Scenario.Notes);
}

function GatherScenarioFromFields()
{
    local CustomScenario Scenario;

    Scenario = CustomScenarioPage.GetCustomScenario();

    Scenario.Notes = txt_notes.GetText();
}
