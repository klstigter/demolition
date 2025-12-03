page 50602 "Resources Board"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Resources Board';

    layout
    {
        area(Content)
        {
            usercontrol(DayPilotResource; "DayPilotResourceAddIn")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    CurrPage.DayPilotResource.Init(StartDate);
                    CurrPage.DayPilotResource.LoadData(ResourceTxt, EventTxt, StartDate, Days);
                end;
            }
        }
    }


    actions
    {
        area(Processing)
        {
            action(TestDisableCells)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.DayPilotResource.DisableCell('1|ARNOUD', '2024-01-24T11:00:00', '2024-01-24T21:00:00');
                end;
            }
        }
    }


    var
        ResourceTxt: Text;
        EventTxt: Text;
        StartDate: Text;
        Days: Integer;

    procedure SetResoucesAndEventJsonTxt(pResourceTxt: Text;
                                         pEventTxt: Text;
                                         pStartDate: Text;
                                         pDays: Integer)
    begin
        ResourceTxt := pResourceTxt;
        EventTxt := pEventTxt;
        StartDate := pStartDate;
        Days := pDays;
    end;
}