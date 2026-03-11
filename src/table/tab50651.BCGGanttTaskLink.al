table 50651 "BCG Gantt Task Link"
{
    Caption = 'Gantt Task Link';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job."No.";
        }
        field(2; "Source Task No."; Code[20])
        {
            Caption = 'Source Task No.'; // Predecessor
        }
        field(3; "Target Task No."; Code[20])
        {
            Caption = 'Target Task No.'; // Successor
        }
        field(4; "Link Type"; Enum "BCG Gantt Link Type")
        {
            Caption = 'Link Type';
        }
        field(5; "Lag (Days)"; Integer)
        {
            Caption = 'Lag (Days)';
        }
        field(20; "Source Task Description"; Text[100])
        {
            Caption = 'Source Task Description';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = Lookup("Job Task"."Description" where("Job No." = field("Job No."), "Job Task No." = field("Source Task No.")));
        }
        field(21; "Target Task Description"; Text[100])
        {
            Caption = 'Target Task Description';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = Lookup("Job Task"."Description" where("Job No." = field("Job No."), "Job Task No." = field("Target Task No.")));
        }
        field(50510; "Constraint Type"; Enum "Gantt Constraint Type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Constraint Type';
        }
        field(50511; "Constraint Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Constraint Date';
        }
        field(50512; "Constraint Is Hard"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Constraint Is Hard';
        }
        field(50513; "Deadline Date"; Date) // optional but recommended
        {
            DataClassification = ToBeClassified;
            Caption = 'Deadline Date';
        }

        // Add changes to table fields here

        field(50520; "Scheduling Type"; Enum schedulingType)
        {
            DataClassification = ToBeClassified;
            Caption = 'Scheduling Type';
        }
    }

    keys
    {
        key(PK; "Job No.", "Source Task No.", "Target Task No.", "Link Type")
        {
            Clustered = true;
        }
    }
}


//OLD:
// {
//     Caption = 'Gantt Task Link';
//     DataClassification = CustomerContent;

//     fields
//     {
//         field(1; "Project No."; Code[20])
//         {
//             Caption = 'Project No.';
//             DataClassification = CustomerContent;
//             tableRelation = Job;
//         }
//         field(2; "Source Task No."; Code[20])
//         {
//             Caption = 'Source Task No.';
//             DataClassification = CustomerContent;
//             tableRelation = "job task"."Job Task No." where("Job No." = field("Project No."));
//         }

//         field(3; "Link Id"; Guid)
//         {
//             Caption = 'Link Id';
//             DataClassification = SystemMetadata;
//         }


//         field(5; "Target Task No."; Code[50])
//         {
//             Caption = 'Target Task No.';
//             DataClassification = CustomerContent;
//             tableRelation = "job task"."Job Task No." where("Job No." = field("Project No."));
//         }

//         field(6; "Link Type"; Enum "Gantt Constraint Type")
//         {
//             Caption = 'Link Type';
//             DataClassification = CustomerContent;
//         }

//         field(7; "Lag (Days)"; Integer)
//         {
//             Caption = 'Lag (Days)';
//             DataClassification = CustomerContent;
//             MinValue = 0;
//         }

//         field(8; "Created At"; DateTime)
//         {
//             Caption = 'Created At';
//             Editable = false;
//             DataClassification = SystemMetadata;
//         }

//         field(9; "Modified At"; DateTime)
//         {
//             Caption = 'Modified At';
//             Editable = false;
//             DataClassification = SystemMetadata;
//         }
//     }

//     keys
//     {
//         key(PK; "Project No.", "Source Task No.", "Link Id")
//         {
//             Clustered = true;
//         }

//         key(BySource; "Project No.", "Source Task No.", "Target Task No.") { }
//         key(ByTarget; "Project No.", "Target Task No.", "Source Task No.") { }
//     }

//     trigger OnInsert()
//     begin
//         if IsNullGuid("Link Id") then
//             "Link Id" := CreateGuid();

//         if "Created At" = 0DT then
//             "Created At" := CurrentDateTime();

//         "Modified At" := CurrentDateTime();

//         ValidateLink();
//     end;

//     trigger OnModify()
//     begin
//         "Modified At" := CurrentDateTime();
//         ValidateLink();
//     end;

//     trigger OnRename()
//     begin
//         Error('Renaming is not allowed. Links are identified by Project No. + Link Id.');
//     end;

//     local procedure ValidateLink()
//     begin
//         if "Project No." = '' then
//             Error('Project No. must be filled.');

//         if "Source Task No." = '' then
//             Error('Source Task No. must be filled.');

//         if "Target Task No." = '' then
//             Error('Target Task No. must be filled.');

//         if "Source Task No." = "Target Task No." then
//             Error('Source Task No. and Target Task No. cannot be the same.');

//         // Optional: prevent duplicates within a project (same source+target+type)
//         // Uncomment if desired.
//         /*
//         var
//             Link2: Record "BCG Gantt Task Link";
//         begin
//             Link2.SetRange("Project No.", "Project No.");
//             Link2.SetRange("Source Task Id", "Source Task Id");
//             Link2.SetRange("Target Task Id", "Target Task Id");
//             Link2.SetRange("Link Type", "Link Type");
//             Link2.SetFilter("Link Id", '<>%1', "Link Id");
//             if Link2.FindFirst() then
//                 Error('A link with the same Source, Target and Type already exists.');
//         end;
//         */
//     end;
// }
