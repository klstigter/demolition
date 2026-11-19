tableextension 50603 "Opti Resource" extends Resource
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Opti Pool Resource No."; Code[20])
        {
            Caption = 'Pool Resource No.';
            DataClassification = CustomerContent;
            tablerelation = Resource where("Opti Is Pool" = const(true));

            trigger OnValidate()
            var
                Res: Record Resource;
                Res2: Record Resource;
            begin
                if "Opti Pool Resource No." = '' then begin
                    "Opti Is Pool" := false;
                    "Opti Is Pool Member" := false;
                    if xRec."Opti Pool Resource No." <> '' then begin
                        if xRec."Opti Pool Resource No." = "No." then begin
                            Res.SetRange("Opti Pool Resource No.", "No.");
                            Res.SetFilter("No.", '<>%1', "No.");
                            if Res.FindSet() then begin
                                if not Confirm(ErrorLbl, false, xRec."Opti Pool Resource No.", Res.Count, Rec."Vendor No.") then
                                    error(Error2Lbl);
                                repeat
                                    Res2 := Res;
                                    Res2."Opti Pool Resource No." := '';
                                    Res2."Opti Is Pool Member" := false;
                                    Res2."Vendor No." := Rec."Vendor No.";
                                    if Res2."Vendor No." <> '' then
                                        Res2."Opti Is External" := true;
                                    Res2.Modify();
                                until Res.Next() = 0;
                            end;
                        end else begin
                            Res.Get(xRec."Opti Pool Resource No.");
                            Rec."Vendor No." := Res."Vendor No.";
                        end;
                        if Rec."Vendor No." <> '' Then
                            Rec."Opti Is External" := true;
                    end;
                end else begin
                    "Opti Is Pool" := "Opti Pool Resource No." = "No.";
                    "Opti Is External" := false;
                    if not "Opti Is Pool" then begin
                        Res.Get("Opti Pool Resource No.");
                        "Opti Is Pool Member" := Res."Vendor No." <> '';
                        "Vendor No." := '';
                    end;
                end;
            end;
        }
        field(50601; "Opti Day Plannings"; Decimal)
        {
            Caption = 'Day Plannings';

            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Opti Day Planning"."Assigned Hours" where("Assigned Resource No." = field("No."),
              "Plan Date" = field("Date Filter")));
        }
        field(50602; "Opti Skills"; integer)
        {
            Caption = 'Skills';

            FieldClass = FlowField;
            CalcFormula = Count("Resource Skill" where("No." = field("No."), type = const(Resource)));
        }
        field(50603; "Opti Is Pool Member"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Pool Member';

            trigger OnValidate()
            var
                Res: Record Resource;
                ResList: Page "Resource List";
                OldPoolResNo: Code[20];
            begin
                if "Opti Is Pool Member" then begin
                    OldPoolResNo := "Opti Pool Resource No.";
                    "Opti Pool Resource No." := ''; // so always popup pool resource
                    if "Opti Pool Resource No." = '' then begin
                        Clear(ResList);
                        Res.Setrange("Opti Is Pool", true);
                        Res.Setfilter("No.", '<>%1', Rec."No.");
                        ResList.SetTableView(Res);
                        ResList.LookupMode := true;
                        if ResList.RunModal() = Action::LookupOK then begin
                            ResList.GetRecord(Res);
                            "Opti Pool Resource No." := Res."No.";
                            "Vendor No." := '';
                            "Opti Is Pool" := false;
                            "Opti Is External" := false;
                        end else begin
                            "Opti Is Pool Member" := false;
                            "Opti Pool Resource No." := OldPoolResNo;
                        end;
                    end else begin
                        "Vendor No." := '';
                        "Opti Is Pool" := false;
                        "Opti Is External" := false;
                    end;
                end else begin
                    "Opti Pool Resource No." := '';
                    "Vendor No." := '';
                    "Opti Is Pool" := false;
                    "Opti Is External" := false;
                end;
            end;
        }
        field(50604; "Opti Is External"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is External';

            trigger OnValidate()
            var
                Ven: Record Vendor;
                VenList: Page "Vendor List";
            begin
                if "Opti Is External" then begin
                    if "Vendor No." = '' then begin
                        Clear(VenList);
                        VenList.SetTableView(Ven);
                        VenList.LookupMode := true;
                        if VenList.RunModal() = Action::LookupOK then begin
                            VenList.GetRecord(Ven);
                            "Vendor No." := Ven."No.";
                            "Opti Pool Resource No." := '';
                            "Opti Is Pool" := false;
                            "Opti Is Pool Member" := false;
                        end else begin
                            "Opti Is External" := false;
                        end;
                    end else begin
                        "Opti Pool Resource No." := '';
                        "Opti Is Pool" := false;
                        "Opti Is Pool Member" := false;
                    end;
                end else begin
                    "Vendor No." := '';
                    "Opti Pool Resource No." := '';
                    "Opti Is Pool" := false;
                    "Opti Is Pool Member" := false;
                end;
            end;
        }
        field(50610; "Opti Assigned Hours"; Decimal)
        {
            CalcFormula = sum("Opti Day Planning"."Assigned Hours" where("Assigned Resource No." = field("No."),
                                                                    "Plan Date" = field("Date Filter")));
            Caption = 'Capacity';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            Editable = false;
        }
        field(50611; "Opti Requested Hours"; Decimal)
        {
            CalcFormula = sum("Opti Day Planning"."Requested Hours" where("Requested Resource No." = field("No."),
                                                                     "Plan Date" = field("Date Filter")));
            Caption = 'Requested';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            Editable = false;
        }
        field(50620; "Opti Mandatory Schedulling"; Boolean)
        {
            Caption = 'Mandatory Schedulling';
            DataClassification = CustomerContent;
        }
        field(50622; "Opti Is Foreman"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Foreman';
        }
        field(50624; "Opti Is Pool"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Pool';
            trigger OnValidate()
            var
                Res: Record Resource;
                Res2: Record Resource;
                Ven: Record Vendor;
                VenList: Page "Vendor List";
            begin
                if "Opti Is Pool" then begin
                    if "Vendor No." = '' then begin
                        Clear(VenList);
                        VenList.SetTableView(Ven);
                        VenList.LookupMode := true;
                        if VenList.RunModal() = Action::LookupOK then begin
                            VenList.GetRecord(Ven);
                            "Vendor No." := Ven."No.";
                            "Opti Pool Resource No." := "No.";
                            "Opti Is Pool Member" := false;
                            "Opti Is External" := false;
                        end else begin
                            "Opti Is Pool" := false;
                        end;
                    end else begin
                        "Opti Pool Resource No." := "No.";
                        "Opti Is Pool Member" := false;
                        "Opti Is External" := false;
                    end;
                end else begin
                    "Opti Pool Resource No." := '';
                    if (xRec."Opti Pool Resource No." <> '') then begin
                        if xRec."Opti Pool Resource No." = "No." then begin
                            Rec."Opti Is Pool Member" := false;
                            Res.SetRange("Opti Pool Resource No.", "No.");
                            Res.SetFilter("No.", '<>%1', "No.");
                            if Res.FindSet() then begin
                                if not Confirm(ErrorLbl, false, xRec."Opti Pool Resource No.", Res.Count, Rec."Vendor No.") then
                                    error(Error2Lbl);
                                repeat
                                    Res2 := Res;
                                    Res2."Opti Pool Resource No." := '';
                                    Res2."Opti Is Pool Member" := false;
                                    Res2."Vendor No." := Rec."Vendor No.";
                                    if Res2."Vendor No." <> '' then
                                        Res2."Opti Is External" := true;
                                    Res2.Modify();
                                until Res.Next() = 0;
                            end;
                        end;
                    end;
                    if Rec."Vendor No." <> '' then
                        Rec."Opti Is External" := true;
                end;
            end;
        }
        field(50630; "Opti Default Foreman"; Code[20])
        {
            Caption = 'Default Foreman';
            DataClassification = CustomerContent;
            tablerelation = Resource where("Opti Is Foreman" = const(true));
        }
        field(50631; "Opti Default Foreman Name"; Text[100])
        {
            Caption = 'Default Foreman Name';
            FieldClass = FlowField;
            CalcFormula = Lookup(Resource.Name Where("No." = field("Opti Default Foreman")));
            Editable = false;
        }
        field(50640; "Opti Work Hour Template"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Work Hour Template';
            TableRelation = "Work-Hour Template";
        }

    }

    keys
    {
        key(OptiPoolResource; "Opti Is Pool", "Opti Pool Resource No.") { }
    }

    fieldgroups
    {
        addlast(DropDown; "Resource Group No.")
        {
        }

    }

    var
        ErrorLbl: Label 'Resource %1 will be changed from Pool to Not Pool for Vendor No. %3. As a result, %2 related resource(s) will be set to External under Vendor No. %3.', Comment = '%1 = value, %2 = value, %3 = value';
        Error2Lbl: Label 'Modify aborted';
}