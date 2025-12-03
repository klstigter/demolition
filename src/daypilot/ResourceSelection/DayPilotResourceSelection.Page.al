page 50601 "Resource Selection"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Resource Selection';

    layout
    {
        area(Content)
        {
            group(Parameters)
            {
                group(JobTask)
                {
                    field("Job No."; Job."No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Job No.';
                        Editable = false;
                    }
                    field("Job Description"; Job.Description)
                    {
                        ApplicationArea = All;
                        Caption = 'Job Description';
                        Editable = false;
                    }
                    field("Job Task No."; JobTask."Job Task No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Job Task No.';
                        Editable = false;
                    }
                    field("Job task Description"; JobTask.Description)
                    {
                        ApplicationArea = All;
                        Caption = 'Job Task Description';
                        Editable = false;
                    }
                }
                group("New Planning Line")
                {
                    Grid("Date-Time")
                    {
                        GridLayout = Columns;
                        field("Start Date"; JobPlanningLine."Planning Date")
                        {
                            ApplicationArea = All;
                            Caption = 'Start';
                        }
                        field("Start Time"; JobPlanningLine."Start Time")
                        {
                            ApplicationArea = All;
                            ShowCaption = false;
                        }
                        field("End Date"; JobPlanningLine."End Planning Date")
                        {
                            ApplicationArea = All;
                            Caption = 'End';
                        }

                        field("End Time"; JobPlanningLine."End Time")
                        {
                            ApplicationArea = All;
                            ShowCaption = false;
                        }
                    }
                    field(gResourcesJsonTxt; gResourcesDisplay) //gResourcesJsonTxt
                    {
                        ApplicationArea = All;
                        Caption = 'Selected Resources';
                        Editable = false;
                        MultiLine = true;
                    }
                }
            }

            usercontrol(DayPilotResourceSelection; ResourceSelectionAddIn)
            {
                ApplicationArea = All;

                trigger ResControlReady()
                begin
                    CurrPage.DayPilotResourceSelection.ResInit(StartDate,
                                                                Format(JobPlanningLine."Planning Date", 0, '<Year4>-<Month,2>-<Day,2>')
                                                                + 'T'
                                                                + format(JobPlanningLine."Start Time", 0, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'),
                                                                Format(JobPlanningLine."End Planning Date", 0, '<Year4>-<Month,2>-<Day,2>')
                                                                + 'T'
                                                                + format(JobPlanningLine."End Time", 0, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'));
                    CurrPage.DayPilotResourceSelection.ResLoadData(ResourceTxt, EventTxt, StartDate, 14);
                end;

                trigger OnAfterInit()
                begin

                end;

                trigger onRowSelect()
                begin
                    CurrPage.DayPilotResourceSelection.GetSelectedResources();
                end;

                trigger onRowSelected(ResourcesJsonTxt: Text)
                begin
                    gResourcesJsonTxt := ResourcesJsonTxt;
                    GetResourceName();
                    CurrPage.Update();
                end;
            }
        }
    }

    /*
    actions
    {
        area(Processing)
        {
            action(GetSelectedResources)
            {
                ApplicationArea = All;
                Caption = 'Get Selected Resources';
                trigger OnAction()
                begin
                    CurrPage.DayPilotResourceSelection.GetSelectedResources();
                end;
            }
        }
    }
    */

    trigger OnOpenPage()
    var
        ResourceDayPilotHandler: Codeunit "Resource DayPilot Handler";
    begin
        ResourceDayPilotHandler.GetResourceAndEventsFromBCResource(ResourceTxt, EventTxt, StartDate);
    end;

    var
        JobPlanningLine: record "Job Planning Line";
        Job: Record Job;
        JobTask: record "Job Task";
        StartDate: Text;
        ResourceTxt: Text;
        EventTxt: Text;

        gResourcesJsonTxt: Text;
        gResourcesDisplay: Text;

    procedure SetPageVar(JobNo: Code[20]; TaskNo: Code[20]; DT1: Datetime; DT2: Datetime)
    begin
        Job.Get(JobNo);
        JobTask.Get(JobNo, TaskNo);
        JobPlanningLine.Init();
        JobPlanningLine."Job No." := JobNo;
        JobPlanningLine."Job Task No." := TaskNo;
        JobPlanningLine."Planning Date" := DT2Date(DT1);
        JobPlanningLine."End Planning Date" := DT2Date(DT2);
        JobPlanningLine."Start Time" := DT2Time(DT1);
        JobPlanningLine."End Time" := DT2Time(DT2);

        StartDate := Format(DT2DATE(DT1), 0, '<Year4>-<Month,2>-<Day,2>')
                     + 'T'
                     + format(DT2Time(DT1), 0, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>');
    end;

    local procedure GetResourceName()
    var
        InArr: JsonArray;
        Tok, NameTok : JsonToken;
        NamesArr: JsonArray;
        i: Integer;
    begin
        //modal: gResourcesJsonTxt, target: gResourcesDisplay
        gResourcesDisplay := '';
        if not InArr.ReadFrom(gResourcesJsonTxt) then
            exit;
        for i := 0 to InArr.Count() - 1 do begin
            InArr.Get(i, Tok);
            if Tok.IsObject() and Tok.AsObject().Get('name', NameTok) then
                NamesArr.Add(NameTok);
        end;
        NamesArr.WriteTo(gResourcesDisplay);
    end;

    procedure GetSelection(var Events: Text)
    var
        JobPlanningLineHandler: Codeunit "Job Planning Line Handler";
        InArr: JsonArray;
        EventsArr: JsonArray;
        Tok, ResNameTok, ResIdTok : JsonToken;
        EventObj: JsonObject;
        ResNo: Code[20];
        i: Integer;
        _Date: Date;
    begin
        //Booking event
        /* 
        [
            {
            "id":"PR00010|220",
            "text":"<Resource Name>",
            "start":"2025-06-04T03:00:00",
            "end":"2025-06-04T03:00:00.001",
            "resource":"PR00010|220",
            "bubbleHtml":"Book" -> it will be change during daypilot event creation from job planning line
            },
            {
            "id":"PR00010|220",
            "text":"<Resource Name>",
            "start":"2025-06-04T03:00:00",
            "end":"2025-06-04T03:00:00.001",
            "resource":"PR00010|220",
            "bubbleHtml":"Book" -> it will be change during daypilot event creation from job planning line
            }
        ]

        SourceJsonText :=
        '[{"start":"2024-01-22T00:00:00","name":"ARNOUD - Arnoud Wolthuis","value":"ARNOUD","id":"ARNOUD","index":0},' +
        '{"start":"2024-01-22T00:00:00","name":"HESSEL - Hessel Wanders","value":"HESSEL","id":"HESSEL","index":3}]';
        */

        JobPlanningLine.TestField("Planning Date");
        Events := '';
        if not InArr.ReadFrom(gResourcesJsonTxt) then
            exit;
        for i := 0 to InArr.Count() - 1 do begin
            InArr.Get(i, Tok);
            if Tok.IsObject() and Tok.AsObject().Get('name', ResNameTok) then begin
                Tok.AsObject().Get('id', ResIdTok);
                ResNo := ResIdTok.AsValue().AsText();

                Clear(EventObj);
                EventObj.Add('id', JobPlanningLine."Job No." + '|' + JobPlanningLine."Job Task No." + '|' + ResNo); //Line No. is not known, id will define during event creation
                EventObj.Add('text', ResNameTok.AsValue().AsText());
                EventObj.Add('start', JobPlanningLineHandler.GetTaskDateTime(JobPlanningLine."Planning Date", JobPlanningLine."Start Time", false));
                _Date := JobPlanningLine."Planning Date";
                if JobPlanningLine."End Planning Date" <> 0D then
                    _Date := JobPlanningLine."End Planning Date";
                EventObj.Add('end', JobPlanningLineHandler.GetTaskDateTime(_Date, JobPlanningLine."End Time", true));
                EventObj.Add('resource', JobPlanningLine."Job No." + '|' + JobPlanningLine."Job Task No.");
                EventObj.Add('bubbleHtml', 'Book');
                EventsArr.Add(EventObj);
            end;
        end;
        EventsArr.WriteTo(Events);
    end;
}
