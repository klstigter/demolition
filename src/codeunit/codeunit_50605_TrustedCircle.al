codeunit 50605 "TrustedCircle Integration"
{
    trigger OnRun()
    begin
    end;

    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";

    procedure TestProductUpdate()
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestBody: Text;
        ResponseBody: Text;
        EndpointURL: Text;
        JsonBody: JsonObject;
    begin
        DailyOptimizerSetup.Get();
        DailyOptimizerSetup.TestField("TrustedCircle Bearer Token");
        DailyOptimizerSetup.TestField("TrustedCircle API Base URL");

        EndpointURL := DailyOptimizerSetup."TrustedCircle API Base URL" + '/products/7b71865e-a8ab-4c90-914a-217def6fbb7b';

        JsonBody.Add('price', 145000000);
        JsonBody.Add('stock', 10);
        JsonBody.Add('name', 'Laptop OK - BC');
        JsonBody.Add('description', 'Laptop paling OK Banget - BC');
        JsonBody.WriteTo(RequestBody);

        Content.WriteFrom(RequestBody);
        Content.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');

        Client.DefaultRequestHeaders().Add('Authorization', 'Bearer ' + DailyOptimizerSetup."TrustedCircle Bearer Token");
        Request.SetRequestUri(EndpointURL);
        Request.Method := 'PATCH';
        Request.Content := Content;

        if not Client.Send(Request, Response) then begin
            LogActivity('PATCH', EndpointURL, RequestBody, '', 0, 'Test Product Update');
            Error('HTTP request failed. Check network connectivity or the endpoint URL.');
        end;

        Response.Content.ReadAs(ResponseBody);
        LogActivity('PATCH', EndpointURL, RequestBody, ResponseBody, Response.HttpStatusCode(), 'Test Product Update');

        if Response.IsSuccessStatusCode() then
            Message('Product updated. HTTP %1', Response.HttpStatusCode())
        else
            Error('Update failed. HTTP %1\n%2', Response.HttpStatusCode(), ResponseBody);
    end;

    local procedure LogActivity(Method: Text; EndpointURL: Text; RequestBody: Text; ResponseBody: Text; StatusCode: Integer; Desc: Text)
    var
        LogEntry: Record "TrustedCircle API Log";
        OutStr: OutStream;
    begin
        LogEntry.Init();
        LogEntry."Entry No." := GetNextLogEntryNo();
        LogEntry.Description := CopyStr(Desc, 1, MaxStrLen(LogEntry.Description));
        LogEntry."Endpoint URL" := CopyStr(EndpointURL, 1, MaxStrLen(LogEntry."Endpoint URL"));
        LogEntry."Response Code" := StatusCode;
        LogEntry."Created At" := CurrentDateTime();
        case UpperCase(Method) of
            'GET':
                LogEntry.Method := LogEntry.Method::GET;
            'POST':
                LogEntry.Method := LogEntry.Method::POST;
            'PUT':
                LogEntry.Method := LogEntry.Method::PUT;
            'PATCH':
                LogEntry.Method := LogEntry.Method::PATCH;
            'DELETE':
                LogEntry.Method := LogEntry.Method::DELETE;
            'HEAD':
                LogEntry.Method := LogEntry.Method::HEAD;
            else
                LogEntry.Method := LogEntry.Method::OPTIONS;
        end;

        LogEntry."Request Payload".CreateOutStream(OutStr);
        OutStr.WriteText(RequestBody);

        Clear(OutStr);
        LogEntry."Response Payload".CreateOutStream(OutStr);
        OutStr.WriteText(ResponseBody);

        LogEntry.Insert();
    end;

    local procedure GetNextLogEntryNo(): Integer
    var
        LogEntry: Record "TrustedCircle API Log";
    begin
        if LogEntry.FindLast() then
            exit(LogEntry."Entry No." + 1);
        exit(1);
    end;
}
