/// <summary>
/// Request-page-only picker (Report 50611) used by the Task Scheduler "Add Day Planning" action
/// when the clicked section carries no Job/Job Task (e.g. the 'nodata' row).
/// Caller pattern: SetContext(...); RunModal(); if IsConfirmed() then GetContext(...).
/// </summary>
report 50611 "Add Day Planning"
{
    UsageCategory = None;
    ApplicationArea = All;
    ProcessingOnly = true;
    UseRequestPage = true;
    Caption = 'Add Day Planning';

    dataset
    {
        dataitem(DummyInteger; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(0));

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(General)
                {
                    ShowCaption = false;

                    field(fldJobNo; JobNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Job No.';
                        ToolTip = 'Specifies the job to add the day planning to.';
                        TableRelation = Job."No.";
                    }
                    field(fldJobTaskNo; JobTaskNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Job Task No.';
                        ToolTip = 'Specifies the job task to add the day planning to.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            JobTask: Record "Job Task";
                            JobTaskList: Page "Job Task List";
                        begin
                            if JobNo <> '' then
                                JobTask.SetRange("Job No.", JobNo);
                            JobTaskList.SetTableView(JobTask);
                            JobTaskList.LookupMode(true);
                            if JobTaskList.RunModal() = Action::LookupOK then begin
                                JobTaskList.GetRecord(JobTask);
                                JobNo := JobTask."Job No.";
                                Text := JobTask."Job Task No.";
                                exit(true);
                            end;
                            exit(false);
                        end;
                    }
                    field(fldSkill; SkillCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Skill';
                        ToolTip = 'Specifies the skill preselected in the new sequence. Optional - blank uses the default skill from Daily Optimizer Setup.';
                        TableRelation = "Skill Code";
                    }
                }
            }
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            Confirmed := CloseAction = Action::OK;
            exit(true);
        end;
    }

    var
        JobNo: Code[20];
        JobTaskNo: Code[20];
        SkillCode: Code[10];
        Confirmed: Boolean;

    /// <summary>Must be called BEFORE RunModal(). Pre-fills the request page.</summary>
    procedure SetContext(pJobNo: Code[20]; pJobTaskNo: Code[20]; pSkillCode: Code[10])
    begin
        JobNo := pJobNo;
        JobTaskNo := pJobTaskNo;
        SkillCode := pSkillCode;
    end;

    /// <summary>Must be called AFTER RunModal(), guarded by IsConfirmed().</summary>
    procedure GetContext(var pJobNo: Code[20]; var pJobTaskNo: Code[20]; var pSkillCode: Code[10])
    begin
        pJobNo := JobNo;
        pJobTaskNo := JobTaskNo;
        pSkillCode := SkillCode;
    end;

    /// <summary>Must be called AFTER RunModal(). True when the user closed the request page with OK.</summary>
    procedure IsConfirmed(): Boolean
    begin
        exit(Confirmed);
    end;
}
