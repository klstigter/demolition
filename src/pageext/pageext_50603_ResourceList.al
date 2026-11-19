pageextension 50603 "Opti ResourceList" extends "Resource List"
{
    layout
    {
        // Add changes to page layout here
        addafter(Type)
        {
            field("Opti Pool Resource No."; Rec."Opti Pool Resource No.")
            {
                Caption = 'Pool Resource No.';
                ToolTip = 'Specifies the value of the Pool Resource No. field.';
                ApplicationArea = All;
            }
            field("Opti Vendor No."; Rec."Vendor No.")
            {
                Caption = 'Vendor No.';
                ToolTip = 'Specifies the value of the Vendor No. field.';
                ApplicationArea = All;
            }
            field("Opti Is Pool"; Rec."Opti Is Pool")
            {
                Caption = 'Is Pool';
                ToolTip = 'Specifies the value of the Is Pool field.';
                ApplicationArea = All;
            }
            field("Opti Is Pool Member"; Rec."Opti Is Pool Member")
            {
                Caption = 'Is Pool Member';
                ToolTip = 'Specifies the value of the Is Pool Member field.';
                ApplicationArea = All;
            }
            field("Opti Is External"; Rec."Opti Is External")
            {
                Caption = 'Is External';
                ToolTip = 'Specifies the value of the Is External field.';
                ApplicationArea = All;
            }
            field("Opti Is Foreman"; Rec."Opti Is Foreman")
            {
                Caption = 'Is Foreman';
                ToolTip = 'Specifies the value of the Is Foreman field.';
                ApplicationArea = All;
            }
            field("Opti Mandatory Schedulling"; Rec."Opti Mandatory Schedulling")
            {
                Caption = 'Mandatory Schedulling';
                ToolTip = 'Specifies the value of the Mandatory Schedulling field.';
                ApplicationArea = All;
            }
            field("Opti Default Foreman"; Rec."Opti Default Foreman")
            {
                Caption = 'Default Foreman';
                ToolTip = 'Specifies the value of the Default Foreman field.';
                ApplicationArea = All;
            }
            field("Opti Default Foreman Name"; Rec."Opti Default Foreman Name")
            {
                Caption = 'Default Foreman Name';
                ToolTip = 'Specifies the value of the Default Foreman Name field.';
                ApplicationArea = All;
            }

        }
    }

    actions
    {
        // Add changes to page actions here
        addafter("&Resource")
        {
            action("Opti Schedule (Visual)")
            {
                Caption = 'Schedule (Visual)';
                ToolTip = 'Executes the Schedule (Visual) action.';
                ApplicationArea = All;
                trigger OnAction()
                var
                    ResScheduler: page "Opti Resource Calendar";
                begin
                    ResScheduler.SetResourceFilter(GetSelectionFilter());
                    ResScheduler.RunModal();
                end;
            }
            action("Opti DayPlannings (Visual)")
            {
                Caption = 'DayPlannings (Visual)';
                ToolTip = 'Executes the Day Plannings (Visual) action.';
                ApplicationArea = All;
                trigger OnAction()
                var
                    DayPlanningScheduler: page "Opti DHX Scheduler (Project)";
                begin
                    DayPlanningScheduler.SetResourceFilter(GetSelectionFilter());
                    DayPlanningScheduler.RunModal();
                end;
            }
            action("Opti Capacity (Visual)")
            {
                Caption = 'Capacity (Visual)';
                ToolTip = 'Executes the Capacity (Visual) action.';
                ApplicationArea = All;
                trigger OnAction()
                var
                    ResScheduler: page "Opti DHX Scheduler (Pool Res.)";
                begin
                    //ResScheduler.SetResourceFilter(Rec."No.");
                    ResScheduler.RunModal();
                end;
            }
            action("Opti Set Capacity Opt")
            {
                ApplicationArea = Jobs;
                Caption = '&Set Capacity';
                RunObject = Page "Opti Res. Cap. Settings Opt";
                RunPageLink = "No." = field("No.");
                ToolTip = 'Change the capacity of the resource, such as a technician.';
            }
            action("Opti Absence")
            {
                ApplicationArea = All;
                Caption = 'Absence';
                Image = Absence;
                RunObject = page "Opti Resource Absence List";
                RunPageLink = "Resource No." = field("No."), "Opti Type" = const(Absence);
                ToolTip = 'View and register absence entries for this resource.';
            }

            action("Opti S&kills_Custom")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'S&kills';
                Image = Skills;
                RunObject = Page "Resource Skills";
                RunPageLink = Type = const(Resource),
                                "No." = field("No.");
                ToolTip = 'View the assignment of skills to the resource. You can use skill codes to allocate skilled resources to service items or items that need special skills for servicing.';
            }
            action("Opti Resource Scheduler")
            {
                ToolTip = 'Executes the Resource Scheduler action.';
                ApplicationArea = All;
                Caption = 'Resource Calendar';
                trigger OnAction()
                var
                    ResScheduler: page "Opti Resource Calendar";
                begin
                    ResScheduler.SetResourceFilter(Rec."No.");
                    ResScheduler.RunModal();
                end;
            }
            action("Opti DayPlanning")
            {
                ToolTip = 'Executes the Day Planning action.';
                ApplicationArea = All;
                Caption = 'Day Planning';

                trigger OnAction()
                var
                    DayPlanning: Record "Opti Day Planning";
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
                    Page.Run(Page::"Opti Day Plannings", DayPlanning);
                end;
            }
        }
        addafter("Ledger E&ntries_Promoted")
        {
            Group("Opti Capacity")
            {
                Caption = 'Capacity';
                ShowAs = SplitButton;
                Image = Planning;
                actionref("Opti Set Capacity Opt actionref"; "Opti Set Capacity Opt") { }
                actionref("Opti Absence_actionref"; "Opti Absence") { }
                actionref("Opti Resource &Capacity_actionref"; "Resource &Capacity") { }
            }
            Group("Opti Visuals")
            {
                Caption = 'Planning';
                ShowAs = SplitButton;
                Image = Planning;
                actionref("Opti Schedule (Visual) actionref"; "Opti Schedule (Visual)") { }
                actionref("Opti DayPlannings (Visual) actionref"; "Opti DayPlannings (Visual)") { }
                actionref("Opti Capacity actionref"; "Opti Capacity (Visual)") { }
            }
        }
        addafter("Create Time Sheets_Promoted")
        {
            actionref("Opti S&kills_Promoted_custom_list"; "Opti S&kills_Custom") { }
            actionref("Opti Resource Scheduler_Promoted_list"; "Opti Resource Scheduler") { }
            actionref("Opti DayPlanningRef_list"; "Opti DayPlanning") { }
            actionref("Opti Set Capacity Opt actionref_home"; "Opti Set Capacity Opt") { }
            actionref("Opti Absence actionref_home"; "Opti Absence") { }
            actionref("Opti Resource Capacity actionref_home"; "Resource &Capacity") { }
        }
    }

    var
        myInt: Integer;
}