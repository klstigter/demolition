codeunit 50604 "DHX Data Handler"
{
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;

    procedure GetYUnitElementsJSON(StartDate: Date; EndDate: Date): Text
    // var
    //     elements: Text;
    // begin
    //     elements :=
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
    //     exit(elements);

    // end;
    var
        Jobs: Record Job;
        JobTasks: Record "Job Task";
        JobObject: JsonObject;
        TaskObject: JsonObject;
        ChildrenArray: JsonArray;
        Root: JsonObject;
        DataArray: JsonArray;
        OutText: Text;
    begin
        Clear(DataArray);

        Jobs.Reset();
        if Jobs.FindSet() then begin
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
        end;

        Clear(Root);
        Root.Add('data', DataArray);

        // Write JSON to text
        Root.WriteTo(OutText);
        exit(OutText);
    end;
}