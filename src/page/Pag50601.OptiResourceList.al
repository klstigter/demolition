page 50601 "Opti Resource List"
{
    AdditionalSearchTerms = 'Workforce List, Mechanism List, Device List';
    ApplicationArea = Jobs;
    Caption = 'Resources with Day Plannings';
    CardPageID = "Resource Card";
    PageType = List;
    QueryCategory = 'Resource List';
    SourceTable = Resource;
    UsageCategory = Lists;
    ShowFilter = true;
    DeleteAllowed = false;
    ModifyAllowed = true;
    InsertAllowed = false;
    SourceTableView = sorting("pool resource no.", "No.");

    layout
    {
        area(content)
        {
            group(GroupFilter)
            {
                Caption = 'Filters';
                grid(FilterRow)
                {
                    ShowCaption = false;
                    GridLayout = Columns;
                    group(Col1)
                    {
                        ShowCaption = false;
                        field("Date Filter"; Rec.getfilter("Date Filter"))
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Date Filter';
                            ToolTip = 'The date to filter the resources that have day plannings on the specified date.';
                        }
                    }
                    group(Col2)
                    {
                        ShowCaption = false;
                        field("Skill Filter"; SkillToFind)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Skill Filter';
                            editable = false;
                            ToolTip = 'The skill to filter the resources that have day plannings with the specified skill.';
                        }
                    }
                    group(Col3)
                    {
                        ShowCaption = false;
                        field(Filters; RecFilters)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Filters (toggle clear and reapply)';
                            ToolTip = 'Filters applied to the list. Use this field to identify the filters that are applied to the list, including filters applied through the user interface and programmatically.';
                            Editable = false;

                            trigger OnAssistEdit()
                            var
                                KeepDateFilter: Text;
                            begin
                                if (RecFilters <> '') or Rec.MarkedOnly() then begin
                                    // Save view and marked state before clearing
                                    xRecFilters := Rec.GetView();
                                    xRecMarkedOnly := Rec.MarkedOnly();
                                    KeepDateFilter := Rec.GetFilter("Date Filter");
                                    // Save which records were marked into xRecMarking's own mark table.
                                    // Reset() clears all marks in xRecMarking before saving new ones.
                                    xRecMarking.Reset();
                                    if xRecMarkedOnly then
                                        if Rec.FindSet() then  // FindSet with MarkedOnly=true returns only marked records
                                            repeat
                                                if xRecMarking.Get(Rec."No.") then
                                                    xRecMarking.Mark(true);
                                            until Rec.Next() = 0;
                                    Rec.MarkedOnly(false);
                                    Rec.Reset();
                                    if KeepDateFilter <> '' then
                                        Rec.SetFilter("Date Filter", KeepDateFilter);
                                    RecFilters := '';
                                end else begin
                                    if (xRecFilters <> '') or xRecMarkedOnly then begin
                                        Rec.SetView(xRecFilters);
                                        if xRecMarkedOnly then begin
                                            // Restore marks from xRecMarking back into Rec
                                            xRecMarking.MarkedOnly(true);
                                            if xRecMarking.FindSet() then
                                                repeat
                                                    if Rec.Get(xRecMarking."No.") then
                                                        Rec.Mark(true);
                                                until xRecMarking.Next() = 0;
                                            xRecMarking.MarkedOnly(false);
                                            Rec.MarkedOnly(true);
                                        end;
                                        RecFilters := Rec.GetFilters();
                                    end;
                                end;
                                CurrPage.Update(false);
                            end;
                        }
                    }

                }
            }
            group(ResourcesList)
            {

                repeater(Control1)
                {
                    ShowCaption = false;
                    Editable = false;


                    field("No."; Rec."No.")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    }
                    field(Name; Rec.Name)
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies a description of the resource.';
                        StyleExpr = Stylexp;

                    }
                    field("Pool Resource No."; Rec."Pool Resource No.")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the pool resource that this resource is assigned to.';
                        Visible = true;
                        StyleExpr = Stylexp;

                    }
                    field(Type; Rec.Type)
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies whether the resource is a person or a machine.';
                        Visible = false;
                        StyleExpr = Stylexp;

                    }
                    field("Base Unit of Measure"; Rec."Base Unit of Measure")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the base unit used to measure the resource, such as hour, piece, or kilometer.';
                        StyleExpr = Stylexp;

                    }
                    field(capacity; Rec.Capacity)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Capacity';
                        BlankZero = true;


                    }
                    field("Requested Hours"; Rec."Requested Hours")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Requested';
                        BlankZero = true;

                    }
                    field("Day Plannings"; Rec."Assigned Hours")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Assigned';
                        BlankZero = true;


                    }
                    field(Skills; Rec.Skills)
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the number of skills associated with this resource.';
                        blankZero = true;
                        Visible = true;
                        StyleExpr = Stylexp;

                    }

                    field("Vendor No."; Rec."Vendor No.")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the vendor number associated with the resource.';
                        Visible = false;
                        StyleExpr = Stylexp;

                    }
                    field("External Resource"; Rec."Is Pool Member")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Indicates whether the resource is an external resource.';
                        Visible = true;
                        StyleExpr = Stylexp;
                    }
                    field("Is Foreman"; Rec."Is Foreman")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Indicates whether the resource is a foreman.';
                        Visible = true;
                        StyleExpr = Stylexp;

                    }
                    field("Is Pool"; Rec."Is Pool")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Indicates whether the resource is a pool resource.';
                        Visible = true;
                        StyleExpr = Stylexp;

                    }
                    field("Default Foreman"; Rec."Default Foreman")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the team leader responsible for the resource.';
                        Visible = false;
                        StyleExpr = Stylexp;

                    }
                    field("Resource Group No."; Rec."Resource Group No.")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the resource group that this resource is assigned to.';
                        Visible = true;
                        StyleExpr = Stylexp;

                    }

                    field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                        Visible = false;
                        StyleExpr = Stylexp;

                    }
                    field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                        Visible = false;
                        StyleExpr = Stylexp;

                    }
                    field("Privacy Blocked"; Rec."Privacy Blocked")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review.';
                        Visible = false;
                        StyleExpr = Stylexp;

                    }
                    field("Search Name"; Rec."Search Name")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                        StyleExpr = Stylexp;

                    }
                    field("Work Hour Template"; Rec."Work Hour Template")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the work hour template that is assigned to the resource.';
                        Visible = true;
                        StyleExpr = Stylexp;
                    }
                }


            }
        }
        area(factboxes)
        {
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::Resource), "No." = field("No.");
            }
            part(Control1906609707; "Resource Statistics FactBox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "No." = field("No."),
                              "Chargeable Filter" = field("Chargeable Filter"),
                              "Service Zone Filter" = field("Service Zone Filter"),
                              "Unit of Measure Filter" = field("Unit of Measure Filter");
                Visible = true;
            }
            part(Control1907012907; "Resource Details FactBox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "No." = field("No."),
                              "Chargeable Filter" = field("Chargeable Filter"),
                              "Service Zone Filter" = field("Service Zone Filter"),
                              "Unit of Measure Filter" = field("Unit of Measure Filter");
                Visible = true;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }

        }

    }

    actions
    {
        area(Processing)
        {
            group(Visuals)
            {
                caption = 'Visuals';
                image = Planning;
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
            }

        }
        area(navigation)
        {
            group("&Resource")
            {
                Caption = '&Resource';
                Image = Resource;
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

                action(Statistics)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Resource Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const(Resource),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = const(156),
                                      "No." = field("No.");
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            Res: Record Resource;
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(Res);
                            DefaultDimMultiple.SetMultiRecord(Res, Rec.FieldNo("No."));
                            DefaultDimMultiple.RunModal();
                        end;
                    }
                }
                action("&Picture")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Picture';
                    Image = Picture;
                    RunObject = Page "Resource Picture";
                    RunPageLink = "No." = field("No.");
                    ToolTip = 'View or add a picture of the resource or, for example, the company''s logo.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Ledger E&ntries';
                    Image = ResourceLedger;
                    RunObject = Page "Resource Ledger Entries";
                    RunPageLink = "Resource No." = field("No.");
                    RunPageView = sorting("Resource No.")
                                  order(descending);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("E&xtended Texts")
                {
                    ApplicationArea = Suite;
                    Caption = 'E&xtended Texts';
                    Image = Text;
                    RunObject = Page "Extended Text List";
                    RunPageLink = "Table Name" = const(Resource),
                                  "No." = field("No.");
                    RunPageView = sorting("Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
                    ToolTip = 'View the extended description that is set up.';
                }
                action("Units of Measure")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Units of Measure';
                    Image = UnitOfMeasure;
                    RunObject = Page "Resource Units of Measure";
                    RunPageLink = "Resource No." = field("No.");
                    ToolTip = 'View or edit the units of measure that are set up for the resource.';
                }
            }

            group("Plan&ning")
            {
                Caption = 'Plan&ning';
                Image = Planning;
                action("Resource &Capacity")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource &Capacity';
                    Image = Capacity;
                    RunObject = Page "Resource Capacity";
                    RunPageOnRec = true;
                    ToolTip = 'View this project''s resource capacity.';
                }
                action("Resource A&vailability")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource A&vailability';
                    Image = Calendar;
                    RunObject = Page "Resource Availability";
                    RunPageLink = "No." = field("No."),
                                  "Unit of Measure Filter" = field("Unit of Measure Filter"),
                                  "Chargeable Filter" = field("Chargeable Filter");
                    ToolTip = 'View a summary of resource capacities, the quantity of resource hours allocated to projects on order, the quantity allocated to service orders, the capacity assigned to projects on quote, and the resource availability.';
                }
            }
        }
        area(creation)
        {
            action("New Resource Group")
            {
                ApplicationArea = Jobs;
                Caption = 'New Resource Group';
                Image = NewResourceGroup;
                RunObject = Page "Resource Groups";
                RunPageMode = Create;
                ToolTip = 'Create a new resource.';

            }
        }
        area(reporting)
        {
            action("Resource - List")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource - List';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Resource - List";
                ToolTip = 'View the list of resources.';
            }
            action("Resource Statistics")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource Statistics';
                Image = "Report";
                RunObject = Report "Resource Statistics";
                ToolTip = 'View detailed, historical information for the resource.';
            }
            action("Resource Usage")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource Usage';
                Image = "Report";
                RunObject = Report "Resource Usage";
                ToolTip = 'View the resource utilization that has taken place. The report includes the resource capacity, quantity of usage, and the remaining balance.';
            }

            action("Resource Register")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource Register';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Resource Register";
                ToolTip = 'View a list of all the resource registers. Every time a resource entry is posted, a register is created. Every register shows the first and last entry numbers of its entries. You can use the information in a resource register to document when entries were posted.';
            }
        }

        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New', Comment = 'Generated from the PromotedActionCategories property index 0.';

                actionref("New Resource Group_Promoted"; "New Resource Group")
                {
                }
            }

            Group(Visuals_Ref)
            {
                Caption = 'Planning';
                ShowAs = SplitButton;
                Image = Planning;
                actionref("Schedule (Visual) actionref"; "Schedule (Visual)") { }
                actionref("DayPlannings (Visual) actionref"; "DayPlannings (Visual)") { }
                actionref("Capacity actionref"; "Capacity (Visual)") { }
            }

            group(Category_Category4)
            {
                Caption = 'Resource', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Set Capacity Opt actionref"; "Set Capacity Opt") { }
                actionref("Absence_actionref"; "Absence") { }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Ledger E&ntries_Promoted"; "Ledger E&ntries")
                {
                }
                group(Category_Dimensions)
                {
                    Caption = 'Dimensions';
                    ShowAs = SplitButton;

                    actionref("Dimensions-&Multiple_Promoted"; "Dimensions-&Multiple")
                    {
                    }
                    actionref("Dimensions-Single_Promoted"; "Dimensions-Single")
                    {
                    }
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }

                separator(Navigate_Separator)
                {
                }

                actionref("Units of Measure_Promoted"; "Units of Measure")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("Resource Statistics_Promoted"; "Resource Statistics")
                {
                }
                actionref("Resource Usage_Promoted"; "Resource Usage")
                {
                }

            }


        }
    }

    trigger OnAfterGetCurrRecord()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        CRMIsCoupledToRecord := CRMIntegrationEnabled;
        if CRMIsCoupledToRecord then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
    end;

    trigger OnAfterGetRecord()
    begin
        Stylexp := '';
        if rec."Is Pool" then
            Stylexp := 'Strong';

    end;

    trigger OnOpenPage()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        if CRMIntegrationEnabled then
            if IntegrationTableMapping.Get('RESOURCE-PRODUCT') then
                BlockedFilterApplied := IntegrationTableMapping.GetTableFilter().Contains('Field38=1(0)');
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
        RecFilters := Rec.GetFilters();
        xRecFilters := Rec.GetView();
    end;

    var
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        BlockedFilterApplied: Boolean;
        ExtendedPriceEnabled: Boolean;
        RecFilters: Text;
        xRecFilters: Text;
        Stylexp: Text;
        xRecMarkedOnly: Boolean;
        xRecMarking: Record Resource;
        SkillToFind: Code[10];

    procedure GetSelectionFilter(): Text
    var
        Resource: Record Resource;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(Resource);
        exit(SelectionFilterManagement.GetSelectionFilterForResource(Resource));
    end;

    procedure SetSelection(var Resource: Record Resource)
    begin
        CurrPage.SetSelectionFilter(Resource);
    end;

    procedure SetSkillToFind(Skill: code[10])
    begin
        SkillToFind := Skill;
    end;
}