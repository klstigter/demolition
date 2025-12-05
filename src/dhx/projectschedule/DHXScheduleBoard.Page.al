page 50621 "DHX Schedule Board"
{
    PageType = Card; //userControlHost;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Project Planning Lines (DHX)';

    layout
    {
        area(content)
        {
            usercontrol(DhxScheduler; "DHXProjectScheduleAddin")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    CurrPage.DhxScheduler.Init(DHXDataHandler.GetYUnitElementsJSON(DMY2Date(1, 1, 2025), DMY2Date(31, 12, 2025)));
                    CurrPage.DhxScheduler.LoadData('');
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {

        }
    }

    var
        DHXDataHandler: Codeunit "DHX Data Handler";

}