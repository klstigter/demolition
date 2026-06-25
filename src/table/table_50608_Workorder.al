table 50608 "Work Order"
{
    Caption = 'Workorder';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Work Order No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;

        }

        field(10; "Order Intake No."; Code[20])
        {
            Caption = 'Order Intake No.';
            DataClassification = CustomerContent;
            TableRelation = "Order Intake Header Opt.";
        }

        field(20; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(25; "Work Order NOS"; Code[20])
        {
            Caption = 'Work Order NOS';
            DataClassification = CustomerContent;
            tableRelation = "No. Series";
        }

        field(30; "Long Description"; blob)
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

        // field(220; "Time Span Days"; Integer)
        // {
        //     Caption = 'Time Span Days';
        //     DataClassification = CustomerContent;
        //     trigger OnValidate()
        //     var
        //         WorkloadSpec: Record "Workorder Capacity Request";
        //     begin
        //         WorkloadSpec.SetRange("Workorder No.", "Work Order No.");
        //         if WorkloadSpec.FindFirst() then
        //             repeat
        //                 WorkloadSpec.CalcTotalHours("Time Span Days");
        //             until WorkloadSpec.Next() = 0;

        //     end;
        // }

        field(225; "Placeholder Date"; Date)
        {
            Caption = 'Placeholder Date';
            DataClassification = CustomerContent;
        }

        field(230; "Requested Hours"; Decimal)
        {
            Caption = 'Requested Hours';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            CalcFormula = sum("Day Planning"."Requested Hours" where("Work order No." = FIELD("Work Order No.")));
            Editable = false;
        }
        field(231; "Assigned Hours"; Decimal)
        {
            Caption = 'Assigned Hours';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            CalcFormula = sum("Day Planning"."Assigned Hours" where("Work order No." = FIELD("Work Order No.")));
            Editable = false;
        }
        field(232; "Realized Hours"; Decimal)
        {
            Caption = 'Realized Hours';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            CalcFormula = sum("Day Planning"."Realized Hours" where("Work order No." = FIELD("Work Order No.")));
            Editable = false;
        }
        field(300; "Items"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Work Order Line" where("Work Order No." = field("Work Order No.")));
            Editable = false;
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
        field(1000; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(PK; "Work Order No.")
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
        fieldgroup(DropDown; "Work Order No.", Description, "Customer No.", "Date Window Start", "Date Window End")
        {
        }

        fieldgroup(Brick; "Work Order No.", Description, "Customer No.", "Requested Hours")
        {
        }
    }

    trigger OnInsert()
    begin
        testfield("Work Order No.");
        "Created DateTime" := CurrentDateTime();
        "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));
        SetLastModified();
    end;

    trigger OnModify()
    begin
        SetLastModified();
    end;

    trigger OnDelete()
    var
        WOLine: Record "Work Order Line";
        DayPlanning: Record "Day Planning";
    begin
        WOLine.SetRange("Work Order No.", "Work Order No.");
        if WOLine.FindSet() then
            WOLine.DeleteAll(true);
        DayPlanning.SetRange("Work Order No.", "Work Order No.");
        if DayPlanning.FindSet() then
            DayPlanning.DeleteAll(true);
    end;

    var
        WorkOrder: Record "Work Order";
        OptimizerSetup: record "Daily Optimizer Setup";
        NoSeries: Codeunit "No. Series";

    procedure AssistEdit(OldWorkOrder: Record "Work Order") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, OldWorkOrder, IsHandled, Result);
        if IsHandled then
            exit(Result);

        WorkOrder := Rec;
        OptimizerSetup.Get();
        OptimizerSetup.TestField("Order Intake Nos");
        if NoSeries.LookupRelatedNoSeries(OptimizerSetup."Order Intake Nos", OldWorkOrder."No. Series", WorkOrder."No. Series") then begin
            WorkOrder."Work Order No." := NoSeries.GetNextNo(WorkOrder."No. Series");
            Rec := WorkOrder;
            exit(true);
        end;
    end;

    procedure SetDescription(pDescBody: Text)
    var
        OutStream: OutStream;
    begin
        Rec."Long Description".CreateOutStream(OutStream);
        OutStream.WriteText(pDescBody);
        Rec.Modify();
    end;

    procedure GetDescription(): Text
    var
        InStream: InStream;
        DescText: Text;
    begin
        DescText := '';
        Rec.CalcFields("Long Description");
        if Rec."Long Description".HasValue() then begin
            Rec."Long Description".CreateInStream(InStream);
            InStream.ReadText(DescText);
        end;
        exit(DescText);
    end;

    local procedure SetLastModified()
    begin
        "Last Modified DateTime" := CurrentDateTime();
        "Last Modified By" := CopyStr(UserId(), 1, MaxStrLen("Last Modified By"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var OrderIntakeHeader: Record "Work Order"; xOldOrderIntakeHeader: Record "Work Order"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;
}