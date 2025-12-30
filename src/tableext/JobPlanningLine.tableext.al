tableextension 50600 "Job Planning Line ext" extends "Job Planning Line"
{
    DrillDownPageId = "Job Planning Line Card";
    LookupPageId = "Job Planning Line Card";

    fields
    {
        // Add changes to table fields here
        field(50601; "Start Planning Date"; Date)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                CheckOverlap();
            end;
        }
        field(50602; "End Planning Date"; Date)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                CheckOverlap();
            end;
        }
        field(50603; "Start Time"; Time)
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                CheckOverlap();
                CalculateNonWorkingHours();
            end;
        }
        field(50604; "End Time"; Time)
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                CheckOverlap();
                CalculateNonWorkingHours();
            end;
        }

        field(50610; "Quantity of Lines"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quantity of Lines';
        }

        field(50615; "Vendor No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Vendor;
            Caption = 'Vendor No.';
        }
        field(50616; "Vendor Name"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
            Editable = false;
            Caption = 'Vendor Name';
        }
        // field(50605; "Planning Resource id"; Integer)
        // {
        //     DataClassification = ToBeClassified;
        // }
        field(50620; "Work-Hour Template"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Work-Hour Template";
            Caption = 'Work-Hour Template';
            trigger OnValidate()
            var
                workHourTemplate: Record "Work-Hour Template";
            begin
                if workHourTemplate.Get(Rec."Work-Hour Template") then begin
                    rec."Start Time" := workHourTemplate."Default Start Time";
                    rec."End Time" := workHourTemplate."Default End Time";
                    rec."Non Working Minutes" := workHourTemplate."Non Working Minutes";
                    Rec.Modify();
                end;
            end;
        }
        field(50630; "Non Working Minutes"; Integer)
        {
            Caption = 'Non Working Minutes';
            DataClassification = CustomerContent;
            Editable = true;

            trigger OnValidate()
            begin
                CalculateNonWorkingHours();
            end;
        }
        field(50640; "Working Hours"; Decimal)
        {
            Caption = 'Working Hours';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 2;
            Editable = false;
        }

        field(50650; SkillsRequired; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Skills Required';
            TableRelation = "Skill Code";
        }

        field(50660; Depth; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(50670; IsBoor; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(50680; "Job View Type"; Enum "Job View Type")
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Job Task"."Job View Type" where("Job Task No." = Field("Job Task No."), "Job No." = Field("Job No.")));
            Editable = false;
        }
    }

    keys
    {
        // Add changes to keys here
        key(P0001; IsBoor)
        {

        }

    }

    fieldgroups
    {
        // Add changes to field groups here
    }


    trigger OnAfterModify()
    var
        Res: Record Resource;
        Ven: Record Vendor;
        IntegrationSetup: Record "Planning Integration Setup";
        RestMgt: Codeunit "Rest API Mgt.";
        auto: Boolean;
    begin
        BalanceResourceQnty();

        if Rec."No." <> xRec."No." then
            if Type = Type::Resource then
                if Res.Get(Rec."No.") then
                    if Res."Planning Vendor Id" <> 0 then begin
                        Ven.SetRange("Planning Vendor id", Res."Planning Vendor Id");
                        if Ven.FindFirst() then begin
                            "Vendor No." := Ven."No.";
                            Modify();
                        end;
                    end;
    end;

    var

    Local procedure BalanceResourceQnty()
    var
    begin
        if CurrFieldNo = FieldNo("Quantity") then
            if rec.Quantity > 1 then begin
                rec."No." := '';
                rec."Vendor No." := '';
            end;
        if CurrFieldNo = FieldNo("No.") then
            if rec."No." <> '' then begin
                rec.Quantity := 1;
                rec."Vendor No." := '';
            end;
        if CurrFieldNo = FieldNo("Vendor No.") then
            if rec."Vendor No." <> '' then begin
                rec.Quantity := 1;
                rec."No." := '';
            end;
    end;


    local procedure CheckOverlap()
    var
        DT: Date;
        DT1: DateTime;
        DT2: DateTime;
    begin
        DT1 := 0DT;
        DT2 := CreateDateTime(DMY2Date(31, 12, 2999), Time);

        if ("Start Planning Date" <> 0D) and ("Start Time" <> 0T) then begin
            DT := "Start Planning Date";
            DT1 := CreateDateTime(DT, "Start Time");
        end;
        if ("End Planning Date" <> 0D) and ("End Time" <> 0T) then begin
            DT := "End Planning Date";
            DT2 := CreateDateTime(DT, "End Time");
        end;
        if DT1 > DT2 then
            error('Datetime overlaped!');
    end;

    local procedure CalculateNonWorkingHours()
    var
        TotalMinutes: Integer;
        WorkingMinutes: Integer;
    begin
        // If either time is not set, clear both hours fields
        if ("Start Time" = 0T) or ("End Time" = 0T) then begin
            "Working Hours" := 0;
            "Non Working Minutes" := 0;
            exit;
        end;

        // Calculate total minutes in a day (24 hours)
        TotalMinutes := 24 * 60;

        // Calculate working minutes
        WorkingMinutes := ("End Time" - "Start Time") div 60000;
        WorkingMinutes := WorkingMinutes - "Non Working Minutes";

        // Convert to hours (decimal)
        "Working Hours" := WorkingMinutes / 60;

    end;

    procedure GetResourceOrProductIDFromPlanningIntegration(): Integer
    var
        Resource: Record Resource;
        Item: Record Item;
        rtv: Integer;
    begin
        rtv := 0;
        if Rec."No." <> '' then
            case Rec.Type of
                Rec.Type::Resource:
                    begin
                        if Resource.Get(Rec."No.") then
                            rtv := Resource."Planning Resource Id";
                    end;
                Rec.Type::Item:
                    begin
                        if Item.Get(Rec."No.") then
                            rtv := Item."Planning Product Id";
                    end;
            end;
        exit(rtv);
    end;
}