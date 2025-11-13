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
            group(General)
            {
                field("Request Nos."; Rec."Request Nos.")
                {
                    ApplicationArea = All;
                }
            }
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
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = All;
                }
                field("Default Unit of Measure Code"; Rec."Default Unit of Measure Code")
                {
                    ApplicationArea = All;
                }
                field("Default Vacant Text"; Rec."Default Vacant Text")
                {
                    ApplicationArea = All;
                }
            }
            group("Auto")
            {
                Caption = 'Auto';

                group(Log)
                {
                    field("Log Incoming Api Request"; Rec."Log Incoming Api Request")
                    {
                        ApplicationArea = All;
                    }
                    field("ShowLog"; 'Show Log')
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnAssistEdit()
                        var
                            LogPage: page "DDSIA Incoming Check";
                        begin
                            LogPage.Run();
                        end;
                    }
                }
                field("Auto Sync. Integration"; Rec."Auto Sync. Integration")
                {
                    ApplicationArea = All;
                }
            }
            group("Test Functions")
            {
                Caption = 'Test Functions';

                field("UTCDT"; 'Get UTC Datatime Now')
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnAssistEdit()
                    var
                        RestMgt: codeunit "DDSIA Rest API Mgt.";
                    begin
                        message('%1', RestMgt.DT2UTC(CreateDateTime(Today, Time)));
                    end;
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