table 50608 "Workorder"
{
    Caption = 'Workorder';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Workorder No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
            NotBlank = true;
        }

        field(10; "Order Intake No."; Code[20])
        {
            Caption = 'Order Intake No.';
            DataClassification = CustomerContent;
            // TODO: Add TableRelation = "Order Intake Header"."No.";
        }

        field(20; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }

        field(30; "Long Description"; Text[2048])
        {
            Caption = 'Long Description';
            DataClassification = CustomerContent;
        }

        field(40; "External Reference"; Text[100])
        {
            Caption = 'External Reference';
            DataClassification = CustomerContent;
        }

        field(50; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer."No.";
            DataClassification = CustomerContent;
        }

        field(60; "Project No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job."No.";
            DataClassification = CustomerContent;
        }
        field(61; "Project Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            DataClassification = CustomerContent;
            TableRelation = "Job Task"."Job Task No." where("Job No." = FIELD("Project No."));
        }

        field(110; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            TableRelation = Contact."No.";
            DataClassification = CustomerContent;
        }

        field(130; "Source Type"; Enum "Workload Source Type")
        {
            Caption = 'Source Type';
            DataClassification = CustomerContent;
            //manual, order intake
        }

        field(200; "Date Window Start"; Date)
        {
            Caption = 'Date Window Start';
            DataClassification = CustomerContent;
        }

        field(210; "Date Window End"; Date)
        {
            Caption = 'Date Window End';
            DataClassification = CustomerContent;
        }

        field(280; "Deadline Date"; Date)
        {
            Caption = 'Deadline Date';
            DataClassification = CustomerContent;
        }

        field(220; "Time Span Days"; Integer)
        {
            Caption = 'Time Span Days';
            DataClassification = CustomerContent;
            trigger OnValidate()
            var
                WorkloadSpec: Record "Workorder Capacity Request";
            begin
                WorkloadSpec.SetRange("Workorder No.", "Workorder No.");
                if WorkloadSpec.FindFirst() then
                    repeat
                        WorkloadSpec.CalcTotalHours("Time Span Days");
                    until WorkloadSpec.Next() = 0;

            end;
        }

        field(230; "Requested Hours"; Decimal)
        {
            Caption = 'Requested Hours';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            CalcFormula = sum("Workorder Capacity Request"."Total Hours Workorder Spec." where("Workorder No." = FIELD("Workorder No.")));
            //Editable = false;

        }

        field(920; Closed; Boolean)
        {
            Caption = 'Closed';
            DataClassification = CustomerContent;
        }

        field(930; "Closed Date"; Date)
        {
            Caption = 'Closed Date';
            DataClassification = CustomerContent;
        }

        field(940; "Closed Reason Code"; Code[20])
        {
            Caption = 'Closed Reason Code';
            DataClassification = CustomerContent;
        }

        field(950; "Created DateTime"; DateTime)
        {
            Caption = 'Created DateTime';
            Editable = false;
            DataClassification = SystemMetadata;
        }

        field(960; "Created By"; Code[50])
        {
            Caption = 'Created By';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }

        field(970; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified DateTime';
            Editable = false;
            DataClassification = SystemMetadata;
        }

        field(980; "Last Modified By"; Code[50])
        {
            Caption = 'Last Modified By';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; "Workorder No.")
        {
            Clustered = true;
        }

        key(CustomerDateWindow; "Customer No.", "Date Window Start", "Date Window End")
        {
        }

        key(OrderIntake; "Order Intake No.")
        {
        }

        key(DateWindow; "Date Window Start", "Date Window End")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Workorder No.", Description, "Customer No.", "Date Window Start", "Date Window End")
        {
        }

        fieldgroup(Brick; "Workorder No.", Description, "Customer No.", "Requested Hours")
        {
        }
    }

    trigger OnInsert()
    begin
        "Created DateTime" := CurrentDateTime();
        "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));
        SetLastModified();
    end;

    trigger OnModify()
    begin
        SetLastModified();
    end;

    local procedure SetLastModified()
    begin
        "Last Modified DateTime" := CurrentDateTime();
        "Last Modified By" := CopyStr(UserId(), 1, MaxStrLen("Last Modified By"));
    end;
}