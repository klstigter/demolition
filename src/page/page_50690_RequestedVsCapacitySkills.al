page 50690 "Requested vs Capacity (Skills)"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    Caption = 'Requested vs Capacity (Skills)';

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

                usercontrol(BusinessChart; BusinessChart)
                {
                    ApplicationArea = All;

                    trigger AddInReady()
                    begin
                        ChartReady := true;
                        RefreshChart();
                    end;

                    trigger Refresh()
                    begin
                        RefreshChart();
                    end;

                    trigger DataPointClicked(Point: JsonObject)
                    begin
                    end;

                    trigger DataPointDoubleClicked(Point: JsonObject)
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
        BusinessChartMgt: Codeunit "Business Chart";
        SkillCapacityAnalysisMgt: Codeunit "Skill Capacity Analysis Mgt.";
        ResourceNoFilter: Code[20];
        SkillCodeFilter: Code[10];
        DateFromFilter: Date;
        DateToFilter: Date;
        ChartReady: Boolean;
        RequestedHoursMeasureTxt: Label 'Requested Hours';
        CapacityMeasureTxt: Label 'Capacity';
        VarianceMeasureTxt: Label 'Variance';
        SkillDimensionTxt: Label 'Skill';

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

    // SERIES COLOURS - do not re-investigate, this is a platform constraint, not a bug here.
    // The BusinessChart add-in (System Application, Resources/BusinessChart/js/BusinessChartAddIn.js)
    // never sets a per-series colour. It hands Highcharts a fixed palette and lets Highcharts
    // assign palette[i] to series i, in AddMeasure registration order. Under the M365 theme
    // (createPalette() -> useModena365Theme() branch) palette[0] = "80% Ash grey", palette[1] =
    // "80% Ash grey 50%" (also grey), and palette[2] = "80% Tertiary shade 2" (teal). There is no
    // Color field or parameter on Codeunit "Business Chart", Table "Business Chart Buffer" or the
    // add-in, and the 2nd Variant argument of AddMeasure is only a drill-down tag (Business Chart
    // Impl. stores it in MeasureNameToValueMap), so it has no effect on colour.
    //
    // Requested Hours and Capacity are the two measures the user actually needs to tell apart, so
    // they must NOT land on the two adjacent grey slots. A third measure (Variance = Capacity -
    // Requested Hours) is registered BETWEEN them purely to absorb the grey[1] slot, pushing
    // Capacity onto the teal slot: Requested Hours -> palette[0] grey, Variance -> palette[1] grey,
    // Capacity -> palette[2] teal. Registration order is what matters here, not visual importance.
    local procedure RefreshChart()
    var
        XAxisIndex: Integer;
    begin
        if not ChartReady then
            exit;

        // Initialize() fully resets the chart state (clears the DataTable, its columns, the measure
        // list and MeasureNameToValueMap), so calling RefreshChart() repeatedly does not accumulate
        // or duplicate measures.
        BusinessChartMgt.Initialize();
        BusinessChartMgt.SetXDimension(SkillDimensionTxt, Enum::"Business Chart Data Type"::String);
        BusinessChartMgt.AddMeasure(RequestedHoursMeasureTxt, 1, Enum::"Business Chart Data Type"::Decimal, Enum::"Business Chart Type"::Column);
        BusinessChartMgt.AddMeasure(VarianceMeasureTxt, 2, Enum::"Business Chart Data Type"::Decimal, Enum::"Business Chart Type"::Column);
        BusinessChartMgt.AddMeasure(CapacityMeasureTxt, 3, Enum::"Business Chart Data Type"::Decimal, Enum::"Business Chart Type"::Column);

        Buffer.Reset();
        if Buffer.FindSet() then
            repeat
                BusinessChartMgt.AddDataRowWithXDimension(Buffer."Skill Code");
                BusinessChartMgt.SetValue(RequestedHoursMeasureTxt, XAxisIndex, Buffer."Requested Hours");
                BusinessChartMgt.SetValue(VarianceMeasureTxt, XAxisIndex, Buffer.Capacity - Buffer."Requested Hours");
                BusinessChartMgt.SetValue(CapacityMeasureTxt, XAxisIndex, Buffer.Capacity);
                XAxisIndex += 1;
            until Buffer.Next() = 0;

        BusinessChartMgt.Update(CurrPage.BusinessChart);
    end;
}
