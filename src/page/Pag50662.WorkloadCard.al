page 50662 "Workorder Card"
{
    Caption = 'Workorder';
    PageType = Card;
    SourceTable = "Workorder";
    ApplicationArea = All;
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."Workorder No.")
                {
                    ApplicationArea = All;
                }
                field("Order Intake No."; Rec."Order Intake No.")
                {
                    ApplicationArea = All;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }

            }
            Group(RichtTextEditor)
            {
                Caption = 'Description';
                field("Long Description"; Rec."Long Description")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                }
            }

            group(Scheduling)
            {
                field("Project No."; Rec."Project No.")
                {
                    ApplicationArea = All;
                }
                field("Project Task No."; Rec."Project Task No.")
                {
                    ApplicationArea = All;
                }
                group(Dates)
                {
                    ShowCaption = false;
                    field("Date Window Start"; Rec."Date Window Start")
                    {
                        ApplicationArea = All;
                    }
                    field("Date Window End"; Rec."Date Window End")
                    {
                        ApplicationArea = All;
                    }
                    field("Deadline Date"; Rec."Deadline Date")
                    {
                        ApplicationArea = All;
                    }
                }
                field("Time Span Days"; Rec."Time Span Days")
                {
                    ApplicationArea = All;
                }
                field("Requested Hours"; Rec."Requested Hours")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Lookup = false;
                }
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = All;
                }
            }

            part(SpecificationLines; "Workorder Cap. Req. Subfrm")
            {
                ApplicationArea = All;
                SubPageLink = "Workorder No." = FIELD("Workorder No.");
            }
        }
    }
}