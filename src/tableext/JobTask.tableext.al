tableextension 50605 "DDSIAJobTask" extends "Job Task"
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Job View Type"; Enum "Job View Type")
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    trigger OnAfterInsert()
    var
        Job: Record Job;
    begin
        if Job.Get(Rec."Job No.") then begin
            Rec."Job View Type" := Job."Job View Type";
            Rec.Modify();
        end;
    end;

    var
        myInt: Integer;
}