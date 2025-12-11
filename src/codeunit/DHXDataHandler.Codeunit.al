codeunit 50604 "DHX Data Handler"
{
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;

    //     '{' +
    //         '"data": [ ' +
    //             '{key:10, label:"Web Testing Dep.", open: true, children: [' +
    //             '    {key:20, label:"Elizabeth Taylor"},' +
    //             '    {key:30, label:"Managers", open: true, children: [' +
    //             '        {key:40, label:"John Williams"},' +
    //             '        {key:50, label:"David Miller"}' +
    //             '    ]},' +
    //             '    {key:60, label:"Linda Brown"},' +
    //             '    {key:70, label:"George Lucas"}' +
    //             ']},' +
    //             '{key:80, label:"Kate Moss"},' +
    //             '{key:90, label:"Dian Fossey"}' +
    //         ']' +
    //     '}';
    procedure GetYUnitElementsJSON(StartDate: Date;
                                   EndDate: Date;
                                   var PlanninJsonTxt: Text;
                                   var EarliestPlanningDate: Date): Text
    var
        Jobs: Record Job;
        JobTasks: Record "Job Task";
        Planning: Record "Job Planning Line";

        JobObject: JsonObject;
        TaskObject: JsonObject;
        ChildrenArray: JsonArray;
        PlanningObject, Root : JsonObject;
        PlanningArray, DataArray : JsonArray;
        OutText: Text;

        StartDateTxt: Text;
        EndDateTxt: Text;
    begin
        PlanninJsonTxt := '';
        //Marking Job based on Job Planning Lines within the given date range
        Planning.SetRange("Planning Date", StartDate, EndDate);
        Planning.SetFilter("Job No.", '<>%1', ''); //Exclude blank Job Nos
        Planning.SetRange(Type, Planning.Type::Resource);
        if Planning.FindSet() then begin
            repeat
                Jobs.Get(Planning."Job No.");
                Jobs.Mark(true);
                // create event data
                if EarliestPlanningDate < Planning."Planning Date" then
                    EarliestPlanningDate := Planning."Planning Date";
                GetStartEndTxt(Planning, StartDateTxt, EndDateTxt);
                Clear(PlanningObject);
                PlanningObject.Add('id', Planning."Job No." + '|' + Planning."Job Task No." + '|' + Format(Planning."Line No."));
                PlanningObject.Add('start_date', StartDateTxt);
                PlanningObject.Add('end_date', EndDateTxt);
                PlanningObject.Add('text', Planning.Description);
                PlanningObject.Add('section_id', Planning."Job No." + '|' + Planning."Job Task No.");
                PlanningArray.Add(PlanningObject);
                PlanningArray.WriteTo(PlanninJsonTxt);
            until Planning.Next() = 0;
        end;
        Jobs.MarkedOnly := true;
        if Jobs.FindSet() then begin
            Clear(DataArray);
            repeat
                JobTasks.SetRange("Job No.", Jobs."No.");
                JobTasks.SetRange("Job Task Type", JobTasks."Job Task Type"::Posting);

                Clear(JobObject);
                JobObject.Add('key', Jobs."No."); // string keys are fine
                JobObject.Add('label', StrSubstNo('%1 - %2', Jobs."No.", Jobs.Description));
                JobObject.Add('open', true);

                Clear(ChildrenArray);
                if JobTasks.FindSet() then begin
                    repeat
                        Clear(TaskObject);
                        TaskObject.Add('key', Jobs."No." + '|' + JobTasks."Job Task No.");
                        TaskObject.Add('label', StrSubstNo('%1 - %2', JobTasks."Job Task No.", JobTasks.Description));
                        ChildrenArray.Add(TaskObject);
                    until JobTasks.Next() = 0;
                end;

                JobObject.Add('children', ChildrenArray);
                DataArray.Add(JobObject);
            until Jobs.Next() = 0;
            Clear(Root);
            Root.Add('data', DataArray);

            // Write JSON to text
            Root.WriteTo(OutText);
            exit(OutText);
        end;
        exit('');
    end;

    local procedure GetStartEndTxt(JobPlaningLine: Record "Job Planning Line";
                                   var StartDateTxt: Text;
                                   var EndDateTxt: Text)
    var
    begin
        StartDateTxt := '';
        EndDateTxt := '';
        case true of
            (JobPlaningLine."Planning Date" <> 0D) and (JobPlaningLine."Start Time" <> 0T):
                StartDateTxt := Format(JobPlaningLine."Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' ' + Format(JobPlaningLine."Start Time");
            (JobPlaningLine."Planning Date" <> 0D) and (JobPlaningLine."Start Time" = 0T):
                StartDateTxt := Format(JobPlaningLine."Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
            (JobPlaningLine."Planning Date" = 0D) and (JobPlaningLine."Start Time" <> 0T),
            (JobPlaningLine."Planning Date" = 0D) and (JobPlaningLine."Start Time" = 0T):
                StartDateTxt := '';
        end;

        case true of
            (JobPlaningLine."End Planning Date" = 0D) and (JobPlaningLine."End Time" <> 0T):
                EndDateTxt := Format(JobPlaningLine."Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' ' + Format(JobPlaningLine."End Time");
            (JobPlaningLine."End Planning Date" <> 0D) and (JobPlaningLine."End Time" <> 0T):
                EndDateTxt := Format(JobPlaningLine."End Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' ' + Format(JobPlaningLine."End Time");
            (JobPlaningLine."End Planning Date" = 0D) and (JobPlaningLine."End Time" = 0T):
                EndDateTxt := Format(JobPlaningLine."Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
            (JobPlaningLine."End Planning Date" <> 0D) and (JobPlaningLine."End Time" = 0T):
                EndDateTxt := Format(JobPlaningLine."End Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
        end;
    end;

    procedure GetOneYearPeriodDates(CurrentDate: Date; var StartDate: Date; var EndDate: Date)
    begin
        StartDate := CalcDate('<-CY>', CurrentDate);
        EndDate := CalcDate('<CY>', CurrentDate)
    end;
}