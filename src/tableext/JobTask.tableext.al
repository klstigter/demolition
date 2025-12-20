tableextension 50605 "Job Task ext" extends "Job Task"
{
    fields
    {
        // Add changes to table fields here
        field(50520; "Scheduling Type"; Enum schedulingType)
        {
            DataClassification = ToBeClassified;
            Caption = 'Scheduling Type';
        }
        field(50521; PlannedStartDate; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Planned Start Date';
            ToolTip = 'Specifies the start date for the project task. The date is based on the date on the related project planning line.';
        }
        field(50522; PlannedEndDate; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Planned End Date';
            ToolTip = 'Specifies the end date for the project task. The date is based on the date on the related project planning line.';
        }


        field(50530; "Estimated Hours"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Estimated Hours';

        }

        field(50600; "Job View Type"; Enum "Job View Type")
        {
            DataClassification = ToBeClassified;
        }
        field(50601; Progress; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Progress';
            MinValue = 0;
            MaxValue = 100;
        }
        field(50602; "Total Worked Hours"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Day Tasks"."Worked Hours" where("Job No." = field("Job No."), "Job Task No." = field("Job Task No.")));
            Caption = 'Total Worked Hours';
            Editable = false;
            DecimalPlaces = 0 : 2;
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