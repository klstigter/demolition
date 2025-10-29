page 50611 "DDSIAJobPlanningLineBor"
{
    PageType = API;
    Caption = 'apiJobPlanningLine';
    APIPublisher = 'ddsia';
    APIGroup = 'planning';
    APIVersion = 'v1.0';
    EntityName = 'jobPlanningLinebor';
    EntitySetName = 'jobPlanningLinebors';
    SourceTable = "Job Planning Line";
    DelayedInsert = true;
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(jobNo; Rec."Job No.") { }
                field(jobTaskNo; Rec."Job Task No.") { }
                field(lineNo; Rec."Line No.") { }
                field(type; Rec.Type) { }
                field(no; ProductNo) { }
                field(planning_product_id; PlanningProductId) { }
                field(planning_vendor_id; PlanningVendorId) { }
                field(description; Rec.Description) { }
                field(startDateTime; StartDateTime) { }
                field(endDateTime; EndDateTime) { }
                field(qty; PlanningQtyTxt) { }
                field(depth; PlanningDepthTxt) { }
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
        PlanningQty: Decimal;
        PlanningDepth: Decimal;
    begin
        IntegrationSetup.Get();
        if IntegrationSetup."Log Incoming Api Request" then begin
            Clear(JsonObj);
            JsonObj.Add('jobNo', Rec."Job No.");
            JsonObj.Add('jobTaskNo', Rec."Job Task No.");
            JsonObj.Add('lineNo', Rec."Line No.");
            JsonObj.Add('Type', format(Rec.Type));
            JsonObj.Add('No', ProductNo);
            JsonObj.Add('planning_product_id', PlanningProductId);
            JsonObj.Add('planning_vendor_id', PlanningVendorId);
            JsonObj.Add('Description', Rec.Description);
            JsonObj.Add('startDateTime', StartDateTime);
            JsonObj.Add('endDateTime', EndDateTime);
            JsonObj.Add('qty', PlanningQtyTxt);
            JsonObj.Add('depth', PlanningDepthTxt);
            JsonObj.WriteTo(JSonText);

            Incoming.Init();
            Incoming.GetLastEntryNo();
            Incoming."Date Time" := CreateDateTime(Today, Time);
            Incoming."Blob Data".CreateOutStream(OutS);
            OutS.WriteText(JSonText);
            Incoming.Insert();
            Commit();
        end;

        if PlanningQtyTxt <> '' then
            Evaluate(PlanningQty, PlanningQtyTxt);
        if PlanningDepthTxt <> '' then
            Evaluate(PlanningDepth, PlanningDepthTxt);
        RestMgt.UpdateJobPlanningLineFromIntegrationbor(Rec, PlanningProductId, ProductNo, PlanningVendorId, StartDateTime, EndDateTime, PlanningQty, PlanningDepth);
    end;

    var
        PlanningVendorId: Integer;
        PlanningProductId: Integer;
        ProductNo: Text;
        StartDateTime: Text;
        EndDateTime: Text;
        PlanningQtyTxt: Text;
        PlanningDepthTxt: Text;
}