table 50604 "Order Intake Header Opt."
{
    DataClassification = CustomerContent;
    Caption = 'Order Intake Header';
    LookupPageId = "Order Intake Opt.";
    DrillDownPageId = "Order Intake Opt.";

    fields
    {
        field(1; "No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "No." <> xRec."No." then begin
                    OptimizerSetup.Get();
                    NoSeries.TestManual(OptimizerSetup."Order Intake Nos");
                    "No. Series" := '';
                end;
            end;
        }
        field(10; "Order Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Order Date';
            ToolTip = 'Specifies the date of the order intake. The date is used for scheduling and planning purposes, and is based on the date on the related project planning line.';
            //InitValue = format(today(),0,'<year,4>-<month,2>-<day,2>');
        }
        field(20; "Customer No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Customer No.';
            ToolTip = 'Specifies the customer number for the order intake. The customer number is used to link the order intake to a specific customer in the system.';
            TableRelation = Customer;
        }
        field(25; "Customer Name"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Customer Name';
            ToolTip = 'Specifies the name of the customer for the order intake. This field is typically used for display purposes and is not required, as the customer number can be used to retrieve the customer name from the related customer record.';
        }
        field(26; "Contact No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Contact No.';
            ToolTip = 'Specifies the contact number for the order intake. This field is typically used for display purposes and is not required, as the customer number can be used to retrieve the contact number from the related customer record.';
            TableRelation = "Contact" where(Type = const(Person), "Company No." = field("Customer No."));
        }

        field(12; "Short Description"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Short Description';
            ToolTip = 'Specifies the short description for the order intake. for Kanban card view.';
        }
        field(13; Description; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
        field(40; Status; Enum "DayPlanning Order Intake Status")
        {
            DataClassification = CustomerContent;
            Caption = 'Status';
        }
        field(50; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Order Date")
        {
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    trigger OnDelete()
    var
        Workload: Record "Work Order";
        MsgLbl: Label 'Cannot delete Order Intake with status Released or Done.';
    begin
        if Status in [Status::Released, Status::Done] then begin
            Message(MsgLbl);
            exit; // Prevent deletion of records that are in use
        end;
        Workload.SetRange("Order Intake No.", "No.");
        Workload.DeleteAll(true);
    end;

    trigger OnInsert()
    var
        OrderIntake: Record "Order Intake Header Opt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        if "No." = '' then begin
            OptimizerSetup.Get();
            OptimizerSetup.TestField("Order Intake Nos");
            "No. Series" := OptimizerSetup."Order Intake Nos";
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series");
            OrderIntake.ReadIsolation(IsolationLevel::ReadUncommitted);
            OrderIntake.SetLoadFields("No.");
            while OrderIntake.Get("No.") do
                "No." := NoSeries.GetNextNo("No. Series");
        end;
        "Order Date" := Today();
    end;

    trigger OnModify()
    begin

    end;

    trigger OnRename()
    begin

    end;


    var
        gOrderIntake: Record "Order Intake Header Opt.";
        OptimizerSetup: record "Daily Optimizer Setup";
        NoSeries: Codeunit "No. Series";

    procedure AssistEdit(OldOrderIntake: Record "Order Intake Header Opt.") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, OldOrderIntake, IsHandled, Result);
        if IsHandled then
            exit(Result);

        gOrderIntake := Rec;
        OptimizerSetup.Get();
        OptimizerSetup.TestField("Order Intake Nos");
        if NoSeries.LookupRelatedNoSeries(OptimizerSetup."Order Intake Nos", OldOrderIntake."No. Series", gOrderIntake."No. Series") then begin
            gOrderIntake."No." := NoSeries.GetNextNo(gOrderIntake."No. Series");
            Rec := gOrderIntake;
            exit(true);
        end;
    end;

    procedure SetDescription(pDescBody: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Rec.Description);
        Rec.Description.CreateOutStream(OutStream);
        OutStream.WriteText(pDescBody);
        Rec.Modify();
    end;

    procedure GetDescription(): Text
    var
        InStream: InStream;
        DescText: Text;
    begin
        DescText := '';
        Rec.CalcFields(Description);
        if Rec.Description.HasValue() then begin
            Rec.Description.CreateInStream(InStream);
            InStream.ReadText(DescText);
        end;
        exit(DescText);
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateNo(var OrderIntakeHeader: Record "Order Intake Header Opt."; xOrderIntakeHeader: Record "Order Intake Header Opt."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var OrderIntakeHeader: Record "Order Intake Header Opt."; var IsHandled: Boolean; var xOrderIntakeHeader: Record "Order Intake Header Opt.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var OrderIntakeHeader: Record "Order Intake Header Opt."; xOldOrderIntakeHeader: Record "Order Intake Header Opt."; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;
}