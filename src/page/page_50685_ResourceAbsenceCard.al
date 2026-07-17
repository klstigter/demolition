page 50685 "Resource Absence Card"
{
    Caption = 'Resource Absence Card';
    PageType = Card;
    SourceTable = "Res. Capacity Entry";
    SourceTableView = where(Type = const(Absence));

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                    Caption = 'Resource No.';
                    Editable = Rec."Entry No." = 0;
                    ToolTip = 'Specifies the resource this absence entry applies to.';

                    trigger OnValidate()
                    begin
                        UpdateResourceName();
                    end;
                }
                field(ResourceName; ResourceName)
                {
                    ApplicationArea = All;
                    Caption = 'Resource Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the resource.';
                }
                field("Absence Date"; Rec.Date)
                {
                    ApplicationArea = All;
                    Caption = 'Absence Date';
                    ToolTip = 'Specifies the date of the absence.';
                }
                field("Absence Reason"; Rec."Absence Reason Code")
                {
                    ApplicationArea = All;
                    Caption = 'Absence Reason';
                    LookupPageId = "Causes of Absence";
                    ToolTip = 'Specifies the reason for the absence.';
                }
                field(Hours; HoursVar)
                {
                    ApplicationArea = All;
                    Caption = 'Hours';
                    ToolTip = 'Specifies the number of absence hours (positive value).';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateResourceName();
        if Rec."Entry No." <> 0 then
            HoursVar := -Rec.Capacity;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Type := Rec.Type::Absence;
        HoursVar := 0;
        UpdateResourceName();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        ResourceAbsenceMgt.ValidateAndPrepareAbsence(Rec, HoursVar);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        ResourceAbsenceMgt.ValidateAndPrepareAbsence(Rec, HoursVar);
        exit(true);
    end;

    var
        ResourceAbsenceMgt: Codeunit "Resource Absence Mgt.";
        ResourceName: Text[100];
        HoursVar: Decimal;

    local procedure UpdateResourceName()
    var
        Resource: Record Resource;
    begin
        if Resource.Get(Rec."Resource No.") then
            ResourceName := Resource.Name
        else
            ResourceName := '';
    end;
}
