page 50631 "Job Planning Line Card"
{
    Caption = 'Job Planning Line Card';
    PageType = Card;
    SourceTable = "Job Planning Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related project.';
                    Importance = Additional;

                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related project task.';
                    Importance = Additional;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the planning line''s entry number.';
                    Importance = Additional;
                }
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the type of planning line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the resource, item, or G/L account to which this entry applies.';
                    Importance = Promoted;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies information in addition to the description.';
                    Importance = Additional;
                }
                field(SkillsRequired; Rec.SkillsRequired)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the value of the Skills Required field.', Comment = '%';
                    Importance = Promoted;
                }
                group(Planning)
                {

                    field("Remaining Qty."; Rec."Remaining Qty.")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the remaining quantity for this planning line.';
                        Importance = Additional;
                    }
                    field("Qty. Posted"; Rec."Qty. Posted")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the quantity that has been posted to the project ledger, if the Usage Link check box has been selected.';
                        Importance = Additional;
                    }

                }
            }
            part(DayTasksPart; "Job Planning Line Day Tasks")
            {
                ApplicationArea = Jobs;
                SubPageLink = "Job No." = field("Job No."),
                  "Job Task No." = field("Job Task No."),
                  "Job Planning Line No." = field("Line No.");
            }

            group(Schedule)
            {
                Caption = 'Schedule';
                group(PlanningDates)
                {
                    Caption = 'Planning Dates';

                    field("Planning Date"; Rec."Planning Date")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the date of the planning line.';
                        Importance = Promoted;

                    }
                    field("End Planning Date"; Rec."End Planning Date")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the end date for this planning line.';
                        Importance = Promoted;
                    }

                    field("Planned Delivery Date"; Rec."Planned Delivery Date")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the date that is planned to deliver the item connected to the project planning line.';
                        Importance = Additional;
                    }
                }
                group(PlanningTimes)
                {
                    Caption = 'Planning Times';
                    field("Start Time"; Rec."Start Time")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the start time for this planning line.';
                    }
                    field("End Time"; Rec."End Time")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the end time for this planning line.';
                    }
                }
                group(Demand)
                {
                    Caption = 'Demand';


                    field("Work Type Code"; Rec."Work Type Code")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies which work type the planning line applies to.';
                    }
                    field(Quantity; Rec.Quantity)
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the number of units of the resource, item, or general ledger account that should be specified on the planning line.';
                        Importance = Promoted;
                    }
                    field("Unit of Measure Code"; Rec."Unit of Measure Code")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies a unit of measure code that applies to the project planning line.';
                    }
                    field("Quantity (Base)"; Rec."Quantity (Base)")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the quantity in base units of measure.';
                        Importance = Additional;
                    }
                }
                group(ResourcePreview)
                {
                    Caption = 'Resource Preview';

                    field(Depth; Rec.Depth)
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the depth.';
                        Importance = Additional;
                    }
                    field(IsBoor; Rec.IsBoor)
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies if this is a boor line.';
                        Importance = Additional;
                    }

                }

                group(Resource)
                {
                    field(Type; Rec.Type)
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the type of account to which the planning line relates.';
                    }
                    field("No."; Rec."No.")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the number of the account to which the resource, item or general ledger account is posted.';
                    }

                }


                group(Vendor)
                {
                    Caption = 'Vendor';

                    field("Vendor No."; Rec."Vendor No.")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the vendor number for this planning line.';
                    }
                    field("Vendor Name"; Rec."Vendor Name")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the vendor name.';
                    }
                }

            }

            group(Pricing)
            {
                Caption = 'Pricing';

                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                }
                field("Total Cost"; Rec."Total Cost")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total cost for the planning line.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the price of one unit of the item or resource.';
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the amount that will be invoiced for this project planning line when you create a sales invoice.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                }
            }



            group(Details)
            {
                Caption = 'Details';


                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the location of the item you are planning to use.';
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a bin code for the item.';
                }

            }

            group(Posting)
            {
                Caption = 'Posting';

                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a document number for the planning line.';
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions.';
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the item''s product type to link transactions.';
                }
            }
        }

        area(factboxes)
        {
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
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;

                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department.';

                    trigger OnAction()
                    begin
                        message('under construction');
                        //Rec.ShowDimensions();
                        //CurrPage.SaveRecord();
                    end;
                }
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        message('under construction');
                        //Rec.OpenItemTrackingLines();
                    end;
                }
            }
        }

        area(processing)
        {
            action(UnpackToDayTasks)
            {
                ApplicationArea = Jobs;
                Caption = 'Unpack to Day Tasks';
                Image = SplitLines;
                ToolTip = 'Split this planning line into day tasks.';

                trigger OnAction()
                var
                    DayTasksMgt: Codeunit "Day Tasks Mgt.";
                begin
                    DayTasksMgt.UnpackJobPlanningLine(Rec);
                    Message('Day tasks have been created.');
                end;
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(UnpackToDayTasks_Promoted; UnpackToDayTasks)
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }
}
