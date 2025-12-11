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
                var
                    startDate: Date;
                    endDate: Date;
                    EarliestPlanningDate: Date;
                    PlanninJsonTxt: Text;
                    ResourceJSONTxt: Text;
                begin
                    DHXDataHandler.GetOneYearPeriodDates(Today(), startDate, endDate);
                    ResourceJSONTxt := DHXDataHandler.GetYUnitElementsJSON(startDate, endDate, PlanninJsonTxt, EarliestPlanningDate);
                    CurrPage.DhxScheduler.Init(ResourceJSONTxt, EarliestPlanningDate);
                    CurrPage.DhxScheduler.LoadData(PlanninJsonTxt);
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