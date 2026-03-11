table 50611 "Resource DayTask Summary"
{
    TableType = Temporary;
    Caption = 'Resource DayTask Summary';

    fields
    {
        field(1; "Job No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Job No.';
            TableRelation = Job;
        }
        field(2; "Job Task No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(3; "Resource No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Resource No.';
            TableRelation = Resource;
        }
        field(4; "Resource Name"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Resource.Name where("No." = field("Resource No.")));
            Caption = 'Resource Name';
            Editable = false;
        }
        field(10; "First Task Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'First Task Date';
        }
        field(11; "Last Task Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Last Task Date';
        }
        field(20; "Total Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Total Hours';
            DecimalPlaces = 0 : 2;
        }
        field(21; "Total Days"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Total Days';
        }
    }

    keys
    {
        key(PK; "Job No.", "Job Task No.", "Resource No.")
        {
            Clustered = true;
        }
        key(ResourceKey; "Resource No.", "Job No.", "Job Task No.")
        {
        }
    }

    procedure FillBuffer(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        DayTask: Record "Day Tasks";
    begin
        // Clear existing records
        Reset();
        DeleteAll();

        // Filter Day Tasks for the specified Job and Job Task
        DayTask.Reset();
        DayTask.SetRange("Job No.", JobNo);
        DayTask.SetRange("Job Task No.", JobTaskNo);
        DayTask.SetFilter("No.", '<>%1', ''); // Only records with a Resource No.
        if not DayTask.FindSet() then
            exit;

        // Aggregate by Resource No.
        repeat
            Rec.Init();
            Rec."Job No." := DayTask."Job No.";
            Rec."Job Task No." := DayTask."Job Task No.";
            Rec."Resource No." := DayTask."No.";

            if Rec.Find() then begin
                // Update existing summary record
                if DayTask."Task Date" < Rec."First Task Date" then
                    Rec."First Task Date" := DayTask."Task Date";
                if DayTask."Task Date" > Rec."Last Task Date" then
                    Rec."Last Task Date" := DayTask."Task Date";
                Rec."Total Hours" += DayTask."Requested Hours";
                Rec."Total Days" += 1;
                Rec.Modify();
            end else begin
                // Insert new summary record
                Rec."First Task Date" := DayTask."Task Date";
                Rec."Last Task Date" := DayTask."Task Date";
                Rec."Total Hours" := DayTask."Requested Hours";
                Rec."Total Days" := 1;
                Rec.Insert();
            end;
        until DayTask.Next() = 0;

    end;
}
