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
                field(no; ResourceNo)
                {
                    Caption = 'ResourceNo';
                }
                field(planning_resource_id; Rec."Planning Resource id")
                {
                    Caption = 'planning_resource_id';
                }
                field(planning_vendor_id; PlanningVendorId)
                {
                    Caption = 'planning_vendor_id';
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
        IntegrationSetup: record "Planning Integration Setup";
        Incoming: record "DDSIA Incoming Check";
        RestMgt: Codeunit "DDSIA Rest API Mgt.";

        JsonObj: JsonObject;
        i: Integer;
        JSonText: Text;
        OutS: OutStream;
    begin
        IntegrationSetup.Get();
        if IntegrationSetup."Log Incoming Api Request" then begin
            Clear(JsonObj);
            JsonObj.Add('Job No.', Rec."Job No.");
            JsonObj.Add('Job Task No.', Rec."Job Task No.");
            JsonObj.Add('Line No.', Rec."Line No.");
            JsonObj.Add('Type', format(Rec.Type));
            JsonObj.Add('No.', ResourceNo);
            JsonObj.Add('planning_resource_id', Rec."Planning Resource id");
            JsonObj.Add('planning_vendor_id', PlanningVendorId);
            JsonObj.Add('Description', Rec.Description);
            JsonObj.WriteTo(JSonText);

            Incoming.Init();
            Incoming.GetLastEntryNo();
            Incoming."Date Time" := CreateDateTime(Today, Time);
            Incoming."Blob Data".CreateOutStream(OutS);
            OutS.WriteText(JSonText);
            Incoming.Insert();
            Commit();
        end;

        RestMgt.UpdateJobPlanningLineFromIntegration(Rec, PlanningVendorId, ResourceNo);
    end;

    var
        PlanningVendorId: Integer;
        ResourceNo: Text;
}