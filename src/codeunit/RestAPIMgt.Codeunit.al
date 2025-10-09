codeunit 50602 "DDSIA Rest API Mgt."
{
    trigger OnRun()
    begin

    end;

    var
    //myInt: Integer;

    local procedure GetRequest(pEndpoint: text; var ResponseText: Text)
    var
        IntegrationSetup: record "Planning Integration Setup";

        Client: HttpClient;
        RequestHeaders: HttpHeaders;
        Response: HttpResponseMessage;

        Url: Text;
        ApiKey: Text;
        UrlLbl: Label '%1%2';
        ErrLbl: Label 'Failed to connect to Rest API. Status code: %1';
    begin
        IntegrationSetup.Get();
        IntegrationSetup.TestField("Planning API Url");
        IntegrationSetup.TestField("Planning API Key");
        Url := StrSubstNo(UrlLbl, IntegrationSetup."Planning API Url", pEndpoint);
        ApiKey := IntegrationSetup."Planning API Key"; //'479f0c4f36aba1f0f501f8abdcc05ce7b34e1d21'; //Odoo API Key from user name = apiaccess
        // Add API Key to request headers
        RequestHeaders := Client.DefaultRequestHeaders();
        RequestHeaders.Add('Authorization', 'Bearer ' + ApiKey);
        if Client.Get(Url, Response) then begin
            Response.Content.ReadAs(ResponseText);
        end else begin
            Error(ErrLbl, Response.HttpStatusCode());
        end;
    end;

    local procedure PostRequest(pEndpoint: text; pBody: Text; var ResponseText: Text)
    var
        IntegrationSetup: record "Planning Integration Setup";

        HttpClient: HttpClient;
        HttpContent: HttpContent;
        ContentHeaders: HttpHeaders;
        Response: HttpResponseMessage;
        ResponseString: Text;
        OdooUrl: Text;

        Url: Text;
        ApiKey: Text;
        UrlLbl: Label '%1%2';
    begin
        ResponseText := '';

        IntegrationSetup.Get();
        IntegrationSetup.TestField("Planning API Url");
        IntegrationSetup.TestField("Planning API Key");
        Url := StrSubstNo(UrlLbl, IntegrationSetup."Planning API Url", pEndpoint);
        ApiKey := IntegrationSetup."Planning API Key";

        // Create content with the payload and set content type
        HttpContent.WriteFrom(pBody);
        // Get headers from content and set Content-Type
        httpContent.GetHeaders(ContentHeaders);
        ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');

        // Add API Key to the request headers (commonly in 'Authorization' or custom header)
        HttpClient.DefaultRequestHeaders().Add('Authorization', 'Bearer ' + ApiKey);

        // Send POST request
        if HttpClient.Post(Url, HttpContent, Response) then begin
            if Response.IsSuccessStatusCode() then begin
                Response.Content.ReadAs(ResponseString);
                ResponseText := StrSubstNo('POST to Planning Integration successful. Status: %1, content: %2', Response.HttpStatusCode(), ResponseString);
            end else begin
                ResponseText := StrSubstNo('POST failed. Status: %1, Reason: %2', Response.HttpStatusCode(), Response.ReasonPhrase());
            end;
        end else begin
            ResponseText := 'HTTP POST request could not be sent.';
        end;
    end;

    procedure hello_test()
    var
        ResponseText: Text;
    begin
        GetRequest('/hello', ResponseText);
        Message('Odoo Response: %1', ResponseText);
    end;

    procedure SelectPlanningVendor(var pVendorName: Text): Integer
    var
        VenBuffer: record "DDSIA Vendor Selection";
        rtv: Integer;
        ResponseText: Text;

        JsonArray: JsonArray;
        JsonObject: JsonObject;
        JsonToken, VendorIdToken, VendorNameToken : JsonToken;
        VendorId: Integer;
        VendorName: Text;
        i: Integer;
    begin
        rtv := 0;
        pVendorName := '';
        GetRequest('/planning/partners', ResponseText);
        JsonArray.ReadFrom(ResponseText);
        for i := 0 to JsonArray.Count() - 1 do begin
            JsonArray.Get(i, JsonToken);
            JsonObject := JsonToken.AsObject();
            JsonObject.Get('vendor_id', VendorIdToken);
            VendorId := VendorIdToken.AsValue().AsInteger();
            JsonObject.Get('vendor_name', VendorNameToken);
            VendorName := VendorNameToken.AsValue().AsText();

            VenBuffer.Init();
            VenBuffer."Vendor ID" := VendorId;
            VenBuffer."Vendor Name" := VendorName;
            VenBuffer.Insert();
        end;

        // Show as a page for selection
        if Page.RunModal(0, VenBuffer) = Action::LookupOK then begin
            rtv := VenBuffer."Vendor ID"; // Return the selected Vendor ID
            pVendorName := VenBuffer."Vendor Name";
        end;
        exit(rtv);
    end;

    procedure PushProjectToPlanningIntegration(Job: record Job; DownloadJSonRequest: Boolean)
    var
        PlanningLine: record "Job Planning Line";
        Task: record "Job Task";
        Ven: Record Vendor;
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        ToFile: Text;

        Project_Obj: JsonObject;

        TaskArray: JsonArray;
        TaskObj: JsonObject;

        LineArray: JsonArray;
        LineObj: JsonObject;

        ProjectJsonText: Text;
        ResponseText: Text;

        IntegrationPartnerId: Integer;
    begin
        // Job
        Project_Obj.Add('bc_project_no', Job."No.");
        Project_Obj.Add('bc_project_desc', Job.Description);

        // Task
        Task.SetRange("Job No.", Job."No.");
        if Task.FindSet() then
            repeat
                Clear(TaskObj);
                TaskObj.Add('bc_task_no', task."Job Task No.");
                TaskObj.Add('bc_task_desc', task.Description);

                // Planning Lines
                Clear(LineArray);
                PlanningLine.SetRange("Job No.", Task."Job No.");
                PlanningLine.SetRange("Job Task No.", Task."Job Task No.");
                PlanningLine.SetFilter(Type, '%1|%2', PlanningLine.Type::Resource, PlanningLine.Type::Text);
                PlanningLine.SetFilter("No.", '<>%1', '');
                if PlanningLine.FindSet() then
                    repeat
                        clear(LineObj);
                        LineObj.Add('bc_jobplanningline_lineno', PlanningLine."Line No.");
                        LineObj.Add('bc_jobplanningline_type', format(PlanningLine.Type));
                        LineObj.Add('bc_jobplanningline_no', PlanningLine."No.");
                        LineObj.Add('bc_jobplanningline_resid', GetResIdFromResource(PlanningLine));
                        LineObj.Add('bc_jobplanningline_desc', PlanningLine.Description);

                        if PlanningLine."Vendor No." <> '' then begin
                            Ven.Get(PlanningLine."Vendor No.");
                            Ven.TestField("Planning Vendor id");
                            IntegrationPartnerId := Ven."Planning Vendor id";
                            LineObj.Add('bc_jobplanningline_vendorid', IntegrationPartnerId);
                        end else begin
                            LineObj.Add('bc_jobplanningline_vendorid', 0);
                        end;

                        LineObj.Add('bc_jobplanningline_datestart',
                            PlanningLine."Planning Date" <> 0D ? format(PlanningLine."Planning Date", 0, '<Year4><Month,2><Day,2>') : '');
                        LineObj.Add('bc_jobplanningline_timestart',
                            PlanningLine."Start Time" <> 0T ? format(PlanningLine."Start Time", 0, '<Hours24,2><Filler Character,0>:<Minutes,2>') : '');
                        LineObj.Add('bc_jobplanningline_dateend',
                            PlanningLine."End Planning Date" <> 0D ? format(PlanningLine."End Planning Date", 0, '<Year4><Month,2><Day,2>') : '');
                        LineObj.Add('bc_jobplanningline_timeend',
                            PlanningLine."End Time" <> 0T ? format(PlanningLine."End Time", 0, '<Hours24,2><Filler Character,0>:<Minutes,2>') : '');

                        LineArray.Add(LineObj);
                    until PlanningLine.Next() = 0;
                TaskObj.Add('bc_planninglines', LineArray);
                TaskArray.Add(TaskObj);
            until Task.Next() = 0;

        Project_Obj.Add('tasks', TaskArray);
        Project_Obj.WriteTo(ProjectJsonText);

        if DownloadJSonRequest then begin
            TempBlob.CreateOutStream(OutS);
            OutS.WriteText(ProjectJsonText);
            TempBlob.CreateInStream(InS);
            ToFile := '_JsonRequest.txt';
            DownloadFromStream(InS, '', '', '', ToFile);
        end else begin
            PostRequest('/planning/projectcreationfrombc', ProjectJsonText, ResponseText);
            Message(ResponseText);
        end;
    end;

    local procedure GetResIdFromResource(PlanningLine: record "Job Planning Line"): Integer
    var
        rtv: Integer;
        Resource: record Resource;
    begin
        rtv := 0;
        if (PlanningLine."Vendor No." <> '') and (PlanningLine.Type = PlanningLine.Type::Resource) and (PlanningLine."No." <> '') then begin
            Resource.Get(PlanningLine."No.");
            Resource.TestField("Planning Resource Id");
            rtv := Resource."Planning Resource Id";
        end;
        exit(rtv);
    end;

}