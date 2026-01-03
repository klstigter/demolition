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
                StartEndLimitations(false);
            end;
        }
        field(50602; "End Planning Date"; Date)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                StartEndLimitations(false);
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
            MinValue = 0;
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

        field(50690; "Total Worked Hours"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Day Tasks"."Working Hours" where("Job No." = field("Job No."), "Job Task No." = field("Job Task No."), "Job Planning Line No." = field("Line No.")));
            BlankNumbers = BlankZero;
            Editable = false;
        }
        field(50700; "Total Day Taks"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Day Tasks" where("Job No." = field("Job No."), "Job Task No." = field("Job Task No."), "Job Planning Line No." = field("Line No.")));
            BlankNumbers = BlankZero;
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
        job: Record Job;
        genUtil: Codeunit "General Planning Utilities";


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
            if (rec."Start Planning Date" = 0D) or (rec."Start Time" = 0T)
                        or (rec."End Planning Date" = 0D) or (rec."End Time" = 0T) then
                error('Start and End Planning Date and Time must be set to create Day Lines!');

        if ("Start Planning Date" <> 0D) and ("Start Time" <> 0T) then begin
            DT := "Start Planning Date";
            DTstart := CreateDateTime(DT, "Start Time");
        end;
        if ("End Planning Date" <> 0D) and ("End Time" <> 0T) then begin
            DT := "End Planning Date";
            DTend := CreateDateTime(DT, "End Time");
        end;
        if DTstart > DTend then
            if not TryCreateDayLines then
                error('Datetime overlaped!')
            else begin
                exit(true);
            end;
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

    local procedure GetJob()
    begin
        if job."No." <> Rec."Job No." then
            job.Get(Rec."Job No.");
    end;

    procedure StartEndLimitations(TryCreateDayLines: Boolean) hasOverlap: Boolean
    var
    begin
        GetJob();
        IF TryCreateDayLines THEN begin
            IF CheckOverlap(TryCreateDayLines) then begin
                StartEndLimitations(false); //try to fix
                exit(true);
            end;
        end else
            CheckOverlap(false);
        if TryCreateDayLines or (FieldNo("Start Planning Date") = CurrFieldNo) then begin
            if (job."Starting Date" <> 0D) and (Rec."Start Planning Date" < job."Starting Date") then begin
                if TryCreateDayLines then
                    error('Start Planning Date cannot be earlier than Job Starting Date %1', job."Starting Date");
                Rec."Start Planning Date" := job."Starting Date";
                if GuiAllowed then
                    Message('Start Planning Date adjusted to Job Starting Date limit.');
            end;
            if (job."Starting Date" <> 0D) and (job."Ending Date" < Rec."Start Planning Date") then begin
                if TryCreateDayLines then
                    error('Start Planning Date cannot be later than Job Ending Date %1', job."Ending Date");
                Rec."Start Planning Date" := job."Ending Date";
                if GuiAllowed then
                    Message('Start Planning Date adjusted to Job Ending Date limit.');
            end;
        end;
        if TryCreateDayLines or (FieldNo("End Planning Date") = CurrFieldNo) then begin
            if (job."Ending Date" <> 0D) and (Rec."End Planning Date" > job."Ending Date") then begin
                if TryCreateDayLines then
                    error('End Planning Date cannot be later than Job Ending Date %1', job."Ending Date");
                Rec."End Planning Date" := job."Ending Date";
                if GuiAllowed then
                    Message('End Planning Date adjusted to Job Ending Date limit.');
            end;
            if (job."Ending Date" <> 0D) and (job."Starting Date" > Rec."End Planning Date") then begin
                if TryCreateDayLines then
                    error('End Planning Date cannot be earlier than Job Starting Date %1', job."Starting Date");
                Rec."End Planning Date" := job."Starting Date";
                if GuiAllowed then
                    Message('End Planning Date adjusted to Job Starting Date limit.');
            end;
        end;
    end;

    local procedure RemoveDayTasksOutsideLimits()
    var
        DayTask: Record "Day Tasks";
    begin
        DayTask.SetRange("Job No.", Rec."Job No.");
        DayTask.SetRange("Job Task No.", Rec."Job Task No.");
        DayTask.SetRange("Job Planning Line No.", Rec."Line No.");
        DayTask.SetFilter("Day No.", '<%1|>%2', genUtil.DateToInteger(Rec."Start Planning Date"), genUtil.DateToInteger(Rec."End Planning Date"));
        if DayTask.FindSet() then begin
            if Confirm('There are %1 Day Tasks outside the new planning line dates. Do you want to delete them?', false, DayTask.Count) then
                DayTask.DeleteAll();
        end;
    end;

}