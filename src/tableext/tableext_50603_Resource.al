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
            begin
                if "Pool Resource No." = '' then begin
                    "is Pool" := false;
                    if (xRec."Pool Resource No." <> '') and (xRec."Pool Resource No." = "No.") then begin
                        Res.SetRange("Pool Resource No.", "No.");
                        Res.SetFilter("No.", '<>%1', "No.");
                        if Res.FindSet() then
                            Res.ModifyAll("Pool Resource No.", '');
                    end;
                end else begin
                    "is Pool" := "Pool Resource No." = "No.";
                    if not "is Pool" then begin
                        Res.Get("Pool Resource No.");
                        "External Resource" := Res."Vendor No." <> '';
                    end;
                end;
            end;
        }
        field(50601; "Day Tasks"; Decimal)
        {

            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Day Tasks"."Assigned Hours" where("No." = field("No."),
              "Task Date" = field("Date Filter")));
        }
        field(50602; "Skills"; integer)
        {
            Caption = 'Skills';

            FieldClass = FlowField;
            CalcFormula = Count("Resource Skill" where("No." = field("No."), type = const(Resource)));
        }
        field(50603; "External Resource"; Boolean)
        {
            DataClassification = ToBeClassified;
            Editable = false; // Control by "Pool Resource No.";
        }
        field(50610; "Day Task"; Decimal)
        {
            CalcFormula = sum("Day Tasks"."Assigned Hours" where("No." = field("No."),
                                                                    "Task Date" = field("Date Filter")));
            Caption = 'Capacity';
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
            begin
                if "Is Pool" then begin
                    testfield("Vendor No.");
                    "Pool Resource No." := "No.";
                    "External Resource" := true;
                end else begin
                    "Pool Resource No." := '';
                    if (xRec."Pool Resource No." <> '') and (xRec."Pool Resource No." = "No.") then begin
                        Res.SetRange("Pool Resource No.", "No.");
                        Res.SetFilter("No.", '<>%1', "No.");
                        if Res.FindSet() then
                            Res.ModifyAll("Pool Resource No.", '');
                    end;
                end;
            end;
        }
        field(50630; "Team Leader"; Code[20])
        {
            DataClassification = ToBeClassified;
            tablerelation = Resource;
        }
        field(50631; "Team Leader Name"; Text[100])
        {
            Caption = 'Team Leader Name';
            FieldClass = FlowField;
            CalcFormula = Lookup(Resource.Name Where("No." = field("Team Leader")));
            Editable = false;
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

}