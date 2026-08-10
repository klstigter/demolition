/// <summary>
/// Batch "Set Capacity" report (Report 50661).
///
/// Combines two already-verified patterns in this codebase:
///  1. The per-date/per-duplicate-id capacity calculation from Page 50627
///     "Resource Capacity Settings Opt" (UpdateCapacity action) - see
///     src/page/page_6013_ResourceCapacitySettings.al - replicated here but run
///     across many resources (a real Resource dataitem) instead of a single Rec.
///  2. The multi-select filter lookup pattern from Report 50609 "Resource
///     Scheduler Filter" (fldResourceNo/fldSkill) - see
///     src/report/report_50609_ResourceSchedulerFilter.al, whose class doc-comment
///     documents in detail why "Page.SetSelectionFilter(RecordVar)" on an explicit
///     Page variable is the only proven-working approach (PAGE.RunModal(0, Record)
///     alone does NOT populate the selection filter - confirmed broken by live
///     testing). Copied verbatim for both Resource No. and Skill Codes below.
/// </summary>
report 50661 "Set Capacity opt."
{
    Caption = 'Set Capacity';
    ProcessingOnly = true;
    UseRequestPage = true;
    ApplicationArea = All;
    UsageCategory = None;

    dataset
    {
        dataitem(Resource; Resource)
        {
            DataItemTableView = SORTING("No.") WHERE("Blocked" = CONST(false));

            trigger OnPreDataItem()
            begin
                if StartDate = 0D then
                    Error(Text002);

                if EndDate = 0D then
                    Error(Text003);

                if StartDate > EndDate then
                    Error(Text000);

                if ResourceNoFilter <> '' then
                    Resource.SetFilter("No.", ResourceNoFilter);

                if Mandatory then
                    Resource.SetRange("Mandatory Schedulling", true);

                if not Confirm(Text005, false, StartDate, EndDate) then
                    CurrReport.Break();

                SetCalendar(CustomizedCalendarChange);
                ResourcesChanged := 0;
                TotalChangedDays := 0;
            end;

            trigger OnAfterGetRecord()
            var
                ResCapacityEntry: Record "Res. Capacity Entry";
                ResourceDaysChanged: Integer;
            begin
                // Filter by Resource Type (All/Internal/External), matching the
                // same boolean expression used in
                // src/dhx/barchart/codeunit_50662_SkillCapacityAnalysisMgt.al
                case ResourceTypeFilter of
                    ResourceTypeFilter::Internal:
                        if IsExternalResource(Resource) then
                            CurrReport.Skip();
                    ResourceTypeFilter::External:
                        if not IsExternalResource(Resource) then
                            CurrReport.Skip();
                end;

                // Filter by Skill Codes, if specified
                if SkillFilter <> '' then
                    if not ResourceHasMatchingSkill(Resource."No.") then
                        CurrReport.Skip();

                ResourceDaysChanged := UpdateCapacityForResource(Resource, CustomizedCalendarChange);
                if ResourceDaysChanged > 0 then begin
                    ResourcesChanged += 1;
                    TotalChangedDays += ResourceDaysChanged;
                end;
            end;

            trigger OnPostDataItem()
            begin
                if ResourcesChanged > 0 then
                    Message(Text006, ResourcesChanged, TotalChangedDays)
                else
                    Message(Text008);
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(FilterGroup)
                {
                    Caption = 'Filters';

                    field(fldMandatory; Mandatory)
                    {
                        ApplicationArea = All;
                        Caption = 'Mandatory';
                        ToolTip = 'When enabled, only resources flagged as Mandatory Scheduling are processed. When disabled, all resources are processed regardless of their Mandatory Scheduling flag.';
                    }
                    field(fldResourceNo; ResourceNoFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Resource No.';
                        ToolTip = 'Specifies the filter to apply on Resource No. Standard filter syntax is supported (e.g. wildcards, ranges, OR-lists), or use the lookup to multi-select resources.';
                        TableRelation = Resource;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            Resource: Record Resource;
                            ResourceList: Page "Resource List";
                            SelectionFilterManagement: Codeunit SelectionFilterManagement;
                        begin
                            Resource.SetFilter("No.", ResourceNoFilter);
                            ResourceList.SetTableView(Resource);
                            ResourceList.LookupMode(true);
                            if ResourceList.RunModal() = Action::LookupOK then begin
                                ResourceList.SetSelectionFilter(Resource);
                                Text := SelectionFilterManagement.GetSelectionFilterForResource(Resource);
                                exit(true);
                            end;
                            exit(false);
                        end;
                    }
                    field(fldResourceType; ResourceTypeFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Resource Type';
                        ToolTip = 'Specifies which resources are processed: All, only Internal, or only External (External/Pool/Pool Member).';
                    }
                    field(fldSkill; SkillFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Skill Codes';
                        ToolTip = 'Specifies the filter to apply on the resource''s assigned Skill Code. Standard filter syntax is supported (e.g. wildcards, ranges, OR-lists), or use the lookup to multi-select skill codes. When blank, resources are not filtered by skill.';
                        TableRelation = "Skill Code";

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            SkillCode: Record "Skill Code";
                            SkillCodeList: Page "Skill Codes";
                            SelectionFilterManagement: Codeunit SelectionFilterManagement;
                            RecRef: RecordRef;
                        begin
                            SkillCode.SetFilter(Code, SkillFilter);
                            SkillCodeList.SetTableView(SkillCode);
                            SkillCodeList.LookupMode(true);
                            if SkillCodeList.RunModal() = Action::LookupOK then begin
                                SkillCodeList.SetSelectionFilter(SkillCode);
                                RecRef.GetTable(SkillCode);
                                Text := SelectionFilterManagement.GetSelectionFilter(RecRef, SkillCode.FieldNo(Code));
                                exit(true);
                            end;
                            exit(false);
                        end;
                    }
                }
                group(Parameters)
                {
                    Caption = 'Capacity';

                    field(fldStartDate; StartDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Date From';
                        ToolTip = 'Specifies the starting date for the time period for which you want to change capacity.';
                    }
                    field(fldEndDate; EndDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Date To';
                        ToolTip = 'Specifies the end date relating to the resource capacity.';

                        trigger OnValidate()
                        begin
                            if (StartDate <> 0D) and (EndDate <> 0D) and (StartDate > EndDate) then
                                Error(Text000);
                        end;
                    }
                    field(fldWorkTemplateCode; WorkTemplateCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Work-Hour Template';
                        LookupPageID = "Work-Hour Templates";
                        TableRelation = "Work-Hour Template";
                        ToolTip = 'Specifies the work-hour template applied uniformly to every resource processed by this run.';

                        trigger OnValidate()
                        begin
                            ApplyWorkTemplateDefaults();
                        end;
                    }
                    field(fldStartTime; StartTime)
                    {
                        ApplicationArea = All;
                        Caption = 'Start Time';
                        ToolTip = 'Specifies the default start time for the resource working hours. Overrides the Work-Hour Template''s per-weekday hours when set together with End Time.';

                        trigger OnValidate()
                        begin
                            UseCustomTimes := true;
                        end;
                    }
                    field(fldEndTime; EndTime)
                    {
                        ApplicationArea = All;
                        Caption = 'End Time';
                        ToolTip = 'Specifies the default end time for the resource working hours. Overrides the Work-Hour Template''s per-weekday hours when set together with Start Time.';

                        trigger OnValidate()
                        begin
                            UseCustomTimes := true;
                        end;
                    }
                    field(fldNoOfDuplicates; NoOfDuplicates)
                    {
                        ApplicationArea = All;
                        Caption = 'Number of Duplicates';
                        ToolTip = 'Specifies the number of times you want to duplicate the capacity change.';

                        trigger OnValidate()
                        begin
                            if NoOfDuplicates < 1 then
                                NoOfDuplicates := 1;
                        end;
                    }
                }
            }
        }

        trigger OnOpenPage()
        var
            DailyOptimizerSetup: Record "Daily Optimizer Setup";
        begin
            Mandatory := true;
            ResourceTypeFilter := ResourceTypeFilter::All;
            NoOfDuplicates := 1;
            UseCustomTimes := false;

            if DailyOptimizerSetup.Get() and (DailyOptimizerSetup."Work hour Template" <> '') then begin
                WorkTemplateCode := DailyOptimizerSetup."Work hour Template";
                ApplyWorkTemplateDefaults();
            end;
        end;
    }

    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CalendarMgmt: Codeunit "Calendar Management";
        ResourceNoFilter: Text;
        SkillFilter: Text;
        WorkTemplateCode: Code[10];
        StartDate: Date;
        EndDate: Date;
        StartTime: Time;
        EndTime: Time;
        NoOfDuplicates: Integer;
        Mandatory: Boolean;
        UseCustomTimes: Boolean;
        ResourcesChanged: Integer;
        TotalChangedDays: Integer;
        ResourceTypeFilter: Option All,Internal,External;

