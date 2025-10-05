codeunit 50602 "DDSIA Rest API Mgt."
{
    trigger OnRun()
    begin

    end;

    var
    //myInt: Integer;

    local procedure GetResponse(pEndpoint: text; var ResponseText: Text)
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

    procedure hello_test()
    var
        ResponseText: Text;
    begin
        GetResponse('/hello', ResponseText);
        Message('Odoo Response: %1', ResponseText);
    end;

}