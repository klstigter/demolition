page 50681 "Job Ledger Invoice Link"
{
    Caption = 'Job Ledger Invoice Link';
    PageType = List;
    SourceTable = "Job Ledger Invoice Link";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Job Ledger Entry No."; Rec."Job Ledger Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posted Job Ledger Entry (resource usage) that this link row traces back to.';
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the project that the usage entry belongs to.';
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the project task that the usage entry belongs to.';
                }
                field("Invoice Job Planning Line No."; Rec."Invoice Job Planning Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the billable Project Planning Line that this usage entry was rolled into.';

                    trigger OnDrillDown()
                    var
                        JobPlanningLine: Record "Job Planning Line";
                        JobPlanningLinesPage: Page "Job Planning Lines";
                    begin
                        JobPlanningLine.SetRange("Job No.", Rec."Job No.");
                        JobPlanningLine.SetRange("Job Task No.", Rec."Job Task No.");
                        JobPlanningLine.SetRange("Line No.", Rec."Invoice Job Planning Line No.");
                        if JobPlanningLine.FindFirst() then begin
                            JobPlanningLinesPage.SetRecord(JobPlanningLine);
                            JobPlanningLinesPage.SetTableView(JobPlanningLine);
                            JobPlanningLinesPage.Run();
                        end else
                            Message('The Project Planning Line that this usage entry was rolled into could not be found. It may have been deleted.');
                    end;
                }
                field("Skill Code"; Rec."Skill Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the skill that this usage entry originated from, for reporting purposes.';
                }
                field("Invoice Job Ledger Entry No."; Rec."Invoice Job Ledger Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posted Job Ledger Entry that was created for the invoice line that this usage entry was rolled into.';

                    trigger OnDrillDown()
                    var
                        JobLedgerEntry: Record "Job Ledger Entry";
                        JobLedgerEntriesPage: Page "Job Ledger Entries";
                    begin
                        if Rec."Invoice Job Ledger Entry No." = 0 then
                            exit;
                        if JobLedgerEntry.Get(Rec."Invoice Job Ledger Entry No.") then begin
                            JobLedgerEntriesPage.SetRecord(JobLedgerEntry);
                            JobLedgerEntriesPage.SetTableView(JobLedgerEntry);
                            JobLedgerEntriesPage.Run();
                        end else
                            Message('The Job Ledger Entry for the posted invoice could not be found.');
                    end;
                }
            }
        }
    }
}
