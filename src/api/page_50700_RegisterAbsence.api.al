page 50700 "RegisterAbsenceApi Opt"
{
    PageType = API;
    Caption = 'Register Absence API Optimization';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'RegisterAbsence';
    EntitySetName = 'RegisterAbsences';
    SourceTable = "Register Absence";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'System Id';
                }
                field(lineNo_; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(resourceNo_; Rec."Resource No.")
                {
                    Caption = 'Resource No.';
                }
                field(date; Rec.Date)
                {
                    Caption = 'Date';
                }
                field(absenceReasonCode; Rec."Absence Reason Code")
                {
                    Caption = 'Absence Reason Code';
                }
                field(hours; Rec.Hours)
                {
                    Caption = 'Hours';
                }
                field(existingCapacity; Rec."Existing Capacity")
                {
                    Caption = 'Existing Capacity';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Line No." := -1; // the API framework rejects a zero key before OnInsertRecord; replaced there when still untouched
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        APIKeyMgt: Codeunit "API Key Mgt Opt.";
    begin
        if Rec."Line No." = -1 then
            Rec."Line No." := APIKeyMgt.GetNextAbsenceLineNo();
        exit(true);
    end;
}
