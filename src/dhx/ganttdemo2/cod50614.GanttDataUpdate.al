codeunit 50615 "Gantt Update Data"
{
    procedure UpdateJobTaskFromJson(JsonText: Text): Boolean
    var
        JobTask: Record "Job Task";
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JobNo: Code[20];
        JobTaskNo: Code[20];
        Description: Text[100];
    begin
        if not JsonObject.ReadFrom(JsonText) then
            exit(false);

        // Extract Job No. and Job Task No. from the 'id' field or separate fields
        if JsonObject.Get('bcJobNo', JsonToken) then
            JobNo := CopyStr(JsonToken.AsValue().AsCode(), 1, MaxStrLen(JobNo));

        if JsonObject.Get('bcJobTaskNo', JsonToken) then
            JobTaskNo := CopyStr(JsonToken.AsValue().AsCode(), 1, MaxStrLen(JobTaskNo));

        if not JobTask.Get(JobNo, JobTaskNo) then
            exit(false);

        // Update description
        if JsonObject.Get('text', JsonToken) then begin
            Description := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(Description));
            JobTask.Description := Description;
        end;

        JobTask.Modify(true);
        exit(true);
    end;
}