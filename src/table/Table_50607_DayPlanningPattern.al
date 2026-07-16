table 50607 "Day Planning Pattern"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            Editable = false;
            NotBlank = true;
            TableRelation = Job;
        }
        field(2; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            NotBlank = true;
            Editable = false;
            TableRelation = "Job Task"."Job Task No." where("job No." = field("job No."));
        }
        field(5; "Line No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Line No.';
        }
        field(3; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                Res: Record Resource;
                ResourceSkill: Record "Resource Skill";
            begin
                if Res.Get("Resource No.") then begin
                    if Res."Work Hour Template" <> '' then
                        Rec.Validate("Work-Hour Template", Res."Work Hour Template");
                    ResourceSkill.SetRange(Type, ResourceSkill.Type::Resource);
                    ResourceSkill.SetRange("No.", "Resource No.");
                    ResourceSkill.SetRange(Prefered, true);
                    ResourceSkill.SetFilter("Skill Code", '<>%1', '');
                    if ResourceSkill.FindFirst() then
                        Rec.SkillsRequired := ResourceSkill."Skill Code";
                end;
            end;
        }
        field(4; SkillsRequired; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Skills Required';
            TableRelation = "Skill Code";
        }
        field(6; "Resource Category"; enum "Resource Category Opt.")
        {
            DataClassification = ToBeClassified;
            Caption = 'Resource Category';
        }
        field(10; "Work-Hour Template"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Work-Hour Template";
            Caption = 'Work-Hour Template';
            trigger OnValidate()
            var
                workHourTemplate: Record "Work-Hour Template";
                DayPlanningMgt: Codeunit "Day Plannings Mgt.";
            begin
                if workHourTemplate.Get(Rec."Work-Hour Template") then begin
                    rec."Start Time" := workHourTemplate."Default Start Time";
                    rec."End Time" := workHourTemplate."Default End Time";
                    rec."Non Working Minutes" := workHourTemplate."Non Working Minutes";
                    this.CalculateNonWorkingHours();
                end;
                Rec."Week Pattern" := DayPlanningMgt.GetActiveWeekdaysText(Rec."Work-Hour Template");
            end;
        }

        field(15; "Work Order No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Work Order No.';
            TableRelation = "Work Order";
        }

        field(20; "Start Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Planned Start Date';
            ToolTip = 'Specifies the start date for the project task. The date is based on the date on the related project planning line.';
            trigger OnValidate()
            begin
            end;
        }
        field(21; "Start Time"; Time)
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                CheckOverlap();
                CalculateNonWorkingHours();
            end;
        }
        field(30; "End Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Planned End Date';
            ToolTip = 'Specifies the end date for the project task. The date is based on the date on the related project planning line.';
            trigger OnValidate()
            begin
            end;
        }

        field(31; "End Time"; Time)
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                CheckOverlap();
                CalculateNonWorkingHours();
            end;
        }
        field(40; "Quantity of Lines"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quantity of Lines';
            MinValue = 0;
        }

        field(57; "Week Pattern"; Code[13])
        {
            DataClassification = ToBeClassified;
            Caption = 'Week Pattern';
            Description = 'full configuration is 1|2|3|4|5|6|7. Derived from "Work-Hour Template"''s weekday hours - see that field''s OnValidate.';
            Editable = false;
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
        field(50640; "Requested Hours"; Decimal)
        {
            Caption = 'Requested Hours';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 2;
            Editable = false;
        }


        Field(50660; "Is Pool"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is Pooled Resource';
        }
        Field(50670; "Pool Resource No."; code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Is Pooled Resource';
        }


    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

    var
        myInt: Integer;

    local procedure CalculateNonWorkingHours()
    var
        TotalMinutes: Integer;
        WorkingMinutes: Integer;
    begin
        // If either time is not set, clear both hours fields
        if ("Start Time" = 0T) or ("End Time" = 0T) then begin
            "Requested Hours" := 0;
            "Non Working Minutes" := 0;
            exit;
        end;

        // Calculate total minutes in a day (24 hours)
        TotalMinutes := 24 * 60;

        // Calculate working minutes
        WorkingMinutes := ("End Time" - "Start Time") div 60000;
        WorkingMinutes := WorkingMinutes - "Non Working Minutes";

        // Convert to hours (decimal)
        "Requested Hours" := WorkingMinutes / 60;

    end;

    local procedure CheckOverlap()
    begin
        CheckOverlap(True);
    end;

    local procedure CheckOverlap(TryCreateDayLines: Boolean) HasOverlap: Boolean
    var
        DT: Date;
        DTstart: DateTime;
        DTend: DateTime;
    begin
        DTstart := 0DT;
        DTend := CreateDateTime(DMY2Date(31, 12, 2999), Time);

        if TryCreateDayLines then
            if (rec."Start Date" = 0D) or (rec."Start Time" = 0T)
                        or (rec."End Date" = 0D) or (rec."End Time" = 0T) then
                error('Start and End Planning Date and Time must be set to create Day Lines!');

        if ("Start Date" <> 0D) and ("Start Time" <> 0T) then begin
            DT := "Start Date";
            DTstart := CreateDateTime(DT, "Start Time");
        end;
        if ("End Date" <> 0D) and ("End Time" <> 0T) then begin
            DT := "End Date";
            DTend := CreateDateTime(DT, "End Time");
        end;
        if DTstart > DTend then
            if not TryCreateDayLines then
                error('Datetime overlaped!')
            else begin
                exit(true);
            end;
    end;

    // procedure FillBuffer(JobNo: Code[20]; JobTaskNo: Code[20])
    // var
    //     DailyOptimizerSetup: Record "Daily Optimizer Setup";
    //     WorkHourTemplate: Record "Work-Hour Template";
    //     DayPlanning: Record "Day Planning";
    //     DoInSert: Boolean;
    //     Resource: Record Resource;
    // begin
    //     DailyOptimizerSetup.Get();
    //     reset;
    //     DeleteAll();
    //     DayPlanning.SetRange("Job No.", JobNo);
    //     DayPlanning.SetRange("Job Task No.", JobTaskNo);
    //     if DayPlanning.FindSet() then
    //         repeat
    //             rec.Init();
    //             rec."Job No." := JobNo;
    //             rec."Job Task No." := JobTaskNo;
    //             rec."Resource No." := DayPlanning."Assigned Resource No.";
    //             rec.SkillsRequired := DayPlanning.Skill;
    //             Rec."Work-Hour Template" := DailyOptimizerSetup."Work hour Template";
    //             if Rec."Work-Hour Template" <> '' then begin
    //                 WorkHourTemplate.Get(Rec."Work-Hour Template");
    //                 Rec."Start Time" := WorkHourTemplate."Default Start Time";
    //                 Rec."End Time" := WorkHourTemplate."Default End Time";
    //                 Rec."Non Working Minutes" := WorkHourTemplate."Non Working Minutes";
    //             end;
    //             Rec."Quantity of Lines" := 1;
    //             if rec.Find('=') then begin
    //                 if DayPlanning."Task Date" < rec."Start Date" then
    //                     rec."Start Date" := DayPlanning."Task Date";
    //                 if DayPlanning."Task Date" > rec."End Date" then
    //                     rec."End Date" := DayPlanning."Task Date";
    //                 rec.Modify()
    //             end else begin
    //                 rec."Start Date" := DayPlanning."Task Date";
    //                 rec."End Date" := DayPlanning."Task Date";
    //                 if Resource.get(DayPlanning."Assigned Resource No.") then
    //                     if Resource."Pool Resource No." <> '' then begin
    //                         rec."Is Pool" := Resource."Pool Resource No." <> Resource."No.";
    //                         rec."Pool Resource No." := Resource."Pool Resource No.";
    //                         rec."Vendor No." := Resource."Vendor No.";
    //                     end;
    //                 rec.Insert();
    //             end;
    //             if (rec."Start Date" <> 0D) and (rec."End Date" <> 0D) then begin
    //                 Rec.Validate("End Time");
    //                 Rec.Modify();
    //             end;
    //         until DayPlanning.Next() = 0;
    // end;

}