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
                        CalcFilters();
                    end;
                }
                field(ShowSkillCode; ShowSkillCode)
                {
                    ToolTip = 'Set the Skill Code field visible or not. Visible by default.';
                    trigger OnValidate()
                    begin
                        SkillCodeFilter := '';
                        GroupByDataSet();
                        CalcFilters();
                    end;
                }
                field(ShowJob; ShowJob)
                {
                    ToolTip = 'Set the Job field visible or not. Visible by default.';
                    Visible = Job_Visible;
                    trigger OnValidate()
                    begin
                        JobNoFilter := '';
                        if not ShowJob then begin
                            ShowJobTask := False;
                            JobTaskNoFilter := '';
                        end;
                        GroupByDataSet();
                        CalcFilters();
                    end;
                }
                field(ShowJobTask; ShowJobTask)
                {
                    ToolTip = 'Set the Job Task field visible or not. Visible by default.';
                    Visible = Job_Visible;
                    trigger OnValidate()
                    begin
                        JobTaskNoFilter := '';
                        if ShowJobTask then
                            ShowJob := true;
                        GroupByDataSet();
                        CalcFilters();
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
                        CalcFilters();
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
                        CalcFilters();
                    end;
                }
            }

            group(FilterSettings)
            {

                Caption = 'Filters';
                group(job)
                {
                    ShowCaption = false;
                    Visible = ShowJob or (Not Job_Visible);
                    editable = ShowJob or Job_Visible;

                    field("JobNoFilter"; JobNoFilter)
                    {
                        ToolTip = 'Specifies the job number for the new day planning.';
                        trigger OnValidate()
                        begin
                            CalcJobFilter();
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
                    Visible = ShowJobTask or (Not Job_Visible);
                    editable = ShowJob or Job_Visible;

                    field("JobTaskNoFilter"; JobTaskNoFilter)
                    {
                        ToolTip = 'Specifies the job task number for the new day planning.';
                        trigger OnValidate()
                        begin
                            CalcJobTaskFilter();
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
                        ToolTip = 'Specifies the resource number for the new day planning.';
                        trigger OnValidate()
                        begin
                            CalcResourceFilter();
                            CurrPage.Update();
                        end;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            Resource: Record "Resource" temporary;
                            Pg: Page "Opti Resource List Temp";
                        begin
                            rec.HandOverToPage(Pg);
                            pg.LookupMode(true);
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
                        ToolTip = 'Specifies the skill code for the new day planning.';
                        trigger OnValidate()
                        begin
                            CalcSkillCodeFilter();
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
                            CalcWeekFilter();
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
                    StyleExpr = StyleStr;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ToolTip = 'Specifies the value of the Job Task No. field.', Comment = '%';
                    Visible = ShowJobTask;
                    StyleExpr = StyleStr;

                }
                field(Purpose; Rec.Purpose)
                {
                    ToolTip = 'Specifies the value of the Purpose field.', Comment = '%';
                    Visible = False;
                    StyleExpr = StyleStr;
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
                    StyleExpr = StyleStr;

                }
                field("Week No."; Rec."Week No.")
                {
                    ToolTip = 'Specifies the ISO week number.';
                    Visible = ShowWeekNo;
                    StyleExpr = StyleStr;

                }
                field("Total Requested Hours"; Rec."Total Requested Hours")
                {
                    ToolTip = 'Specifies total requested hours for the entire week.';
                    StyleExpr = StyleStr;

                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(0);
                    end;
                }
                field("Total Assigned Hours"; Rec."Total Assigned Hours")
                {
                    ToolTip = 'Specifies total assigned hours for the entire week.';
                    StyleExpr = StyleStr;

                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(0);
                    end;
                }
                field("Monday Requested Hours"; Rec."Monday Requested Hours")
                {
                    ToolTip = 'Specifies requested hours on Monday.';
                    StyleExpr = StyleStr;

                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(1);
                    end;
                }
                field("Monday Assigned Hours"; Rec."Monday Assigned Hours")
                {
                    ToolTip = 'Specifies assigned hours on Monday.';
                    StyleExpr = StyleStr;

                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(1);
                    end;
                }
                field("Tuesday Requested Hours"; Rec."Tuesday Requested Hours")
                {
                    ToolTip = 'Specifies requested hours on Tuesday.';
                    StyleExpr = StyleStr;

                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(2);
                    end;
                }
                field("Tuesday Assigned Hours"; Rec."Tuesday Assigned Hours")
                {
                    ToolTip = 'Specifies assigned hours on Tuesday.';
                    StyleExpr = StyleStr;

                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(2);
                    end;
                }
                field("Wednesday Requested Hours"; Rec."Wednesday Requested Hours")
                {
                    ToolTip = 'Specifies requested hours on Wednesday.';
                    StyleExpr = StyleStr;

                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(3);
                    end;
                }
                field("Wednesday Assigned Hours"; Rec."Wednesday Assigned Hours")
                {
                    ToolTip = 'Specifies assigned hours on Wednesday.';
                    StyleExpr = StyleStr;

                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(3);
                    end;
                }
                field("Thursday Requested Hours"; Rec."Thursday Requested Hours")
                {
                    ToolTip = 'Specifies requested hours on Thursday.';
                    StyleExpr = StyleStr;

                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(4);
                    end;
                }
                field("Thursday Assigned Hours"; Rec."Thursday Assigned Hours")
                {
                    ToolTip = 'Specifies assigned hours on Thursday.';
                    StyleExpr = StyleStr;

                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(4);
                    end;
                }
                field("Friday Requested Hours"; Rec."Friday Requested Hours")
                {
                    ToolTip = 'Specifies requested hours on Friday.';
                    StyleExpr = StyleStr;

                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(5);
                    end;
                }
                field("Friday Assigned Hours"; Rec."Friday Assigned Hours")
                {
                    ToolTip = 'Specifies assigned hours on Friday.';
                    StyleExpr = StyleStr;

                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(5);
                    end;
                }
                field("Saturday Requested Hours"; Rec."Saturday Requested Hours")
                {
                    ToolTip = 'Specifies requested hours on Saturday.';
                    StyleExpr = StyleStr;

                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(6);
                    end;
                }
                field("Saturday Assigned Hours"; Rec."Saturday Assigned Hours")
                {
                    ToolTip = 'Specifies assigned hours on Saturday.';
                    StyleExpr = StyleStr;

                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(6);
                    end;
                }
                field("Sunday Requested Hours"; Rec."Sunday Requested Hours")
                {
                    ToolTip = 'Specifies requested hours on Sunday.';
                    StyleExpr = StyleStr;

                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(7);
                    end;
                }
                field("Sunday Assigned Hours"; Rec."Sunday Assigned Hours")
                {
                    ToolTip = 'Specifies assigned hours on Sunday.';
                    StyleExpr = StyleStr;

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
                Caption = 'Reset Data';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
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
        Job_Visible: Boolean;
        ShowYear: Boolean;
        ShowWeekNo: Boolean;
        ShowPlanStatus: Boolean;
        StyleStr: Text;

    trigger OnAfterGetRecord()
    begin
        if rec."Resource No." = '' then
            StyleStr := 'Attention'
        else
            StyleStr := '';
    end;

    #region  Procedures
    procedure SetJobAndJobTaskVisibility(Visible: Boolean)
    begin
        Job_Visible := Visible;
        if not Visible then begin
            ShowJob := false;
            ShowJobTask := false;
        end;
    end;

    procedure LoadDataSet(DateRangeFilter: Text)
    begin
        rec.reset;
        rec.DeleteAll();
        SetAllShowTrue();
        DateFilter := DateRangeFilter;
        rec.ScanDayPlanningDateFilter(DateFilter);
        rec.LoadSummary();
    end;

    procedure LoadDataSet(pJobNoFilter: Text; pJobTaskNoFilter: Text)
    begin
        SetAllShowTrue();
        JobNoFilter := CopyStr(pJobNoFilter, 1, MaxStrLen(JobNoFilter));
        JobTaskNoFilter := CopyStr(pJobTaskNoFilter, 1, MaxStrLen(JobTaskNoFilter));
        rec.ScanDayPlanningFilter(pJobNoFilter, pJobTaskNoFilter);
        rec.LoadSummary();
        if JobNoFilter <> '' then
            rec.SetFilter("Job No.", JobNoFilter);
        if JobTaskNoFilter <> '' then
            rec.SetFilter("Job Task No.", JobTaskNoFilter);
    end;

    procedure SetDefaultView()
    begin
        ShowSkillCode := False;
        ShowJob := False;
        ShowJobTask := False;
        GroupByDataSet();
        WeekFilter := GetYearWeekFromDateFilter(DateFilter);
        CalcFilters();
    end;

    local procedure GetYearWeekFromDateFilter(pDateFilter: Text): Text
    var
        d: Date;
        y, w : Integer;
        FilterPart: Text;
    begin
        if pDateFilter = '' then
            exit('');
        if pDateFilter.Contains('..') then
            FilterPart := pDateFilter.Split('..').Get(1)
        else
            FilterPart := pDateFilter;
        if not Evaluate(d, FilterPart) then
            exit('');
        if d = 0D then
            exit('');
        y := Date2DWY(d, 3);
        w := Date2DWY(d, 2);
        // if w < 10 then
        //     exit(Format(y) + '-0' + Format(w))
        // else
        exit(Format(y) + '-' + Format(w));
    end;

    Local procedure SetAllShowTrue()
    begin
        ShowResource := True;
        ShowSkillCode := True;
        ShowJob := True;
        ShowJobTask := True;
        ShowYear := True;
        ShowWeekNo := True;
        Job_Visible := True;
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
                    Temp."Total Requested Hours" += TempCopy."Total Requested Hours";
                    Temp."Total Assigned Hours" += TempCopy."Total Assigned Hours";
                    Temp."Monday Requested Hours" += TempCopy."Monday Requested Hours";
                    Temp."Monday Assigned Hours" += TempCopy."Monday Assigned Hours";
                    Temp."Tuesday Requested Hours" += TempCopy."Tuesday Requested Hours";
                    Temp."Tuesday Assigned Hours" += TempCopy."Tuesday Assigned Hours";
                    Temp."Wednesday Requested Hours" += TempCopy."Wednesday Requested Hours";
                    Temp."Wednesday Assigned Hours" += TempCopy."Wednesday Assigned Hours";
                    Temp."Thursday Requested Hours" += TempCopy."Thursday Requested Hours";
                    Temp."Thursday Assigned Hours" += TempCopy."Thursday Assigned Hours";
                    Temp."Friday Requested Hours" += TempCopy."Friday Requested Hours";
                    Temp."Friday Assigned Hours" += TempCopy."Friday Assigned Hours";
                    Temp."Saturday Requested Hours" += TempCopy."Saturday Requested Hours";
                    Temp."Saturday Assigned Hours" += TempCopy."Saturday Assigned Hours";
                    Temp."Sunday Requested Hours" += TempCopy."Sunday Requested Hours";
                    Temp."Sunday Assigned Hours" += TempCopy."Sunday Assigned Hours";
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
        Pg: Page "Day Plannings";
        Rc: Record "Day Planning";
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
            rc.SetRange("Assigned Resource No.", Rec."Resource No.");
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
    #endregion
    local procedure CalcFilters()
    begin
        CalcResourceFilter();
        CalcSkillCodeFilter();
        CalcJobFilter();
        CalcJobTaskFilter();
        CalcWeekFilter();
    end;

    local procedure CalcResourceFilter()
    begin
        if ResourceNoFilter <> '' then
            rec.setfilter("Resource No.", ResourceNoFilter)
        else
            rec.SetRange("Resource No.");
    end;

    local procedure CalcSkillCodeFilter()
    begin
        if SkillCodeFilter <> '' then
            rec.setfilter("Skill Code", SkillCodeFilter)
        else
            rec.SetRange("Skill Code");
    end;

    local procedure CalcJobFilter()
    begin
        if JobNoFilter <> '' then
            rec.setfilter("Job No.", JobNoFilter)
        else
            rec.SetRange("Job No.");
    end;

    local procedure CalcJobTaskFilter()
    begin
        if JobTaskNoFilter <> '' then
            rec.setfilter("Job Task No.", JobTaskNoFilter)
        else
            rec.SetRange("Job Task No.");
    end;

    local procedure CalcWeekFilter()
    begin
        if ValidateYrWkFilterFormat(WeekFilter) then begin
            rec.setfilter("Year", CopyStr(WeekFilter, 1, 4));
            if ShowWeekNo then
                rec.setfilter("Week No.", CopyStr(WeekFilter, 6, 2));
        end else begin
            rec.SetRange("Year");
            rec.SetRange("Week No.");
        end;
    end;
}