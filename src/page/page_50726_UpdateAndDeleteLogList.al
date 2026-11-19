// API Integeration for Exposing API Pages
page 50726 "Opti Upd. Del. Log List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Update and Delete Log Opti";
    Caption = 'Update and Delete Log';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = true;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Log)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the value of the Entry No. field.';
                    ApplicationArea = All;
                }
                field(Action; Rec.Action)
                {
                    ToolTip = 'Specifies the value of the Action field.';
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the value of the Status field.';
                    ApplicationArea = All;
                }
                field("API Field Name"; Rec."API Field Name")
                {
                    ToolTip = 'Specifies the value of the API Field Name field.';
                    ApplicationArea = All;
                }
                field(EntitySetName; Rec.EntitySetName)
                {
                    ToolTip = 'Specifies the value of the Entity Set Name field.';
                    ApplicationArea = All;
                }
                field("Record SystemId"; Rec."Record SystemId")
                {
                    ToolTip = 'Specifies the value of the Record System Id field.';
                    ApplicationArea = All;
                }
                field("Table No."; Rec."Table No.")
                {
                    ToolTip = 'Specifies the value of the Table No. field.';
                    ApplicationArea = All;
                }
                field("Field No."; Rec."Field No.")
                {
                    ToolTip = 'Specifies the value of the Field No. field.';
                    ApplicationArea = All;
                }
                field("Old Value"; Rec."Old Value")
                {
                    ToolTip = 'Specifies the value of the Old Value field.';
                    ApplicationArea = All;
                }
                field("New Value"; Rec."New Value")
                {
                    ToolTip = 'Specifies the value of the New Value field.';
                    ApplicationArea = All;
                }
                field("Modified At"; Rec."Modified At")
                {
                    ToolTip = 'Specifies the value of the Modified At field.';
                    ApplicationArea = All;
                }
                field("Synchronized At"; Rec."Synchronized At")
                {
                    ToolTip = 'Specifies the value of the Synchronized At field.';
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(WebhookSubscriber)
            {
                Caption = 'Webhook Subscriber';
                ToolTip = 'Open the webhook subscription table (API Webhook Subscription) in Business Central';
                ApplicationArea = All;
                Image = Link;

                trigger OnAction()
                begin
                    Hyperlink(WebhookSubscriberUrlTxt);
                end;
            }
        }
        area(Promoted)
        {
            actionref(WebhookSubscriber_Promoted; WebhookSubscriber)
            {
            }
        }
    }

    var
        WebhookSubscriberUrlTxt: Label 'https://businesscentral.dynamics.com/a60762e1-df10-4e4b-8f44-174c51589110/NL_Test?table=2000000095', Locked = true;
}
