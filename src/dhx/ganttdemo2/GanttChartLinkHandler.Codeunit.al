codeunit 50616 "Gantt Chart Link Handler"
{
    // -------------------------------------------------------
    // Handles all CRUD operations for:
    //   - BCG Gantt Task Link  (dependency links between tasks)
    //   - Job Task constraints (date boundary per task)
    //
    // Task ID convention (dhtmlx <-> BC):
    //   dhtmlx id  = "JobNo|JobTaskNo"  e.g. "DEMO001|1000"
    //   link type  = "0"=FS, "1"=SS, "2"=FF, "3"=SF
    //   date fmt   = "YYYY-MM-DD"
    // -------------------------------------------------------

    var
        GenUtils: Codeunit "General Planning Utilities";

    // =======================================================
    // LINKS  –  BC -> dhtmlx
    // =======================================================

    /// <summary>
    /// Returns all links for a given Job as a JSON array ready for dhtmlx.
    /// Shape: [{ id, source, target, type, lag }, ...]
    /// </summary>
    procedure GetLinksAsJson(JobNoFilter: Code[20]): Text
    var
        GanttLink: Record "BCG Gantt Task Link";
        LinkArray: JsonArray;
        LinkObj: JsonObject;
        Result: Text;
    begin
        // Only filter when a specific job filter is set;
        // empty filter means load all jobs
        if JobNoFilter <> '' then
            GanttLink.SetFilter("Job No.", JobNoFilter);
        if not GanttLink.FindSet() then begin
            LinkArray.WriteTo(Result);
            exit(Result);
        end;

        repeat
            Clear(LinkObj);
            // Composite link id: source_target_type — unique and reconstructable
            LinkObj.Add('id', BuildLinkId(GanttLink));
            LinkObj.Add('source', BuildTaskId(GanttLink."Job No.", GanttLink."Source Task No."));
            LinkObj.Add('target', BuildTaskId(GanttLink."Job No.", GanttLink."Target Task No."));
            LinkObj.Add('type', Format(GanttLink."Link Type".AsInteger()));
            LinkObj.Add('lag', GanttLink."Lag (Days)");
            LinkArray.Add(LinkObj);
        until GanttLink.Next() = 0;

        LinkArray.WriteTo(Result);
        exit(Result);
    end;

    // =======================================================
    // LINKS  –  dhtmlx -> BC  (OnLinkCreated / OnLinkUpdated)
    // =======================================================

    /// <summary>
    /// Creates or updates a link record from a dhtmlx link JSON.
    /// Expected JSON: { id, source, target, type, lag? }
    /// Returns true on success.
    /// </summary>
    procedure UpsertLinkFromJson(LinkJsonTxt: Text): Boolean
    var
        GanttLink: Record "BCG Gantt Task Link";
        JsonObj: JsonObject;
        JsonToken: JsonToken;
        JobNo: Code[20];
        SourceTaskNo: Code[20];
        TargetTaskNo: Code[20];
        TargetJobNo: Code[20];
        LinkTypeInt: Integer;
        LagDays: Integer;
        LinkTypeEnum: Enum "BCG Gantt Link Type";
    begin
        if not JsonObj.ReadFrom(LinkJsonTxt) then
            exit(false);

        // source  →  "JobNo|TaskNo"
        if not JsonObj.Get('source', JsonToken) then
            exit(false);
        if not ParseTaskId(JsonToken.AsValue().AsText(), JobNo, SourceTaskNo) then
            exit(false);

        // target  →  "JobNo|TaskNo"  (must be same job)
        if not JsonObj.Get('target', JsonToken) then
            exit(false);
        if not ParseTaskId(JsonToken.AsValue().AsText(), TargetJobNo, TargetTaskNo) then
            exit(false);

        if JobNo <> TargetJobNo then
            exit(false);  // cross-job links not supported

        if SourceTaskNo = TargetTaskNo then
            exit(false);  // self-link not allowed

        // link type (default: 0 = Finish-to-Start)
        if JsonObj.Get('type', JsonToken) then begin
            if not Evaluate(LinkTypeInt, JsonToken.AsValue().AsText()) then
                LinkTypeInt := 0;
        end else
            LinkTypeInt := 0;

        // lag (default: 0)
        if JsonObj.Get('lag', JsonToken) then begin
            if not Evaluate(LagDays, JsonToken.AsValue().AsText()) then
                LagDays := 0;
        end else
            LagDays := 0;

        LinkTypeEnum := Enum::"BCG Gantt Link Type".FromInteger(LinkTypeInt);

        if GanttLink.Get(JobNo, SourceTaskNo, TargetTaskNo, LinkTypeEnum) then begin
            // Update existing
            GanttLink."Lag (Days)" := LagDays;
            GanttLink.Modify(true);
        end else begin
            // Insert new
            GanttLink.Init();
            GanttLink."Job No." := JobNo;
            GanttLink."Source Task No." := SourceTaskNo;
            GanttLink."Target Task No." := TargetTaskNo;
            GanttLink."Link Type" := LinkTypeEnum;
            GanttLink."Lag (Days)" := LagDays;
            GanttLink.Insert(true);
        end;

        exit(true);
    end;

    // =======================================================
    // LINKS  –  dhtmlx -> BC  (OnLinkDeleted)
    // =======================================================

    /// <summary>
    /// Deletes a link from BC based on a dhtmlx link JSON.
    /// Expected JSON: { source, target, type }
    /// Returns true if the record was found and deleted.
    /// </summary>
    procedure DeleteLinkFromJson(LinkJsonTxt: Text): Boolean
    var
        GanttLink: Record "BCG Gantt Task Link";
        JsonObj: JsonObject;
        JsonToken: JsonToken;
        JobNo: Code[20];
        SourceTaskNo: Code[20];
        TargetJobNo: Code[20];
        TargetTaskNo: Code[20];
        LinkTypeInt: Integer;
    begin
        if not JsonObj.ReadFrom(LinkJsonTxt) then
            exit(false);

        if not JsonObj.Get('source', JsonToken) then
            exit(false);
        if not ParseTaskId(JsonToken.AsValue().AsText(), JobNo, SourceTaskNo) then
            exit(false);

        if not JsonObj.Get('target', JsonToken) then
            exit(false);
        if not ParseTaskId(JsonToken.AsValue().AsText(), TargetJobNo, TargetTaskNo) then
            exit(false);

        if JsonObj.Get('type', JsonToken) then begin
            if not Evaluate(LinkTypeInt, JsonToken.AsValue().AsText()) then
                LinkTypeInt := 0;
        end else
            LinkTypeInt := 0;

        if GanttLink.Get(JobNo, SourceTaskNo, TargetTaskNo, Enum::"BCG Gantt Link Type".FromInteger(LinkTypeInt)) then begin
            GanttLink.Delete(true);
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Deletes all links associated with a Job.
    /// Call this before deleting the Job.
    /// </summary>
    procedure DeleteAllLinksForJob(JobNo: Code[20])
    var
        GanttLink: Record "BCG Gantt Task Link";
    begin
        GanttLink.SetRange("Job No.", JobNo);
        GanttLink.DeleteAll(true);
    end;

    /// <summary>
    /// Deletes all links where TaskNo is either source or target.
    /// Call this before deleting a Job Task.
    /// </summary>
    procedure DeleteLinksForTask(JobNo: Code[20]; TaskNo: Code[20])
    var
        GanttLink: Record "BCG Gantt Task Link";
    begin
        GanttLink.SetRange("Job No.", JobNo);
        GanttLink.SetRange("Source Task No.", TaskNo);
        GanttLink.DeleteAll(true);

        GanttLink.SetRange("Source Task No.");
        GanttLink.SetRange("Target Task No.", TaskNo);
        GanttLink.DeleteAll(true);
    end;

    // =======================================================
    // CONSTRAINTS  –  dhtmlx -> BC  (OnJobTaskUpdated)
    // =======================================================

    /// <summary>
    /// Reads constraint_type and constraint_date from a dhtmlx task JSON
    /// and persists them onto the matching Job Task record.
    /// Expected JSON fields: id ("JobNo|TaskNo"), constraint_type, constraint_date
    /// Returns true on success.
    /// </summary>
    procedure UpdateConstraintFromJson(TaskJsonTxt: Text): Boolean
    var
        JobTask: Record "Job Task";
        JsonObj: JsonObject;
        JsonToken: JsonToken;
        TaskId: Text;
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ConstraintTypeStr: Text;
        ConstraintDateTxt: Text;
        NewConstraintType: Enum "Gantt Constraint Type";
        NewConstraintDate: Date;
    begin
        if not JsonObj.ReadFrom(TaskJsonTxt) then
            exit(false);

        // Resolve task identity
        if not JsonObj.Get('id', JsonToken) then
            exit(false);
        TaskId := JsonToken.AsValue().AsText();
        if not ParseTaskId(TaskId, JobNo, JobTaskNo) then
            exit(false);

        if not JobTask.Get(JobNo, JobTaskNo) then
            exit(false);

        // Constraint type (dhtmlx string  →  BC enum)
        if JsonObj.Get('constraint_type', JsonToken) then begin
            ConstraintTypeStr := JsonToken.AsValue().AsText();
            NewConstraintType := MapDhtmlxToConstraintType(ConstraintTypeStr);
        end else
            NewConstraintType := Enum::"Gantt Constraint Type"::None;

        // Constraint date
        if JsonObj.Get('constraint_date', JsonToken) then begin
            ConstraintDateTxt := JsonToken.AsValue().AsText();
            if ConstraintDateTxt <> '' then
                NewConstraintDate := ParseDate(ConstraintDateTxt)
            else
                NewConstraintDate := 0D;
        end else
            NewConstraintDate := 0D;

        // Clear date when constraint is None
        if NewConstraintType = Enum::"Gantt Constraint Type"::None then
            NewConstraintDate := 0D;

        JobTask."Constraint Type" := NewConstraintType;
        JobTask."Constraint Date" := NewConstraintDate;

        // Hard constraint: MSO or MFO ignore dependency scheduling
        JobTask."Constraint Is Hard" :=
            NewConstraintType in [
                Enum::"Gantt Constraint Type"::"Must Start On",
                Enum::"Gantt Constraint Type"::"Must Finish On"
            ];

        JobTask.Modify(true);
        exit(true);
    end;

    // =======================================================
    // CONSTRAINTS  –  BC -> dhtmlx
    // =======================================================

    /// <summary>
    /// Returns constraint fields for a Job Task as a JSON object snippet.
    /// Shape: { constraint_type: "fnlt", constraint_date: "2026-03-15", constraint_is_hard: false }
    /// </summary>
    procedure GetConstraintAsJson(JobNo: Code[20]; JobTaskNo: Code[20]): Text
    var
        JobTask: Record "Job Task";
        JsonObj: JsonObject;
        Result: Text;
    begin
        if not JobTask.Get(JobNo, JobTaskNo) then
            exit('{}');

        JsonObj.Add('constraint_type', GenUtils.MapConstraintTypeToDhtmlx(JobTask."Constraint Type"));

        if (JobTask."Constraint Type" <> JobTask."Constraint Type"::None) and
           (JobTask."Constraint Date" <> 0D)
        then
            JsonObj.Add('constraint_date', FormatDate(JobTask."Constraint Date"))
        else
            JsonObj.Add('constraint_date', '');

        JsonObj.Add('constraint_is_hard', JobTask."Constraint Is Hard");

        JsonObj.WriteTo(Result);
        exit(Result);
    end;

    // =======================================================
    // MAPPING HELPERS
    // =======================================================

    /// <summary>
    /// Maps a dhtmlx constraint_type string to the BC enum value.
    /// </summary>
    procedure MapDhtmlxToConstraintType(DhtmlxStr: Text): Enum "Gantt Constraint Type"
    begin
        case LowerCase(DhtmlxStr) of
            'mso':
                exit(Enum::"Gantt Constraint Type"::"Must Start On");
            'mfo':
                exit(Enum::"Gantt Constraint Type"::"Must Finish On");
            'snet':
                exit(Enum::"Gantt Constraint Type"::"Start No Earlier Than");
            'snlt':
                exit(Enum::"Gantt Constraint Type"::"Start No Later Than");
            'fnet':
                exit(Enum::"Gantt Constraint Type"::"Finish No Earlier Than");
            'fnlt':
                exit(Enum::"Gantt Constraint Type"::"Finish No Later Than");
            else
                exit(Enum::"Gantt Constraint Type"::None);
        end;
    end;

    /// <summary>
    /// Builds the dhtmlx task id string from Job No. and Job Task No.
    /// Format: "JobNo|TaskNo"  e.g. "DEMO001|1000"
    /// </summary>
    procedure BuildTaskId(JobNo: Code[20]; TaskNo: Code[20]): Text
    begin
        exit(Format(JobNo) + '|' + Format(TaskNo));
    end;

    /// <summary>
    /// Splits a dhtmlx task id ("JobNo|TaskNo") back into its BC components.
    /// Returns false if the id is not in expected format.
    /// </summary>
    procedure ParseTaskId(TaskId: Text; var JobNo: Code[20]; var TaskNo: Code[20]): Boolean
    var
        PipePos: Integer;
    begin
        PipePos := StrPos(TaskId, '|');
        if PipePos = 0 then
            exit(false);

        JobNo := CopyStr(TaskId, 1, PipePos - 1);
        TaskNo := CopyStr(TaskId, PipePos + 1);
        exit((JobNo <> '') and (TaskNo <> ''));
    end;

    // =======================================================
    // INTERNAL HELPERS
    // =======================================================

    local procedure BuildLinkId(GanttLink: Record "BCG Gantt Task Link"): Text
    begin
        // Deterministic id: source_target_type  — matches composite PK
        exit(
            GanttLink."Job No." + '|' + GanttLink."Source Task No." + '_' +
            GanttLink."Target Task No." + '_' +
            Format(GanttLink."Link Type".AsInteger())
        );
    end;

    local procedure FormatDate(InputDate: Date): Text
    begin
        if InputDate = 0D then
            exit('');
        exit(Format(InputDate, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    local procedure ParseDate(DateText: Text): Date
    var
        Year: Integer;
        Month: Integer;
        Day: Integer;
        Parts: List of [Text];
    begin
        // Accepts  YYYY-MM-DD  (ISO format used by dhtmlx)
        if DateText = '' then
            exit(0D);

        Parts := DateText.Split('-');
        if Parts.Count <> 3 then
            exit(0D);

        if not Evaluate(Year, Parts.Get(1)) then exit(0D);
        if not Evaluate(Month, Parts.Get(2)) then exit(0D);
        if not Evaluate(Day, Parts.Get(3)) then exit(0D);

        exit(DMY2Date(Day, Month, Year));
    end;
}
