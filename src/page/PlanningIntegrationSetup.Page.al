page 50603 "Planning Integration Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Planning Integration Setup";
    Caption = 'Planning Integration Setup';
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(APIIntegeration)
            {
                Caption = 'API Integration';

                field("Planning API Url"; Rec."Planning API Url")
                {
                    ApplicationArea = All;
                }
                field("Planning API Key"; Rec."Planning API Key")
                {
                    ApplicationArea = All;
                }
                field("Log Incoming Api Request"; Rec."Log Incoming Api Request")
                {
                    ApplicationArea = All;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = All;
                }
                field("Default Unit of Measure Code"; Rec."Default Unit of Measure Code")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    /*
    actions
    {
        area(Processing)
        {
            action(ActionName)
            {

                trigger OnAction()
                begin

                end;
            }
        }
    }
    */

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    var
    //myInt: Integer;
}