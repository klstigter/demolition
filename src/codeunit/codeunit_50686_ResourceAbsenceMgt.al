codeunit 50686 "Resource Absence Mgt."
{
    // Owns every Absence business rule for table 160 "Res. Capacity Entry" rows with
    // Type = Absence. PostRegisterAbsence (called from the "Register Absence" worksheet's
    // Post action) calls ValidateAndPrepareAbsence once per posted line; the delete-protection
    // guard below runs automatically whenever a Capacity row is deleted anywhere in the system.

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

    /// <summary>
    /// Posts every line CURRENTLY VISIBLE on the "Register Absence" worksheet (i.e. whatever
    /// filter is active on the page when Post is clicked - deliberately NOT Reset(), since this
    /// is a shared table and Post must never reach past the page's own filtered view into other
    /// unrelated rows sitting in the same table): fast field-specific mandatory checks (5.8),
    /// then reuses ValidateAndPrepareAbsence (unchanged, 5.1-5.4) to build and insert the posted
    /// "Res. Capacity Entry" Absence row, deleting the worksheet line once posted. No Commit()
    /// is issued, so a runtime Error() on any line rolls back the entire Post run via BC's
    /// ambient transaction (5.9).
    /// </summary>
    procedure PostRegisterAbsence(var RegisterAbsence: Record "Register Absence")
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
        LastResCapacityEntry: Record "Res. Capacity Entry";
        PostedCount: Integer;
    begin
        if RegisterAbsence.FindSet() then
            repeat
                // 5.8 Fast, field-specific mandatory checks (before the heavier business-rule validation).
                RegisterAbsence.TestField("Resource No.");
                RegisterAbsence.TestField(Date);
                RegisterAbsence.TestField("Absence Reason Code");
                RegisterAbsence.TestField(Hours);
                RegisterAbsence.CalcFields("Existing Capacity");
                if RegisterAbsence."Existing Capacity" <= 0 then
                    Error(NoExistingCapacityErr, RegisterAbsence."Resource No.", RegisterAbsence.Date);

                // Build the posted ledger row and reuse the existing, unchanged validation engine.
                ResCapacityEntry.Init();
                ResCapacityEntry."Resource No." := RegisterAbsence."Resource No.";
                ResCapacityEntry.Date := RegisterAbsence.Date;
                ResCapacityEntry."Absence Reason Code" := RegisterAbsence."Absence Reason Code";
                ValidateAndPrepareAbsence(ResCapacityEntry, RegisterAbsence.Hours);

                // "Entry No." has no AutoIncrement/Number Series on this table - every other
                // writer (e.g. page 50627's "Update Capacity" action) assigns it manually via
                // FindLast()+1, so this must match that same convention.
                LastResCapacityEntry.Reset();
                if LastResCapacityEntry.FindLast() then
                    ResCapacityEntry."Entry No." := LastResCapacityEntry."Entry No." + 1
                else
                    ResCapacityEntry."Entry No." := 1;

                ResCapacityEntry.Insert(true);

                RegisterAbsence.Delete();   // posted lines do not linger in the worksheet
                PostedCount += 1;
            until RegisterAbsence.Next() = 0;

        if PostedCount = 1 then
            Message(PostedOneMsg)
        else
            if PostedCount > 1 then
                Message(PostedManyMsg, PostedCount);
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
        NoExistingCapacityErr: Label 'Resource %1 has no remaining capacity left on %2 to offset this absence - either no capacity is registered for that date, or it has already been fully used by other posted absences.';
        PostedManyMsg: Label '%1 absence lines posted successfully.';
#pragma warning restore AA0470
        PostedOneMsg: Label '1 absence line posted successfully.';
#pragma warning restore AA0074
}
