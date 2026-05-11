table 50614 "Workorder Capacity Request"
{
    Caption = 'Workorder Capacity Request';
    DataClassification = CustomerContent;
    DrillDownPageId = "Workorder Cap. Req. Subfrm";
    LookupPageId = "Workorder Cap. Req. Subfrm";

    fields
    {
        field(1; "Workorder No."; Code[20])
        {
            Caption = 'Workorder No.';
            TableRelation = "Workorder"."Workorder No.";
        }

        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }

        field(10; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
        }
        field(20; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource."No.";

            trigger OnValidate()
            begin
                if "Resource No." <> '' then begin
                    "Resource Group Code" := '';
                    "Skill Code" := '';
                end;
            end;
        }

        field(30; "Resource Group Code"; Code[20])
        {
            Caption = 'Resource Group Code';
            TableRelation = "Resource Group"."No.";

            trigger OnValidate()
            begin
                if "Resource Group Code" <> '' then begin
                    "Resource No." := '';
                    "Skill Code" := '';
                end;
            end;
        }

        field(40; "Skill Code"; Code[20])
        {
            Caption = 'Skill Code';
            TableRelation = "Skill Code";
            trigger OnValidate()
            begin
                if "Skill Code" <> '' then begin
                    "Resource No." := '';
                    "Resource Group Code" := '';
                end;
            end;
        }


        field(60; Description; Text[100])
        {
            Caption = 'Description';
        }

        field(70; Mandatory; Boolean)
        {
            Caption = 'Mandatory';
        }
        field(75; "Amount of Resources"; Integer)
        {
            Caption = 'Amount of Resources';
            ToolTip = 'Specifies the amount of resources needed per day for the workload. This field is only applicable when either Resource No. or Resource Group Code is specified.';
            MinValue = 0;
            trigger OnValidate()
            begin
                calcTotalHours();
            end;
        }
        field(80; Hours; Decimal)
        {
            Caption = 'Hours';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the quantity of work per resource to be performed. This field is only applicable when neither Resource No. nor Resource Group Code is specified.';
            MinValue = 0;
            trigger OnValidate()
            begin
                calcTotalHours();
            end;
        }
        field(90; "Total hours per day"; Decimal)
        {
            Caption = 'Total hours per day';
            DecimalPlaces = 0 : 5;
            editable = false;
            ToolTip = 'Specifies the total quantity of work to be performed per day for the workload. This field is calculated based on the values entered in the Amount of Resources and Hours fields.';
            MinValue = 0;
        }
        field(100; "Total Hours Workorder Spec."; Decimal)
        {
            Caption = 'Total Hours';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the total quantity of work to be performed per day for the workload. This field is calculated based on the values entered in the Amount of Resources and Hours fields.';
            Editable = false;
            MinValue = 0;
        }

    }

    keys
    {
        key(PK; "Workorder No.", "Line No.")
        {
            Clustered = true;
        }

        key(Key1; "Sequence No.")
        {
        }

    }
    var
        WorkOrder: Record "Workorder";

    procedure GetWorkOrder()
    begin
        if WorkOrder."Workorder No." <> Rec."Workorder No." then
            WorkOrder.Get("Workorder No.");
    end;

    procedure CalcTotalHours(TimeSpanDyas: integer);
    var
    begin
        "Total Hours Workorder Spec." := "Amount of Resources" * Hours * TimeSpanDyas;
        Modify();
    end;

    procedure CalcTotalHours()
    var
    begin
        if (Hours = 0) then
            exit;
        if "Amount of Resources" = 0 then
            "Amount of Resources" := 1;
        "Total hours per day" := "Amount of Resources" * Hours;
        GetWorkOrder();
        if WorkOrder."Time Span Days" = 0 then
            WorkOrder."Time Span Days" := 1;
        CalcTotalHours(WorkOrder."Time Span Days");
    end;
}