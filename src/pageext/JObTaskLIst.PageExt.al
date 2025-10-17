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
        // Default page filtered on Job Task Type <> Resource Planning
        Rec.SetFilter("Job Task Type", '<>%1', Rec."Job Task Type"::"Resource Planning");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Job Task Type" := Rec."Job Task Type"::Posting;
    end;

    var
        myInt: Integer;
}