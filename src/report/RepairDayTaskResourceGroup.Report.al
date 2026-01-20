report 50600 "RepairDayTaskResGroup"
{
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Repair Day Task Resource Group';
    ProcessingOnly = true;

    dataset
    {

    }

    trigger OnPreReport()
    var
        DayTasks: Record "Day Tasks";
        Resource: Record Resource;
        NCounter: Integer;
    begin
        DayTasks.Reset();
        DayTasks.SetRange(Type, DayTasks.Type::Resource);
        DayTasks.SetFilter("No.", '<>%1', '');
        if DayTasks.FindSet() then begin
            repeat
                Resource.Get(DayTasks."No.");
                DayTasks.Validate("Resource Group No.", Resource."Resource Group No.");
                DayTasks.Modify(true);
                NCounter += 1;
            until DayTasks.Next() = 0;
        end;
        Message('Total %1 Day Task records repaired.', NCounter);
    end;

    var
        myInt: Integer;
}