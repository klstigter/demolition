page 50671 "SkillCodeApi Opt"
{
    PageType = API;
    Caption = 'Skill Code API Optimization';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'SkillCode';
    EntitySetName = 'SkillCodes';
    SourceTable = "Skill Code";
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
                field(code; Rec."Code")
                {
                    Caption = 'Code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
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