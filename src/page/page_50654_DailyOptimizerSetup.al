page 50654 "Opti Daily Optimizer Setup"
{
    Caption = 'Daily Optimizer Setup';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Opti Daily Optimizer Setup";
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
                    ToolTip = 'Specifies the value of the Base Calendar field.';
                    ApplicationArea = All;
                }
                field("Work hour Template"; Rec."Work hour Template")
                {
                    ToolTip = 'Specifies the value of the Work hour Template field.';
                    ApplicationArea = All;
                }
                field("Default Skill"; Rec."Default Skill")
                {
                    ToolTip = 'Specifies the value of the Default Skill field.';
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
                        ToolTip = 'Specifies the value of the Resource Scheduler - List Type field.';
                        ApplicationArea = All;
                        caption = 'List Type';
                    }
                }
                group("Requested/Capacity")
                {
                    Caption = 'Requested/Capacity';

                    usercontrol(CfBarFontColor; "OptiDHXColorFieldAddin")
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

                    usercontrol(CfWeekendColor; "OptiDHXColorFieldAddin")
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
                    usercontrol(CfHolidayColor; "OptiDHXColorFieldAddin")
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

                    usercontrol(CfGTBColornonposting; "OptiDHXColorFieldAddin")
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
                    usercontrol(CfGTBColor; "OptiDHXColorFieldAddin")
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
                    usercontrol(CfGTBBorderColor; "OptiDHXColorFieldAddin")
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
                    usercontrol(CfGTBProgressColor; "OptiDHXColorFieldAddin")
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
                    usercontrol(CfGTBFontColor; "OptiDHXColorFieldAddin")
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

                    usercontrol(CfTooltipBackgroundColor; "OptiDHXColorFieldAddin")
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
                    usercontrol(CfTooltipFontColor; "OptiDHXColorFieldAddin")
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

                        usercontrol(CfFreeCapacityColor; "OptiDHXColorFieldAddin")
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
                        usercontrol(CfFreeCapacityMandatoryColor; "OptiDHXColorFieldAddin")
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
                        usercontrol(CfCapacityBorderColor; "OptiDHXColorFieldAddin")
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
                        usercontrol(CfExternalBorderColor; "OptiDHXColorFieldAddin")
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
                        usercontrol(CfCapacityFontColor; "OptiDHXColorFieldAddin")
                        {
                            ApplicationArea = All;

                            trigger ControlReady()
                            begin
                                ColorFieldReady();
                            end;

                            trigger OnPickRequested()
                            begin
                                PickColor(Rec."Capacity Font Color");
                            end;

                            trigger OnResetRequested()
                            begin
                                ResetColor(Rec."Capacity Font Color", VisualDefaultSettings.GetDefaultCapacityFontColor());
                            end;

                            trigger OnClearRequested()
                            begin
                                ClearColor(Rec."Capacity Font Color");
                            end;
                        }
                    }

                    group(Envelope)
                    {
                        Caption = 'Envelope';

                        usercontrol(CfEnvelopeColor; "OptiDHXColorFieldAddin")
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
                        usercontrol(CfEnvelopeBorderColor; "OptiDHXColorFieldAddin")
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

                            usercontrol(CfAssignedColor; "OptiDHXColorFieldAddin")
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
                    ToolTip = 'Specifies the value of the Order Intake Nos field.';
                    ApplicationArea = All;
                }
                field("Work Order Nos"; Rec."Work Order Nos")
                {
                    ToolTip = 'Specifies the value of the Work Order Nos field.';
                    ApplicationArea = All;
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
                        VisualDefaultSettings: Codeunit "Opti Visual Default Settings";
                        ConfirmLbl: Label 'This will reset the Daily Optimizer Setup list type and colors back to their built-in defaults, overwriting any customizations.\\Continue?';
                    begin
                        if not Confirm(ConfirmLbl, false) then
                            exit;

                        Rec.Get();

                        Rec."Resource Scheduler - List Type" := Rec."Resource Scheduler - List Type"::"By Resource Group";
                        Rec."Assigned Color" := VisualDefaultSettings.GetDefaultAssignedColor();
                        Rec."Free Capacity Color" := VisualDefaultSettings.GetDefaultCapacityColor();
                        Rec."Free Capacity-Mandatory Color" := VisualDefaultSettings.GetDefaultCapacityMandatoryColor();
                        Rec."External Border Color" := VisualDefaultSettings.GetDefaultExternalBorderColor();
                        Rec."Capacity Border Color" := VisualDefaultSettings.GetDefaultCapacityBorderColor();
                        Rec."Capacity Font Color" := VisualDefaultSettings.GetDefaultCapacityFontColor();
                        Rec."Bar Font Color" := VisualDefaultSettings.GetDefaultBarFontColor();
                        Rec."Tooltip Background Color" := VisualDefaultSettings.GetDefaultTooltipBackgroundColor();
                        Rec."Tooltip Font Color" := VisualDefaultSettings.GetDefaultTooltipFontColor();
                        Rec."Weekend Color" := VisualDefaultSettings.GetDefaultWeekendColor();
                        Rec."Holiday Color" := VisualDefaultSettings.GetDefaultHolidayColor();
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
            group(DemoData)
            {
                Caption = 'Demo Data';

                action(DeleteIncorrectDayPlanning)
                {
                    ApplicationArea = All;
                    Caption = 'Delete incorrect Dayplanning';
                    ToolTip = 'Delete unposted Day Planning lines that are missing a Skill or fall outside their Job Task''s planned date range.';
                    Image = RemoveLine;

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(Codeunit::"Opti Del. Incorrect Day Plan.");
                    end;
                }
                action(DemoScenarios)
                {
                    ApplicationArea = All;
                    Caption = 'Demo Scenarios';
                    ToolTip = 'Open the list of demo data scenarios.';
                    Image = List;
                    RunObject = page "Opti Demo Data Scenarios";
                }
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Actions';
                actionref(ResetToDefault_ref; ResetToDefault) { }
            }
            group(Category_DemoData)
            {
                Caption = 'Demo Data';
                actionref(DeleteIncorrectDayPlanning_ref; DeleteIncorrectDayPlanning) { }
                actionref(DemoScenarios_ref; DemoScenarios) { }
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
    var
        GTBProgressColorTooltipLbl: Label 'Progress colour: blank means the Gantt darkens each task''s own fill colour. If someone sets a colour, it applies to every bar.';
    begin
        CurrPage.CfBarFontColor.SetValue('Bar Font Color', Rec."Bar Font Color");
        CurrPage.CfWeekendColor.SetValue('Weekend Color', Rec."Weekend Color");
        CurrPage.CfHolidayColor.SetValue('Holiday Color', Rec."Holiday Color");
        CurrPage.CfGTBColornonposting.SetValue('Gantt Task Bar Color (Non-Posting)', Rec."GTB Color (non posting)");
        CurrPage.CfGTBColor.SetValue('Gantt Task Bar Color', Rec."GTB Color");
        CurrPage.CfGTBBorderColor.SetValue('Gantt Task Bar Border Color', Rec."GTB Border Color");
        CurrPage.CfGTBProgressColor.SetTooltip(GTBProgressColorTooltipLbl);
        CurrPage.CfGTBProgressColor.SetValue('Gantt Task Bar Progress Color', Rec."GTB Progress Color");
        CurrPage.CfGTBFontColor.SetValue('Gantt Task Bar Font Color', Rec."GTB Font Color");
        CurrPage.CfTooltipBackgroundColor.SetValue('Tooltip Background Color', Rec."Tooltip Background Color");
        CurrPage.CfTooltipFontColor.SetValue('Tooltip Font Color', Rec."Tooltip Font Color");
        CurrPage.CfFreeCapacityColor.SetValue('Free Capacity Color', Rec."Free Capacity Color");
        CurrPage.CfFreeCapacityMandatoryColor.SetValue('Free Capacity (Mandatory) Color', Rec."Free Capacity-Mandatory Color");
        CurrPage.CfCapacityBorderColor.SetValue('Capacity Border Color', Rec."Capacity Border Color");
        CurrPage.CfExternalBorderColor.SetValue('External Border Color', Rec."External Border Color");
        CurrPage.CfCapacityFontColor.SetValue('Capacity Font Color', Rec."Capacity Font Color");
        CurrPage.CfEnvelopeColor.SetValue('Envelope Color', Rec."Envelope Color");
        CurrPage.CfEnvelopeBorderColor.SetValue('Envelope Border Color', Rec."Envelope Border Color");
        CurrPage.CfAssignedColor.SetValue('Assigned Color', Rec."Assigned Color");
    end;

    local procedure PickColor(var ColorValue: Text[20])
    var
        ColorPickerPage: Page "Opti Color Picker Lookup";
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
        VisualDefaultSettings: Codeunit "Opti Visual Default Settings";
}