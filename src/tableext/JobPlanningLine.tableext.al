tableextension 50600 "DDSIA Job Task" extends "Job Planning Line"
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Start Time"; Time)
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                CheckOverlap();
            end;
        }
        field(50601; "End Time"; Time)
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
        field(50603; "Vendor No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Vendor;
            Caption = 'Vendor No.';
        }
        field(50604; "Vendor Name"; Text[100])
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
        field(50530; Depth; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(50605; IsBoor; Boolean)
        {
            DataClassification = ToBeClassified;
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
        RestMgt: Codeunit "DDSIA Rest API Mgt.";
        auto: Boolean;
    begin
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

    local procedure CheckOverlap()
    var
        DT: Date;
        DT1: DateTime;
        DT2: DateTime;
    begin
        DT1 := 0DT;
        DT2 := CreateDateTime(DMY2Date(31, 12, 2999), Time);

        if ("Planning Date" <> 0D) and ("Start Time" <> 0T) then begin
            DT := "Planning Date";
            DT1 := CreateDateTime(DT, "Start Time");
        end;
        if ("End Planning Date" <> 0D) and ("End Time" <> 0T) then begin
            DT := "End Planning Date";
            DT2 := CreateDateTime(DT, "End Time");
        end;
        if DT1 > DT2 then
            error('Datetime overlaped!');
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