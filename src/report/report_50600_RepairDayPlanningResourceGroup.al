report 50600 "RepairData"
{
    Permissions = tabledata "Day Planning" = rim,
                  tabledata "Res. Capacity Entry" = rimd,
                  tabledata Resource = rim,
                  tabledata Vendor = r,
                  tabledata "Resource Skill" = rim,
                  tabledata "Skill Code" = r,
                  tabledata "Job Task" = rim;
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Repair Data';
    ProcessingOnly = true;

    dataset
    {

    }

    trigger OnPreReport()
    begin

    end;
}
