table 50610 "Day Tasks"
{
    DataClassification = ToBeClassified;
    Caption = 'Day Tasks';
    DrillDownPageId = "Day Tasks";
    LookupPageId = "Day Tasks";

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
        field(20; Type; Enum "Job Planning Line Type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Type';
        }

        // **** control Resource No.
        field(39; "Pool Resource No."; Code[20])
        {
            DataClassification = ToBeClassified;
            tablerelation = Resource;

            trigger OnValidate()
            var
                Resource: Record Resource;
            begin
                if ("Pool Resource No." <> '') and (Type = Type::Resource) and ("No." <> '') then begin
                    Resource.Get("No.");
                    if Resource."Pool Resource No." <> "Pool Resource No." then
                        Error('Resource %1 does not belong to Pool Resource %2.', "No.", "Pool Resource No.");
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
                        Validate("Pool Resource No.", Resource."No.");
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
                if ("Vendor No." <> '') and (Type = Type::Resource) and ("No." <> '') then begin
                    Resource.Get("No.");
                    if Resource."Vendor No." <> "Vendor No." then
                        Error('Resource %1 does not belong to Vendor %2.', "No.", "Vendor No.");
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
                if ("Resource Group No." <> '') and (Type = Type::Resource) and ("No." <> '') then begin
                    Resource.Get("No.");
                    if Resource."Resource Group No." <> "Resource Group No." then
                        Error('Resource %1 does not belong to Resource Group %2.', "No.", "Resource Group No.");
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
                if ("Skill" <> '') and (Type = Type::Resource) and ("No." <> '') then begin
                    if not SkillRes.Get(SkillRes.Type::Resource, "No.", "Skill") then
                        Error('Resource %1 does not have skill %2.', "No.", "Skill");
                end;
            end;
        }
        // *****

        field(21; "No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'No.';
            TableRelation = if (Type = const(Resource)) Resource
            else if (Type = const(Item)) Item
            else if (Type = const("G/L Account")) "G/L Account";

            trigger OnValidate()
            var
                Resource: Record Resource;
            begin
                if (Type = Type::Resource) and ("No." <> '') then begin
                    Resource.Get("No.");
                    "Resource Group No." := Resource."Resource Group No.";
                    if Resource."Vendor No." <> '' then
                        "Vendor No." := Resource."Vendor No.";
                    if Resource."Pool Resource No." <> '' then
                        "Pool Resource No." := Resource."Pool Resource No.";

                end;
                if (Type = Type::Resource) and ("No." = '') then begin
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
                if Type = Type::Resource then begin
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
                    Resource.MarkedOnly(true);  // Get marked resources


                    // // set limitation if skill is set in Day Task
                    // if "Skill" <> '' then begin
                    //     ResSklill.SetRange(Type, ResSklill.Type::Resource);
                    //     ResSklill.SetFilter("No.", '<>%1', '');
                    //     ResSklill.SetRange("Skill Code", "Skill");
                    //     if ResSklill.FindSet() then
                    //         repeat
                    //             if Resource.Get(ResSklill."No.") then
                    //                 Resource.Mark(true);
                    //         until ResSklill.Next() = 0;
                    //     Resource.MarkedOnly(true);
                    // end else
                    //     Resource.Reset();
                    // // // Get Resouce from group, vendor, and pool resource
                    // // if "Resource Group No." <> '' then
                    // //     Resource.SetRange("Resource Group No.", "Resource Group No.");
                    // // if "Vendor No." <> '' then
                    // //     Resource.SetRange("Vendor No.", "Vendor No.");
                    // // if "Pool Resource No." <> '' then
                    // //     Resource.SetRange("Pool Resource No.", "Pool Resource No.");
                    // if Resource.FindSet() then
                    //     repeat
                    //         Resource.Mark(true);
                    //         // Check Existing capacity entries for the resource
                    //         clear(CapacityUniqueResource);
                    //         CapacityUniqueResource.SetRange(EntryDateFilter, "Task Date");
                    //         if "Resource Group No." <> '' then
                    //             CapacityUniqueResource.SetRange(Resource_Group_No_, "Resource Group No.");
                    //         CapacityUniqueResource.SetRange(Resource_No_, Resource."No.");
                    //         CapacityUniqueResource.Open();
                    //         if not CapacityUniqueResource.Read() then
                    //             Resource.Mark(false);
                    //         CapacityUniqueResource.Close();
                    //     until Resource.Next() = 0;
                    // Resource.MarkedOnly(true);  // Get marked resources

                    Resource.SetFilter("Date Filter", '%1', "Task Date");
                    ResLookupPage.SetTableView(Resource);
                    ResLookupPage.LookupMode(true);
                    if ResLookupPage.RunModal() = ACTION::LookupOK then begin
                        ResLookupPage.GetRecord(Resource);
                        Validate("No.", Resource."No.");
                        Description := Resource.Name;
                    end;
                end else if Type = Type::Item then begin
                    Item.Reset();
                    if page.RunModal(50601, Item) = ACTION::LookupOK then begin
                        "No." := Item."No.";
                        Description := Item."No.";
                    end;
                end else if Type = Type::"G/L Account" then begin
                    GLAccount.Reset();
                    if page.RunModal(50601, GLAccount) = ACTION::LookupOK then begin
                        "No." := GLAccount."No.";
                        Description := GLAccount."No.";
                    end;
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
            CalcFormula = lookup(Resource.Name where("No." = field("Pool Resource No.")));
            Editable = false;
            Caption = 'Pool Resource Name';
        }
        field(50; "Work Type Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Work Type";
            Caption = 'Work Type Code';
        }
        field(60; Depth; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Depth';
        }
        field(61; IsBoor; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is Boor';
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
        field(81; "Non Working Minutes"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Non Working Minutes';
            BlankZero = true;
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
            CalcFormula = sum("Res. Capacity Entry".Capacity where("Resource No." = field("No."),
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
            CalcFormula = sum("Day Tasks"."Assigned Hours" where("No." = field("No."),
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
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Job No.", "Job Task No.", "Task Date", Description)
        {
        }
    }

    var
        generalutils: Codeunit "General Planning Utilities";

    procedure CalculateWorkingHours()
    begin
        CalculateAssignedWorkingHours();
        CalculateRequestedWorkingHours();
    end;

    local procedure CalculateAssignedWorkingHours()
    var
        PlanningUtil: codeunit "General Planning Utilities";
        WorkingMinutes: Integer;
        AssignedHours: Decimal;
        Capacity: Decimal;
    begin
        // If either time is not set, clear both hours fields
        if ("Start Time Assigned" = 0T) or ("End Time Assigned" = 0T) then begin
            "Assigned Hours" := 0;
            "Non Working Minutes" := 0;
            exit;
        end;

        "Capacity Fully Utilized" := PlanningUtil.DayTaskFulFillment(Rec, AssignedHours, Capacity);
        "Assigned Hours" := AssignedHours;
    end;

    local procedure CalculateRequestedWorkingHours()
    var
        PlanningUtil: codeunit "General Planning Utilities";
        WorkingMinutes: Integer;
        RequestedHours: Decimal;
        Capacity: Decimal;
        BoolVar: Boolean;
    begin
        // If either time is not set, clear both hours fields
        if ("Start Time Requested" = 0T) or ("End Time Requested" = 0T) then begin
            "Requested Hours" := 0;
            exit;
        end;

        BoolVar := PlanningUtil.DayTaskFulFillment(Rec, RequestedHours, Capacity);
        "Requested Hours" := RequestedHours;
    end;

    procedure GetNextDayLineNo(TaskDay: date; "Job No.": Code[20]; "Job Task No.": Code[20]): Integer
    var
        DayTask: Record "Day Tasks";
    begin
        // TaskDay is intentionally unused: DayLineNo must now be unique across
        // all dates for a given (Job No., Job Task No.) per the new PK.
        DayTask.SetRange("Job No.", "Job No.");
        DayTask.SetRange("Job Task No.", "Job Task No.");
        if DayTask.FindLast() then
            exit(DayTask."Day Line No." + 10000)
        else
            exit(10000);
    end;


    procedure CheckFirstandLastDay("Job No.": Code[20]; "Job Task No.": Code[20]);
    var
        job: Record Job;
        JobTask: Record "Job Task";
        DayTask: Record "Day Tasks";
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
        DayTask.SetRange("Job No.", "Job No.");
        DayTask.SetRange("Job Task No.", "Job Task No.");
        if DayTask.FindFirst() then
            if DayTask."Task Date" < FirstPlanningDate then
                error('There are Day Tasks before the planned start date %1.', FirstPlanningDate);
        if DayTask.FindLast() then begin
            if DayTask."Task Date" > LastPlanningDate then
                Error('There are Day Tasks after the planned end date %1.', LastPlanningDate);
        end;
    end;

}
