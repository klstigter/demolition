page 50731 "JobTaskBatch Line Opt"
{
    // Nested API subpage of "JobTaskBatch Header Opt". Each submitted line inserts a real Job Task.
    PageType = API;
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'jobTaskRecord';
    EntitySetName = 'jobTaskRecords';
    SourceTable = "Job Task";
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'System Id';
                    Editable = false;
                }
                field(jobNo_; Rec."Job No.")
                {
                    Caption = 'Job No.';
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
                field(plannedStartDate; Rec.PlannedStartDate)
                {
                    Caption = 'Planned Start Date';
                }
                field(plannedEndDate; Rec.PlannedEndDate)
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
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Job Task No." := AutoKeyTok; // the API framework rejects a blank key before OnInsertRecord; replaced there when still untouched
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        NewTask: Record "Job Task";
        GlobalSessionVar: Codeunit "Global Session Var Opt.";
        APIKeyMgt: Codeunit "API Key Mgt Opt.";
        InJobNo: Code[20];
        InTaskNo: Code[20];
        InTaskType: Enum "Job Task Type";
        InDescription: Text[100];
        InProjectManager: Code[50];
        InStart: Date;
        InEnd: Date;
        InAddress: Text[100];
        InAddress2: Text[50];
        InCity: Text[30];
        InCounty: Text[30];
        InRegion: Code[10];
        InBillTo: Code[20];
    begin
        // Snapshot incoming API data first, before Rec is touched
        InJobNo := Rec."Job No.";
        InTaskNo := Rec."Job Task No.";
        InTaskType := Rec."Job Task Type";
        InDescription := Rec.Description;
        InProjectManager := Rec."Project Manager";
        InStart := Rec.PlannedStartDate;
        InEnd := Rec.PlannedEndDate;
        InAddress := Rec."Sell-to Address";
        InAddress2 := Rec."Sell-to Address 2";
        InCity := Rec."Sell-to City";
        InCounty := Rec."Sell-to County";
        InRegion := Rec."Sell-to Country/Region Code";
        InBillTo := Rec."Bill-to Customer No.";

        if GlobalSessionVar.IsHeaderInsertPending() then
            exit(false); // phantom pre-header bind of the first line - the real deep-insert pass follows

        if InJobNo = '' then
            Error(MandatoryFieldErr, 'jobNo_');
        if InDescription = '' then
            Error(MandatoryFieldErr, 'description');
        if InTaskNo = AutoKeyTok then
            InTaskNo := APIKeyMgt.GetNextJobTaskNo(InJobNo); // previous lines of this POST are already inserted below

        NewTask.Init();
        NewTask."Job No." := InJobNo;
        NewTask."Job Task No." := InTaskNo;
        NewTask.Insert(true);
        NewTask.Validate("Job Task Type", InTaskType);
        NewTask.Validate(Description, InDescription);
        if InProjectManager <> '' then
            NewTask.Validate("Project Manager", InProjectManager);
        if InStart <> 0D then
            NewTask.Validate(PlannedStartDate, InStart);
        if InEnd <> 0D then
            NewTask.Validate(PlannedEndDate, InEnd);
        if InAddress <> '' then
            NewTask.Validate("Sell-to Address", InAddress);
        if InAddress2 <> '' then
            NewTask.Validate("Sell-to Address 2", InAddress2);
        if InCity <> '' then
            NewTask.Validate("Sell-to City", InCity);
        if InCounty <> '' then
            NewTask.Validate("Sell-to County", InCounty);
        if InRegion <> '' then
            NewTask.Validate("Sell-to Country/Region Code", InRegion);
        if InBillTo <> '' then
            NewTask.Validate("Bill-to Customer No.", InBillTo);
        NewTask.Modify(true);

        Rec."Job Task No." := NewTask."Job Task No."; // reflect the generated key in the POST response

        exit(false); // BC must NOT insert again
    end;

    var
        AutoKeyTok: Label '#AUTO#', Locked = true;
        MandatoryFieldErr: Label 'The field "%1" is mandatory and must have a value in every jobTaskRecords line.', Comment = '%1 = JSON field name';
}
