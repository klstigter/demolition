page 50701 "DayPlanningJournalLineApi Opt"
{
    PageType = API;
    Caption = 'DayPlanning Journal Line API Optimization';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'DayPlanningJournalLine';
    EntitySetName = 'DayPlanningJournalLines';
    SourceTable = "DayPlanning Journal Line";
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
                field(templateName; Rec."Template Name")
                {
                    Caption = 'Template Name';
                }
                field(batchName; Rec."Batch Name")
                {
                    Caption = 'Batch Name';
                }
                field(dayPlanningDate; Rec."DayPlanning Date")
                {
                    Caption = 'DayPlanning Date';
                }
                field(dayPlanningLineNo_; Rec."DayPlanning Line No.")
                {
                    Caption = 'DayPlanning Line No.';
                }
                field(documentNo_; Rec."Document No.")
                {
                    Caption = 'Document No.';
                }
                field(jobNo_; Rec."Job No.")
                {
                    Caption = 'Job No.';
                }
                field(jobTaskNo_; Rec."Job Task No.")
                {
                    Caption = 'Job Task No.';
                }
                field(resourceNo_; Rec."Resource No.")
                {
                    Caption = 'Resource No.';
                }
                field(hours; Rec.Hours)
                {
                    Caption = 'Hours';
                }
                field(skill; Rec.Skill)
                {
                    Caption = 'Skill';
                }
                field(invoiceResourceNo_; Rec."Invoice Resource No.")
                {
                    Caption = 'Invoice Resource No.';
                }
                field(globalDimension1Code; Rec."Global Dimension 1 Code")
                {
                    Caption = 'Global Dimension 1 Code';
                }
                field(globalDimension2Code; Rec."Global Dimension 2 Code")
                {
                    Caption = 'Global Dimension 2 Code';
                }
                field(dimensionSetId; Rec."Dimension Set ID")
                {
                    Caption = 'Dimension Set ID';
                }
            }
        }
    }
}
