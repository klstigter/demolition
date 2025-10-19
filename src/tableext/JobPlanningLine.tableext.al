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
        field(50605; "Planning Resource id"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(50530; Depth; Decimal)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    trigger OnAfterInsert()
    var
        IntegrationSetup: Record "Planning Integration Setup";
        RestMgt: Codeunit "DDSIA Rest API Mgt.";
        auto: Boolean;
    begin
        auto := NOT IsServiceTier();
        if auto then
            auto := IntegrationSetup.Get();
        if auto then
            auto := IntegrationSetup."Auto Sync. Integration";
        if not auto then
            exit;
        RestMgt.PushJobPlanningLineToIntegration(Rec, false);
    end;

    trigger OnAfterModify()
    var
        Res: Record Resource;
        Ven: Record Vendor;
        IntegrationSetup: Record "Planning Integration Setup";
        RestMgt: Codeunit "DDSIA Rest API Mgt.";
        auto: Boolean;
    begin
        if Rec."No." <> xRec."No." then begin
            "Planning Resource id" := 0;
            Modify();
            if Type = Type::Resource then
                if Res.Get(Rec."No.") then begin
                    "Planning Resource id" := Res."Planning Resource Id";
                    if Res."Planning Vendor Id" <> 0 then begin
                        Ven.SetRange("Planning Vendor id", Res."Planning Vendor Id");
                        if Ven.FindFirst() then
                            "Vendor No." := Ven."No.";
                    end;
                    Modify();
                end;
        end;

        // Integration
        auto := NOT IsServiceTier();
        if auto then
            auto := IntegrationSetup.Get();
        if auto then
            auto := IntegrationSetup."Auto Sync. Integration";
        if auto then
            auto := (Rec."Vendor No." <> xRec."Vendor No.")
                    or (Rec."No." <> xRec."No.");
        if not auto then
            exit;
        RestMgt.PushJobPlanningLineToIntegration(Rec, false);
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
}