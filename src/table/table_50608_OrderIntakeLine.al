table 50608 "Order Intake Line"
{
    Caption = 'Workorder';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Order Intake No."; Code[20])
        {
            Caption = 'Order Intake No.';
            DataClassification = CustomerContent;
            TableRelation = "Order Intake Header Opt.";
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
        }

        field(20; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }

        field(60; "Project No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if Rec."Project No." <> xRec."Project No." then
                    Rec.Validate("Project Task No.", '');
            end;
        }
        field(61; "Project Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            DataClassification = CustomerContent;
            TableRelation = "Job Task"."Job Task No." where("Job No." = FIELD("Project No."));
        }

        field(200; "Planned Start Date"; Date)
        {
            Caption = 'Planned Start Date';
            FieldClass = FlowField;
            CalcFormula = lookup("Job Task"."PlannedStartDate" where("Job No." = field("Project No."), "Job Task No." = FIELD("Project Task No.")));
        }
        field(201; "Planned End Date"; Date)
        {
            Caption = 'Planned End Date';
            FieldClass = FlowField;
            CalcFormula = lookup("Job Task"."PlannedEndDate" where("Job No." = field("Project No."), "Job Task No." = FIELD("Project Task No.")));
        }

    }

    keys
    {
        key(PK; "Order Intake No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Description, "Planned Start Date", "Planned End Date")
        {
        }

        fieldgroup(Brick; Description)
        {
        }
    }


    trigger OnDelete()
    var
        JobTask: Record "Job Task";
    begin
        if JobTask.Get(Rec."Project No.", Rec."Project Task No.") then
            JobTask.Delete(true);
    end;


}