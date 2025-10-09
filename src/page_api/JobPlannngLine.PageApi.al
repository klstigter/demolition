page 50605 "DDSIAJobPlanningLine"
{
    PageType = API;
    Caption = 'apiJobPlanningLine';
    APIPublisher = 'ddsia';
    APIGroup = 'planning';
    APIVersion = 'v1.0';
    EntityName = 'jobPlanningLine';
    EntitySetName = 'jobPlanningLines';
    SourceTable = "Job Planning Line";
    DelayedInsert = true;
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(jobNo; Rec."Job No.")
                {
                    Caption = 'Job No.';
                }
                field(jobTaskNo; Rec."Job Task No.")
                {
                    Caption = 'Job Task No.';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                }
                field(no; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Incoming: record "DDSIA Incoming Check";
        JsonObj: JsonObject;
        i: Integer;
        JSonText: Text;
        OutS: OutStream;
    begin
        Clear(JsonObj);

        JsonObj.Add('Job No.', Rec."Job No.");
        JsonObj.Add('Job Task No.', Rec."Job Task No.");
        JsonObj.Add('Line No.', Rec."Line No.");
        JsonObj.Add('Type', format(Rec.Type));
        JsonObj.Add('No.', Rec."No.");
        JsonObj.Add('Description', Rec.Description);

        JsonObj.WriteTo(JSonText);

        Incoming.Init();
        Incoming.GetLastEntryNo();
        Incoming."Date Time" := CreateDateTime(Today, Time);
        Incoming."Blob Data".CreateOutStream(OutS);
        OutS.WriteText(JSonText);
        Incoming.Insert();
    end;
}