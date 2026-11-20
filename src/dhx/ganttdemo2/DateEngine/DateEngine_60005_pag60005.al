page 60005 "Date Span Test Runner"
{
    Caption = 'Date Span Test Runner';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Date Span Test Result";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Results)
            {
                field("Run At"; Rec."Run DateTime") { ApplicationArea = All; }
                field("Scenario"; Rec."Scenario Code") { ApplicationArea = All; }
                field("Passed"; Rec."Passed") { ApplicationArea = All; }
                field("Message"; Rec."Message") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunAllTests)
            {
                Caption = 'Run All Tests';
                ApplicationArea = All;
                Image = Start;

                trigger OnAction()
                var
                    Suite: Codeunit "Date Span Test Suite";
                begin
                    Suite.RunAll(true); // <-- boolean argument
                    CurrPage.Update(false);
                end;
            }

            action(ClearResults)
            {
                Caption = 'Clear Results';
                ApplicationArea = All;
                Image = Delete;

                trigger OnAction()
                var
                    Suite: Codeunit "Date Span Test Suite";
                begin
                    Suite.Reset();
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
