page 50626 "Summary View"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Summary Weekly";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Summary View';
                field(ShowResource; ShowResource)
                {
                    ToolTip = 'Set the Resource No. field visble or not. Visible by default.';
                    trigger OnValidate()
                    begin
                        GroupByDataSet();
                    end;
                }
                field(ShowSkillCode; ShowSkillCode)
                {
                    ToolTip = 'Set the Skill Code field visible or not. Visible by default.';
                    trigger OnValidate()
                    begin
                        GroupByDataSet();
                    end;
                }
                field(ShowJob; ShowJob)
                {
                    ToolTip = 'Set the Job field visible or not. Visible by default.';
                    trigger OnValidate()
                    begin
                        if not ShowJob then
                            ShowJobTask := False;
                        GroupByDataSet();
                    end;
                }
                field(ShowJobTask; ShowJobTask)
                {
                    ToolTip = 'Set the Job Task field visible or not. Visible by default.';
                    trigger OnValidate()
                    begin
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
                        GroupByDataSet();
                    end;
                }
                field(ShowWeekNo; ShowWeekNo)
                {
                    ToolTip = 'Set the Week No. field visible or not. Visible by default.';
                    trigger OnValidate()
                    begin
                        GroupByDataSet();
                    end;
                }
            }

            /* group(Create)
            {

                Caption = 'Create Daytask';
                field("JobNo"; JobNo)
                {
                    ToolTip = 'Specifies the job number for the new day task.';
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
                field("JobTaskNo"; JobTaskNo)
                {
                    ToolTip = 'Specifies the job task number for the new day task.';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        JobTask: Record "Job Task" temporary;
                        Pg: Page "Opti Job Task List TEMP";
                    begin
                        rec.HandOverToPage(Pg);
                        if JobNo <> '' then
                            JobTask.SetRange("Job No.", JobNo);
                        pg.LookupMode(true);
                        pg.SetTableView(JobTask);
                        if Pg.RunModal() = Action::LookupOK then begin
                            pg.GetRecord(JobTask);
                            Text := JobTask."Job Task No.";
                            if JobNo = '' then
                                JobNo := JobTask."Job No.";
                            exit(true);
                        end;
                    end;
                }
                field(RescoureNo; ResourceNo)
                {
                    ToolTip = 'Specifies the resource number for the new day task.';
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
                field(SkillCode; SkillCode)
                {
                    ToolTip = 'Specifies the skill code for the new day task.';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Skill: Record "Skill Code" temporary;
                        pg: Page "Opti Skill Codes";
                    begin
                        rec.HandOverToPage(pg);
                        if SkillCode <> '' then begin
                            Skill.get(SkillCode);
                        end;
                        if Pg.RunModal() = Action::LookupOK then begin
                            Pg.GetRecord(Skill);
                            Text := Skill.Code;
                            exit(true);
                        end;
                    end;
                }
            } */
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
                }
                field("Monday Hours"; Rec."Monday Hours")
                {
                    ToolTip = 'Specifies total hours on Monday.';
                }
                field("Thursday Hours"; Rec."Thursday Hours")
                {
                    ToolTip = 'Specifies total hours on Thursday.';
                }
                field("Wednesday Hours"; Rec."Wednesday Hours")
                {
                    ToolTip = 'Specifies total hours on Wednesday.';
                }
                field("Tuesday Hours"; Rec."Tuesday Hours")
                {
                    ToolTip = 'Specifies total hours on Tuesday.';
                }
                field("Friday Hours"; Rec."Friday Hours")
                {
                    ToolTip = 'Specifies total hours on Friday.';
                }
                field("Saturday Hours"; Rec."Saturday Hours")
                {
                    ToolTip = 'Specifies total hours on Saturday.';
                }
                field("Sunday Hours"; Rec."Sunday Hours")
                {
                    ToolTip = 'Specifies total hours on Sunday.';
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
                    SetAllShowTrue();
                    rec.LoadSummary();
                end;
            }
        }
    }

    var
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        SkillCode: Code[20];
        DateFilter: Text;
        ShowResource: Boolean;
        ShowSkillCode: Boolean;
        ShowJob: Boolean;
        ShowJobTask: Boolean;
        ShowYear: Boolean;
        ShowWeekNo: Boolean;

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
}