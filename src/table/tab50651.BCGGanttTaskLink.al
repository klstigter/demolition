table 50651 "BCG Gantt Task Link"
{
    Caption = 'Gantt Task Link';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Project No."; Code[20])
        {
            Caption = 'Project No.';
            DataClassification = CustomerContent;
            tableRelation = Job;
        }
        field(2; "Source Task No."; Code[20])
        {
            Caption = 'Source Task No.';
            DataClassification = CustomerContent;
            tableRelation = "job task"."Job Task No." where("Job No." = field("Project No."));
        }

        field(3; "Link Id"; Guid)
        {
            Caption = 'Link Id';
            DataClassification = SystemMetadata;
        }


        field(5; "Target Task No."; Code[50])
        {
            Caption = 'Target Task No.';
            DataClassification = CustomerContent;
            tableRelation = "job task"."Job Task No." where("Job No." = field("Project No."));
        }

        field(6; "Link Type"; Enum "Gantt Constraint Type")
        {
            Caption = 'Link Type';
            DataClassification = CustomerContent;
        }

        field(7; "Lag (Days)"; Integer)
        {
            Caption = 'Lag (Days)';
            DataClassification = CustomerContent;
            MinValue = 0;
        }

        field(8; "Created At"; DateTime)
        {
            Caption = 'Created At';
            Editable = false;
            DataClassification = SystemMetadata;
        }

        field(9; "Modified At"; DateTime)
        {
            Caption = 'Modified At';
            Editable = false;
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Project No.", "Source Task No.", "Link Id")
        {
            Clustered = true;
        }

        key(BySource; "Project No.", "Source Task No.", "Target Task No.") { }
        key(ByTarget; "Project No.", "Target Task No.", "Source Task No.") { }
    }

    trigger OnInsert()
    begin
        if IsNullGuid("Link Id") then
            "Link Id" := CreateGuid();

        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();

        "Modified At" := CurrentDateTime();

        ValidateLink();
    end;

    trigger OnModify()
    begin
        "Modified At" := CurrentDateTime();
        ValidateLink();
    end;

    trigger OnRename()
    begin
        Error('Renaming is not allowed. Links are identified by Project No. + Link Id.');
    end;

    local procedure ValidateLink()
    begin
        if "Project No." = '' then
            Error('Project No. must be filled.');

        if "Source Task No." = '' then
            Error('Source Task No. must be filled.');

        if "Target Task No." = '' then
            Error('Target Task No. must be filled.');

        if "Source Task No." = "Target Task No." then
            Error('Source Task No. and Target Task No. cannot be the same.');

        // Optional: prevent duplicates within a project (same source+target+type)
        // Uncomment if desired.
        /*
        var
            Link2: Record "BCG Gantt Task Link";
        begin
            Link2.SetRange("Project No.", "Project No.");
            Link2.SetRange("Source Task Id", "Source Task Id");
            Link2.SetRange("Target Task Id", "Target Task Id");
            Link2.SetRange("Link Type", "Link Type");
            Link2.SetFilter("Link Id", '<>%1', "Link Id");
            if Link2.FindFirst() then
                Error('A link with the same Source, Target and Type already exists.');
        end;
        */
    end;
}
