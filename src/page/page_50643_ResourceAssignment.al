page 50643 "Resource Assignment"
{
    PageType = Card;
    Caption = 'Resource Assignment';
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Filter';

                field(DateFilterField; DateReference)
                {
                    ApplicationArea = All;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the date used to determine the week shown. Defaults to today.';

                    trigger OnValidate()
                    begin
                        ApplyFilters(0D);
                    end;
                }
                field(ProjectFilterField; ProjectFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Project Filter';
                    TableRelation = Job;
                    ToolTip = 'Specifies the project to filter. Leave blank to show all projects.';

                    trigger OnValidate()
                    begin
                        ApplyFilters(0D);
                    end;
                }
                // field(WeekHeaderField; CurrPage.JobMatrixPart.PAGE.GetWeekHeader())
                // {
                //     ApplicationArea = All;
                //     Caption = 'Week';
                //     Editable = false;
                //     ToolTip = 'Shows the Mon–Sun dates of the displayed week.';
                // }
            }
            part(JobMatrixPart; "Res. Asgmt. Job Matrix")
            {
                ApplicationArea = All;
                Caption = 'Project';
                UpdatePropagation = Both;
            }
            part(DayTasksPart; "Res. Asgmt. Day Tasks")
            {
                ApplicationArea = All;
                Caption = 'Daytasks';
                UpdatePropagation = Both;
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
                ToolTip = 'Refresh the project list and day tasks.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    ApplyFilters(0D);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        DateReference := Today;
        ApplyFilters(0D);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        // Fired by UpdatePropagation = Both when:
        //   a) user moves to a different row in JobMatrixPart (SelectedDate = 0D → full week)
        //   b) OnAssistEdit on a day cell calls CurrPage.Update(false) (SelectedDate = specific day)
        UpdateDayTasksFilter(CurrPage.JobMatrixPart.PAGE.GetSelectedDate());
    end;

    var
        DateReference: Date;
        ProjectFilter: Code[20];

    local procedure ApplyFilters(ForceDate: Date)
    begin
        CurrPage.JobMatrixPart.PAGE.SetFilters(DateReference, ProjectFilter);
        UpdateDayTasksFilter(ForceDate);
    end;

    local procedure UpdateDayTasksFilter(ForceDate: Date)
    var
        SelectedJobNo: Code[20];
        DateFrom: Date;
        DateTo: Date;
    begin
        SelectedJobNo := CurrPage.JobMatrixPart.PAGE.GetCurrentJobNo();
        DateFrom := CurrPage.JobMatrixPart.PAGE.GetWeekDateFrom();
        DateTo := CurrPage.JobMatrixPart.PAGE.GetWeekDateTo();

        CurrPage.DayTasksPart.PAGE.SetFilters(SelectedJobNo, DateFrom, DateTo, ForceDate);
        CurrPage.DayTasksPart.PAGE.GoToFirst();
    end;
}