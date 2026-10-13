page 50729 "JobBatch Line Opt"
{
    // Nested API subpage of "JobBatch Header Opt". Each submitted line inserts a real Job.
    PageType = API;
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'jobRecord';
    EntitySetName = 'jobRecords';
    SourceTable = Job;
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
                field(no_; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(projectType; Rec."Project Type")
                {
                    Caption = 'Project Type';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(projectManager; Rec."Project Manager")
                {
                    Caption = 'Project Manager';
                }
                field(personResponsible; Rec."Person Responsible")
                {
                    Caption = 'Person Responsible';
                }
                field(billtoCustomerNo; Rec."Bill-to Customer No.")
                {
                    Caption = 'Bill-to Customer No.';
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        NewJob: Record Job;
        GlobalSessionVar: Codeunit "Global Session Var Opt.";
        InNo: Code[20];
        InDescription: Text[100];
        InProjectType: Code[20];
        InStatus: Enum "Job Status";
        InProjectManager: Code[50];
        InPersonResponsible: Code[20];
        InBillTo: Code[20];
    begin
        // Snapshot incoming API data first, before Rec is touched
        InNo := Rec."No.";
        InDescription := Rec.Description;
        InProjectType := Rec."Project Type";
        InStatus := Rec.Status;
        InProjectManager := Rec."Project Manager";
        InPersonResponsible := Rec."Person Responsible";
        InBillTo := Rec."Bill-to Customer No.";

        if GlobalSessionVar.IsHeaderInsertPending() then
            exit(false); // phantom pre-header bind of the first line - the real deep-insert pass follows

        if InNo = '' then
            Error(MandatoryFieldErr, 'no_');
        if InDescription = '' then
            Error(MandatoryFieldErr, 'description');

        NewJob.Init();
        NewJob."No." := InNo;
        NewJob.Insert(true);
        if InDescription <> '' then
            NewJob.Validate(Description, InDescription);
        if InProjectType <> '' then
            NewJob.Validate("Project Type", InProjectType);
        NewJob.Validate(Status, InStatus);
        if InProjectManager <> '' then
            NewJob.Validate("Project Manager", InProjectManager);
        if InPersonResponsible <> '' then
            NewJob.Validate("Person Responsible", InPersonResponsible);
        if InBillTo <> '' then
            NewJob.Validate("Bill-to Customer No.", InBillTo);
        NewJob.Modify(true);

        exit(false); // BC must NOT insert again
    end;

    var
        MandatoryFieldErr: Label 'The field "%1" is mandatory and must have a value in every jobRecords line.', Comment = '%1 = JSON field name';
}
