/*
Notes:
1. Do not put integration code that updates other systems in a table trigger. 
   An API might update data during a table's OnModify or OnInsert trigger, 
   which can cause the table to send an update to the other system and lead to failures there because of concurrent or recursive updates.
   advice: Place/put integration code on a page that handles updates to external systems from Business Central.
           so if we put integration code in page: When a user updates data in Business Central using a page, Business Central will propagate those changes to the external system. 
           However, when the external system updates Business Central through the API, Business Central must not forward those changes back to the external system to prevent recursive or duplicate transactions.
           (because there is no intergation code in table trigger)
*/

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
                ResponseText := ResponseString; //StrSubstNo('POST to Planning Integration successful. Status: %1, content: %2', Response.HttpStatusCode(), ResponseString);
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

    procedure SelectPlanningProduct(var pProductName: Text): Integer
    var
        ProductBuffer: record "DDSIA Object Selection";
        rtv: Integer;
        ResponseText: Text;

        JsonArray: JsonArray;
        JsonObject: JsonObject;
        JsonToken, ProductIdToken, ProductNameToken : JsonToken;
        ProductId: Integer;
        ProductName: Text;
        i: Integer;
    begin
        rtv := 0;
        pProductName := '';
        GetRequest('/planning/products', ResponseText);
        JsonArray.ReadFrom(ResponseText);
        for i := 0 to JsonArray.Count() - 1 do begin
            JsonArray.Get(i, JsonToken);
            JsonObject := JsonToken.AsObject();
            JsonObject.Get('product_id', ProductIdToken);
            ProductId := ProductIdToken.AsValue().AsInteger();
            JsonObject.Get('product_name', ProductNameToken);
            ProductName := ProductNameToken.AsValue().AsText();

            ProductBuffer.Init();
            ProductBuffer."Object ID" := ProductId;
            ProductBuffer."Object Name" := ProductName;
            ProductBuffer.Insert();
        end;

        // Show as a page for selection
        if Page.RunModal(0, ProductBuffer) = Action::LookupOK then begin
            rtv := ProductBuffer."Object ID"; // Return the selected Vendor ID
            pProductName := ProductBuffer."Object Name";
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

    procedure RefreshPlanningResource(var pPlanningVendorId: record Integer; DownloadJSonRequest: Boolean)
    var
        JsonArray: JsonArray;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        VendorId: Integer;
        VendorName: Text;
        ContactId: Integer;
        ContactName: Text;
        i: Integer;
        ResponseJsonTxt: Text;
        nModified: Integer;
        nNew: Integer;
        MsgLbl: Label 'Sync. Resource with Planning Integration, Modified recs: %1, Inserted recs: %2';
    begin
        GetPlanningResource(pPlanningVendorId, DownloadJSonRequest, ResponseJsonTxt);
        // Parse the JSON string into a JsonArray
        if not JsonArray.ReadFrom(ResponseJsonTxt) then
            Error('Invalid response JSON format.');
        // Iterate through each object in the array
        for i := 0 to JsonArray.Count - 1 do begin
            Clear(VendorId);
            Clear(VendorName);
            Clear(ContactId);
            Clear(ContactName);
            if JsonArray.Get(i, JsonToken) then begin
                JsonObject := JsonToken.AsObject();

                if JsonObject.Get('vendor_id', JsonToken) then
                    VendorId := JsonToken.AsValue().AsInteger();
                if JsonObject.Get('vendor_name', JsonToken) then
                    VendorName := JsonToken.AsValue().AsText();
                if JsonObject.Get('contact_id', JsonToken) then
                    ContactId := JsonToken.AsValue().AsInteger();
                if JsonObject.Get('contact_name', JsonToken) then
                    ContactName := JsonToken.AsValue().AsText();
            end;
            // Now you can use VendorId, VendorName, ContactId, ContactName
            SyncResource(VendorId, VendorName, ContactId, ContactName, nModified, nNew);
        end;
        Message(MsgLbl, nModified, nNew);
    end;

    local procedure SyncResource(VendorId: Integer;
                                 VendorName: Text;
                                 ContactId: Integer;
                                 ContactName: Text;
                                 var nModified: Integer;
                                 var nNew: Integer)
    var
        Res: Record Resource;
        IntegrationSetup: record "Planning Integration Setup";
        GenProd: record "Gen. Product Posting Group";
        ResUoM: Record "Resource Unit of Measure";
    begin
        Res.SetCurrentKey("Planning Resource Id");
        Res.SetRange("Planning Resource Id", ContactId);
        if Res.FindFirst() then begin
            Res.Name := CopyStr(ContactName, 1, MaxStrLen(Res.Name));
            Res."Planning Vendor Id" := VendorId;
            Res.Modify();
            nModified += 1;
        end else begin
            Res.Init();
            Res."No." := '';
            Res.Insert(true);
            Res.Name := CopyStr(ContactName, 1, MaxStrLen(Res.Name));
            Res."Planning Resource Id" := ContactId;
            Res."Planning Vendor Id" := VendorId;
            Res.Modify();
            nNew += 1;
        end;

        IntegrationSetup.Get();
        IntegrationSetup.TestField("Gen. Prod. Posting Group");
        IntegrationSetup.TestField("Default Unit of Measure Code");
        // Check Gen. prod
        if Res."Gen. Prod. Posting Group" = '' then begin
            Res."Gen. Prod. Posting Group" := IntegrationSetup."Gen. Prod. Posting Group";
            Res.Modify();
        end else begin
            if not GenProd.Get(Res."Gen. Prod. Posting Group") then begin
                Res."Gen. Prod. Posting Group" := IntegrationSetup."Gen. Prod. Posting Group";
                Res.Modify();
            end;
        end;
        // Check UoM
        if res."Base Unit of Measure" = '' then begin
            if not ResUoM.Get(Res."No.", IntegrationSetup."Default Unit of Measure Code") then begin
                ResUoM.Init();
                ResUoM."Resource No." := Res."No.";
                ResUoM.Code := IntegrationSetup."Default Unit of Measure Code";
                ResUoM."Qty. per Unit of Measure" := 1;
                ResUoM.Insert();
            end;
            res.validate("Base Unit of Measure", IntegrationSetup."Default Unit of Measure Code");
            res.Modify();
        end;
    end;

    local procedure GetPlanningResource(var pPlanningVendorId: record Integer; DownloadJSonRequest: Boolean; var ResponseText: Text)
    var
        VendorObj, IdObj : JsonObject;
        IdArray: JsonArray;
        JSonStr: Text;

        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        ToFile: Text;
    begin
        /*
        {
            "vendors":[{
                            "id": 7
                        },
                        {
                            "id": 13
                        }
                    ]
        }
        */
        JSonStr := '';
        if pPlanningVendorId.FindSet() then begin
            clear(IdArray);
            repeat
                Clear(IdObj);
                IdObj.Add('id', pPlanningVendorId.Number);
                IdArray.Add(IdObj);
            until pPlanningVendorId.Next() = 0;
            VendorObj.Add('vendors', IdArray);
            VendorObj.WriteTo(JSonStr);
        end;
        if DownloadJSonRequest then begin
            TempBlob.CreateOutStream(OutS);
            OutS.WriteText(JSonStr);
            TempBlob.CreateInStream(InS);
            ToFile := '_JsonRequest.txt';
            DownloadFromStream(InS, '', '', '', ToFile);
        end else begin
            PostRequest('/planning/contacts', JSonStr, ResponseText);
        end;
    end;

    procedure DeleteIntegrationJobPlanningLine(PlanningLine: record "Job Planning Line"; DownloadJSonRequest: Boolean)
    var
        LineObj: JsonObject;
        PlanningLineJsonText: Text;
        ResponseText: text;

        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        ToFile: Text;
    begin
        if PlanningLine."Vendor No." = '' then
            exit;
        clear(LineObj);
        LineObj.Add('bc_jobplanningline_jobno', PlanningLine."Job No.");
        LineObj.Add('bc_jobplanningline_taskno', PlanningLine."Job Task No.");
        LineObj.Add('bc_jobplanningline_lineno', PlanningLine."Line No.");
        LineObj.WriteTo(PlanningLineJsonText);

        if DownloadJSonRequest then begin
            TempBlob.CreateOutStream(OutS);
            OutS.WriteText(PlanningLineJsonText);
            TempBlob.CreateInStream(InS);
            ToFile := '_JsonRequest.txt';
            DownloadFromStream(InS, '', '', '', ToFile);
        end else begin
            PostRequest('/planning/deleteplanningline', PlanningLineJsonText, ResponseText);
        end;
    end;

    procedure PushJobPlanningLineToIntegration(PlanningLine: record "Job Planning Line"; DownloadJSonRequest: Boolean)
    var
        Ven: Record Vendor;
        LineObj: JsonObject;
        PlanningLineJsonText: Text;
        ResponseText: text;

        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        ToFile: Text;
    begin
        clear(LineObj);
        LineObj.Add('bc_jobplanningline_jobno', PlanningLine."Job No.");
        LineObj.Add('bc_jobplanningline_taskno', PlanningLine."Job Task No.");
        LineObj.Add('bc_jobplanningline_lineno', PlanningLine."Line No.");
        LineObj.Add('bc_jobplanningline_type', format(PlanningLine.Type));
        LineObj.Add('bc_jobplanningline_no', PlanningLine."No.");
        LineObj.Add('bc_jobplanningline_resid', GetResIdFromResource(PlanningLine));
        LineObj.Add('bc_jobplanningline_desc', PlanningLine.Description);

        if PlanningLine."Vendor No." <> '' then begin
            Ven.Get(PlanningLine."Vendor No.");
            Ven.TestField("Planning Vendor id");
            LineObj.Add('bc_jobplanningline_vendorid', Ven."Planning Vendor id");
        end else begin
            LineObj.Add('bc_jobplanningline_vendorid', 0);
        end;

        LineObj.Add('bc_jobplanningline_datetimestart',
            (PlanningLine."Planning Date" <> 0D) and (PlanningLine."Start Time" <> 0T)
            ?
            StrSubstNo('%1T%2',
                format(PlanningLine."Planning Date", 0, '<Year4>-<Month,2>-<Day,2>'),
                format(PlanningLine."Start Time", 0, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'))
            :
            '');

        LineObj.Add('bc_jobplanningline_datetimeend',
            (PlanningLine."End Planning Date" <> 0D) And (PlanningLine."End Time" <> 0T)
            ?
            StrSubstNo('%1T%2',
                format(PlanningLine."End Planning Date", 0, '<Year4>-<Month,2>-<Day,2>'),
                format(PlanningLine."End Time", 0, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'))
            :
            '');

        LineObj.WriteTo(PlanningLineJsonText);

        if DownloadJSonRequest then begin
            TempBlob.CreateOutStream(OutS);
            OutS.WriteText(PlanningLineJsonText);
            TempBlob.CreateInStream(InS);
            ToFile := '_JsonRequest.txt';
            DownloadFromStream(InS, '', '', '', ToFile);
        end else begin
            PostRequest('/planning/planninglinefrombc', PlanningLineJsonText, ResponseText);
        end;
    end;

    procedure PushProjectToPlanningIntegration(Job: record Job; DownloadJSonRequest: Boolean)
    var
        PlanningLine: record "Job Planning Line";
        Task: record "Job Task";
        Ven: Record Vendor;
        User: Record User;
        UserSetup: Record "User Setup";
        TempBlob: Codeunit "Temp Blob";

        AddresMgt: Codeunit "Format Address";
        AddrArray: array[8] of Text[100];
        taskAddress: Text;

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

        i: Integer;
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
                if (IntegrationUserId = 0) and (not IsNullGuid(Task.SystemModifiedBy)) then
                    if User.Get(Task.SystemModifiedBy) then begin
                        UserSetup.Get(User."User Name");
                        UserSetup.TestField("Planning User ID");
                        IntegrationUserId := UserSetup."Planning User ID";
                    end;

                Clear(TaskObj);
                task.CalcFields("Start Date");
                TaskObj.Add('bc_task_no', task."Job Task No.");
                TaskObj.Add('bc_task_desc', task.Description);
                TaskObj.Add('planning_user_id', IntegrationUserId);
                TaskObj.Add('bc_task_date', task."Start Date" <> 0D ? format(task."Start Date", 0, '<Year4>-<Month,2>-<Day,2>') : '');

                AddresMgt.FormatAddr(AddrArray
                                     , task.Description
                                     , '' //Name2: Text[100]
                                     , '' //Contact: Text[100]
                                     , task."Sell-to Address"
                                     , task."Sell-to Address 2"
                                     , task."Sell-to City"
                                     , task."Sell-to Post Code"
                                     , task."Sell-to County"
                                     , task."Sell-to Country/Region Code");
                taskAddress := '';
                for i := 1 to 8 do begin
                    if AddrArray[i] <> '' then begin
                        if taskAddress = '' then
                            taskAddress := AddrArray[i]
                        else
                            taskAddress := taskAddress + ', ' + AddrArray[i];
                    end;
                end;
                TaskObj.Add('bc_task_address', taskAddress);

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

                        LineObj.Add('bc_jobplanningline_datetimestart',
                            (PlanningLine."Planning Date" <> 0D) and (PlanningLine."Start Time" <> 0T)
                            ?
                            StrSubstNo('%1T%2',
                                format(PlanningLine."Planning Date", 0, '<Year4>-<Month,2>-<Day,2>'),
                                format(PlanningLine."Start Time", 0, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'))
                            :
                            '');

                        LineObj.Add('bc_jobplanningline_datetimeend',
                            (PlanningLine."End Planning Date" <> 0D) And (PlanningLine."End Time" <> 0T)
                            ?
                            StrSubstNo('%1T%2',
                                format(PlanningLine."End Planning Date", 0, '<Year4>-<Month,2>-<Day,2>'),
                                format(PlanningLine."End Time", 0, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'))
                            :
                            '');

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


    procedure ConvertDTStringIntoDT(pDT: Text): DateTime
    var
        myList: List of [Text];
        _Date: date;
        _Time: Time;
    begin
        if StrPos(pDT, 'T') = 0 then
            exit(0DT);
        myList := pDT.Split('T');
        evaluate(_Date, myList.Get(1));
        evaluate(_Time, myList.Get(2));
        exit(CreateDateTime(_Date, _Time));
    end;

    procedure UpdateJobPlanningLineFromIntegration(pLine: Record "Job Planning Line";
                                                   PlanningVendorId: Integer;
                                                   ResourceNo: text;
                                                   StartDateTime: Text;
                                                   EndDateTime: Text)
    var
        IntegrationSetup: record "Planning Integration Setup";
        PlanningLine: Record "Job Planning Line";
        Resource: record Resource;
        ResUoM: Record "Resource Unit of Measure";
        Vendor: record Vendor;
        DT: DateTime;
        PlanningLineResourceId: Integer;
    begin
        /* Available data:
            Rec."Job No."
            Rec."Job Task No."
            Rec."Line No."
            Rec.Type
            ResourceNo
            Rec."Planning Resource id"
            PlanningVendorId
            StartDateTime
            EndDateTime
            Rec.Description
        */
        // Check pleanning line, if not exist then insert
        if not PlanningLine.Get(pLine."Job No.", pLine."Job Task No.", pLine."Line No.") then begin
            PlanningLine.Init();
            PlanningLine."Job No." := pLine."Job No.";
            PlanningLine."Job Task No." := pLine."Job Task No.";
            PlanningLine."Line No." := pLine."Line No.";

            DT := ConvertDTStringIntoDT(StartDateTime);
            if DT <> 0DT Then begin
                PlanningLine."Planning Date" := DT2Date(DT);
                PlanningLine."Start Time" := DT2Time(DT);
            end;

            DT := ConvertDTStringIntoDT(EndDateTime);
            if DT <> 0DT Then begin
                PlanningLine."End Planning Date" := DT2Date(DT);
                PlanningLine."End Time" := DT2Time(DT);
            end;

            PlanningLine.Insert();
        end;

        PlanningLineResourceId := pLine.GetResourceOrProductIDFromPlanningIntegration();
        if PlanningLineResourceId <> 0 then begin
            Resource.SetRange("Planning Resource Id", PlanningLineResourceId);
            if not Resource.FindFirst() then begin
                IntegrationSetup.Get();
                IntegrationSetup.TestField("Gen. Prod. Posting Group");
                IntegrationSetup.TestField("Default Unit of Measure Code");

                Resource.Init();
                Resource."No." := CopyStr(ResourceNo, 1, MaxStrLen(Resource."No.")).ToUpper();
                Resource.Name := CopyStr(pLine.Description, 1, MaxStrLen(Resource.Name));

                if not ResUoM.Get(Resource."No.", IntegrationSetup."Default Unit of Measure Code") then begin
                    ResUoM.Init();
                    ResUoM."Resource No." := Resource."No.";
                    ResUoM.Code := IntegrationSetup."Default Unit of Measure Code";
                    ResUoM."Qty. per Unit of Measure" := 1;
                    ResUoM.Insert();
                end;

                Resource."Planning Resource Id" := PlanningLineResourceId;
                Resource.Validate("Gen. Prod. Posting Group", IntegrationSetup."Gen. Prod. Posting Group");
                Resource.Validate("Base Unit of Measure", ResUoM.Code);
                Resource.Insert();
            end;
            PlanningLine.Validate(Type, PlanningLine.Type::Resource);
            PlanningLine.Validate("No.", Resource."No.");
            PlanningLine.Description := pLine.Description;

            DT := ConvertDTStringIntoDT(StartDateTime);
            if DT <> 0DT Then begin
                PlanningLine."Planning Date" := DT2Date(DT);
                PlanningLine."Start Time" := DT2Time(DT);
            end;
            DT := ConvertDTStringIntoDT(EndDateTime);
            if DT <> 0DT Then begin
                PlanningLine."End Planning Date" := DT2Date(DT);
                PlanningLine."End Time" := DT2Time(DT);
            end;
            PlanningLine.Modify();
        end else begin
            IntegrationSetup.Get();
            IntegrationSetup.Testfield("Default Vacant Text");
            PlanningLine.Validate(Type, PlanningLine.Type::Text);
            PlanningLine.Validate("No.", IntegrationSetup."Default Vacant Text");

            DT := ConvertDTStringIntoDT(StartDateTime);
            if DT <> 0DT Then begin
                PlanningLine."Planning Date" := DT2Date(DT);
                PlanningLine."Start Time" := DT2Time(DT);
            end;
            DT := ConvertDTStringIntoDT(EndDateTime);
            if DT <> 0DT Then begin
                PlanningLine."End Planning Date" := DT2Date(DT);
                PlanningLine."End Time" := DT2Time(DT);
            end;
            PlanningLine.Modify();
        end;

        if PlanningVendorId <> 0 then begin
            Vendor.SetRange("Planning Vendor id", PlanningVendorId);
            Vendor.FindFirst();
            PlanningLine."Vendor No." := Vendor."No.";
            PlanningLine.Modify();
        end;
    end;

    procedure DT2UTC(pDT: DateTime): DateTime
    var
        Settings: SessionSettings;
        TZ: Codeunit "Time Zone";
        tzId: Text;
        utcDt: DateTime;
    begin
        Settings.Init();
        tzId := Settings.TimeZone;
        utcDt := pDT - TZ.GetTimezoneOffset(pDT, tzId);
        exit(utcDt);
    end;

}