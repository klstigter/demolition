pageextension 50609 "DDSIA Job Task List" extends "Job Task List"
{
    layout
    {
        // Add changes to page layout here
        addafter(Description)
        {
            field("Ship-to Code"; Rec."Ship-to Code")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    trigger OnOpenPage()
    begin
        // Default page filtered on Job View Type <> Resource
        Rec.SetFilter("Job View Type", '<>%1', Rec."Job View Type"::"Resource");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Job View Type" := Rec."Job View Type"::Project;
    end;

    var
        myInt: Integer;
}