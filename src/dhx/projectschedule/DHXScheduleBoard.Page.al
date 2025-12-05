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
                    CurrPage.DhxScheduler.Init(format(Today, 0, '<year4>-<month,2>-<day,2>'));
                    //CurrPage.DhxScheduler.LoadData(ResourceTxt, EventTxt, StartDate, Days);
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

}