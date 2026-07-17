codeunit 50686 "Resource Absence Mgt."
{
    // Owns every Absence business rule for table 160 "Res. Capacity Entry" rows with
    // Type = Absence. The Resource Absence Card (page 50685) calls ValidateAndPrepareAbsence
    // on both insert and modify of an Absence row; the delete-protection guard below runs
    // automatically whenever a Capacity row is deleted anywhere in the system.

    trigger OnRun()
    begin
    end;

    /// <summary>
    /// Validates a Resource Absence entry (positive Hours, mandatory reason, a matching
    /// Capacity row must exist, and the cumulative absence for that Resource/Date/Duplicate Id
    /// may not exceed the matched Capacity row's Capacity) and prepares the record for
    /// Insert/Modify: sets Type = Absence, copies "Duplicate Id" from the matched Capacity
    /// row, and writes -Hours into the Capacity field.
    /// </summary>
    procedure ValidateAndPrepareAbsence(var ResCapacityEntry: Record "Res. Capacity Entry"; Hours: Decimal)
    var
        CapacityEntry: Record "Res. Capacity Entry";
        AbsenceEntry: Record "Res. Capacity Entry";
        ExistingAbsenceHours: Decimal;
        RemainingCapacity: Decimal;
    begin
        if Hours <= 0 then
            Error(HoursMustBePositiveErr);

        if ResCapacityEntry."Absence Reason Code" = '' then
            Error(ReasonMandatoryErr);

        // 5.1 Existing-capacity guard: find the matching Capacity row for this Resource/Date.
        CapacityEntry.SetRange("Resource No.", ResCapacityEntry."Resource No.");
        CapacityEntry.SetRange(Date, ResCapacityEntry.Date);
        CapacityEntry.SetRange(Type, CapacityEntry.Type::Capacity);
        CapacityEntry.SetFilter(Capacity, '>%1', 0);
        if not CapacityEntry.FindFirst() then
            Error(NoCapacityErr, ResCapacityEntry."Resource No.", ResCapacityEntry.Date);

        // 5.4 Overshoot guard: cumulative, against ALL existing Absence rows for the same
        // Resource/Date/Duplicate Id (multiple Absence rows per day are allowed), excluding
        // this row's own current value when we are modifying an existing Absence entry.
        AbsenceEntry.SetRange("Resource No.", ResCapacityEntry."Resource No.");
        AbsenceEntry.SetRange(Date, ResCapacityEntry.Date);
        AbsenceEntry.SetRange("Duplicate Id", CapacityEntry."Duplicate Id");
        AbsenceEntry.SetRange(Type, AbsenceEntry.Type::Absence);
        if ResCapacityEntry."Entry No." <> 0 then
            AbsenceEntry.SetFilter("Entry No.", '<>%1', ResCapacityEntry."Entry No.");
        AbsenceEntry.CalcSums(Capacity);
        ExistingAbsenceHours := -AbsenceEntry.Capacity;

        if (ExistingAbsenceHours + Hours) > CapacityEntry.Capacity then begin
            RemainingCapacity := CapacityEntry.Capacity - ExistingAbsenceHours;
            Error(OvershootErr, Hours, RemainingCapacity, CapacityEntry.Capacity, ResCapacityEntry."Resource No.", ResCapacityEntry.Date);
        end;

        // 5.2 Sign convention + 5.3 Duplicate Id inheritance.
        ResCapacityEntry.Type := ResCapacityEntry.Type::Absence;
        ResCapacityEntry."Duplicate Id" := CapacityEntry."Duplicate Id";
        ResCapacityEntry.Capacity := -Hours;
    end;

    // 5.5 Delete protection: block deleting a Capacity row while an Absence row still
    // exists for the same Resource No. + Date + Duplicate Id. Only applies to Capacity
    // rows - deleting an Absence row itself is never blocked here.
    [EventSubscriber(ObjectType::Table, Database::"Res. Capacity Entry", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure ResCapacityEntry_OnBeforeDeleteEvent(var Rec: Record "Res. Capacity Entry"; RunTrigger: Boolean)
    var
        AbsenceEntry: Record "Res. Capacity Entry";
    begin
        if Rec.IsTemporary() then
            exit;
        if Rec.Type <> Rec.Type::Capacity then
            exit;

        AbsenceEntry.SetRange("Resource No.", Rec."Resource No.");
        AbsenceEntry.SetRange(Date, Rec.Date);
        AbsenceEntry.SetRange("Duplicate Id", Rec."Duplicate Id");
        AbsenceEntry.SetRange(Type, AbsenceEntry.Type::Absence);
        if not AbsenceEntry.IsEmpty() then
            Error(DeleteBlockedErr, Rec."Resource No.", Rec.Date);
    end;

    var
#pragma warning disable AA0074
        HoursMustBePositiveErr: Label 'Hours must be greater than 0.';
        ReasonMandatoryErr: Label 'You must specify an Absence Reason.';
#pragma warning disable AA0470
        NoCapacityErr: Label 'Resource %1 has no capacity recorded for %2. Register capacity before recording an absence.';
        OvershootErr: Label 'Absence hours (%1) would exceed the remaining capacity (%2 of %3) for resource %4 on %5.';
        DeleteBlockedErr: Label 'Cannot delete this capacity entry for resource %1 on %2 because absence entries are still registered against it. Remove the absence entries first.';
#pragma warning restore AA0470
#pragma warning restore AA0074
}
