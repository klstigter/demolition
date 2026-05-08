page 50603 "JobApi Opt"
{
    PageType = API;
    Caption = 'Job API Optimization';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'Job';
    EntitySetName = 'Jobs';
    SourceTable = "Job";
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
                    Caption = 'Person Responsible';
                }
                field(projectManagerId; GetProjectManagerId())
                {
                    Caption = 'Person Responsible';
                }
                field(personResponsible; Rec."Person Responsible")
                {
                    Caption = 'Person Responsible';
                }
                field(personResponsibleId; GetPersonResponsibleId())
                {
                    Caption = 'Person Responsible';
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

    local procedure GetProjectManagerId(): Guid
    var
        UserSetup: Record "User Setup";
        EmptyGuid: Guid;
    begin
        if Rec."Project Manager" <> '' then
            if UserSetup.Get(Rec."Project Manager") then
                exit(UserSetup.SystemId);
        exit(EmptyGuid);
    end;

    local procedure GetPersonResponsibleId(): Guid
    var
        Res: Record Resource;
        EmptyGuid: Guid;
    begin
        if Rec."Person Responsible" <> '' then
            if Res.Get(Rec."Person Responsible") then
                exit(Res.SystemId);
        exit(EmptyGuid);
    end;
}