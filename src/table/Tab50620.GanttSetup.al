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
