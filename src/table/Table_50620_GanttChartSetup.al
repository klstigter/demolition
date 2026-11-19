table 50620 "Opti Gantt Chart Setup"
{
    Caption = 'Gantt Column Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'User ID';
            TableRelation = User."User Name";
        }

        field(10; "Show Start Date"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Show Start Date';
            InitValue = true;
        }

        field(11; "Show Duration"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Show Duration';
            InitValue = true;
        }

        field(14; "Show Task Type"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Show Task Type';
            InitValue = true;
        }
        field(18; "From Data Formula"; DateFormula)
        {
            DataClassification = CustomerContent;
            Caption = 'From Date Formula';
        }
        field(19; "To Data Formula"; DateFormula)
        {
            DataClassification = CustomerContent;
            Caption = 'To Date Formula';
        }

        field(20; "From Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'From Date';
        }
        field(21; "To Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'To Date';
        }
        field(22; "Date Range Type"; enum "Opti Date Range Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Date Range Type';
            ToolTip = 'Specifies the type of date range to display on the Gantt chart.';
        }
        field(30; "Job No. Filter"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Job No. Filter';
            TableRelation = Job;
            ToolTip = 'Specifies a filter to limit the Gantt chart to a specific job.';
        }

        field(31; "Load Job Tasks"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Load Job Tasks';
            ToolTip = 'Specifies whether to load job tasks for the selected job.';
        }
        field(32; "Load Resources"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Load Resources';
            ToolTip = 'Specifies whether to load resources assigned to job tasks.';
        }
        field(33; "Load Day Plannings"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Load Day Plannings';
            ToolTip = 'Specifies whether to load day plannings for job tasks.';
        }
        field(50; "Download Data for Inspection"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Download Data for Inspection';
            ToolTip = 'Specifies whether to download Gantt chart data for inspection purposes.';
        }
    }

    keys
    {
        key(PK; "User ID")
        {
            Clustered = true;
        }
    }

    procedure EnsureUserRecord()
    begin
        if not Rec.Get(UserId()) then begin
            Rec.Init();
            Rec."User ID" := UserId();
            Rec.Insert();
        end;
    end;

    Procedure GetPeriodLength(anchorD: date): Integer
    var
        d1, d2 : date;
        n: Integer;
    begin
        d1 := CalcDate(rec."From Data Formula", anchorD);
        d2 := CalcDate(rec."To Data Formula", anchorD);
        exit(d2 - d1 + 1);
    end;
}
