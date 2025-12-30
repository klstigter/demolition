table 50620 "Gantt Chart Setup"
{
    Caption = 'Gantt Column Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            TableRelation = User."User Name";
        }

        field(10; "Show Start Date"; Boolean)
        {
            Caption = 'Show Start Date';
            InitValue = true;
        }

        field(11; "Show Duration"; Boolean)
        {
            Caption = 'Show Duration';
            InitValue = true;
        }

        field(12; "Show Constraint Type"; Boolean)
        {
            Caption = 'Show Constraint Type';
            InitValue = true;
        }

        field(13; "Show Constraint Date"; Boolean)
        {
            Caption = 'Show Constraint Date';
            InitValue = true;
        }

        field(14; "Show Task Type"; Boolean)
        {
            Caption = 'Show Task Type';
            InitValue = true;
        }
        field(20; "From Date"; Date)
        {
            Caption = 'From Date';
        }
        field(21; "To Date"; Date)
        {
            Caption = 'To Date';
        }
        field(30; "Job No. Filter"; Code[20])
        {
            Caption = 'Job No. Filter';
            TableRelation = Job;
            ToolTip = 'Specifies a filter to limit the Gantt chart to a specific job.';
        }

        field(31; "Load Job Tasks"; Boolean)
        {
            Caption = 'Load Job Tasks';
            ToolTip = 'Specifies whether to load job tasks for the selected job.';
        }
        field(32; "Load Resources"; Boolean)
        {
            Caption = 'Load Resources';
            ToolTip = 'Specifies whether to load resources assigned to job tasks.';
        }
        field(33; "Load Day Tasks"; Boolean)
        {
            Caption = 'Load Day Tasks';
            ToolTip = 'Specifies whether to load day tasks for job tasks.';
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
}
