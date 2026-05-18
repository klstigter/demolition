page 50626 "Summary View"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Summary Weekly";
    SourceTableTemporary = true;
    ShowFilter = false;


    layout
    {
        area(Content)
        {
            group(SummaryViews)
            {
                Caption = 'Summary View';
                field(ShowResource; ShowResource)
                {
                    ToolTip = 'Set the Resource No. field visble or not. Visible by default.';
                    trigger OnValidate()
                    begin
                        ResourceNoFilter := '';
                        GroupByDataSet();
                    end;
                }
                field(ShowSkillCode; ShowSkillCode)
                {
                    ToolTip = 'Set the Skill Code field visible or not. Visible by default.';
                    trigger OnValidate()
                    begin
                        SkillCodeFilter := '';
                        GroupByDataSet();
                    end;
                }
                field(ShowJob; ShowJob)
                {
                    ToolTip = 'Set the Job field visible or not. Visible by default.';
                    trigger OnValidate()
                    begin
                        JobNoFilter := '';
                        if not ShowJob then begin
                            ShowJobTask := False;
                            JobTaskNoFilter := '';
                        end;
                        GroupByDataSet();
                    end;
                }
                field(ShowJobTask; ShowJobTask)
                {
                    ToolTip = 'Set the Job Task field visible or not. Visible by default.';
                    trigger OnValidate()
                    begin
                        JobTaskNoFilter := '';
                        if ShowJobTask then
                            ShowJob := true;
                        GroupByDataSet();
                    end;
                }
                field(ShowYear; ShowYear)
                {
                    ToolTip = 'Set the Year field visible or not. Visible by default.';
                    trigger OnValidate()
                    begin
                        if not ShowYear then begin
                            ShowWeekNo := false;
                            WeekFilter := '';
                        end;
                        GroupByDataSet();
                    end;
                }
                field(ShowWeekNo; ShowWeekNo)
                {
                    ToolTip = 'Set the Week No. field visible or not. Visible by default.';
                    trigger OnValidate()
                    begin
                        if ShowWeekNo then begin
                            ShowYear := true;
                            WeekFilter := '';
                        end else
                            if WeekFilter <> '' then begin
                                WeekFilter := CopyStr(WeekFilter, 1, 4);
                                rec.setfilter("Year", WeekFilter);
                            end;
                        GroupByDataSet();
                    end;
                }
            }

            group(FilterSettings)
            {

                Caption = 'Filters';
                group(job)
                {
                    ShowCaption = false;
                    Visible = ShowJob;

                    field("JobNoFilter"; JobNoFilter)
                    {
                        ToolTip = 'Specifies the job number for the new day task.';
                        trigger OnValidate()
                        begin
                            if JobNoFilter <> '' then
                                rec.setfilter("Job No.", JobNoFilter)
                            else
                                rec.SetRange("Job No.");
                            CurrPage.Update();
                        end;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            Job: Record Job temporary;
                            Pg: Page "Opti Lookup Job List";
                        begin
                            rec.HandOverToPage(Pg);
                            pg.LookupMode(true);
                            if Pg.RunModal() = action::LookupOK then begin
                                pg.GetRecord(Job);
                                Text := Job."No.";
                                exit(true);
                            end;
                        end;
                    }
                }
                group(JobTask)
                {
                    ShowCaption = false;
                    Visible = ShowJobTask;
                    field("JobTaskNoFilter"; JobTaskNoFilter)
                    {
                        ToolTip = 'Specifies the job task number for the new day task.';
                        trigger OnValidate()
                        begin
                            if JobTaskNoFilter <> '' then
                                rec.setfilter("Job Task No.", JobTaskNoFilter)
                            else
                                rec.SetRange("Job Task No.");
                            CurrPage.Update();
                        end;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            JobTask: Record "Job Task" temporary;
                            Pg: Page "Opti Job Task List TEMP";
                        begin
                            rec.HandOverToPage(Pg);
                            if JobNoFilter <> '' then
                                JobTask.SetRange("Job No.", JobNoFilter);
                            pg.LookupMode(true);
                            pg.SetTableView(JobTask);
                            if Pg.RunModal() = Action::LookupOK then begin
                                pg.GetRecord(JobTask);
                                Text := JobTask."Job Task No.";
                                if JobNoFilter = '' then
                                    JobNoFilter := JobTask."Job No.";
                                exit(true);
                            end;
                        end;
                    }
                }
                group(Resource)
                {
                    ShowCaption = false;
                    Visible = ShowResource;
                    field(RescoureNoFilter; ResourceNoFilter)
                    {
                        ToolTip = 'Specifies the resource number for the new day task.';
                        trigger OnValidate()
                        begin
                            if ResourceNoFilter <> '' then
                                rec.setfilter("Resource No.", ResourceNoFilter)
                            else
                                rec.SetRange("Resource No.");
                            CurrPage.Update();
                        end;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            Resource: Record "Resource" temporary;
                            Pg: Page "Opti Resource List Temp";
                        begin
                            rec.HandOverToPage(Pg);

                            if Pg.RunModal() = Action::LookupOK then begin
                                pg.GetRecord(Resource);
                                Text := Resource."No.";
                                exit(true);
                            end;
                        end;
                    }
                }
                group(Skill)
                {
                    ShowCaption = false;
                    Visible = ShowSkillCode;
                    field(SkillCodeFilter; SkillCodeFilter)
                    {
                        ToolTip = 'Specifies the skill code for the new day task.';
                        trigger OnValidate()
                        begin
                            if SkillCodeFilter <> '' then
                                rec.setfilter("Skill Code", SkillCodeFilter)
                            else
                                rec.SetRange("Skill Code");
                            CurrPage.Update();
                        end;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            Skill: Record "Skill Code" temporary;
                            pg: Page "Opti Skill Codes";
                        begin
                            rec.HandOverToPage(pg);
                            if SkillCodeFilter <> '' then begin
                                Skill.get(SkillCodeFilter);
                            end;
                            if Pg.RunModal() = Action::LookupOK then begin
                                Pg.GetRecord(Skill);
                                Text := Skill.Code;
                                exit(true);
                            end;
                        end;
                    }
                }
                group(week)
                {
                    ShowCaption = false;
                    Visible = ShowYear;
                    field(WeekFilter; WeekFilter)
                    {
                        Caption = 'Year/Week Filter';
                        ToolTip = 'Specifies the year and week number, or only the year for filtering. Format should be YYYY-WW or YYYY.';
                        trigger OnValidate()
                        begin
                            if ValidateYrWkFilterFormat(WeekFilter) then begin
                                rec.setfilter("Year", CopyStr(WeekFilter, 1, 4));
                                if ShowWeekNo then
                                    rec.setfilter("Week No.", CopyStr(WeekFilter, 6, 2));
                            end else begin
                                rec.SetRange("Year");
                                rec.SetRange("Week No.");
                            end;
                            CurrPage.Update();
                        end;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            YearWeek: Record "Integer" temporary;
                            SumWk: Record "Summary Weekly";
                            Pg: Page "Week View";
                            Year: Integer;
                            Week: Integer;
                        begin
                            pg.SetShowWeek(ShowWeekNo);
                            pg.LookupMode(true);
                            rec.HandOverToPage(Pg);
                            if Pg.RunModal() = Action::LookupOK then begin
                                Pg.GetRecord(YearWeek);
                                if ShowWeekNo then begin
                                    SumWk.ExtractYearAndWeek(YearWeek.Number, Year, Week);
                                    Text := Format(Year) + '-' + Format("Week");
                                end else
                                    Text := Format(YearWeek.Number);
                                exit(true);
                            end;
                        end;
                    }
                }
            }
            repeater(Summary)
            {

                field("Job No."; Rec."Job No.")
                {
                    ToolTip = 'Specifies the value of the Job No. field.', Comment = '%';
                    Visible = ShowJob;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ToolTip = 'Specifies the value of the Job Task No. field.', Comment = '%';
                    Visible = ShowJobTask;
                }
                field(Purpose; Rec.Purpose)
                {
                    ToolTip = 'Specifies the value of the Purpose field.', Comment = '%';
                    Visible = False;
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ToolTip = 'Specifies the resource number.';
                    Visible = ShowResource;
                }
                field("Skill Code"; Rec."Skill Code")
                {
                    ToolTip = 'Specifies the skill code.';
                    Visible = ShowSkillCode;
                }
                field(Year; Rec.Year)
                {
                    ToolTip = 'Specifies the year.';
                    Visible = ShowYear;
                }
                field("Week No."; Rec."Week No.")
                {
                    ToolTip = 'Specifies the ISO week number.';
                    Visible = ShowWeekNo;
                }
                field("Total Week Hours"; Rec."Total Week Hours")
                {
                    ToolTip = 'Specifies total hours for the entire week.';
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(0);
                    end;
                }
                field("Monday Hours"; Rec."Monday Hours")
                {
                    ToolTip = 'Specifies total hours on Monday.';
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(1);
                    end;
                }
                field("Tuesday Hours"; Rec."Tuesday Hours")
                {
                    ToolTip = 'Specifies total hours on Tuesday.';
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(2);
                    end;
                }
                field("Wednesday Hours"; Rec."Wednesday Hours")
                {
                    ToolTip = 'Specifies total hours on Wednesday.';
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(3);
                    end;
                }
                field("Thursday Hours"; Rec."Thursday Hours")
                {
                    ToolTip = 'Specifies total hours on Thursday.';
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(4);
                    end;
                }
                field("Friday Hours"; Rec."Friday Hours")
                {
                    ToolTip = 'Specifies total hours on Friday.';
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(5);
                    end;
                }
                field("Saturday Hours"; Rec."Saturday Hours")
                {
                    ToolTip = 'Specifies total hours on Saturday.';
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(6);
                    end;
                }
                field("Sunday Hours"; Rec."Sunday Hours")
                {
                    ToolTip = 'Specifies total hours on Sunday.';
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(7);
                    end;
                }


            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(Processing)
        {
            action(ResetData)
            {

                trigger OnAction()
                begin
                    LoadDataSet(DateFilter);
                end;
            }
        }
    }

    var
        JobNoFilter: Code[20];
        JobTaskNoFilter: Code[20];
        ResourceNoFilter: Code[20];
        SkillCodeFilter: Code[20];
        WeekFilter: Text;
        DateFilter: Text;
        ShowResource: Boolean;
        ShowSkillCode: Boolean;
        ShowJob: Boolean;
        ShowJobTask: Boolean;
        ShowYear: Boolean;
        ShowWeekNo: Boolean;
        ShowPlanStatus: Boolean;

    procedure LoadDataSet(DateRangeFilter: Text)
    begin
        SetAllShowTrue();
        DateFilter := DateRangeFilter;
        rec.ScanDayTaskDateFilter(DateFilter);
        rec.LoadSummary();
    end;

    Local procedure SetAllShowTrue()
    begin
        ShowResource := True;
        ShowSkillCode := True;
        ShowJob := True;
        ShowJobTask := True;
        ShowYear := True;
        ShowWeekNo := True;
    end;

    procedure GroupByDataSet()
    var
        Temp: Record "Summary Weekly" temporary;
        TempCopy: Record "Summary Weekly" temporary;
    begin

        rec.LoadSummary();
        if ShowResource and ShowSkillCode and ShowJob and ShowJobTask and ShowYear and ShowWeekNo then
            exit;
        if rec.FindSet() then
            repeat
                TempCopy.Copy(rec);
                if not ShowResource then
                    TempCopy."Resource No." := '';
                if not ShowSkillCode then
                    TempCopy."Skill Code" := '';
                if not ShowJob then
                    TempCopy."Job No." := '';
                if not ShowJobTask then
                    TempCopy."Job Task No." := '';
                if not ShowYear then
                    TempCopy.Year := 0;
                if not ShowWeekNo then
                    TempCopy."Week No." := 0;
                if not temp.get(TempCopy."Resource No.", TempCopy."Skill Code", TempCopy."Job No.", TempCopy."Job Task No.", TempCopy.Year, TempCopy."Week No.") then begin
                    Temp := tempcopy;
                    Temp.insert();
                end else begin
                    Temp."Total Week Hours" += TempCopy."Total Week Hours";
                    Temp."Monday Hours" += TempCopy."Monday Hours";
                    Temp."Tuesday Hours" += TempCopy."Tuesday Hours";
                    Temp."Wednesday Hours" += TempCopy."Wednesday Hours";
                    Temp."Thursday Hours" += TempCopy."Thursday Hours";
                    Temp."Friday Hours" += TempCopy."Friday Hours";
                    Temp."Saturday Hours" += TempCopy."Saturday Hours";
                    Temp."Sunday Hours" += TempCopy."Sunday Hours";
                    temp.Modify();
                end;
            until rec.Next() = 0;
        rec.DeleteAll();
        if Temp.FindSet() then
            repeat
                rec := Temp;
                rec.Insert();
            until Temp.Next() = 0;
    end;

    local procedure DrillDown2DayTaks(WeekDayNo: Integer)
    var
        Pg: Page "Day Tasks";
        Rc: Record "Day Tasks";
        dtFilter: Text;
    begin
        if not showYear then begin
        end else
            if not ShowWeekNo then begin
                dtFilter := StrSubstNo('%1..%2',
                  Format(DWY2Date(1, 1, Rec.Year)),
                    Format(DWY2Date(7,
                    Date2DWY(DMY2Date(31, 12, Rec.Year), 2),
                    Rec.Year
                    ))
            );
                rc.SetFilter("Task Date", dtFilter);
            end else
                if WeekDayNo = 0 then begin
                    dtFilter := StrSubstNo('%1..%2', Format(DWY2Date(1, rec."Week No.", rec.Year)), Format(DWY2Date(7, rec."Week No.", rec.Year)));
                    rc.SetFilter("Task Date", dtFilter);
                end else
                    rc.SetRange("Task Date", DWY2Date(WeekDayNo, rec."Week No.", rec.Year));

        rc.FilterGroup(2);
        if ShowJob then
            rc.SetRange("Job No.", Rec."Job No.");
        if ShowJobTask then
            Rc.SetRange("Job Task No.", Rec."Job Task No.");
        if ShowResource then
            rc.SetRange("No.", Rec."Resource No.");
        if ShowSkillCode then
            rc.SetRange("Skill", Rec."Skill Code");
        //if SHowPlanStatus then
        //    rc.SetRange("Plan Status", Rec."Plan Status");
        ShowPlanStatus := true;
        rc.FilterGroup(0);
        PG.SetTableView(Rc);

        pg.SetColumsVisible(ShowJob, ShowJobTask, ShowResource, ShowSkillCode, SHowPlanStatus);
        Pg.Run();
    end;

    local procedure ValidateYrWkFilterFormat(var YrWkFilter: Text): Boolean
    var
        y, w, l : Integer;
        NotValidFormat: Boolean;
    begin
        l := StrLen(WeekFilter);
        if l in [0, 4, 7] then begin
            if l = 0 then
                exit(false)
            else begin
                if not Evaluate(y, CopyStr(WeekFilter, 1, 4)) then
                    NotValidFormat := true;
                if ShowWeekNo then begin
                    if not Evaluate(w, CopyStr(WeekFilter, 6, 2)) then
                        NotValidFormat := true;
                    if not (CopyStr(WeekFilter, 5, 1) = '-') then
                        NotValidFormat := true;
                end else
                    if l = 7 then
                        NotValidFormat := true;
            end;
        end else
            NotValidFormat := true;
        if NotValidFormat then
            if not ShowWeekNo then
                Error('Invalid format. Please enter in YYYY format for filtering by year only.')
            else
                Error('Invalid format. Please enter in YYYY-WW format.');
        exit(true)
    end;


}