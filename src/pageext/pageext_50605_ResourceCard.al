pageextension 50605 "ResourceCard Opti" extends "Resource Card"
{
    layout
    {
        // Add changes to page layout here
        addafter("Default Deferral Template Code")
        {
            field("Opti Work Hour Template"; Rec."Opti Work Hour Template")
            {
                Caption = 'Work Hour Template';
                ToolTip = 'Specifies the value of the Work Hour Template field.';
                ApplicationArea = All;
            }
        }
        addafter(Invoicing)
        {
            group("Opti Purchase")
            {
                group("Opti VendorNoGroup")
                {
                    ShowCaption = false;
                    Visible = ShowVendorNo;

                    field("Opti Vendor No."; Rec."Vendor No.")
                    {
                        Caption = 'Vendor No.';
                        ApplicationArea = All;
                        ToolTip = 'Specifies the vendor number associated with the resource.';
                    }
                }
                group("Opti PoolResourceNoGroup")
                {
                    ShowCaption = false;
                    Visible = ShowPoolResourceNo;

                    field("Opti Pool Resource No."; Rec."Opti Pool Resource No.")
                    {
                        Caption = 'Pool Resource No.';
                        ApplicationArea = All;
                        ToolTip = 'Specifies the pool resource number associated with the resource.';
                    }
                }
                group("Opti NotInternalResource")
                {
                    Caption = 'Not Internal Resource';

                    field("Opti Is Pool"; Rec."Opti Is Pool")
                    {
                        Caption = 'Is Pool';
                        ApplicationArea = All;
                        ToolTip = 'Indicates whether the resource is a pool resource.';
                        trigger OnValidate()
                        begin
                            UpdateVisibility();
                        end;
                    }
                    field("Opti Is Pool Member"; Rec."Opti Is Pool Member")
                    {
                        Caption = 'Is Pool Member';
                        ToolTip = 'Specifies the value of the Is Pool Member field.';
                        ApplicationArea = All;
                        trigger OnValidate()
                        begin
                            UpdateVisibility();
                        end;
                    }
                    field("Opti Is External"; Rec."Opti Is External")
                    {
                        Caption = 'Is External';
                        ApplicationArea = All;
                        ToolTip = 'Indicates whether the resource is external';
                        trigger OnValidate()
                        begin
                            UpdateVisibility();
                        end;
                    }
                }

                field("Opti Is Foreman"; Rec."Opti Is Foreman")
                {
                    Caption = 'Is Foreman';
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether the resource is a foreman.';
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
                field("Opti Mandatory Schedulling"; Rec."Opti Mandatory Schedulling")
                {
                    Caption = 'Mandatory Schedulling';
                    ToolTip = 'Specifies the value of the Mandatory Schedulling field.';
                    ApplicationArea = All;
                }
            }
        }
        addafter(Control1906609707)
        {
            part("Opti ResourceSkillsFactbox"; "Opti Res. Skills FactBox Part")
            {
                ApplicationArea = All;
                Caption = 'Resource Skills';
                SubPageLink = "Type" = const(Resource), "No." = field("No.");
            }

        }
    }

    actions
    {
        modify("S&kills")
        {
            Visible = false;
        }
        modify("S&kills_Promoted")
        {
            Visible = false;
        }

        // Add changes to page actions here
        addafter("Units of Measure")
        {
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
            action("Opti Resource Calender")
            {
                ToolTip = 'Executes the Resource Calender action.';
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
            action("Opti Resource Scheduler")
            {
                ToolTip = 'Executes the Resource Scheduler action.';
                ApplicationArea = All;
                Caption = 'Resource Scheduler';
                trigger OnAction()
                var
                    ResScheduler: page "Opti Res. Scheduler - TimeLine";
                begin
                    //TODO SetFilter
                    //ResScheduler.SetResourceFilter(Rec."No.");
                    ResScheduler.RunModal();
                end;
            }
            action("Opti Capacity")
            {
                Caption = 'Capacity';
                ToolTip = 'Executes the Capacity action.';
                ApplicationArea = All;
                trigger OnAction()
                var
                    ResScheduler: page "Opti DHX Scheduler (Pool Res.)";
                begin
                    //ResScheduler.SetResourceFilter(Rec."No.");
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
        }

        addafter(CreateTimeSheets_Promoted)
        {
            actionref("Opti S&kills_Promoted_custom"; "Opti S&kills_Custom") { }
            actionref("Opti DayPlanningRef"; "Opti DayPlanning") { }
            actionref("Opti Set Capacity Opt actionref"; "Opti Set Capacity Opt") { }
            actionref("Opti Absence actionref"; "Opti Absence") { }
            actionref("Opti Resource Capacity actionref"; "Resource &Capacity") { }
            Group("Opti Visuals_Ref")
            {
                Caption = 'Resource (Visuals)';
                ShowAs = SplitButton;
                Image = Planning;
                actionref("Opti Calendar (Visual) actionref"; "Opti Resource Calender") { }
                actionref("Opti Scheduler (Visual) actionref"; "Opti Resource Scheduler") { }
            }

        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateVisibility();
    end;

    var
        ShowPoolResourceNo: Boolean;
        ShowVendorNo: Boolean;

    local procedure UpdateVisibility()
    begin
        ShowPoolResourceNo := (not Rec."Opti Is Pool") and Rec."Opti Is Pool Member";
        // if not Rec."Is Pool" then
        //     ShowPoolResourceNo := Rec."Is Pool Member";
        ShowVendorNo := Rec."Opti Is External" or Rec."Opti Is Pool";
    end;
}