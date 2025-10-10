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
        VenBuffer: record "DDSIA Object Selection";
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
            VenBuffer."Object ID" := VendorId;
            VenBuffer."Object Name" := VendorName;
            VenBuffer.Insert();
        end;

        // Show as a page for selection
        if Page.RunModal(0, VenBuffer) = Action::LookupOK then begin
            rtv := VenBuffer."Object ID"; // Return the selected Vendor ID
            pVendorName := VenBuffer."Object Name";
        end;
        exit(rtv);
    end;

    procedure SelectPlanningUser(var pUserName: Text): Integer
    var
        ObjectBuffer: record "DDSIA Object Selection";
        rtv: Integer;
        ResponseText: Text;

        JsonArray: JsonArray;
        JsonObject: JsonObject;
        JsonToken, UserIdToken, UserNameToken : JsonToken;
        UserId: Integer;
        UserName: Text;
        i: Integer;
    begin
        rtv := 0;
        pUserName := '';
        GetRequest('/planning/users', ResponseText);
        JsonArray.ReadFrom(ResponseText);
        for i := 0 to JsonArray.Count() - 1 do begin
            JsonArray.Get(i, JsonToken);
            JsonObject := JsonToken.AsObject();
            JsonObject.Get('user_id', UserIdToken);
            UserId := UserIdToken.AsValue().AsInteger();
            JsonObject.Get('user_name', UserNameToken);
            UserName := UserNameToken.AsValue().AsText();

            ObjectBuffer.Init();
            ObjectBuffer."Object ID" := UserId;
            ObjectBuffer."Object Name" := UserName;
            ObjectBuffer.Insert();
        end;

        // Show as a page for selection
        if Page.RunModal(0, ObjectBuffer) = Action::LookupOK then begin
            rtv := ObjectBuffer."Object ID"; // Return the selected Vendor ID
            pUserName := ObjectBuffer."Object Name";
        end;
        exit(rtv);
    end;

    procedure PushProjectToPlanningIntegration(Job: record Job; DownloadJSonRequest: Boolean)
    var
        PlanningLine: record "Job Planning Line";
        Task: record "Job Task";
        Ven: Record Vendor;
        User: Record User;
        UserSetup: Record "User Setup";
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
        IntegrationUserId: Integer;
    begin
        UserSetup.Get(UserId);

        // Job
        Project_Obj.Add('bc_project_no', Job."No.");
        Project_Obj.Add('bc_project_desc', Job.Description);

        // Task
        Task.SetRange("Job No.", Job."No.");
        if Task.FindSet() then
            repeat
                // Check SystemCreatedBy, so It will link with Planning User in User Setup
                IntegrationUserId := 0;
                if not IsNullGuid(Task.SystemCreatedBy) then
                    if User.Get(Task.SystemCreatedBy) then begin
                        UserSetup.Get(User."User Name");
                        UserSetup.TestField("Planning User ID");
                        IntegrationUserId := UserSetup."Planning User ID";
                    end;

                Clear(TaskObj);
                TaskObj.Add('bc_task_no', task."Job Task No.");
                TaskObj.Add('bc_task_desc', task.Description);
                TaskObj.Add('planning_user_id', IntegrationUserId);

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

    procedure UpdateJobPlanningLineFromIntegration(pLine: Record "Job Planning Line"; PlanningVendorId: Integer; ResourceNo: text)
    var
        IntegrationSetup: record "Planning Integration Setup";
        PlanningLine: Record "Job Planning Line";
        Resource: record Resource;
        ResUoM: Record "Resource Unit of Measure";
        Vendor: record Vendor;
    begin
        /* Available data:
            Rec."Job No."
            Rec."Job Task No."
            Rec."Line No."
            Rec.Type
            ResourceNo
            Rec."Planning Resource id"
            PlanningVendorId
            Rec.Description
        */
        // Check pleanning line, if not exist then insert
        if not PlanningLine.Get(pLine."Job No.", pLine."Job Task No.", pLine."Line No.") then begin
            PlanningLine.Init();
            PlanningLine."Job No." := pLine."Job No.";
            PlanningLine."Job Task No." := pLine."Job Task No.";
            PlanningLine."Line No." := pLine."Line No.";
            PlanningLine.Insert();
        end;

        if pLine."Planning Resource id" <> 0 then begin
            Resource.SetRange("Planning Resource Id", pLine."Planning Resource id");
            if not Resource.FindFirst() then begin
                IntegrationSetup.Get();
                IntegrationSetup.TestField("Gen. Prod. Posting Group");
                IntegrationSetup.TestField("Default Unit of Measure Code");

                Resource.Init();
                Resource."No." := CopyStr(ResourceNo, 1, MaxStrLen(Resource."No.")).ToUpper();

                if not ResUoM.Get(Resource."No.", IntegrationSetup."Default Unit of Measure Code") then begin
                    ResUoM.Init();
                    ResUoM."Resource No." := Resource."No.";
                    ResUoM.Code := IntegrationSetup."Default Unit of Measure Code";
                    ResUoM."Qty. per Unit of Measure" := 1;
                    ResUoM.Insert();
                end;

                Resource."Planning Resource Id" := pLine."Planning Resource id";
                Resource.Validate("Gen. Prod. Posting Group", IntegrationSetup."Gen. Prod. Posting Group");
                Resource.Validate("Base Unit of Measure", ResUoM.Code);
                Resource.Insert();
            end;
            PlanningLine.Validate(Type, PlanningLine.Type::Resource);
            PlanningLine.Validate("No.", Resource."No.");
            PlanningLine.Modify();
        end;

        if PlanningVendorId <> 0 then begin
            Vendor.SetRange("Planning Vendor id", PlanningVendorId);
            Vendor.FindFirst();
            PlanningLine."Vendor No." := Vendor."No.";
            PlanningLine.Modify();
        end;
    end;

}