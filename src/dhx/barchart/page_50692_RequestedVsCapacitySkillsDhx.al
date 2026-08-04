page 50692 "Requested vs Capacity Skl Dhx"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    Caption = 'Skill Requested/Capacity';

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Filters';

                field(ResourceNoFilterCtrl; ResourceNoFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Resource No.';
                    TableRelation = Resource;
                    ToolTip = 'Specifies the resource to analyze. Leave blank to include all resources.';

                    trigger OnValidate()
                    begin
                        RefreshData();
                    end;
                }
                field(DateFromFilterCtrl; DateFromFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Date From';
                    ToolTip = 'Specifies the first plan date to include. Leave blank for no lower boundary.';

                    trigger OnValidate()
                    begin
                        RefreshData();
                    end;
                }
                field(DateToFilterCtrl; DateToFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Date To';
                    ToolTip = 'Specifies the last plan date to include. Leave blank for no upper boundary.';

                    trigger OnValidate()
                    begin
                        RefreshData();
                    end;
                }
                field(SkillCodeFilterCtrl; SkillCodeFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Skill Code';
                    TableRelation = "Skill Code";
                    ToolTip = 'Specifies the skill to analyze. Leave blank to include all skills.';

                    trigger OnValidate()
                    begin
                        RefreshData();
                    end;
                }
            }

            group(ChartGroup)
            {
                Caption = 'Requested Hours vs Capacity';

                usercontrol(DhxBarChart; DHXBarChartAddin)
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        ChartReady := true;
                        RefreshChart();
                    end;

                    trigger OnDataPointClicked(SkillCode: Text)
                    begin
                    end;
                }
            }
        }

        area(FactBoxes)
        {
            part(DataPart; "Skill Req. vs Capacity Part")
            {
                ApplicationArea = All;
                Caption = 'Requested vs Capacity per Skill';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshAction)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Recalculate the chart and the data list for the current filters.';

                trigger OnAction()
                begin
                    RefreshData();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(RefreshAction_Promoted; RefreshAction)
                {
                }
            }
        }
    }

    var
        Buffer: Record "Skill Req. vs Capacity Buffer" temporary;
        SkillCapacityAnalysisMgt: Codeunit "Skill Capacity Analysis Mgt.";
        ResourceNoFilter: Code[20];
        SkillCodeFilter: Code[10];
        DateFromFilter: Date;
        DateToFilter: Date;
        ChartReady: Boolean;
        RequestedHoursMeasureTxt: Label 'Requested Hours';

    trigger OnOpenPage()
    begin
        RefreshData();
    end;

    local procedure RefreshData()
    begin
        SkillCapacityAnalysisMgt.BuildSkillBuffer(Buffer, ResourceNoFilter, DateFromFilter, DateToFilter, SkillCodeFilter);
        CurrPage.DataPart.Page.LoadData(Buffer, ResourceNoFilter, DateFromFilter, DateToFilter);
        RefreshChart();
    end;

    // SERIES COLOURS - the native BusinessChart version of this page (formerly
    // src/page/page_50690_RequestedVsCapacitySkills.al) was superseded by this DHTMLX page and
    // removed; its long comment used to explain a "phantom Variance measure" workaround needed
    // because BusinessChart's fixed palette put Requested Hours and Capacity on adjacent grey
    // slots. That workaround does not apply here: the DHTMLX Suite Chart add-in lets every
    // series carry its own explicit colour (wrapper.js' RenderChart assigns
    // SERIES_COLOR_PALETTE[seriesIndex]), so there is no fixed-palette grey-collision problem.
    //
    // Table 50622 no longer has a separate Capacity field/column - codeunit 50662 now returns
    // the aggregate capacity total directly in "Requested Hours" on the synthetic "CAPACITY"
    // buffer row, alongside each real skill's own Requested Hours total on its own row. So a
    // single series built from Buffer."Requested Hours" already covers both: one bar per skill
    // category plus one capacity reference bar, never a paired Requested/Capacity bar per
    // category. wrapper.js' RenderChart renders however many series it is given (s0, s1, ...),
    // so dropping down to one series here needs no JS changes.
    local procedure RefreshChart()
    var
        ChartData: JsonObject;
        CategoriesArray: JsonArray;
        SeriesArray: JsonArray;
        RequestedSeries: JsonObject;
        RequestedValues: JsonArray;
        ChartDataJson: Text;
    begin
        if not ChartReady then
            exit;

        Clear(CategoriesArray);
        Clear(RequestedValues);

        Buffer.Reset();
        if Buffer.FindSet() then
            repeat
                CategoriesArray.Add(Buffer."Skill Code");
                RequestedValues.Add(Buffer."Requested Hours");
            until Buffer.Next() = 0;

        RequestedSeries.Add('name', RequestedHoursMeasureTxt);
        RequestedSeries.Add('values', RequestedValues);

        SeriesArray.Add(RequestedSeries);

        ChartData.Add('categories', CategoriesArray);
        ChartData.Add('series', SeriesArray);

        ChartData.WriteTo(ChartDataJson);
        CurrPage.DhxBarChart.LoadData(ChartDataJson);
    end;
}
