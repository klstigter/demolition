page 50726 "Update and Delete Log List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Update and Delete Log Opti";
    Caption = 'Update and Delete Log';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Log)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field(Action; Rec.Action)
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("API Field Name"; Rec."API Field Name")
                {
                    ApplicationArea = All;
                }
                field(EntitySetName; Rec.EntitySetName)
                {
                    ApplicationArea = All;
                }
                field("Record SystemId"; Rec."Record SystemId")
                {
                    ApplicationArea = All;
                }
                field("Table No."; Rec."Table No.")
                {
                    ApplicationArea = All;
                }
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = All;
                }
                field("Old Value"; Rec."Old Value")
                {
                    ApplicationArea = All;
                }
                field("New Value"; Rec."New Value")
                {
                    ApplicationArea = All;
                }
                field("Modified At"; Rec."Modified At")
                {
                    ApplicationArea = All;
                }
                field("Synchronized At"; Rec."Synchronized At")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
