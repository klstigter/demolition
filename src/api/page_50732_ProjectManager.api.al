page 50732 "ProjectManagerApi Opt"
{
    // Read-only list of valid Project Manager values (Job."Project Manager" = User Setup."User ID").
    PageType = API;
    Caption = 'Project Manager API';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'projectManager';
    EntitySetName = 'projectManagers';
    SourceTable = "User Setup";
    ODataKeyFields = SystemId;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

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
                field(userId; Rec."User ID")
                {
                    Caption = 'User ID';
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
}
