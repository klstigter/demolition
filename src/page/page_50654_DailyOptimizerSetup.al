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
                    usercontrol(CfBarFontColor; DHXColorFieldAddin)
                    {
                        ApplicationArea = All;

                        trigger ControlReady()
                        begin
                            ColorFieldReady();
                        end;

                        trigger OnPickRequested()
                        begin
                            PickColor(Rec."Bar Font Color");
                        end;

                        trigger OnResetRequested()
                        begin
                            ResetColor(Rec."Bar Font Color", VisualDefaultSettings.GetDefaultBarFontColor());
                        end;

                        trigger OnClearRequested()
                        begin
                            ClearColor(Rec."Bar Font Color");
                        end;
                    }
                }

                group(WeekendHoliday)
                {
                    Caption = 'Weekend / Day Off';

                    usercontrol(CfWeekendColor; DHXColorFieldAddin)
                    {
                        ApplicationArea = All;

                        trigger ControlReady()
                        begin
                            ColorFieldReady();
                        end;

                        trigger OnPickRequested()
                        begin
                            PickColor(Rec."Weekend Color");
                        end;

                        trigger OnResetRequested()
                        begin
                            ResetColor(Rec."Weekend Color", VisualDefaultSettings.GetDefaultWeekendColor());
                        end;

                        trigger OnClearRequested()
                        begin
                            ClearColor(Rec."Weekend Color");
                        end;
                    }
                    usercontrol(CfHolidayColor; DHXColorFieldAddin)
                    {
                        ApplicationArea = All;

                        trigger ControlReady()
                        begin
                            ColorFieldReady();
                        end;

                        trigger OnPickRequested()
                        begin
                            PickColor(Rec."Holiday Color");
                        end;

                        trigger OnResetRequested()
                        begin
                            ResetColor(Rec."Holiday Color", VisualDefaultSettings.GetDefaultHolidayColor());
                        end;

                        trigger OnClearRequested()
                        begin
                            ClearColor(Rec."Holiday Color");
                        end;
                    }
                }

                group(ganttBarTask)
                {
                    Caption = 'Gantt Task Bar';

                    usercontrol(CfGTBColornonposting; DHXColorFieldAddin)
                    {
                        ApplicationArea = All;

                        trigger ControlReady()
                        begin
                            ColorFieldReady();
                        end;

                        trigger OnPickRequested()
                        begin
                            PickColor(Rec."GTB Color (non posting)");
                        end;

                        trigger OnResetRequested()
                        begin
                            ResetColor(Rec."GTB Color (non posting)", VisualDefaultSettings.GetDefaultGanttTaskBarColorNonPosting());
                        end;

                        trigger OnClearRequested()
                        begin
                            ClearColor(Rec."GTB Color (non posting)");
                        end;
                    }
                    usercontrol(CfGTBColor; DHXColorFieldAddin)
                    {
                        ApplicationArea = All;

                        trigger ControlReady()
                        begin
                            ColorFieldReady();
                        end;

                        trigger OnPickRequested()
                        begin
                            PickColor(Rec."GTB Color");
                        end;

                        trigger OnResetRequested()
                        begin
                            ResetColor(Rec."GTB Color", VisualDefaultSettings.GetDefaultGanttTaskBarColor());
                        end;

                        trigger OnClearRequested()
                        begin
                            ClearColor(Rec."GTB Color");
                        end;
                    }
                    usercontrol(CfGTBBorderColor; DHXColorFieldAddin)
                    {
                        ApplicationArea = All;

                        trigger ControlReady()
                        begin
                            ColorFieldReady();
                        end;

                        trigger OnPickRequested()
                        begin
                            PickColor(Rec."GTB Border Color");
                        end;

                        trigger OnResetRequested()
                        begin
                            ResetColor(Rec."GTB Border Color", VisualDefaultSettings.GetDefaultGanttTaskBarBorderColor());
                        end;

                        trigger OnClearRequested()
                        begin
                            ClearColor(Rec."GTB Border Color");
                        end;
                    }
                    usercontrol(CfGTBProgressColor; DHXColorFieldAddin)
                    {
                        ApplicationArea = All;

                        trigger ControlReady()
                        begin
                            ColorFieldReady();
                        end;

                        trigger OnPickRequested()
                        begin
                            PickColor(Rec."GTB Progress Color");
                        end;

                        trigger OnResetRequested()
                        begin
                            ResetColor(Rec."GTB Progress Color", VisualDefaultSettings.GetDefaultGanttTaskBarProgressColor());
                        end;

                        trigger OnClearRequested()
                        begin
                            ClearColor(Rec."GTB Progress Color");
                        end;
                    }
                    usercontrol(CfGTBFontColor; DHXColorFieldAddin)
                    {
                        ApplicationArea = All;

                        trigger ControlReady()
                        begin
                            ColorFieldReady();
                        end;

                        trigger OnPickRequested()
                        begin
                            PickColor(Rec."GTB Font Color");
                        end;

                        trigger OnResetRequested()
                        begin
                            ResetColor(Rec."GTB Font Color", VisualDefaultSettings.GetDefaultGanttTaskBarFontColor());
                        end;

                        trigger OnClearRequested()
                        begin
                            ClearColor(Rec."GTB Font Color");
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

                group(Tooltip)
                {
                    Caption = 'Hover / Tooltip Popup';

                    usercontrol(CfTooltipBackgroundColor; DHXColorFieldAddin)
                    {
                        ApplicationArea = All;

                        trigger ControlReady()
                        begin
                            ColorFieldReady();
                        end;

                        trigger OnPickRequested()
                        begin
                            PickColor(Rec."Tooltip Background Color");
                        end;

                        trigger OnResetRequested()
                        begin
                            ResetColor(Rec."Tooltip Background Color", VisualDefaultSettings.GetDefaultTooltipBackgroundColor());
                        end;

                        trigger OnClearRequested()
                        begin
                            ClearColor(Rec."Tooltip Background Color");
                        end;
                    }
                    usercontrol(CfTooltipFontColor; DHXColorFieldAddin)
                    {
                        ApplicationArea = All;

                        trigger ControlReady()
                        begin
                            ColorFieldReady();
                        end;

                        trigger OnPickRequested()
                        begin
                            PickColor(Rec."Tooltip Font Color");
                        end;

                        trigger OnResetRequested()
                        begin
                            ResetColor(Rec."Tooltip Font Color", VisualDefaultSettings.GetDefaultTooltipFontColor());
                        end;

                        trigger OnClearRequested()
                        begin
                            ClearColor(Rec."Tooltip Font Color");
                        end;
                    }
                }

                group(Colors)
                {
                    Caption = 'Bar Colors';

                    group(Capacity)
                    {
                        Caption = 'Capacity';

                        usercontrol(CfFreeCapacityColor; DHXColorFieldAddin)
                        {
                            ApplicationArea = All;

                            trigger ControlReady()
                            begin
                                ColorFieldReady();
                            end;

                            trigger OnPickRequested()
                            begin
                                PickColor(Rec."Free Capacity Color");
                            end;

                            trigger OnResetRequested()
                            begin
                                ResetColor(Rec."Free Capacity Color", VisualDefaultSettings.GetDefaultCapacityColor());
                            end;

                            trigger OnClearRequested()
                            begin
                                ClearColor(Rec."Free Capacity Color");
                            end;
                        }
                        usercontrol(CfFreeCapacityMandatoryColor; DHXColorFieldAddin)
                        {
                            ApplicationArea = All;

                            trigger ControlReady()
                            begin
                                ColorFieldReady();
                            end;

                            trigger OnPickRequested()
                            begin
                                PickColor(Rec."Free Capacity-Mandatory Color");
                            end;

                            trigger OnResetRequested()
                            begin
                                ResetColor(Rec."Free Capacity-Mandatory Color", VisualDefaultSettings.GetDefaultCapacityMandatoryColor());
                            end;

                            trigger OnClearRequested()
                            begin
                                ClearColor(Rec."Free Capacity-Mandatory Color");
                            end;
                        }
                        usercontrol(CfCapacityBorderColor; DHXColorFieldAddin)
                        {
                            ApplicationArea = All;

                            trigger ControlReady()
                            begin
                                ColorFieldReady();
                            end;

                            trigger OnPickRequested()
                            begin
                                PickColor(Rec."Capacity Border Color");
                            end;

                            trigger OnResetRequested()
                            begin
                                ResetColor(Rec."Capacity Border Color", VisualDefaultSettings.GetDefaultCapacityBorderColor());
                            end;

                            trigger OnClearRequested()
                            begin
                                ClearColor(Rec."Capacity Border Color");
                            end;
                        }
                        usercontrol(CfExternalBorderColor; DHXColorFieldAddin)
                        {
                            ApplicationArea = All;

                            trigger ControlReady()
                            begin
                                ColorFieldReady();
                            end;

                            trigger OnPickRequested()
                            begin
                                PickColor(Rec."External Border Color");
                            end;

                            trigger OnResetRequested()
                            begin
                                ResetColor(Rec."External Border Color", VisualDefaultSettings.GetDefaultExternalBorderColor());
                            end;

                            trigger OnClearRequested()
                            begin
                                ClearColor(Rec."External Border Color");
                            end;
                        }
                    }

                    group(Envelope)
                    {
                        Caption = 'Envelope';

                        usercontrol(CfEnvelopeColor; DHXColorFieldAddin)
                        {
                            ApplicationArea = All;

                            trigger ControlReady()
                            begin
                                ColorFieldReady();
                            end;

                            trigger OnPickRequested()
                            begin
                                PickColor(Rec."Envelope Color");
                            end;

                            trigger OnResetRequested()
                            begin
                                ResetColor(Rec."Envelope Color", VisualDefaultSettings.GetDefaultEnvelopeColor());
                            end;

                            trigger OnClearRequested()
                            begin
                                ClearColor(Rec."Envelope Color");
                            end;
                        }
                        usercontrol(CfEnvelopeBorderColor; DHXColorFieldAddin)
                        {
                            ApplicationArea = All;

                            trigger ControlReady()
                            begin
                                ColorFieldReady();
                            end;

                            trigger OnPickRequested()
                            begin
                                PickColor(Rec."Envelope Border Color");
                            end;

                            trigger OnResetRequested()
                            begin
                                ResetColor(Rec."Envelope Border Color", VisualDefaultSettings.GetDefaultEnvelopeBorderColor());
                            end;

                            trigger OnClearRequested()
                            begin
                                ClearColor(Rec."Envelope Border Color");
                            end;
                        }
                    }
                    group(AssignedRequested)
                    {
                        ShowCaption = false;

                        group(Assigned)
                        {
                            Caption = 'Assigned';

                            usercontrol(CfAssignedColor; DHXColorFieldAddin)
                            {
                                ApplicationArea = All;

                                trigger ControlReady()
                                begin
                                    ColorFieldReady();
                                end;

                                trigger OnPickRequested()
                                begin
                                    PickColor(Rec."Assigned Color");
                                end;

                                trigger OnResetRequested()
                                begin
                                    ResetColor(Rec."Assigned Color", VisualDefaultSettings.GetDefaultAssignedColor());
                                end;

                                trigger OnClearRequested()
                                begin
                                    ClearColor(Rec."Assigned Color");
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
                        Rec."Free Capacity Color" := VisualDefaultSettings.GetDefaultCapacityColor();
                        Rec."Free Capacity-Mandatory Color" := VisualDefaultSettings.GetDefaultCapacityMandatoryColor();
                        Rec."External Border Color" := VisualDefaultSettings.GetDefaultExternalBorderColor();
                        Rec."Capacity Border Color" := VisualDefaultSettings.GetDefaultCapacityBorderColor();
                        Rec."Bar Font Color" := VisualDefaultSettings.GetDefaultBarFontColor();
                        Rec."Tooltip Background Color" := VisualDefaultSettings.GetDefaultTooltipBackgroundColor();
                        Rec."Tooltip Font Color" := VisualDefaultSettings.GetDefaultTooltipFontColor();
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

    trigger OnAfterGetCurrRecord()
    begin
        if ColorFieldsReadyCount >= 17 then
            PushColorFields();
    end;

    local procedure ColorFieldReady()
    begin
        ColorFieldsReadyCount += 1;
        if ColorFieldsReadyCount = 17 then
            PushColorFields();
    end;

    local procedure PushColorFields()
    begin
        CurrPage.CfBarFontColor.SetValue('Bar Font Color', Rec."Bar Font Color");
        CurrPage.CfWeekendColor.SetValue('Weekend Color', Rec."Weekend Color");
        CurrPage.CfHolidayColor.SetValue('Holiday Color', Rec."Holiday Color");
        CurrPage.CfGTBColornonposting.SetValue('Gantt Task Bar Color (Non-Posting)', Rec."GTB Color (non posting)");
        CurrPage.CfGTBColor.SetValue('Gantt Task Bar Color', Rec."GTB Color");
        CurrPage.CfGTBBorderColor.SetValue('Gantt Task Bar Border Color', Rec."GTB Border Color");
        CurrPage.CfGTBProgressColor.SetValue('Gantt Task Bar Progress Color', Rec."GTB Progress Color");
        CurrPage.CfGTBFontColor.SetValue('Gantt Task Bar Font Color', Rec."GTB Font Color");
        CurrPage.CfTooltipBackgroundColor.SetValue('Tooltip Background Color', Rec."Tooltip Background Color");
        CurrPage.CfTooltipFontColor.SetValue('Tooltip Font Color', Rec."Tooltip Font Color");
        CurrPage.CfFreeCapacityColor.SetValue('Free Capacity Color', Rec."Free Capacity Color");
        CurrPage.CfFreeCapacityMandatoryColor.SetValue('Free Capacity (Mandatory) Color', Rec."Free Capacity-Mandatory Color");
        CurrPage.CfCapacityBorderColor.SetValue('Capacity Border Color', Rec."Capacity Border Color");
        CurrPage.CfExternalBorderColor.SetValue('External Border Color', Rec."External Border Color");
        CurrPage.CfEnvelopeColor.SetValue('Envelope Color', Rec."Envelope Color");
        CurrPage.CfEnvelopeBorderColor.SetValue('Envelope Border Color', Rec."Envelope Border Color");
        CurrPage.CfAssignedColor.SetValue('Assigned Color', Rec."Assigned Color");
    end;

    local procedure PickColor(var ColorValue: Text[20])
    var
        ColorPickerPage: Page "Color Picker Lookup";
    begin
        ColorPickerPage.SetInitialColor(ColorValue);
        if ColorPickerPage.RunModal() = Action::OK then begin
            ColorValue := CopyStr(ColorPickerPage.GetSelectedColor(), 1, MaxStrLen(ColorValue));
            Rec.Modify(true);
            PushColorFields();
        end;
    end;

    local procedure ResetColor(var ColorValue: Text[20]; DefaultValue: Text)
    begin
        ColorValue := CopyStr(DefaultValue, 1, MaxStrLen(ColorValue));
        Rec.Modify(true);
        PushColorFields();
    end;

    local procedure ClearColor(var ColorValue: Text[20])
    begin
        ColorValue := '';
        Rec.Modify(true);
        PushColorFields();
    end;

    var
        ColorFieldsReadyCount: Integer;
        VisualDefaultSettings: Codeunit "Visual Default Settings";
}