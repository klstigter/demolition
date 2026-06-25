page 50664 "Work Order Lines"
{
    PageType = List;
    SourceTable = "Work Order Line";
    Caption = 'Work Order Lines';
    ApplicationArea = All;
    UsageCategory = None;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line number.';
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item number for this line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the item.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity for this line.';
                }
                field(Depth; Rec.Depth)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the depth for this line.';
                }
                field(Diameter; Rec.Diameter)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the diameter for this line.';
                }
                field("Item Price"; Rec."Item Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit price for this line.';
                }
                field(Price; Rec."Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the depth price for this line.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total amount (Quantity x Depth Price) for this line.';
                    Editable = false;
                }
            }
        }
        area(FactBoxes)
        {
            part(ItemDetails; "Item Card")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("Item No.");
                Visible = false;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NewLine)
            {
                ApplicationArea = All;
                Caption = 'New Line';
                Image = NewRow;
                ToolTip = 'Add a new work order line.';
                trigger OnAction()
                var
                    WorkOrderLine: Record "Work Order Line";
                begin
                    WorkOrderLine.Init();
                    WorkOrderLine."Work Order No." := Rec."Work Order No.";
                    WorkOrderLine."Line No." := 0;
                    WorkOrderLine.Insert(true);
                    CurrPage.Update(false);
                end;
            }
            action(DeleteLine)
            {
                ApplicationArea = All;
                Caption = 'Delete Line';
                Image = DeleteRow;
                ToolTip = 'Delete the selected work order line.';
                trigger OnAction()
                begin
                    CurrPage.SetSelectionFilter(Rec);
                    Rec.DeleteAll(true);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(NewLine_Ref; NewLine) { }
                actionref(DeleteLine_Ref; DeleteLine) { }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if Rec."Line No." = 0 then
            Rec."Line No." := GetNextLineNo();
        exit(true);
    end;

    local procedure GetNextLineNo(): Integer
    var
        WorkOrderLine: Record "Work Order Line";
    begin
        WorkOrderLine.SetRange("Work Order No.", Rec."Work Order No.");
        if WorkOrderLine.FindLast() then
            exit(WorkOrderLine."Line No." + 10000);
        exit(10000);
    end;
}
