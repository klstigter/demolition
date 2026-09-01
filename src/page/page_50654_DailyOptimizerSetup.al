page 50654 "Daily Optimizer Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Daily Optimizer Setup";
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Base Calendar"; Rec."Base Calendar")
                {
                    ApplicationArea = All;
                }
                field("Work hour Template"; Rec."Work hour Template")
                {
                    ApplicationArea = All;
                }
                field("Default Skill"; Rec."Default Skill")
                {
                    ApplicationArea = All;
                }
            }
            group(Visual)
            {
                group("Resource Scheduler")
                {
                    Caption = 'Resource Scheduler';

                    field("Resource Scheduler - List Type"; Rec."Resource Scheduler - List Type")
                    {
                        ApplicationArea = All;
                        caption = 'List Type';
                    }
                }
                group("Requested/Capacity")
                {
                    Caption = 'Requested/Capacity';

                    field("Bar Width (px) - Bar Chart"; Rec."Bar Width (px) - Bar Chart")
                    {
                        ApplicationArea = All;
                        caption = 'Bar Width (px)';
                        ToolTip = 'Specifies the width, in pixels, of each bar on the Requested Hours vs Capacity bar charts (Daily and Weekly). Leave at 0 to use the chart''s default width.';
                    }
                    field("Bar Font Color"; Rec."Bar Font Color")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Color of the text/caption shown on every event bar''s on-bar label (Gantt chart tasks, scheduler timeline bars, and Day Planning bars). Enter a hex color, e.g. #000000.';

                        trigger OnAssistEdit()
                        var
                            ColorPickerPage: Page "Color Picker Lookup";
                        begin
                            ColorPickerPage.SetInitialColor(Rec."Bar Font Color");
                            if ColorPickerPage.RunModal() = Action::OK then begin
                                Rec."Bar Font Color" := ColorPickerPage.GetSelectedColor();
                                Rec.Modify(true);
                                CurrPage.Update(false);
                            end;
                        end;
                    }
                }

                group(WeekendHoliday)
                {
                    Caption = 'Weekend / Day Off';

                    field("Weekend Color"; Rec."Weekend Color")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Background color used to shade Saturday/Sunday columns on the Gantt chart and Day Planning Sequence timeline. Enter a hex color, e.g. #ffe0e0.';

                        trigger OnAssistEdit()
                        var
                            ColorPickerPage: Page "Color Picker Lookup";
                        begin
                            ColorPickerPage.SetInitialColor(Rec."Weekend Color");
                            if ColorPickerPage.RunModal() = Action::OK then begin
                                Rec."Weekend Color" := ColorPickerPage.GetSelectedColor();
                                Rec.Modify(true);
                                CurrPage.Update(false);
                            end;
                        end;
                    }
                    field("Holiday Color"; Rec."Holiday Color")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Background color used to shade Base Calendar day-off/public-holiday dates on the Gantt chart and Day Planning Sequence timeline. Enter a hex color, e.g. #fff3cd.';

                        trigger OnAssistEdit()
                        var
                            ColorPickerPage: Page "Color Picker Lookup";
                        begin
                            ColorPickerPage.SetInitialColor(Rec."Holiday Color");
                            if ColorPickerPage.RunModal() = Action::OK then begin
                                Rec."Holiday Color" := ColorPickerPage.GetSelectedColor();
                                Rec.Modify(true);
                                CurrPage.Update(false);
                            end;
                        end;
                    }
                }

                group(ganttBarTask)
                {
                    Caption = 'Gantt Task Bar';

                    field("GTB Color (non posting)"; Rec."GTB Color (non posting)")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Background color of the Gantt chart task bar for non-posting Job Tasks. Enter a hex color, e.g. #7FB3FA.';

                        trigger OnAssistEdit()
                        var
                            ColorPickerPage: Page "Color Picker Lookup";
                        begin
                            ColorPickerPage.SetInitialColor(Rec."GTB Color (non posting)");
                            if ColorPickerPage.RunModal() = Action::OK then begin
                                Rec."GTB Color (non posting)" := ColorPickerPage.GetSelectedColor();
                                Rec.Modify(true);
                                CurrPage.Update(false);
                            end;
                        end;
                    }
                    field("GTB Color"; Rec."GTB Color")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Background color of the Gantt chart task bar. Enter a hex color, e.g. #7FB3FA.';

                        trigger OnAssistEdit()
                        var
                            ColorPickerPage: Page "Color Picker Lookup";
                        begin
                            ColorPickerPage.SetInitialColor(Rec."GTB Color");
                            if ColorPickerPage.RunModal() = Action::OK then begin
                                Rec."GTB Color" := ColorPickerPage.GetSelectedColor();
                                Rec.Modify(true);
                                CurrPage.Update(false);
                            end;
                        end;
                    }
                    field("GTB Border Color"; Rec."GTB Border Color")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Border color of the Gantt chart task bar. Enter a hex color, e.g. #14294D.';

                        trigger OnAssistEdit()
                        var
                            ColorPickerPage: Page "Color Picker Lookup";
                        begin
                            ColorPickerPage.SetInitialColor(Rec."GTB Border Color");
                            if ColorPickerPage.RunModal() = Action::OK then begin
                                Rec."GTB Border Color" := ColorPickerPage.GetSelectedColor();
                                Rec.Modify(true);
                                CurrPage.Update(false);
                            end;
                        end;
                    }
                    field("GTB Progress Color"; Rec."GTB Progress Color")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Progress color of the Gantt chart task bar. Enter a hex color, e.g. #7FB3FA.';

                        trigger OnAssistEdit()
                        var
                            ColorPickerPage: Page "Color Picker Lookup";
                        begin
                            ColorPickerPage.SetInitialColor(Rec."GTB Progress Color");
                            if ColorPickerPage.RunModal() = Action::OK then begin
                                Rec."GTB Progress Color" := ColorPickerPage.GetSelectedColor();
                                Rec.Modify(true);
                                CurrPage.Update(false);
                            end;
                        end;
                    }
                    field("GTB Font Color"; Rec."GTB Font Color")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Font color of the Gantt chart task bar text. Enter a hex color, e.g. #000000.';

                        trigger OnAssistEdit()
                        var
                            ColorPickerPage: Page "Color Picker Lookup";
                        begin
                            ColorPickerPage.SetInitialColor(Rec."GTB Font Color");
                            if ColorPickerPage.RunModal() = Action::OK then begin
                                Rec."GTB Font Color" := ColorPickerPage.GetSelectedColor();
                                Rec.Modify(true);
                                CurrPage.Update(false);
                            end;
                        end;
                    }
                    field("GTB Font Size (px)"; Rec."GTB Font size (px)")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Font size of the Gantt chart task bar text. Enter a value in pixels.';
                    }
                    field("GTB Height (px)"; Rec."GTB Height (px)")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Height of the Gantt chart task bar. Enter a value in pixels.';
                    }

                }

                group(Colors)
                {
                    Caption = 'Bar Colors';

                    group(Capacity)
                    {
                        Caption = 'Capacity';

                        field("Unassigned Capacity Color"; Rec."Unassigned Capacity Color")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Color of the Unassigned Capacity bar. Enter a hex color, e.g. #7FB3FA.';

                            trigger OnAssistEdit()
                            var
                                ColorPickerPage: Page "Color Picker Lookup";
                            begin
                                ColorPickerPage.SetInitialColor(Rec."Unassigned Capacity Color");
                                if ColorPickerPage.RunModal() = Action::OK then begin
                                    Rec."Unassigned Capacity Color" := ColorPickerPage.GetSelectedColor();
                                    Rec.Modify(true);
                                    CurrPage.Update(false);
                                end;
                            end;
                        }
                        field("Capacity Border Color"; Rec."Capacity Border Color")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Border color of the Capacity bar/event on the Resource Scheduler timeline (Resource Capacity Scheduler and Resource Scheduler - Timeline pages). Enter a hex color, e.g. #C97F16.';

                            trigger OnAssistEdit()
                            var
                                ColorPickerPage: Page "Color Picker Lookup";
                            begin
                                ColorPickerPage.SetInitialColor(Rec."Capacity Border Color");
                                if ColorPickerPage.RunModal() = Action::OK then begin
                                    Rec."Capacity Border Color" := ColorPickerPage.GetSelectedColor();
                                    Rec.Modify(true);
                                    CurrPage.Update(false);
                                end;
                            end;
                        }
                        field("External Border Color"; Rec."External Border Color")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Border color used on the Requested Hours vs Capacity bar charts (Daily and Weekly) to flag the portion of a bar that goes over capacity. Enter a hex color, e.g. #FF0000.';

                            trigger OnAssistEdit()
                            var
                                ColorPickerPage: Page "Color Picker Lookup";
                            begin
                                ColorPickerPage.SetInitialColor(Rec."External Border Color");
                                if ColorPickerPage.RunModal() = Action::OK then begin
                                    Rec."External Border Color" := ColorPickerPage.GetSelectedColor();
                                    Rec.Modify(true);
                                    CurrPage.Update(false);
                                end;
                            end;
                        }
                    }

                    group(Envelope)
                    {
                        Caption = 'Envelope';

                        field("Envelope Color"; Rec."Envelope Color")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Background color of the full Day Planning bar (visible where neither the Assigned nor Requested strip covers it). Enter a hex color, e.g. #1B3A6B.';

                            trigger OnAssistEdit()
                            var
                                ColorPickerPage: Page "Color Picker Lookup";
                            begin
                                ColorPickerPage.SetInitialColor(Rec."Envelope Color");
                                if ColorPickerPage.RunModal() = Action::OK then begin
                                    Rec."Envelope Color" := ColorPickerPage.GetSelectedColor();
                                    Rec.Modify(true);
                                    CurrPage.Update(false);
                                end;
                            end;
                        }
                        field("Envelope Border Color"; Rec."Envelope Border Color")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Border color of the full Day Planning bar. Enter a hex color, e.g. #14294D.';

                            trigger OnAssistEdit()
                            var
                                ColorPickerPage: Page "Color Picker Lookup";
                            begin
                                ColorPickerPage.SetInitialColor(Rec."Envelope Border Color");
                                if ColorPickerPage.RunModal() = Action::OK then begin
                                    Rec."Envelope Border Color" := ColorPickerPage.GetSelectedColor();
                                    Rec.Modify(true);
                                    CurrPage.Update(false);
                                end;
                            end;
                        }
                    }
                    group(AssignedRequested)
                    {
                        ShowCaption = false;

                        group(Assigned)
                        {
                            Caption = 'Assigned';

                            field("Assigned Color"; Rec."Assigned Color")
                            {
                                ApplicationArea = All;
                                ToolTip = 'Color of the Assigned time-range strip on the Day Planning bar. Enter a hex color, e.g. #7FB3FA.';

                                trigger OnAssistEdit()
                                var
                                    ColorPickerPage: Page "Color Picker Lookup";
                                begin
                                    ColorPickerPage.SetInitialColor(Rec."Assigned Color");
                                    if ColorPickerPage.RunModal() = Action::OK then begin
                                        Rec."Assigned Color" := ColorPickerPage.GetSelectedColor();
                                        Rec.Modify(true);
                                        CurrPage.Update(false);
                                    end;
                                end;
                            }
                            field("Assigned High (%)"; Rec."Assigned High (%)")
                            {
                                ApplicationArea = All;
                                ToolTip = 'Percentage of the Assigned height relative to envelope.';
                            }
                        }
                        group(Requested)
                        {
                            Caption = 'Requested';

                            field("Requested High (%)"; Rec."Requested High (%)")
                            {
                                ApplicationArea = All;
                                ToolTip = 'Percentage of the Requested height relative to envelope.';
                            }
                        }
                    }
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Order Intake Nos"; Rec."Order Intake Nos")
                {
                    ApplicationArea = All;
                }
                field("Work Order Nos"; Rec."Work Order Nos")
                {
                    ApplicationArea = All;
                }
            }
            group(TrustedCircle)
            {
                Caption = 'TrustedCircle Integration';

                field("TrustedCircle API Base URL"; Rec."TrustedCircle API Base URL")
                {
                    ApplicationArea = ALL;
                }
                field("TrustedCircle Bearer Token"; Rec."TrustedCircle Bearer Token")
                {
                    ApplicationArea = ALL;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(DefaultSetup)
            {
                caption = 'Default Setup';

                action(ResetToDefault)
                {
                    ApplicationArea = All;
                    Caption = 'Reset to default';
                    ToolTip = 'Reset all settings to their default values.';
                    Image = Default;

                    trigger OnAction()
                    var
                        CreateDemoData: Codeunit "Create Demo Data";
                        VisualDefaultSettings: Codeunit "Visual Default Settings";
                        ConfirmLbl: Label 'This will reset all Daily Optimizer Setup values - calendar/work hour template/default skill/number series, colors, and bar width - back to their built-in defaults, overwriting any customizations.\\Continue?';
                    begin
                        if not Confirm(ConfirmLbl, false) then
                            exit;

                        // Initialize() MUST run first - CreateDailyOptimizerSetupDefault() calls
                        // CreateDemoCalendar()/CreateDemoCalendarChanges() internally, which do date
                        // math (CalcDate) against gStartDate/gEndDate. Those globals are only
                        // populated by Initialize() (normally called once at the top of the full
                        // OnRun() demo-data run) - calling CreateDailyOptimizerSetupDefault() on its
                        // own from this action without it left gStartDate at its default 0D,
                        // producing "You cannot base a date calculation on an undefined date."
                        // Initialize() has no destructive side effects of its own (just computes the
                        // demo date window and resumes gLogEntryNo from the last log entry), so it's
                        // safe to call standalone here - matches how external repair reports (see
                        // report_50600_RepairDayPlanningResourceGroup.al) already call it before
                        // reusing CreateDemoCalendar() outside a full run.
                        //
                        // CreateDailyOptimizerSetupDefault() owns Base Calendar/Work hour
                        // Template/Default Skill/Order Intake Nos/Work Order Nos - it ensures the
                        // referenced master data exists and does its own Get()/Insert()/Modify()
                        // against the singleton. Called first, then Rec is re-fetched so the
                        // color/width/list-type fields below are applied on top of its result in
                        // one final Modify - avoids two competing Modify calls on the same record.
                        CreateDemoData.Initialize();
                        CreateDemoData.CreateDailyOptimizerSetupDefault();
                        Rec.Get();

                        Rec."Resource Scheduler - List Type" := Rec."Resource Scheduler - List Type"::"By Resource Group";
                        Rec."Assigned Color" := VisualDefaultSettings.GetDefaultAssignedColor();
                        Rec."Unassigned Capacity Color" := VisualDefaultSettings.GetDefaultCapacityColor();
                        Rec."External Border Color" := VisualDefaultSettings.GetDefaultExternalBorderColor();
                        Rec."Capacity Border Color" := VisualDefaultSettings.GetDefaultCapacityBorderColor();
                        Rec."Bar Font Color" := VisualDefaultSettings.GetDefaultBarFontColor();
                        Rec."Weekend Color" := VisualDefaultSettings.GetDefaultWeekendColor();
                        Rec."Holiday Color" := VisualDefaultSettings.GetDefaultHolidayColor();
                        Rec."Bar Width (px) - Bar Chart" := VisualDefaultSettings.GetDefaultDailyBarChartWidth();
                        Rec."GTB Color" := VisualDefaultSettings.GetDefaultGanttTaskBarColor();
                        Rec."GTB Color (non posting)" := VisualDefaultSettings.GetDefaultGanttTaskBarColorNonPosting();
                        Rec."GTB Border Color" := VisualDefaultSettings.GetDefaultGanttTaskBarBorderColor();
                        Rec."GTB Progress Color" := VisualDefaultSettings.GetDefaultGanttTaskBarProgressColor();
                        Rec."GTB Font Color" := VisualDefaultSettings.GetDefaultGanttTaskBarFontColor();
                        Rec."GTB Font size (px)" := VisualDefaultSettings.GetDefaultGanttTaskBarFontSize();
                        Rec."GTB Height (px)" := VisualDefaultSettings.GetDefaultGanttTaskBarHeight();
                        Rec.Modify(true);
                        CurrPage.Update(false);
                    end;
                }
            }
            group(Color)
            {
                Caption = 'Color Setup';

                action(ResourceSchedulerColor)
                {
                    ApplicationArea = All;
                    Caption = 'Resource Scheduler Color';
                    ToolTip = 'Set up colors for Resource Scheduler based on resources, day plannings, and capacity.';
                    Image = ResourcePlanning;

                    trigger OnAction()
                    begin
                        PAGE.Run(Page::"Resource Scheduler Color opt");
                    end;
                }

                action(TaskColor)
                {
                    ApplicationArea = All;
                    Caption = 'Task Color';
                    ToolTip = 'Set up colors for tasks based on job and task.';
                    Image = TaskQualityMeasure;

                    trigger OnAction()
                    begin
                        PAGE.Run(Page::"Task Color Opt.");
                    end;
                }
                action(ProjectTaskTypeColor)
                {
                    ApplicationArea = All;
                    Caption = 'Project Task Type Color';
                    ToolTip = 'Set up colors for project task types.';
                    Image = TaskList;

                    trigger OnAction()
                    begin
                        PAGE.Run(Page::"Project Type Color Opt.");
                    end;
                }
            }

            group(TrustedCircleActions)
            {
                action(TestUpdateProduct)
                {
                    ApplicationArea = All;
                    Caption = 'Test API Connection';
                    Image = TestDatabase;

                    trigger OnAction()
                    var
                        ti: Codeunit "TrustedCircle Integration";
                    begin
                        ti.TestConnection();
                    end;
                }
                action(TrustedCircleAPILog)
                {
                    ApplicationArea = All;
                    Caption = 'API Log';
                    ToolTip = 'View the log of all TrustedCircle API requests and responses.';
                    Image = Log;

                    trigger OnAction()
                    begin
                        PAGE.Run(Page::"TrustedCircle API Log");
                    end;
                }
            }
            group(Tests)
            {
                Caption = 'Tests';

                action(OpenNodeSet)
                {
                    ApplicationArea = All;
                    Caption = 'Open Node Set';
                    Image = Documents;

                    trigger OnAction()
                    begin
                        PAGE.Run(Page::"Date Span Document");
                    end;
                }
                action(DateEngineTests)
                {
                    ApplicationArea = All;
                    Caption = 'Date Engine Tests';
                    Image = TestFile;

                    trigger OnAction()
                    begin
                        PAGE.Run(Page::"Date Span Test Runner");
                    end;
                }
            }

            group(DemoData)
            {
                Caption = 'Demo Data';

                action(CreateDemoData)
                {
                    ApplicationArea = All;
                    Caption = 'Create Demo Data';
                    ToolTip = 'Delete existing demo data and recreate it fresh for all three demo jobs.';
                    Image = Setup;

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(Codeunit::"Create Demo Data");
                    end;
                }
                action(DeleteDemoData)
                {
                    ApplicationArea = All;
                    Caption = 'Delete Demo Data';
                    ToolTip = 'Delete only the records that were created by the demo data run. User-created data is not affected.';
                    Image = Delete;

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(Codeunit::"Delete Demo Data");
                    end;
                }
                action(DemoDataLog)
                {
                    ApplicationArea = All;
                    Caption = 'Demo Data Log';
                    ToolTip = 'View the log of all records created by the demo data run.';
                    Image = Log;

                    trigger OnAction()
                    begin
                        PAGE.Run(Page::"Demo Data Log");
                    end;
                }
                action(DeleteIncorrectDayPlanning)
                {
                    ApplicationArea = All;
                    Caption = 'Delete incorrect Dayplanning';
                    ToolTip = 'Delete unposted Day Planning lines that are missing a Skill or fall outside their Job Task''s planned date range.';
                    Image = RemoveLine;

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(Codeunit::"Delete Incorrect Day Planning");
                    end;
                }
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Actions';
                actionref(ResetToDefault_ref; ResetToDefault) { }
                actionref(ResourceSchedulerColor_ref; ResourceSchedulerColor) { }
                actionref(TaskColor_ref; TaskColor) { }
                actionref(ProjectTaskTypeColor_ref; ProjectTaskTypeColor) { }
            }
            group(Category_DemoData)
            {
                Caption = 'Demo Data';
                actionref(CreateDemoData_ref; CreateDemoData) { }
                actionref(DeleteDemoData_ref; DeleteDemoData) { }
                actionref(DemoDataLog_ref; DemoDataLog) { }
                actionref(DeleteIncorrectDayPlanning_ref; DeleteIncorrectDayPlanning) { }
            }
            group(TrustedCirclePromoted)
            {
                Caption = 'TrustedCircle';
                actionref(TestUpdateProduct_ref; TestUpdateProduct) { }
                actionref(TrustedCircleAPILog_ref; TrustedCircleAPILog) { }
            }
            group(Category_Tests)
            {
                Caption = 'Tests';
                actionref(OpenNodeSet_ref; OpenNodeSet) { }
                actionref(DateEngineTests_ref; DateEngineTests) { }
            }
        }
    }



    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    var
        myInt: Integer;
}