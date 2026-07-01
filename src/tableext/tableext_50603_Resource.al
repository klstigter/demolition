tableextension 50603 "Resource Opt" extends Resource
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Pool Resource No."; Code[20])
        {
            DataClassification = ToBeClassified;
            tablerelation = Resource where("is pool" = const(true));

            trigger OnValidate()
            var
                Res: Record Resource;
                Res2: Record Resource;
            begin
                if "Pool Resource No." = '' then begin
                    "is Pool" := false;
                    "is Pool Member" := false;
                    if xRec."Pool Resource No." <> '' then begin
                        if xRec."Pool Resource No." = "No." then begin
                            Res.SetRange("Pool Resource No.", "No.");
                            Res.SetFilter("No.", '<>%1', "No.");
                            if Res.FindSet() then begin
                                if not Confirm(ErrorLbl, false, xRec."Pool Resource No.", Res.Count, Rec."Vendor No.") then
                                    error(Error2Lbl);
                                repeat
                                    Res2 := Res;
                                    Res2."Pool Resource No." := '';
                                    Res2."Is Pool Member" := false;
                                    Res2."Vendor No." := Rec."Vendor No.";
                                    if Res2."Vendor No." <> '' then
                                        Res2."Is External" := true;
                                    Res2.Modify();
                                until Res.Next() = 0;
                            end;
                        end else begin
                            Res.Get(xRec."Pool Resource No.");
                            Rec."Vendor No." := Res."Vendor No.";
                        end;
                        if Rec."Vendor No." <> '' Then
                            Rec."Is External" := true;
                    end;
                end else begin
                    "is Pool" := "Pool Resource No." = "No.";
                    "Is External" := false;
                    if not "is Pool" then begin
                        Res.Get("Pool Resource No.");
                        "Is Pool Member" := Res."Vendor No." <> '';
                        "Vendor No." := '';
                    end;
                end;
            end;
        }
        field(50601; "Day Plannings"; Decimal)
        {

            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Day Planning"."Assigned Hours" where("Assigned Resource No." = field("No."),
              "Task Date" = field("Date Filter")));
        }
        field(50602; "Skills"; integer)
        {
            Caption = 'Skills';

            FieldClass = FlowField;
            CalcFormula = Count("Resource Skill" where("No." = field("No."), type = const(Resource)));
        }
        field(50603; "Is Pool Member"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is Pool Member';
            Editable = false; // Control by "Pool Resource No.";
        }
        field(50604; "Is External"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is External';
            Editable = false; // Control by "Vendor No.";
        }
        field(50610; "Assigned Hours"; Decimal)
        {
            CalcFormula = sum("Day Planning"."Assigned Hours" where("Assigned Resource No." = field("No."),
                                                                    "Task Date" = field("Date Filter")));
            Caption = 'Capacity';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            Editable = false;
        }
        field(50611; "Requested Hours"; Decimal)
        {
            CalcFormula = sum("Day Planning"."Requested Hours" where("Requested Resource No." = field("No."),
                                                                     "Task Date" = field("Date Filter")));
            Caption = 'Requested';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            Editable = false;
        }
        field(50620; "Mandatory Schedulling"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(50622; "Is Foreman"; Boolean)
        {
            Caption = 'Is Foreman';
        }
        field(50624; "Is Pool"; Boolean)
        {
            Caption = 'Is Pool';
            trigger OnValidate()
            var
                Res: Record Resource;
                Res2: Record Resource;
            begin
                if "Is Pool" then begin
                    testfield("Vendor No.");
                    "Pool Resource No." := "No.";
                    "Is Pool Member" := false;
                    "Is External" := false;
                end else begin
                    "Pool Resource No." := '';
                    if (xRec."Pool Resource No." <> '') then begin
                        if xRec."Pool Resource No." = "No." then begin
                            Rec."Is Pool Member" := false;
                            Res.SetRange("Pool Resource No.", "No.");
                            Res.SetFilter("No.", '<>%1', "No.");
                            if Res.FindSet() then begin
                                if not Confirm(ErrorLbl, false, xRec."Pool Resource No.", Res.Count, Rec."Vendor No.") then
                                    error(Error2Lbl);
                                repeat
                                    Res2 := Res;
                                    Res2."Pool Resource No." := '';
                                    Res2."Is Pool Member" := false;
                                    Res2."Vendor No." := Rec."Vendor No.";
                                    if Res2."Vendor No." <> '' then
                                        Res2."Is External" := true;
                                    Res2.Modify();
                                until Res.Next() = 0;
                            end;
                        end;
                    end;
                    if Rec."Vendor No." <> '' then
                        Rec."Is External" := true;
                end;
            end;
        }
        field(50630; "Default Foreman"; Code[20])
        {
            Caption = 'Default Foreman';
            DataClassification = ToBeClassified;
            tablerelation = Resource where("Is Foreman" = const(true));
        }
        field(50631; "Default Foreman Name"; Text[100])
        {
            Caption = 'Default Foreman Name';
            FieldClass = FlowField;
            CalcFormula = Lookup(Resource.Name Where("No." = field("Default Foreman")));
            Editable = false;
        }
        field(50640; "Work Hour Template"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Work Hour Template';
            TableRelation = "Work-Hour Template";
        }

    }

    keys
    {
        key(PoolResource; "Is Pool", "Pool Resource No.") { }
    }

    fieldgroups
    {
        addlast(DropDown; "Resource Group No.")
        {
        }

    }

    var
        ErrorLbl: Label 'Resource %1 will be changed from Pool to Not Pool for Vendor No. %3. As a result, %2 related resource(s) will be set to External under Vendor No. %3.';
        Error2Lbl: Label 'Modify aborted';
}