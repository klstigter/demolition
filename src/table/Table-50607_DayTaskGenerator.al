table 50607 "Day Task Generator"
{
    DataClassification = ToBeClassified;
    TableType = Temporary;

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
        field(3; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource;
            ValidateTableRelation = false;
        }
        field(4; SkillsRequired; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Skills Required';
            TableRelation = "Skill Code";
        }
        field(10; "Work-Hour Template"; Code[20])
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
                    this.CalculateNonWorkingHours();
                end;
            end;
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
        key(Key1; "Job No.", "Job Task No.", "Resource No.", SkillsRequired)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;

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

    procedure FillBuffer(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        daytask: Record "Day Tasks";
        DoInSert: Boolean;
        Resource: Record Resource;
    begin
        reset;
        DeleteAll();
        daytask.SetRange("Job No.", JobNo);
        daytask.SetRange("Job Task No.", JobTaskNo);
        if daytask.FindSet() then
            repeat
                rec.Init();
                rec."Job No." := JobNo;
                rec."Job Task No." := JobTaskNo;
                rec."Resource No." := daytask."No.";
                rec.SkillsRequired := daytask.Skill;
                if rec.Find('=') then begin
                    if daytask."Task Date" < rec."Start Date" then
                        rec."Start Date" := daytask."Task Date";
                    if daytask."Task Date" > rec."End Date" then
                        rec."End Date" := daytask."Task Date";
                    rec.Modify()
                end else begin
                    rec."Start Date" := daytask."Task Date";
                    rec."End Date" := daytask."Task Date";
                    if Resource.get(daytask."No.") then
                        if Resource."Pool Resource No." <> '' then begin
                            rec."Is Pool" := Resource."Pool Resource No." <> Resource."No.";
                            rec."Pool Resource No." := Resource."Pool Resource No.";
                            rec."Vendor No." := Resource."Vendor No.";
                        end;
                    rec.Insert();
                end;
            until daytask.Next() = 0;
    end;

}