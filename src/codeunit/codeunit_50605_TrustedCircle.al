codeunit 50605 "TrustedCircle Integration"
{
    trigger OnRun()
    begin
    end;

    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";


    /*
    Each outcome now writes a distinct description to the log:

    Scenario	    Description in log
    Network error	Test Connection: Network error. Could not reach the endpoint URL.
    401 / 403	    Test Connection: Authentication failed. HTTP 401 - Bearer Token is invalid or expired.
    404	            Test Connection: Successful. HTTP 404 - Server is reachable, but the base URL has no root route. This is expected.
    2xx / other	    Test Connection: Successful. HTTP 200.

    */
    procedure TestConnection()
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        ResponseBody: Text;
        EndpointURL: Text;
    begin
        DailyOptimizerSetup.Get();
        DailyOptimizerSetup.TestField("TrustedCircle Bearer Token");
        DailyOptimizerSetup.TestField("TrustedCircle API Base URL");

        EndpointURL := DailyOptimizerSetup."TrustedCircle API Base URL";

        Client.DefaultRequestHeaders().Add('Authorization', 'Bearer ' + DailyOptimizerSetup."TrustedCircle Bearer Token");

        if not Client.Get(EndpointURL, Response) then begin
            LogActivity('GET', EndpointURL, '', '', 0, 'Test Connection: Network error. Could not reach the endpoint URL.');
            Error('Connection failed. Check network connectivity or the endpoint URL.');
        end;

        Response.Content.ReadAs(ResponseBody);

        case Response.HttpStatusCode() of
            401, 403:
                begin
                    LogActivity('GET', EndpointURL, '', ResponseBody, Response.HttpStatusCode(),
                        StrSubstNo('Test Connection: Authentication failed. HTTP %1 - Bearer Token is invalid or expired.', Response.HttpStatusCode()));
                    Error('Authentication failed. Check the Bearer Token. HTTP %1', Response.HttpStatusCode());
                end;
            404:
                begin
                    LogActivity('GET', EndpointURL, '', ResponseBody, Response.HttpStatusCode(),
                        'Test Connection: Successful. HTTP 404 - Server is reachable, but the base URL has no root route. This is expected.');
                    Message('Connection successful. HTTP %1', Response.HttpStatusCode());
                end;
            else begin
                LogActivity('GET', EndpointURL, '', ResponseBody, Response.HttpStatusCode(),
                    StrSubstNo('Test Connection: Successful. HTTP %1.', Response.HttpStatusCode()));
                Message('Connection successful. HTTP %1', Response.HttpStatusCode());
            end;
        end;
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
