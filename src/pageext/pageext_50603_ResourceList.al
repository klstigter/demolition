pageextension 50603 "Opt ResourceList" extends "Resource List"
{
    layout
    {
        // Add changes to page layout here
        addafter(Type)
        {
            field("Pool Resource No."; Rec."Pool Resource No.")
            {
                ApplicationArea = All;
            }
            field("Vendor No."; Rec."Vendor No.")
            {
                ApplicationArea = All;
            }
            field("Is Pool"; Rec."Is Pool")
            {
                ApplicationArea = All;
            }
            field("Is Pool Member"; Rec."Is Pool Member")
            {
                ApplicationArea = All;
            }
            field("Is External"; Rec."Is External")
            {
                ApplicationArea = All;
            }
            field("Is Foreman"; Rec."Is Foreman")
            {
                ApplicationArea = All;
            }
            field("Mandatory Schedulling"; Rec."Mandatory Schedulling")
            {
                ApplicationArea = All;
            }
            field("Default Foreman"; Rec."Default Foreman")
            {
                ApplicationArea = All;
            }
            field("Default Foreman Name"; Rec."Default Foreman Name")
            {
                ApplicationArea = All;
            }

        }
    }

    actions
    {
        // Add changes to page actions here
        addafter("&Resource")
        {
            action("Schedule (Visual)")
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    ResScheduler: page "DHX Resource Scheduler";
                begin
                    ResScheduler.SetResourceFilter(GetSelectionFilter());
                    ResScheduler.RunModal();
                end;
            }
            action("DayPlannings (Visual)")
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    DayPlanningScheduler: page "DHX Scheduler (Project)";
                begin
                    DayPlanningScheduler.SetResourceFilter(GetSelectionFilter());
                    DayPlanningScheduler.RunModal();
                end;
            }
            action("Capacity (Visual)")
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    ResScheduler: page "DHX Scheduler (Pool Resource)";
                begin
                    //ResScheduler.SetResourceFilter(Rec."No.");
                    ResScheduler.RunModal();
                end;
            }
            action("Set Capacity Opt")
            {
                ApplicationArea = Jobs;
                Caption = '&Set Capacity';
                RunObject = Page "Resource Capacity Settings Opt";
                RunPageLink = "No." = field("No.");
                ToolTip = 'Change the capacity of the resource, such as a technician.';
            }
            action("Absence")
            {
                ApplicationArea = All;
                Caption = 'Absence';
                Image = Absence;
                RunObject = page "Resource Absence List";
                RunPageLink = "Resource No." = field("No."), Type = const(Absence);
                ToolTip = 'View and register absence entries for this resource.';
            }

            action("S&kills_Custom")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'S&kills';
                Image = Skills;
                RunObject = Page "Resource Skills";
                RunPageLink = Type = const(Resource),
                                "No." = field("No.");
                ToolTip = 'View the assignment of skills to the resource. You can use skill codes to allocate skilled resources to service items or items that need special skills for servicing.';
            }
            action("Resource Scheduler")
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    ResScheduler: page "DHX Resource Scheduler";
                begin
                    ResScheduler.SetResourceFilter(Rec."No.");
                    ResScheduler.RunModal();
                end;
            }
            action(DayPlanning)
            {
                ApplicationArea = All;
                Caption = 'Day Planning';

                trigger OnAction()
                var
                    DayPlanning: Record "Day Planning";
                begin
                    DayPlanning.Reset();
                    DayPlanning.FilterGroup(2);
                    DayPlanning.SetRange("Requested Resource No.", Rec."No.");
                    if DayPlanning.FindSet() then
                        repeat
                            DayPlanning.Mark(true);
                        until DayPlanning.Next() = 0;
                    DayPlanning.SetRange("Requested Resource No.");
                    DayPlanning.SetRange("Assigned Resource No.", Rec."No.");
                    if DayPlanning.FindSet() then
                        repeat
                            DayPlanning.Mark(true);
                        until DayPlanning.Next() = 0;
                    DayPlanning.SetRange("Assigned Resource No.");
                    DayPlanning.MarkedOnly := true;
                    DayPlanning.FilterGroup(0);
                    Page.Run(Page::"Day Plannings", DayPlanning);
                end;
            }
        }
        addafter("Ledger E&ntries_Promoted")
        {
            Group(Capacity)
            {
                Caption = 'Capacity';
                ShowAs = SplitButton;
                Image = Planning;
                actionref("Set Capacity Opt actionref"; "Set Capacity Opt") { }
                actionref("Absence_actionref"; "Absence") { }
                actionref("Resource &Capacity_actionref"; "Resource &Capacity") { }
            }
            Group(Visuals)
            {
                Caption = 'Planning';
                ShowAs = SplitButton;
                Image = Planning;
                actionref("Schedule (Visual) actionref"; "Schedule (Visual)") { }
                actionref("DayPlannings (Visual) actionref"; "DayPlannings (Visual)") { }
                actionref("Capacity actionref"; "Capacity (Visual)") { }
            }
        }
        addafter("Create Time Sheets_Promoted")
        {
            actionref("S&kills_Promoted_custom_list"; "S&kills_Custom") { }
            actionref("Resource Scheduler_Promoted_list"; "Resource Scheduler") { }
            actionref("DayPlanningRef_list"; DayPlanning) { }
            actionref("Set Capacity Opt actionref_home"; "Set Capacity Opt") { }
            actionref("Absence actionref_home"; "Absence") { }
            actionref("Resource Capacity actionref_home"; "Resource &Capacity") { }
        }
    }

    var
        myInt: Integer;
}