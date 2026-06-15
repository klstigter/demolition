report 50605 "Daily Capacity Balance Report"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = DailyCapacityBalanceReport;

    dataset
    {
        dataitem(Dates; Date)
        {
            dataitemtableview = sorting("Period Start") where("Period Type" = const(0));
            Column(TodayFormatted; Format(Today, 0, 4)) { }
            Column(CompanyName; COMPANYPROPERTY.DisplayName()) { }
            Column(ReportCaption; ReportCaption) { }
            Column(CurrReportPageNoCaption; CurrReportPageNoCaption) { }
            column(TaskDate; dates."Period Start") { }


            dataitem(DayPlanning; "Day Planning")
            {
                dataitemlink = "Task Date" = field("Period Start");
                dataitemlinkreference = Dates;

                dataitemtableview = sorting("Task Date");
                column(JobNo; JobDescription) { }
                column(JobTaskNo; JobTaskDescription) { }

                Column(DayLineNo; DayPlanning."Day Line No.") { }
                Column(PlanStatus; DayPlanning."Plan Status") { }


                dataitem(Dp; Integer)
                {
                    dataitemtableview = sorting(number) where(Number = filter(1 | 2));

                    Column(PlanningLineType; dp.number) { }
                    Column(PlanningLineTypeLable; PlanningLineTypeLable) { }
                    Column(ResNo; resource."No.") { }
                    Column(Hours; Hours) { }
                    Column(ResourceNo; ResourceNo) { }
                    Column(StartTm; StartTm) { }
                    Column(EndTim; EndTim) { }
                    Column(NonWorkingMinutes; NonWorkingMinutes) { }
                    Column(SortAmountType; Number) { }
                    Column(SortResourceGroup; SortResourceGroup) { }
                    Column(SortResourceGroupSqnc; SortResourceGroupSqnc) { }


                    trigger OnAfterGetRecord()
                    begin
                        case number of
                            2:
                                begin
                                    PlanningLineTypeLable := 'Assigned';
                                    Hours := Dayplanning."Assigned Hours";
                                    ResourceNo := DayPlanning."Assigned Resource No.";
                                    StartTm := dayplanning."Start Time Requested";
                                    EndTim := dayplanning."End Time Requested";
                                    NonWorkingMinutes := DayPlanning."Non Working Minutes";

                                    if not Resource.Get(DayPlanning."Assigned Resource No.") then
                                        clear(Resource);
                                end;
                            1:
                                begin
                                    PlanningLineTypeLable := 'Requested';
                                    Hours := dayplanning."Requested Hours";
                                    ResourceNo := DayPlanning."Requested Resource No.";
                                    StartTm := dayplanning."Start Time Requested";
                                    EndTim := dayplanning."End Time Requested";
                                    NonWorkingMinutes := DayPlanning."Non Working Minutes";

                                    if not Resource.Get(DayPlanning."Requested Resource No.") then
                                        clear(Resource);
                                end;
                        end;
                        case true of
                            Resource."is Pool" and resource."Mandatory Schedulling":
                                begin
                                    SortResourceGroup := 'FixedPool';
                                    SortResourceGroupSqnc := 2;
                                end;
                            Resource."is Pool":
                                begin
                                    SortResourceGroup := 'Pool';
                                    SortResourceGroupSqnc := 3;
                                end;
                            Resource."Vendor No." <> '':
                                begin
                                    SortResourceGroup := 'External';
                                    SortResourceGroupSqnc := 4;
                                end;
                            else begin
                                SortResourceGroup := 'Internal';
                                SortResourceGroupSqnc := 1;
                            end;
                        end;

                    end;


                }

                trigger OnAfterGetRecord()
                var
                begin

                end;

            }
        }
    }
    requestpage
    {
        AboutTitle = 'Teaching tip title';
        AboutText = 'Teaching tip content';
        layout
        {
            area(Content)
            {
                group(GroupName)
                {


                }
            }
        }
        trigger OnOpenPage()
        begin
            dates.FilterGroup(5);
            dates.setrange("Period Start", StartDateDataSet, EndDateDataSet);
            dates.FilterGroup(0);
        end;

    }

    rendering
    {
        layout(DailyCapacityBalanceReport)
        {
            Type = Rdlc;
            LayoutFile = 'src/report/50605 CapacityBalanceReport/DailyCapacityBalanceReport.rdlc';
        }
    }

    trigger OnPreReport()
    begin

    end;

    var
        Resource: Record Resource;
        ReportCaption: Label 'Resource Details Planning';
        CurrReportPageNoCaption: Label 'Page';
        JobDescription: Text;
        JobTaskDescription: Text;
        PlanningLineTypeLable: Text;
        Hours: Decimal;
        ResourceNo: Text;
        StartTm: Time;
        EndTim: Time;
        SortResourceGroup: Text;
        SortResourceGroupSqnc: Integer;
        NonWorkingMinutes: Integer;
        StartDateDataSet: Date;
        EndDateDataSet: Date;

    Procedure SetDataViewDateRange(StartDateDataSetp: Date; EndDateDataSetp: Date)
    begin
        StartDateDataSet := StartDateDataSetp;
        EndDateDataSet := EndDateDataSetp;
    end;
}