#pragma warning disable AA0074
        Text000: Label 'The starting date is later than the ending date.';
        Text002: Label 'You must fill in the Date From field.';
        Text003: Label 'You must fill in the Date To field.';
#pragma warning disable AA0470
        Text005: Label 'Do you want to set/update capacity for the selected resources between %1 and %2?';
        Text006: Label 'Capacity was updated for %1 resource(s), %2 day(s) total.';
#pragma warning restore AA0470
        Text008: Label 'No resources were changed.';
#pragma warning restore AA0074

    local procedure ApplyWorkTemplateDefaults()
    var
        WorkTemplateRec: Record "Work-Hour Template";
    begin
        if WorkTemplateRec.Get(WorkTemplateCode) then begin
            StartTime := WorkTemplateRec."Default Start Time";
            EndTime := WorkTemplateRec."Default End Time";
        end;
    end;

    local procedure IsExternalResource(var Resource: Record Resource): Boolean
    begin
        exit(Resource."Is External" or Resource."Is Pool" or Resource."Is Pool Member");
    end;

    local procedure ResourceHasMatchingSkill(ResourceNo: Code[20]): Boolean
    var
        ResourceSkill: Record "Resource Skill";
    begin
        ResourceSkill.SetRange("No.", ResourceNo);
        ResourceSkill.SetRange(Type, ResourceSkill.Type::Resource);
        ResourceSkill.SetFilter("Skill Code", SkillFilter);
        exit(not ResourceSkill.IsEmpty());
    end;

    local procedure SetCalendar(var CustomizedCalendarChange: Record "Customized Calendar Change")
    var
        CompanyInformation: Record "Company Information";
    begin
        if CompanyInformation.Get() then begin
            CompanyInformation.TestField("Base Calendar Code");
            CalendarMgmt.SetSource(CompanyInformation, CustomizedCalendarChange);
        end;
    end;

    local procedure SelectCapacity(var WorkTemplateRec: Record "Work-Hour Template"; TargetDate: Date) Hours: Decimal
    begin
        case Date2DWY(TargetDate, 1) of
            1:
                Hours := WorkTemplateRec.Monday;
            2:
                Hours := WorkTemplateRec.Tuesday;
            3:
                Hours := WorkTemplateRec.Wednesday;
            4:
                Hours := WorkTemplateRec.Thursday;
            5:
                Hours := WorkTemplateRec.Friday;
            6:
                Hours := WorkTemplateRec.Saturday;
            7:
                Hours := WorkTemplateRec.Sunday;
        end;
    end;

    /// <summary>
    /// Batch version of Page 50627 "Resource Capacity Settings Opt"'s UpdateCapacity
    /// action, run for a single Resource. Returns the number of days that were
    /// actually changed for this resource.
    /// </summary>
    local procedure UpdateCapacityForResource(var Resource: Record Resource; var CustomizedCalendarChange: Record "Customized Calendar Change") ChangedDays: Integer
    var
        WorkTemplateRec: Record "Work-Hour Template";
        ResCapacityEntry: Record "Res. Capacity Entry";
        ResCapacityEntry2: Record "Res. Capacity Entry";
        TempDate: Date;
        TempCapacity: Decimal;
        NewCapacity: Decimal;
        LastEntry: Integer;
        LoopCounter: Integer;
        Holiday: Boolean;
        HasWorkTemplate: Boolean;
    begin
        HasWorkTemplate := WorkTemplateRec.Get(WorkTemplateCode);

        ChangedDays := 0;
        TempDate := StartDate;
        repeat
            Holiday := CalendarMgmt.IsNonworkingDay(TempDate, CustomizedCalendarChange);

            if Holiday then
                NewCapacity := 0
            else
                if UseCustomTimes and (StartTime <> 0T) and (EndTime <> 0T) then
                    NewCapacity := (EndTime - StartTime) / 3600000
                else
                    if HasWorkTemplate then
                        NewCapacity := SelectCapacity(WorkTemplateRec, TempDate)
                    else
                        NewCapacity := 0;

            if NewCapacity <> 0 then begin
                for LoopCounter := 1 to NoOfDuplicates do begin
                    ResCapacityEntry.Reset();
                    ResCapacityEntry.SetRange("Resource No.", Resource."No.");
                    ResCapacityEntry.SetRange(Date, TempDate);
                    ResCapacityEntry.SetRange("Duplicate Id", LoopCounter);
                    ResCapacityEntry.CalcSums(Capacity);
                    TempCapacity := ResCapacityEntry.Capacity;

                    ResCapacityEntry2.Reset();
                    if ResCapacityEntry2.FindLast() then;
                    LastEntry := ResCapacityEntry2."Entry No." + 1;
                    ResCapacityEntry2.Init();
                    ResCapacityEntry2."Entry No." := LastEntry;

                    ResCapacityEntry2.Capacity := NewCapacity - TempCapacity;
                    ResCapacityEntry2."Resource No." := Resource."No.";
                    ResCapacityEntry2."Resource Group No." := Resource."Resource Group No.";
                    ResCapacityEntry2.Date := TempDate;
                    ResCapacityEntry2."Duplicate Id" := LoopCounter;

                    //<< Same as page 50627's UpdateCapacity action
                    if UseCustomTimes and (StartTime <> 0T) then begin
                        ResCapacityEntry2."Start Time" := StartTime;
                        if EndTime <> 0T then
                            ResCapacityEntry2."End Time" := EndTime
                        else
                            ResCapacityEntry2."End Time" := StartTime + (Abs(ResCapacityEntry2.Capacity) * 3600000);
                    end else if HasWorkTemplate then begin
                        if WorkTemplateRec."Default Start Time" <> 0T then begin
                            ResCapacityEntry2."Start Time" := WorkTemplateRec."Default Start Time";
                            if WorkTemplateRec."Default End Time" <> 0T then
                                ResCapacityEntry2."End Time" := WorkTemplateRec."Default End Time"
                            else
                                ResCapacityEntry2."End Time" := WorkTemplateRec."Default Start Time" + (Abs(ResCapacityEntry2.Capacity) * 3600000);
                        end;
                    end;
                    //>>

                    if ResCapacityEntry2.Insert(true) then;
                end;
                ChangedDays += 1;
            end;
            TempDate := TempDate + 1;
        until TempDate > EndDate;
    end;
}
