table 50604 "Request Header"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if "No." <> xRec."No." then begin
                    PlanningSetup.Get();
                    NoSeries.TestManual(PlanningSetup."Request Nos.");
                    "No. Series" := '';
                end;
            end;
        }

        field(10; Description; Text[35])
        {
            DataClassification = ToBeClassified;
            Caption = 'Description';
        }

        field(500; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }


    trigger OnInsert()
    var
        Request: Record "Request Header";
        NoSeriesMgt: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            PlanningSetup.Get();
            PlanningSetup.TestField("Request Nos.");

            "No. Series" := PlanningSetup."Request Nos.";
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series");
            Request.ReadIsolation(IsolationLevel::ReadUncommitted);
            Request.SetLoadFields("No.");
            while Request.Get("No.") do
                "No." := NoSeries.GetNextNo("No. Series");
        end;
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
        PlanningSetup: Record "Planning Integration Setup";
        Req: record "Request Header";
        NoSeries: Codeunit "No. Series";



    procedure AssistEdit(OldRes: Record Resource) Result: Boolean
    begin
        Req := Rec;
        PlanningSetup.Get();
        PlanningSetup.TestField("Request Nos.");
        if NoSeries.LookupRelatedNoSeries(PlanningSetup."Request Nos.", OldRes."No. Series", Req."No. Series") then begin
            Req."No." := NoSeries.GetNextNo(Req."No. Series");
            Rec := Req;
            exit(true);
        end;
    end;

}