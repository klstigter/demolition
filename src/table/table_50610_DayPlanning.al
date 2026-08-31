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
        field(1; "Plan Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Plan Date';

            trigger OnValidate()
            var
                JobTask: Record "Job Task";
                DayPlanningMgt: Codeunit "Day Plannings Mgt.";
            begin
                if ("Job No." = '') or ("Job Task No." = '') then
                    exit;
                if JobTask.Get("Job No.", "Job Task No.") then
                    DayPlanningMgt.EnsureJobTaskCoversDate(JobTask, "Plan Date");
                AssignedCheck();
            end;
        }
        field(7; "Task Date Fixation"; Enum "Task Date Fixation")
        {
            DataClassification = ToBeClassified;
            Caption = 'Task Date Fixation'; //DA1-T62
        }
        field(8; Assigned; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Assigned'; //DA1-T128
        }
        field(9; "Sequence No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Sequence No.';
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
                AssignedCheck();
            end;
        }
        field(12; "End Time Assigned"; Time)
        {
            DataClassification = ToBeClassified;
            Caption = 'End Time Assigned';

            trigger OnValidate()
            begin
                CalculateWorkingHours();
                AssignedCheck();
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
                if "Requested Pool Resource No." <> '' then begin
                    if "Requested Resource No." <> '' then begin
                        Resource.Get("Requested Resource No.");
                        if Resource."Pool Resource No." <> "Requested Pool Resource No." then
                            "Requested Resource No." := "Requested Pool Resource No.";
                    end else begin
                        "Requested Resource No." := "Requested Pool Resource No.";
                    end;
                end else begin
                    validate("Requested Resource No.");
                end;
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
                if "Assigned Pool Resource No." <> '' then begin
                    if "Assigned Resource No." <> '' then begin
                        Resource.Get("Assigned Resource No.");
                        if Resource."Pool Resource No." <> "Assigned Pool Resource No." then
                            "Assigned Resource No." := "Assigned Pool Resource No.";
                    end else begin
                        "Assigned Resource No." := "Assigned Pool Resource No.";
                    end;
                end else begin
                    validate("Assigned Resource No.");
                end;
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
            TableRelation = if ("Assigned Pool Resource No." = const('')) Resource where(Blocked = const(false))
            else
            Resource where(Blocked = const(false), "Pool Resource No." = field("Assigned Pool Resource No."));

            trigger OnValidate()
            var
                Resource: Record Resource;
            begin
                if ("Assigned Resource No." <> '') then begin
                    Resource.Get("Assigned Resource No.");
                    CheckResourceHasSkill("Assigned Resource No.");
                    "Resource Group No." := Resource."Resource Group No.";
                    if Resource."Vendor No." <> '' then
                        "Vendor No." := Resource."Vendor No.";

                    if Resource."Is Pool" or Resource."Is Pool Member" then begin
                        if Resource."Is Pool" then
                            "Assigned Pool Resource No." := Resource."No.";
                        if Resource."Is Pool Member" then
                            "Assigned Pool Resource No." := Resource."Pool Resource No.";
                    end else
                        "Assigned Pool Resource No." := '';

                    "Assigned Leader" := Resource."Is Foreman";
                    "Assigned Team Leader" := Resource."Default Foreman";
                    Skill := GetFirstSkill("Assigned Resource No.");
                    CalculateWorkingHours();
                end else begin
                    validate("Assigned Hours", 0);
                    if "Assigned Pool Resource No." <> '' then
                        "Assigned Resource No." := "Assigned Pool Resource No.";
                end;
                AssignedCheck();
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
                CapacityUniqueResource.SetRange(EntryDateFilter, "Plan Date");
                CapacityUniqueResource.Open();
                while CapacityUniqueResource.Read() do begin
                    if Resource.Get(CapacityUniqueResource.Resource_No_) then begin
                        Resource.Mark(true);
                        if "Assigned Pool Resource No." <> '' then begin
                            if Resource."Pool Resource No." <> "Assigned Pool Resource No." then
                                Resource.Mark(false);
                        end;
                    end;
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
                Resource.SetFilter("Date Filter", '%1', "Plan Date");
                ReslookupPage.SetSkillToFind(Skill, "Assigned Pool Resource No.");
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
        field(20; "Requested Leader"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Requested Leader';

            trigger OnValidate()
            var
                DayPlanning: Record "Day Planning";
                DayPlanning2: Record "Day Planning";
            begin
                if Rec."Requested Leader" then begin
                    Rec.TestField("Requested Resource No.");

                    // on the same record set "Requested Team Leader" = "Requested Resource No."
                    "Requested Team Leader" := Rec."Requested Resource No.";

                    // Check other leader in the same of Task and Work Date
                    // if does not exsit then update all member with same "Requested Team Leader"
                    DayPlanning.Reset();
                    DayPlanning.SetRange("Job No.", Rec."Job No.");
                    DayPlanning.SetRange("Job Task No.", Rec."Job Task No.");
                    DayPlanning.SetRange("Plan Date", Rec."Plan Date");
                    DayPlanning.SetRange("Requested Leader", true);
                    DayPlanning.SetFilter("Day Line No.", '<>%1', Rec."Day Line No.");
                    if DayPlanning.IsEmpty() then begin
                        DayPlanning.SetRange("Requested Leader", false); // get members
                        if DayPlanning.FindSet() then
                            DayPlanning.ModifyAll("Requested Team Leader", Rec."Requested Resource No.");
                    end;
                end else begin
                    // at record-self
                    "Requested Team Leader" := '';

                    // members
                    DayPlanning.Reset();
                    DayPlanning.SetRange("Job No.", Rec."Job No.");
                    DayPlanning.SetRange("Job Task No.", Rec."Job Task No.");
                    DayPlanning.SetRange("Plan Date", Rec."Plan Date");
                    DayPlanning.SetRange("Requested Leader", false);
                    DayPlanning.SetRange("Requested Team Leader", xRec."Requested Team Leader");
                    DayPlanning.SetFilter("Day Line No.", '<>%1', Rec."Day Line No.");
                    if DayPlanning.FindSet() then
                        repeat
                            DayPlanning2 := DayPlanning;
                            DayPlanning2."Requested Team Leader" := '';
                            DayPlanning2.Modify();
                        until DayPlanning.Next() = 0;
                end;
            end;
        }
        field(25; "Requested Team Leader"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Resource;
            Caption = 'Requested Team Leader';

            trigger OnValidate()
            var
                DayPlanning: Record "Day Planning";
                LeaderErr: Label 'As a %1, the %2 must be set as %3';
                LeaderNotFoundErr: label '%1 as %2 does not exist in %3 %4 %5, %6 %7, %8 %9';
            begin
                if "Requested Leader" then begin
                    TestField("Requested Resource No.");
                    if "Requested Team Leader" <> "Requested Resource No." then
                        Error(LeaderErr, Rec.FieldCaption("Requested Leader"), FieldCaption("Requested Team Leader"), "Requested Resource No.");
                end else
                    if "Requested Team Leader" <> '' then begin
                        DayPlanning.Reset();
                        DayPlanning.SetRange("Job No.", Rec."Job No.");
                        DayPlanning.SetRange("Job Task No.", Rec."Job Task No.");
                        DayPlanning.SetRange("Plan Date", Rec."Plan Date");
                        DayPlanning.SetRange("Requested Leader", true);
                        DayPlanning.SetRange("Requested Team Leader", Rec."Requested Team Leader");
                        DayPlanning.SetFilter("Day Line No.", '<>%1', Rec."Day Line No.");
                        if DayPlanning.IsEmpty() then
                            Error(LeaderNotFoundErr, Rec.FieldCaption("Requested Leader"),
                                                    "Requested Team Leader",
                                                    Rec.TableCaption,
                                                    Rec.FieldCaption("Job No."), Rec."Job No.",
                                                    Rec.FieldCaption("Job Task No."), Rec."Job Task No.",
                                                    Rec.FieldCaption("Plan Date"), Rec."Plan Date");
                    end;
            end;

            trigger OnLookup()
            var
                DayPlanning: Record "Day Planning";
                Res: Record Resource;
                NoLeaderLbl: Label 'No leader specified';
            begin
                Res.Reset();
                DayPlanning.Reset();
                DayPlanning.SetRange("Job No.", Rec."Job No.");
                DayPlanning.SetRange("Job Task No.", Rec."Job Task No.");
                DayPlanning.SetRange("Plan Date", Rec."Plan Date");
                DayPlanning.SetRange("Requested Leader", true);
                DayPlanning.Setfilter("Requested Team Leader", '<>%1', '');
                if DayPlanning.FindSet() then begin
                    repeat
                        Res.Get(DayPlanning."Requested Team Leader");
                        Res.Mark(true);
                    until DayPlanning.Next() = 0;
                    Res.MarkedOnly := true;
                    if page.RunModal(0, Res) = Action::LookupOK then begin
                        Validate("Requested Team Leader", Res."No.");
                    end;
                end else
                    Message(NoLeaderLbl);
            end;

        }
        field(26; "Assigned Leader"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Assigned Leader';

            trigger OnValidate()
            var
                DayPlanning: Record "Day Planning";
                DayPlanning2: Record "Day Planning";
            begin
                if Rec."Assigned Leader" then begin
                    Rec.TestField("Assigned Resource No.");

                    // on the same record set "Assigned Team Leader" = "Assigned Resource No."
                    "Assigned Team Leader" := Rec."Assigned Resource No.";

                    // Check other leader in the same of Task and Work Date
                    // if does not exsit then update all member with same "Assigned Team Leader"
                    DayPlanning.SetRange("Job No.", Rec."Job No.");
                    DayPlanning.SetRange("Job Task No.", Rec."Job Task No.");
                    DayPlanning.SetRange("Plan Date", Rec."Plan Date");
                    DayPlanning.SetRange("Assigned Leader", true);
                    DayPlanning.SetFilter("Day Line No.", '<>%1', Rec."Day Line No.");
                    if DayPlanning.IsEmpty() then begin
                        DayPlanning.SetRange("Assigned Leader", false); // get members
                        if DayPlanning.FindSet() then
                            DayPlanning.ModifyAll("Assigned Team Leader", Rec."Assigned Resource No.");
                    end;
                end else begin
                    // at record-self
                    "Assigned Team Leader" := '';

                    // members
                    DayPlanning.Reset();
                    DayPlanning.SetRange("Job No.", Rec."Job No.");
                    DayPlanning.SetRange("Job Task No.", Rec."Job Task No.");
                    DayPlanning.SetRange("Plan Date", Rec."Plan Date");
                    DayPlanning.SetRange("Assigned Leader", false);
                    DayPlanning.SetRange("Assigned Team Leader", xRec."Assigned Team Leader");
                    DayPlanning.SetFilter("Day Line No.", '<>%1', Rec."Day Line No.");
                    if DayPlanning.FindSet() then
                        repeat
                            DayPlanning2 := DayPlanning;
                            DayPlanning2."Assigned Team Leader" := '';
                            DayPlanning2.Modify();
                        until DayPlanning.Next() = 0;
                end;
            end;
        }
        field(28; "Assigned Team Leader"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Resource;
            Caption = 'Assigned Team Leader';

            trigger OnValidate()
            var
                DayPlanning: Record "Day Planning";
                LeaderErr: Label 'As a %1, the %2 must be set as %3';
                LeaderNotFoundErr: label '%1 as %2 does not exist in %3 %4 %5, %6 %7, %8 %9';
            begin
                if "Assigned Leader" then begin
                    TestField("Assigned Resource No.");
                    if "Assigned Team Leader" <> "Assigned Resource No." then
                        Error(LeaderErr, Rec.FieldCaption("Assigned Leader"), FieldCaption("Assigned Team Leader"), "Assigned Resource No.");
                end else
                    if "Assigned Team Leader" <> '' then begin
                        DayPlanning.Reset();
                        DayPlanning.SetRange("Job No.", Rec."Job No.");
                        DayPlanning.SetRange("Job Task No.", Rec."Job Task No.");
                        DayPlanning.SetRange("Plan Date", Rec."Plan Date");
                        DayPlanning.SetRange("Assigned Leader", true);
                        DayPlanning.SetRange("Assigned Team Leader", Rec."Assigned Team Leader");
                        DayPlanning.SetFilter("Day Line No.", '<>%1', Rec."Day Line No.");
                        if DayPlanning.IsEmpty() then
                            Error(LeaderNotFoundErr, Rec.FieldCaption("Assigned Leader"),
                                                    "Assigned Team Leader",
                                                    Rec.TableCaption,
                                                    Rec.FieldCaption("Job No."), Rec."Job No.",
                                                    Rec.FieldCaption("Job Task No."), Rec."Job Task No.",
                                                    Rec.FieldCaption("Plan Date"), Rec."Plan Date");
                    end;
            end;

            trigger OnLookup()
            var
                DayPlanning: Record "Day Planning";
                Res: Record Resource;
                NoLeaderLbl: Label 'No leader specified';
            begin
                Res.Reset();
                DayPlanning.Reset();
                DayPlanning.SetRange("Job No.", Rec."Job No.");
                DayPlanning.SetRange("Job Task No.", Rec."Job Task No.");
                DayPlanning.SetRange("Plan Date", Rec."Plan Date");
                DayPlanning.SetRange("Assigned Leader", true);
                DayPlanning.Setfilter("Assigned Team Leader", '<>%1', '');
                if DayPlanning.FindSet() then begin
                    repeat
                        Res.Get(DayPlanning."Assigned Team Leader");
                        Res.Mark(true);
                    until DayPlanning.Next() = 0;
                    Res.MarkedOnly := true;
                    if page.RunModal(0, Res) = Action::LookupOK then begin
                        Validate("Assigned Team Leader", Res."No.");
                    end;
                end else
                    Message(NoLeaderLbl);
            end;
        }
        field(27; "Requested Resource No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Requested Resource No.';
            TableRelation = if ("Requested Pool Resource No." = const('')) Resource where(Blocked = const(false))
            else
            Resource where(Blocked = const(false), "Pool Resource No." = field("Requested Pool Resource No."));

            trigger OnValidate()
            var
                Resource: Record Resource;
            begin
                if "Requested Resource No." <> '' then begin
                    Resource.Get("Requested Resource No.");
                    CheckResourceHasSkill("Requested Resource No.");
                    "Resource Group No." := Resource."Resource Group No.";
                    if Resource."Vendor No." <> '' then
                        "Vendor No." := Resource."Vendor No.";

                    if Resource."Is Pool" or Resource."Is Pool Member" then begin
                        if Resource."Is Pool" then
                            "Requested Pool Resource No." := Resource."No.";
                        if Resource."Is Pool Member" then
                            "Requested Pool Resource No." := Resource."Pool Resource No.";
                    end else
                        "Requested Pool Resource No." := '';

                    "Requested Leader" := Resource."Is Foreman";
                    "Requested Team Leader" := Resource."Default Foreman";
                    Skill := GetFirstSkill("Requested Resource No.");
                    if "Assigned Resource No." <> '' then
                        Skill := GetFirstSkill("Assigned Resource No.");
                    CalculateWorkingHours();
                end else begin
                    Validate("Requested Hours", 0);
                    if "Requested Pool Resource No." <> '' then
                        "Requested Resource No." := "Requested Pool Resource No.";
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

            trigger onValidate()
            begin
                AssignedCheck();
            end;
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
                                                                    Date = field("Plan Date")));
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
              "Plan Date" = field("Plan Date")));
            DecimalPlaces = 0 : 2;
            FieldClass = FlowField;
            Editable = false;
            BlankZero = true;
        }
        Field(133; "Total Requested Hours"; Decimal)
        {
            Caption = 'Total Requested Hours';
            CalcFormula = sum("Day Planning"."Requested Hours" where("Requested Resource No." = field("Requested Resource No."),
              "Plan Date" = field("Plan Date")));
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
        key(Rec1; "Job No.", "Job Task No.", "Plan Date", "Day Line No.")
        {
        }
        key(DateKey; "Plan Date", "Start Time Assigned")
        {
        }
        Key(Key2; "Plan Date", "Skill", "Assigned Resource No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Job No.", "Job Task No.", "Plan Date", Description)
        {
        }

    }

    trigger OnInsert()
    var
        DailyOptimizerSetup: record "Daily Optimizer Setup";
        DayPlanningSequenceMgt: Codeunit "Day Planning Sequence Mgt.";
    begin
        if Rec.Skill = '' then begin
            DailyOptimizerSetup.Get();
            if DailyOptimizerSetup."Default Skill" <> '' then
                Rec.Skill := DailyOptimizerSetup."Default Skill";
        end;
        if Rec.Skill <> '' then
            DayPlanningSequenceMgt.CalcSequence(Rec);
    end;

    trigger OnModify()
    var
        DayPlanningSequenceMgt: Codeunit "Day Planning Sequence Mgt.";
    begin
        if Rec.Skill <> '' then
            DayPlanningSequenceMgt.CalcSequence(Rec);
    end;

    trigger OnDelete()
    begin
        TestField("Assigned Hours", 0);
        TestField("Realized Hours", 0);
    end;

    var
        generalutils: Codeunit "General Planning Utilities";


    procedure GetNextDayLineNo();
    begin
        Rec.TestField("Job No.");
        Rec.TestField("Job Task No.");
        Rec."Day Line No." := GetNextDayLineNo(Rec."Plan Date", Rec."Job No.", Rec."Job Task No.");
    end;

    procedure AssignedCheck()
    var
        AssignedFlag: Boolean;
    begin
        AssignedFlag := ("Plan Date" <> 0D)
                        and ("Assigned Resource No." <> '')
                        and ("Start Time Assigned" <> 0T)
                        and ("End Time Assigned" <> 0T)
                        and ("Assigned Hours" <> 0);
        Assigned := AssignedFlag;
    end;

    local procedure CheckResourceHasSkill(ResNo: Code[20])
    var
        ResSkill: Record "Resource Skill";
    begin
        ResSkill.SetRange(Type, ResSkill.Type::Resource);
        ResSkill.SetRange("No.", ResNo);
        if ResSkill.IsEmpty() then
            Error('Resource %1 does not have a Skill assigned.', ResNo);
    end;

    local procedure GetFirstSkill(ResNo: Code[20]): Code[20]
    var
        ResSkill: Record "Resource Skill";
    begin
        // Caller must call CheckResourceHasSkill(ResNo) first to guarantee this FindFirst succeeds.
        ResSkill.SetRange(Type, ResSkill.Type::Resource);
        ResSkill.SetRange("No.", ResNo);
        ResSkill.FindFirst();
        exit(ResSkill."Skill Code");
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
        CandidateLineNo: Integer;
    begin
        // TaskDay is intentionally unused: DayLineNo must now be unique across
        // all dates for a given (Job No., Job Task No.) per the new PK.
        DayPlanning.SetRange("Job No.", "Job No.");
        DayPlanning.SetRange("Job Task No.", "Job Task No.");
        if DayPlanning.FindLast() then
            CandidateLineNo := DayPlanning."Day Line No." + 10000
        else
            CandidateLineNo := 10000;

        // Legacy rows from before the PK change can already occupy this number on another date; skip past them.
        while DayPlanning.Get("Job No.", "Job Task No.", CandidateLineNo) do
            CandidateLineNo += 10000;

        exit(CandidateLineNo);
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
            if DayPlanning."Plan Date" < FirstPlanningDate then
                error('There are Day Plannings before the planned start date %1.', FirstPlanningDate);
        if DayPlanning.FindLast() then begin
            if DayPlanning."Plan Date" > LastPlanningDate then
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

        // Planned Start/End Date both set - original hard boundary check, unchanged.
        if (JobTask.PlannedStartDate <> 0D) and (JobTask.PlannedEndDate <> 0D) then begin
            if ("Plan Date" < JobTask.PlannedStartDate) or ("Plan Date" > JobTask.PlannedEndDate) then
                Error(ErrLbl, "Plan Date", JobTask.PlannedStartDate, JobTask.PlannedEndDate);
            exit;
        end;

        // No (complete) Planned dates yet - fall back to the constraint-derived period
        // ("Constraint Calc. - Start/End Date", tableext 50605). This is the task's first real
        // Day Planning commitment: if Plan Date falls inside that period, allow it and
        // materialize Planned Start/End Date to this single day, so the Gantt bar - until now
        // only shown via the wider constraint-derived period - reflects the actual scheduled day
        // on the next refresh.
        if (JobTask."Constraint Calc. - Start Date" <> 0D) and (JobTask."Constraint Calc. - End Date" <> 0D) and
           ("Plan Date" >= JobTask."Constraint Calc. - Start Date") and ("Plan Date" <= JobTask."Constraint Calc. - End Date")
        then begin
            JobTask.PlannedStartDate := "Plan Date";
            JobTask.PlannedEndDate := "Plan Date";
            JobTask.CalculateDuration();
            JobTask.Modify();
            exit;
        end;

        Error(ErrLbl, "Plan Date", JobTask.PlannedStartDate, JobTask.PlannedEndDate);
    end;

    procedure CopyRequestedToAssigned()
    begin
        if Rec."Assigned Resource No." = '' then
            Rec.Validate("Assigned Resource No.", Rec."Requested Resource No.");
        if Rec."Assigned Pool Resource No." = '' then
            Rec."Assigned Pool Resource No." := Rec."Requested Pool Resource No.";

        if rec."Requested Hours" <> 0 then
            if Rec."Assigned Hours" = 0 then
                Rec."Assigned Hours" := Rec."Requested Hours";
        if rec."Non Working Minutes Requested" <> 0 then
            if Rec."Non Working Minutes Assigned" = 0 then
                Rec."Non Working Minutes Assigned" := Rec."Non Working Minutes Requested";
        if rec."Start Time Requested" <> 0T then
            if Rec."Start Time Assigned" = 0T then
                Rec."Start Time Assigned" := Rec."Start Time Requested";
        if rec."End Time Requested" <> 0T then begin
            if Rec."End Time Assigned" = 0T then
                Rec.validate("End Time Assigned", Rec."End Time Requested")
        end else
            Rec.Validate("End Time Assigned");
        if rec."Requested Leader" then
            if not Rec."Assigned Leader" then
                Rec."Assigned Leader" := Rec."Requested Leader";

        if rec."Requested Team Leader" <> '' then
            if Rec."Assigned Team Leader" = '' then
                Rec."Assigned Team Leader" := Rec."Requested Team Leader";

        Rec.Modify();
    end;

}
