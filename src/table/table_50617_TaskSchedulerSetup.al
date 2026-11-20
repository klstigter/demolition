table 50617 "Task Scheduler Setup"
{
    DataClassification = CustomerContent;
    Caption = 'Task Scheduler Setup';

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = CustomerContent;
            TableRelation = User."User Name";
        }
        field(50; "Timeline Hour Step"; Integer)
        {
            Caption = 'Timeline Hour Step';
            DataClassification = CustomerContent;
        }
        field(60; "Timeline Start Hour"; Integer)
        {
            Caption = 'Timeline Start Hour';
            DataClassification = CustomerContent;
        }
        field(70; "Timeline End Hour"; Integer)
        {
            Caption = 'Timeline End Hour';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "User ID")
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
