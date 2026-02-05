report 50600 "RepairData"
{
    Permissions = tabledata "Day Tasks" = rimd,
                  tabledata Resource = rimd,
                  tabledata "Res. Capacity Entry" = rimd;
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Repair Data';
    ProcessingOnly = true;

    dataset
    {

    }

    // trigger OnPreReport()
    // var
    //     DayTasks: Record "Day Tasks";
    //     Resource: Record Resource;
    //     NCounter: Integer;
    // begin
    //     DayTasks.Reset();
    //     DayTasks.SetRange(Type, DayTasks.Type::Resource);
    //     DayTasks.SetFilter("No.", '<>%1', '');
    //     if DayTasks.FindSet() then begin
    //         repeat
    //             Resource.Get(DayTasks."No.");
    //             DayTasks.Validate("Resource Group No.", Resource."Resource Group No.");
    //             DayTasks."Vendor No." := Resource."Vendor No.";
    //             DayTasks.CalculateWorkingHours();
    //             DayTasks.Modify(true);
    //             NCounter += 1;
    //         until DayTasks.Next() = 0;
    //     end;
    //     Message('Total %1 Day Task records repaired.', NCounter);
    // end;

    trigger OnPreReport()
    var
        ResourceCapEntry: Record "Res. Capacity Entry";
    begin
        ResourceCapEntry.SetFilter(Date, '>=%1', DMY2Date(1, 2, 2026));
        if ResourceCapEntry.FindSet() then begin
            ResourceCapEntry.DeleteAll();
            Message('All Resource Capacity Entry records from 1-Feb-2026 have been deleted.');
        end else
            Message('No Resource Capacity Entry records found for deletion.');
    end;

    var
    //myInt: Integer;
}