page 50672 "ResourceSkillApi Opt"
{
    PageType = API;
    Caption = 'Resource Skill API Optimization';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'ResourceSkill';
    EntitySetName = 'ResourceSkills';
    SourceTable = "Resource Skill";
    SourceTableView = where(Type = Const(Resource));
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
                field(resourceNo; Rec."No.")
                {
                    Caption = 'Resource No.';
                }
                field(skillCode; Rec."Skill Code")
                {
                    Caption = 'Skill Code';
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