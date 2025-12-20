page 50606 "Incoming Check"
{
    Caption = 'Incoming Check';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Incoming Check";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Date Time"; Rec."Date Time")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteSelected)
            {
                Caption = 'Delete Selected';
                ApplicationArea = All;
                trigger OnAction()
                var
                    SelectedRecs: Record "Incoming Check";
                    Clbl: Label 'Selected record will be delete';
                begin
                    if not confirm(Clbl) then
                        exit;
                    CurrPage.SetSelectionFilter(SelectedRecs);
                    if SelectedRecs.FindSet() then
                        SelectedRecs.DeleteAll();
                end;
            }
            action(ShowData)
            {
                Caption = 'Show Data';
                ApplicationArea = All;
                trigger OnAction()
                var
                    InS: InStream;
                    FileName: Text;
                    lbl: Label 'The %1 has not a value';
                begin
                    Rec.CalcFields("Blob Data");
                    if not Rec."Blob Data".HasValue then begin
                        Message(lbl, Rec.FieldCaption("Blob Data"));
                        exit;
                    end;
                    Rec."Blob Data".CreateInStream(InS);
                    FileName := '_data.txt';
                    DownloadFromStream(InS, '', '', '', FileName);
                end;
            }
            action(RunUpdateJobPlanningLineFromIntegration)
            {
                Caption = 'Run UpdateJobPlanningLineFromIntegration';
                ApplicationArea = All;
                trigger OnAction()
                var
                    PlannigLine: Record "Job Planning Line";
                    RestApiMgt: Codeunit "DDSIA Rest API Mgt.";

                    JsonObj: JsonObject;
                    Token: JsonToken;
                    Value: JsonValue;

                    InS: InStream;
                    JSonTxt: Text;
                    lbl: Label 'The %1 has not a value';
                    i: Integer;

                    jobNo: Code[20];
                    jobTaskNo: Code[20];
                    PlanninglineNo: Integer;
                    MyType: Text;
                    NoField: Text;
                    PlanningResourceId: Integer;
                    PlanningVendorId: Integer;
                    Description: Text;
                    StartDateTime: Text;
                    EndDateTime: Text;
                begin
                    Rec.CalcFields("Blob Data");
                    if not Rec."Blob Data".HasValue then begin
                        Message(lbl, Rec.FieldCaption("Blob Data"));
                        exit;
                    end;
                    Rec."Blob Data".CreateInStream(InS);
                    InS.ReadText(JSonTxt);
                    if not JsonObj.ReadFrom(JSonTxt) then
                        Error('Invalid JSON');

                    // jobNo (string)
                    if JsonObj.Get('jobNo', Token) then begin
                        Value := Token.AsValue();           // JsonValue
                        if not Value.IsNull() then
                            JobNo := Value.AsCode()
                        else
                            JobNo := '';
                    end else
                        JobNo := '';

                    // jobTaskNo
                    if JsonObj.Get('jobTaskNo', Token) then begin
                        Value := Token.AsValue();
                        if not Value.IsNull() then
                            JobTaskNo := Value.AsCode();
                    end;

                    // lineNo (integer)
                    if JsonObj.Get('lineNo', Token) then begin
                        Value := Token.AsValue();
                        if not Value.IsNull() then
                            PlanninglineNo := Value.AsInteger();
                    end;

                    // Type / No / planning ids / description
                    if JsonObj.Get('Type', Token) then begin
                        Value := Token.AsValue();
                        if not Value.IsNull() then
                            MyType := Value.AsText();
                    end;

                    if JsonObj.Get('No', Token) then begin
                        Value := Token.AsValue();
                        if not Value.IsNull() then
                            NoField := Value.AsText();
                    end;

                    if JsonObj.Get('planning_resource_id', Token) then begin
                        Value := Token.AsValue();
                        if not Value.IsNull() then
                            PlanningResourceId := Value.AsInteger();
                    end;

                    if JsonObj.Get('planning_vendor_id', Token) then begin
                        Value := Token.AsValue();
                        if not Value.IsNull() then
                            PlanningVendorId := Value.AsInteger();
                    end;

                    if JsonObj.Get('Description', Token) then begin
                        Value := Token.AsValue();
                        if not Value.IsNull() then
                            Description := Value.AsText();
                    end;

                    // DateTime fields
                    if JsonObj.Get('startDateTime', Token) then begin
                        Value := Token.AsValue();
                        if not Value.IsNull() then
                            StartDateTime := Value.AsText();
                    end;

                    if JsonObj.Get('endDateTime', Token) then begin
                        Value := Token.AsValue();
                        if not Value.IsNull() then
                            EndDateTime := Value.AsText();
                    end;

                    PlannigLine.Get(JobNo, jobTaskNo, PlanninglineNo);
                    RestApiMgt.UpdateJobPlanningLineFromIntegration(PlannigLine,
                                                                    PlanningVendorId,
                                                                    PlanningResourceId,
                                                                    NoField,
                                                                    StartDateTime,
                                                                    EndDateTime)
                end;
            }
        }
    }
}