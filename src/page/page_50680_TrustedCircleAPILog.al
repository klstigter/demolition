page 50680 "TrustedCircle API Log"
{
    Caption = 'TrustedCircle API Log';
    PageType = List;
    SourceTable = "TrustedCircle API Log";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    DeleteAllowed = true;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Method; Rec.Method)
                {
                    ApplicationArea = All;
                }
                field("Endpoint URL"; Rec."Endpoint URL")
                {
                    ApplicationArea = All;
                }
                field("Response Code"; Rec."Response Code")
                {
                    ApplicationArea = All;
                    Style = Unfavorable;
                    StyleExpr = (Rec."Response Code" >= 400) or (Rec."Response Code" = 0);
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ExportRequestPayload)
            {
                Caption = 'Export Request Payload';
                ToolTip = 'Download the raw JSON body that was sent in the request.';
                Image = Export;
                ApplicationArea = All;

                trigger OnAction()
                var
                    InStr: InStream;
                    FileName: Text;
                begin
                    Rec.CalcFields("Request Payload");
                    if not Rec."Request Payload".HasValue() then begin
                        Message('No request payload for this entry.');
                        exit;
                    end;
                    Rec."Request Payload".CreateInStream(InStr);
                    FileName := 'request_' + Format(Rec."Entry No.") + '.json';
                    DownloadFromStream(InStr, 'Export Request Payload', '', 'JSON Files (*.json)|*.json', FileName);
                end;
            }

            action(ExportResponsePayload)
            {
                Caption = 'Export Response Payload';
                ToolTip = 'Download the raw response body returned by the API.';
                Image = ExportFile;
                ApplicationArea = All;

                trigger OnAction()
                var
                    InStr: InStream;
                    FileName: Text;
                begin
                    Rec.CalcFields("Response Payload");
                    if not Rec."Response Payload".HasValue() then begin
                        Message('No response payload for this entry.');
                        exit;
                    end;
                    Rec."Response Payload".CreateInStream(InStr);
                    FileName := 'response_' + Format(Rec."Entry No.") + '.json';
                    DownloadFromStream(InStr, 'Export Response Payload', '', 'JSON Files (*.json)|*.json', FileName);
                end;
            }
        }

        area(Promoted)
        {
            group(Category_Export)
            {
                Caption = 'Export';
                actionref(ExportRequestPayload_ref; ExportRequestPayload) { }
                actionref(ExportResponsePayload_ref; ExportResponsePayload) { }
            }
        }
    }
}
