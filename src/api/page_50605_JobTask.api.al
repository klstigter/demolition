page 50605 "JobTaskApi Opt"
{
    PageType = API;
    Caption = 'Job Task API Optimization';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'jobTask';
    EntitySetName = 'jobTasks';
    SourceTable = "Job Task";
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
                field(jobNo_; Rec."Job No.")
                {
                    Caption = 'No.';
                }
                field(jobTaskNo_; Rec."Job Task No.")
                {
                    Caption = 'Task No.';
                }
                field(taskType; Rec."Job Task Type")
                {
                    Caption = 'Task Type';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(projectManager; Rec."Project Manager")
                {
                    Caption = 'Project Manager';
                }
                field(plannedStartDate; Rec.VisualBarStartDate)
                {
                    Caption = 'Planned Start Date';
                }
                field(plannedEndDate; Rec.VisualBarEndDate)
                {
                    Caption = 'Planned End Date';
                }
                field(address; Rec."Sell-to Address")
                {
                    Caption = 'Sell-to Address';
                }
                field(address2; Rec."Sell-to Address 2")
                {
                    Caption = 'Sell-to Address 2';
                }
                field(city; Rec."Sell-to City")
                {
                    Caption = 'Sell-to City';
                }
                field(county; Rec."Sell-to County")
                {
                    Caption = 'Sell-to County';
                }
                field(regionCode; Rec."Sell-to Country/Region Code")
                {
                    Caption = 'Sell-to Country/Region Code';
                }
                field(billtoCustomerNo; Rec."Bill-to Customer No.")
                {
                    Caption = 'Bill-to Customer No.';
                }
                field(systemCreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Created At';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'Modified At';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Job Task No." := AutoKeyTok; // the API framework rejects a blank key before OnInsertRecord; replaced there when still untouched
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        APIKeyMgt: Codeunit "API Key Mgt Opt.";
    begin
        if Rec."Job Task No." = AutoKeyTok then begin
            Rec.TestField("Job No.");
            Rec."Job Task No." := APIKeyMgt.GetNextJobTaskNo(Rec."Job No.");
        end;
        exit(true);
    end;

    var
        AutoKeyTok: Label '#AUTO#', Locked = true;
}