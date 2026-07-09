/*
    Requested
    ===============================
    "Requested Resource No."
    "Requested Pool Resource No."
    "Start Time Requested"
    "End Time Requested"
    "Non Working Minutes Requested"
    "Requested Hours"
    "Total Requested Hours"

    Assigned
    ===============================
    "Assigned Resource No."
    "Assigned Pool Resource No."
    "Start Time Assigned"
    "End Time Assigned"
    "Non Working Minutes Assigned"
    "Assigned Hours"
    "Total Assigned Hours"

    Realized
    ===============================
    "Realized Hours"
    "Start Time Realized"
    "End Time Realized"

*/
table 50610 "Day Planning"
{
    DataClassification = ToBeClassified;
    Caption = 'Day Plannings';
    DrillDownPageId = "Day Plannings";
    LookupPageId = "Day Plannings";

    fields
    {
        field(3; "Job No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Job;
            Caption = 'Job No.';
        }
        field(4; "Job Task No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
            Caption = 'Job Task No.';
        }
        field(2; "Day Line No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Day Line No.';
            editable = false;
        }
        field(10; "Day No."; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(1; "Task Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Task Date';

        }
        field(5; "Plan Status"; Enum "Plan Status")
        {
            DataClassification = ToBeClassified;
            Caption = 'Plan Status';
        }
        field(6; "Pattern Line No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Pattern Line No.';
            ToolTip = 'The Value related to Day Planning Pattern';
        }
        field(11; "Start Time Assigned"; Time)
        {
            DataClassification = ToBeClassified;
            Caption = 'Start Time Assigned';

            trigger OnValidate()
            begin
                CalculateWorkingHours();
            end;
        }
        field(12; "End Time Assigned"; Time)
        {
            DataClassification = ToBeClassified;
            Caption = 'End Time Assigned';

            trigger OnValidate()
            begin
                CalculateWorkingHours();
            end;
        }
        field(13; "Start Time Requested"; Time)
        {
            DataClassification = ToBeClassified;
            Caption = 'Start Time Requested';

            trigger OnValidate()
            begin
                CalculateWorkingHours();
            end;
        }
        field(14; "End Time Requested"; Time)
        {
            DataClassification = ToBeClassified;
            Caption = 'End Time Requested';

            trigger OnValidate()
            begin
                CalculateWorkingHours();
            end;
        }

        // **** control Resource No.
        field(38; "Requested Pool Resource No."; Code[20])
        {
            DataClassification = ToBeClassified;
            tablerelation = Resource;

            trigger OnValidate()
            var
                Resource: Record Resource;
            begin
                if ("Requested Pool Resource No." <> '') and ("Requested Resource No." <> '') then begin
                    Resource.Get("Requested Resource No.");
                    if Resource."Pool Resource No." <> "Requested Pool Resource No." then
                        Error('Resource %1 does not belong to Pool Resource %2.', "Requested Resource No.", "Requested Pool Resource No.");
                end
            end;

            trigger OnLookup()
            var
                Resource: Record Resource;
            begin
                Resource.Reset();
                Resource.SetFilter("pool Resource No.", '<>%1', '');
                if Resource.FindSet() then
                    repeat
                        if Resource."Pool Resource No." = Resource."No." then
                            Resource.Mark(True);
                    until Resource.Next() = 0;
                Resource.MarkedOnly(true);
                if Resource.FindSet() then begin
                    if page.RunModal(0, Resource) = ACTION::LookupOK then
                        Validate("Requested Pool Resource No.", Resource."No.");
                end else
                    Message('No Pool Resources found.');
            end;
        }

        field(39; "Assigned Pool Resource No."; Code[20])
        {
            DataClassification = ToBeClassified;
            tablerelation = Resource;

            trigger OnValidate()
            var
                Resource: Record Resource;
            begin
                if ("Assigned Pool Resource No." <> '') and ("Assigned Resource No." <> '') then begin
                    Resource.Get("Assigned Resource No.");
                    if Resource."Pool Resource No." <> "Assigned Pool Resource No." then
                        Error('Resource %1 does not belong to Pool Resource %2.', "Assigned Resource No.", "Assigned Pool Resource No.");
                end
            end;

            trigger OnLookup()
            var
                Resource: Record Resource;
            begin
                Resource.Reset();
                Resource.SetFilter("pool Resource No.", '<>%1', '');
                if Resource.FindSet() then
                    repeat
                        if Resource."Pool Resource No." = Resource."No." then
                            Resource.Mark(True);
                    until Resource.Next() = 0;
                Resource.MarkedOnly(true);
                if Resource.FindSet() then begin
                    if page.RunModal(0, Resource) = ACTION::LookupOK then
                        Validate("Assigned Pool Resource No.", Resource."No.");
                end else
                    Message('No Pool Resources found.');
            end;
        }
        field(40; "Vendor No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Vendor;
            Caption = 'Vendor No.';

            trigger OnValidate()
            var
                Resource: Record Resource;
            begin
                if ("Vendor No." <> '') and ("Assigned Resource No." <> '') then begin
                    Resource.Get("Assigned Resource No.");
                    if Resource."Vendor No." <> "Vendor No." then
                        Error('Resource %1 does not belong to Vendor %2.', "Assigned Resource No.", "Vendor No.");
                end
            end;
        }
        field(23; "Resource Group No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Resource Group No.';
            TableRelation = "Resource Group";

            trigger OnValidate()
            var
                Resource: Record Resource;
            begin
                if ("Resource Group No." <> '') and ("Assigned Resource No." <> '') then begin
                    Resource.Get("Assigned Resource No.");
                    if Resource."Resource Group No." <> "Resource Group No." then
                        Error('Resource %1 does not belong to Resource Group %2.', "Assigned Resource No.", "Resource Group No.");
                end;
            end;
        }
        field(24; "Skill"; Code[20])
        {
            Caption = 'Skill';
            TableRelation = "Skill Code";

            trigger OnValidate()
            var
                SkillRes: Record "Resource Skill";
            begin
                if ("Skill" <> '') and ("Assigned Resource No." <> '') then begin
                    if not SkillRes.Get(SkillRes.Type::Resource, "Assigned Resource No.", "Skill") then
                        Error('Resource %1 does not have skill %2.', "Assigned Resource No.", "Skill");
                end;
            end;
        }
        // *****

        field(21; "Assigned Resource No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Assigned Resource No.';
            TableRelation = Resource;

            trigger OnValidate()
            var
                Resource: Record Resource;
            begin
                if ("Assigned Resource No." <> '') then begin
                    Resource.Get("Assigned Resource No.");
                    "Resource Group No." := Resource."Resource Group No.";
                    if Resource."Vendor No." <> '' then
                        "Vendor No." := Resource."Vendor No.";
                    if Resource."Pool Resource No." <> '' then
                        "Assigned Pool Resource No." := Resource."Pool Resource No.";
                    Leader := Resource."Is Foreman";
                    "Team Leader" := Resource."Default Foreman";
                    CalculateWorkingHours();
                end else begin
                    validate("Assigned Hours", 0);
                end;
            end;

            trigger OnLookup()
            var
                Resource: Record Resource;
                //ResLookupRec: Record Resource;
                Item: Record Item;
                GLAccount: Record "G/L Account";
                ResSklill: Record "Resource Skill";
                CapacityUniqueResource: Query "Unique Resource in Capacity";
                ResLookupPage: Page "Opti Resource List";
                TempText: Text;
            begin

                Resource.Reset();
                // Check Existing capacity entries for the resource
                clear(CapacityUniqueResource);
                CapacityUniqueResource.SetRange(EntryDateFilter, "Task Date");
                CapacityUniqueResource.Open();
                while CapacityUniqueResource.Read() do begin
                    if Resource.Get(CapacityUniqueResource.Resource_No_) then
                        Resource.Mark(true);
                end;
                Resource.MarkedOnly(true);  // Get marked resources
                CapacityUniqueResource.Close();
                if "Skill" <> '' then begin
                    if Resource.FindSet() then
                        repeat
                            if not ResSklill.Get(ResSklill.Type::Resource, Resource."No.", Skill) then
                                Resource.Mark(false);
                        until Resource.Next() = 0;
                end;
                Resource.MarkedOnly(true);  // Get marked resources with the skill
                Resource.SetFilter("Date Filter", '%1', "Task Date");
                ResLookupPage.SetTableView(Resource);
                ResLookupPage.LookupMode(true);
                if ResLookupPage.RunModal() = ACTION::LookupOK then begin
                    ResLookupPage.GetRecord(Resource);
                    Validate("Assigned Resource No.", Resource."No.");
                    Description := Resource.Name;
                end;

            end;
        }
        field(22; Description; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Description';
        }
        field(25; "Team Leader"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Resource;
            Caption = 'Team Leader';
        }
        field(26; "Leader"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Leader';
        }
        field(27; "Requested Resource No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Requested Resource No.';
            TableRelation = Resource;

            trigger OnValidate()
            var
                Resource: Record Resource;
            begin
                if "Requested Resource No." <> '' then begin
                    Resource.Get("Requested Resource No.");
                    "Resource Group No." := Resource."Resource Group No.";
                    if "Assigned Resource No." = '' then begin
                        if (Resource."Vendor No." <> '') then
                            "Vendor No." := Resource."Vendor No.";
                        Leader := Resource."Is Foreman";
                        "Team Leader" := Resource."Default Foreman";
                    end;
                    if Resource."Pool Resource No." <> '' then
                        "Requested Pool Resource No." := Resource."Pool Resource No.";
                    CalculateWorkingHours();
                end else
                    Validate("Requested Hours", 0);
            end;

            trigger OnLookup()
            var
                Resource: Record Resource;
                ResSklill: Record "Resource Skill";
                ResLookupPage: Page "Opti Resource List";
                CapacityUniqueResource: Query "Unique Resource in Capacity";
            begin
                Resource.Reset();
                // Check Existing capacity entries for the resource
                clear(CapacityUniqueResource);
                CapacityUniqueResource.SetRange(EntryDateFilter, "Task Date");
                CapacityUniqueResource.Open();
                while CapacityUniqueResource.Read() do begin
                    if Resource.Get(CapacityUniqueResource.Resource_No_) then
                        Resource.Mark(true);
                end;
                Resource.MarkedOnly(true);  // Get marked resources
                CapacityUniqueResource.Close();
                if "Skill" <> '' then begin
                    if Resource.FindSet() then
                        repeat
                            if not ResSklill.Get(ResSklill.Type::Resource, Resource."No.", Skill) then
                                Resource.Mark(false);
                        until Resource.Next() = 0;
                end;
                Resource.MarkedOnly(true);  // Get marked resources with the skill
                Resource.SetFilter("Date Filter", '%1', "Task Date");
                ResLookupPage.SetTableView(Resource);
                ResLookupPage.LookupMode(true);
                if ResLookupPage.RunModal() = ACTION::LookupOK then begin
                    ResLookupPage.GetRecord(Resource);
                    Validate("Requested Resource No.", Resource."No.");
                    Description := Resource.Name;
                end;
            end;
        }
        field(31; "Unit of Measure Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Unit of Measure Code';
        }
        field(41; "Vendor Name"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
            Editable = false;
            Caption = 'Vendor Name';
        }
        field(42; "Pool Resource Name"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Resource.Name where("No." = field("Assigned Pool Resource No.")));
            Editable = false;
            Caption = 'Pool Resource Name';
        }
        field(50; "Work Type Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Work Type";
            Caption = 'Work Type Code';
        }
        field(55; "Work Order No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Work Order No.';
            TableRelation = "Work Order";
        }
        Field(65; "Requested Hours"; Decimal)
        {
            Caption = 'Requested Hours';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }

        field(70; "Worked Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Worked Hours';
            DecimalPlaces = 0 : 2;
        }
        field(80; "Assigned Hours"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Assigned Hours';
            DecimalPlaces = 0 : 2;
            Editable = false;
            BlankZero = true;
        }
        field(81; "Non Working Minutes Assigned"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Non Working Minutes Assigned';
            BlankZero = true;
            trigger OnValidate()
            begin
                CalculateWorkingHours();
            end;

        }
        field(82; "Non Working Minutes Requested"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Non Working Minutes Requested';
            BlankZero = true;
            trigger OnValidate()
            begin
                CalculateWorkingHours();
            end;

        }


        field(85; "Realized Hours"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Realized Hours';
            DecimalPlaces = 0 : 2;
            Editable = false;
            BlankZero = true;
        }
        field(86; "Start Time Realized"; Time)
        {
            DataClassification = ToBeClassified;
            Caption = 'Start Time Realized';

            trigger OnValidate()
            begin
                CalculateWorkingHours();
            end;
        }
        field(87; "End Time Realized"; Time)
        {
            DataClassification = ToBeClassified;
            Caption = 'End Time Realized';

            trigger OnValidate()
            begin
                CalculateWorkingHours();
            end;
        }

        field(90; "Manual Modified"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Do Not Change automatically by process';
            Editable = false;
        }

        // field(100; "Date Filter"; Date)
        // {
        //     Caption = 'Date Filter';
        //     FieldClass = FlowFilter;
        // }

        field(110; Capacity; Decimal)
        {
            CalcFormula = sum("Res. Capacity Entry".Capacity where("Resource No." = field("Assigned Resource No."),
                                                                    Date = field("Task Date")));
            Caption = 'Capacity';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            BlankZero = true;
        }
        field(120; "Capacity Fully Utilized"; Boolean)
        {
            Caption = 'Capacity Fully Utilized';
        }
        Field(132; "Total Assigned Hours"; Decimal)
        {
            Caption = 'Total Assigned Hours';
            CalcFormula = sum("Day Planning"."Assigned Hours" where("Assigned Resource No." = field("Assigned Resource No."),
              "Task Date" = field("Task Date")));
            DecimalPlaces = 0 : 2;
            FieldClass = FlowField;
            Editable = false;
            BlankZero = true;
        }
        Field(133; "Total Requested Hours"; Decimal)
        {
            Caption = 'Total Requested Hours';
            CalcFormula = sum("Day Planning"."Requested Hours" where("Requested Resource No." = field("Requested Resource No."),
              "Task Date" = field("Task Date")));
            DecimalPlaces = 0 : 2;
            FieldClass = FlowField;
            Editable = false;
            BlankZero = true;
        }
        field(140; "Data Owner"; Enum "Data Owner Opt.")
        {
            DataClassification = ToBeClassified;
            Caption = 'Data Owner';
        }
        field(150; "Posted"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Posted';
        }
        field(151; "Job Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Job Entry No.';
        }
        field(152; "Resource Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Resource Entry No.';
        }
        // field(160; "Qty. to Transfer to Invoice"; Decimal)
        // {
        //     DataClassification = CustomerContent;
        //     Caption = 'Qty. to Transfer to Invoice';
        //     DecimalPlaces = 0 : 2;
        //     BlankZero = true;
        // }
        field(161; "Qty. Transferred to Invoice"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Sales Line".Quantity where("Document Type" = const(Invoice),
                                                          "Job No." = field("Job No."),
                                                          "Job Task No." = field("Job Task No."),
                                                          "Day Planning Line No." = field("Day Line No.")));
            Caption = 'Qty. Transferred to Invoice';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(162; "Sales Invoice No."; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = max("Sales Line"."Document No." where("Document Type" = const(Invoice),
                                                          "Job No." = field("Job No."),
                                                          "Job Task No." = field("Job Task No."),
                                                          "Day Planning Line No." = field("Day Line No.")));
            Caption = 'Sales Invoice No.';
            Editable = false;
        }
        field(163; "Qty. Invoiced"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Sales Invoice Line".Quantity where("Job No." = field("Job No."),
                                                          "Job Task No." = field("Job Task No."),
                                                          "Day Planning Line No." = field("Day Line No.")));
            Caption = 'Qty. Invoiced';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(164; "Posted Sales Invoice No."; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = max("Sales Invoice Line"."Document No." where("Job No." = field("Job No."),
                                                          "Job Task No." = field("Job Task No."),
                                                          "Day Planning Line No." = field("Day Line No.")));
            Caption = 'Posted Sales Invoice No.';
            Editable = false;
        }
        field(165; "Posted Sales Invoice Line No."; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = max("Sales Invoice Line"."Line No." where("Job No." = field("Job No."),
                                                          "Job Task No." = field("Job Task No."),
                                                          "Day Planning Line No." = field("Day Line No.")));
            Caption = 'Posted Sales Invoice Line No.';
            Editable = false;
        }
        field(166; "Sales Invoice Line No."; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = max("Sales Line"."Line No." where("Document Type" = const(Invoice),
                                                          "Job No." = field("Job No."),
                                                          "Job Task No." = field("Job Task No."),
                                                          "Day Planning Line No." = field("Day Line No.")));
            Caption = 'Sales Invoice Line No.';
            Editable = false;
        }
        field(169; "Qty. Transferred to Credit"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Sales Line".Quantity where("Document Type" = const("Credit Memo"),
                                                          "Job No." = field("Job No."),
                                                          "Job Task No." = field("Job Task No."),
                                                          "Day Planning Line No." = field("Day Line No.")));
            Caption = 'Qty. Transferred to Credit';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(170; "Sales Credit No."; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = max("Sales Line"."Document No." where("Document Type" = const("Credit Memo"),
                                                          "Job No." = field("Job No."),
                                                          "Job Task No." = field("Job Task No."),
                                                          "Day Planning Line No." = field("Day Line No.")));
            Caption = 'Sales Credit No.';
            Editable = false;
        }
        field(171; "Sales Credit Line No."; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = max("Sales Line"."Line No." where("Document Type" = const("Credit Memo"),
                                                          "Job No." = field("Job No."),
                                                          "Job Task No." = field("Job Task No."),
                                                          "Day Planning Line No." = field("Day Line No.")));
            Caption = 'Sales Credit Line No.';
            Editable = false;
        }
        field(172; "Qty. Credited"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Sales Cr.Memo Line".Quantity where("Job No." = field("Job No."),
                                                          "Job Task No." = field("Job Task No."),
                                                          "Day Planning Line No." = field("Day Line No.")));
            Caption = 'Qty. Credited';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(173; "Posted Sales Credit No."; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = max("Sales Cr.Memo Line"."Document No." where("Job No." = field("Job No."),
                                                          "Job Task No." = field("Job Task No."),
                                                          "Day Planning Line No." = field("Day Line No.")));
            Caption = 'Posted Sales Credit No.';
            Editable = false;
        }
        field(174; "Posted Sales Credit Line No."; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = max("Sales Cr.Memo Line"."Line No." where("Job No." = field("Job No."),
                                                          "Job Task No." = field("Job Task No."),
                                                          "Day Planning Line No." = field("Day Line No.")));
            Caption = 'Posted Sales Credit Line No.';
            Editable = false;
        }
    }
    keys
    {
        //<< OLD:
        // key(PK; "Task Date", "Day Line No.", "Job No.", "Job Task No.")
        // {
        //     Clustered = true;
        // }
        // NEW:
        key(PK; "Job No.", "Job Task No.", "Day Line No.")
        {
            Clustered = true;
        }
        //>>
        key(Rec1; "Job No.", "Job Task No.", "Task Date", "Day Line No.")
        {
        }
        key(DateKey; "Task Date", "Start Time Assigned")
        {
        }
        Key(Key2; "Task Date", "Assigned Resource No.", "Start Time Assigned")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Job No.", "Job Task No.", "Task Date", Description)
        {
        }

    }

    trigger OnInsert()
    var
        DailyOptimizerSetup: record "Daily Optimizer Setup";
    begin
        if Rec.Skill = '' then begin
            DailyOptimizerSetup.Get();
            if DailyOptimizerSetup."Default Skill" <> '' then
                Rec.Skill := DailyOptimizerSetup."Default Skill";
        end;
    end;

    trigger OnDelete()
    begin
        TestField("Assigned Hours", 0);
        TestField("Realized Hours", 0);
    end;

    var
        generalutils: Codeunit "General Planning Utilities";

    procedure CanCreateSalesInvoice(): Boolean
    begin
        CalcFields("Qty. Transferred to Invoice", "Qty. Invoiced", "Qty. Credited");
        if "Realized Hours" <= 0 then
            exit(false);
        if "Qty. Transferred to Invoice" > 0 then
            exit(false);
        if ("Qty. Invoiced" - "Qty. Credited") >= "Realized Hours" then
            exit(false);
        exit(true);
    end;

    procedure CanCreateSalesCreditMemo(): Boolean
    begin
        CalcFields("Qty. Invoiced", "Qty. Credited", "Qty. Transferred to Credit");
        if "Qty. Transferred to Credit" > 0 then
            exit(false);
        if "Qty. Invoiced" <= "Qty. Credited" then
            exit(false);
        exit(true);
    end;

    procedure GetNextDayLineNo();
    var
        DayPlannings: Record "Day Planning";
        DayLineNo: Integer;
    begin
        DayPlannings.SetRange("Job No.", "Job No.");
        DayPlannings.SetRange("Job Task No.", "Job Task No.");
        if DayPlannings.FindLast() then
            DayLineNo := DayPlannings."Day Line No." + 10000
        else
            DayLineNo := 10000;
        Rec."Day Line No." := DayLineNo;
    end;

    procedure CalculateWorkingHours()
    begin
        CalculateAssignedWorkingHours();
        CalculateRequestedWorkingHours();
        CalculateRealizedWorkingHours();
    end;

    local procedure CalculateRealizedWorkingHours()
    var
        PlanningUtil: codeunit "General Planning Utilities";
        WorkingMinutes: Integer;
        RealizedHours: Decimal;
        PartType: Option "Requested","Assigned","Realized";
    begin
        // If either time is not set, clear both hours fields
        if ("Start Time Realized" = 0T) or ("End Time Realized" = 0T) then begin
            "Realized Hours" := 0;
            exit;
        end;

        "Capacity Fully Utilized" := PlanningUtil.DayPlanningFulFillment(Rec, PartType::Realized, RealizedHours, Capacity);
        "Assigned Hours" := RealizedHours;
    end;

    local procedure CalculateAssignedWorkingHours()
    var
        PlanningUtil: codeunit "General Planning Utilities";
        WorkingMinutes: Integer;
        AssignedHours: Decimal;
        PartType: Option "Requested","Assigned","Realized";
    begin
        // If either time is not set, clear both hours fields
        if ("Start Time Assigned" = 0T) or ("End Time Assigned" = 0T) then begin
            "Assigned Hours" := 0;
            "Non Working Minutes Assigned" := 0;
            exit;
        end;

        "Capacity Fully Utilized" := PlanningUtil.DayPlanningFulFillment(Rec, PartType::Assigned, AssignedHours, Capacity);
        "Assigned Hours" := AssignedHours;
    end;

    local procedure CalculateRequestedWorkingHours()
    var
        PlanningUtil: codeunit "General Planning Utilities";
        WorkingMinutes: Integer;
        RequestedHours: Decimal;
        BoolVar: Boolean;
        PartType: Option "Requested","Assigned","Realized";
    begin
        // If either time is not set, clear both hours fields
        if ("Start Time Requested" = 0T) or ("End Time Requested" = 0T) then begin
            "Requested Hours" := 0;
            exit;
        end;

        BoolVar := PlanningUtil.DayPlanningFulFillment(Rec, PartType::Requested, RequestedHours, Capacity);
        "Requested Hours" := RequestedHours;
    end;

    procedure GetNextDayLineNo(TaskDay: date; "Job No.": Code[20]; "Job Task No.": Code[20]): Integer
    var
        DayPlanning: Record "Day Planning";
    begin
        // TaskDay is intentionally unused: DayLineNo must now be unique across
        // all dates for a given (Job No., Job Task No.) per the new PK.
        DayPlanning.SetRange("Job No.", "Job No.");
        DayPlanning.SetRange("Job Task No.", "Job Task No.");
        if DayPlanning.FindLast() then
            exit(DayPlanning."Day Line No." + 10000)
        else
            exit(10000);
    end;


    procedure CheckFirstandLastDay("Job No.": Code[20]; "Job Task No.": Code[20]);
    var
        job: Record Job;
        JobTask: Record "Job Task";
        DayPlanning: Record "Day Planning";
        FirstPlanningDate: Date;
        LastPlanningDate: Date;
    begin
        if "Job Task No." = '' then begin
            job.SetLoadFields("Starting Date", "Ending Date");
            job.get("Job No.");
            FirstPlanningDate := job."Starting Date";
            LastPlanningDate := job."Ending Date";
        end else begin
            JobTask.get("Job No.", "Job Task No.");
            JobTask.SetLoadFields("PlannedStartDate", "PlannedEndDate");
            FirstPlanningDate := JobTask.PlannedStartDate;
            LastPlanningDate := JobTask.PlannedEndDate;
        end;

        // check the first and last planning dates for the given first and last dates
        DayPlanning.SetRange("Job No.", "Job No.");
        DayPlanning.SetRange("Job Task No.", "Job Task No.");
        if DayPlanning.FindFirst() then
            if DayPlanning."Task Date" < FirstPlanningDate then
                error('There are Day Plannings before the planned start date %1.', FirstPlanningDate);
        if DayPlanning.FindLast() then begin
            if DayPlanning."Task Date" > LastPlanningDate then
                Error('There are Day Plannings after the planned end date %1.', LastPlanningDate);
        end;
    end;

    procedure CheckDayPlanningDateInProjectTaskRange()
    var
        JobTask: Record "Job Task";
        ErrLbl: Label 'The Task Date %1 must be within the planned start date %2 and end date %3 of the Job Task.';
    begin
        if "Job Task No." = '' then
            exit; // skip check if Job Task is not specified

        JobTask.get("Job No.", "Job Task No.");
        if ("Task Date" < JobTask.PlannedStartDate) or ("Task Date" > JobTask.PlannedEndDate) then
            Error(ErrLbl, "Task Date", JobTask.PlannedStartDate, JobTask.PlannedEndDate);
    end;

    procedure CopyRequestedToAssigned()
    begin
        Rec."Assigned Resource No." := Rec."Requested Resource No.";
        Rec."Assigned Hours" := Rec."Requested Hours";
        Rec."Start Time Assigned" := Rec."Start Time Requested";
        Rec."Assigned Pool Resource No." := Rec."Requested Pool Resource No.";
        Rec."Non Working Minutes Assigned" := Rec."Non Working Minutes Requested";
        Rec.Validate("End Time Assigned", Rec."End Time Requested");
        Rec.Modify();
    end;

}
