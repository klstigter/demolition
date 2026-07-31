table 50633 "Resource Scheduler Setup"
{
    DataClassification = CustomerContent;
    Caption = 'Resource Scheduler Setup';

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = CustomerContent;
            TableRelation = User."User Name";
        }
        field(10; "Vacant Field"; Code[20])
        {
            Caption = 'Vacant Field';
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
