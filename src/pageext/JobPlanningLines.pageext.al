pageextension 50600 "DDSIA Job Planning Lines" extends "Job Planning Lines"
{
    layout
    {
        // Add changes to page layout here
        modify("Job No.")
        {
            visible = ShowJobNo;
        }
        addafter("Planning Date")
        {
            field("Start Time"; Rec."Start Time")
            {
                ApplicationArea = All;
            }
            field("End Planning Date"; Rec."End Planning Date")
            {
                ApplicationArea = All;
            }
            field("End Time"; Rec."End Time")
            {
                ApplicationArea = All;
            }
        }
        addbefore("Document No.")
        {
            field("Vendor No."; Rec."Vendor No.")
            {
                ApplicationArea = All;
            }
            field("Vendor Name"; Rec."Vendor Name")
            {
                ApplicationArea = All;
            }
        }
        addafter(Quantity)
        {
            field(Depth; Rec.Depth)
            {
                ApplicationArea = All;
                ToolTip = 'Drill depth in cm';
            }
        }
    }

    actions
    {
        addbefore("Category_Process")
        {
            group("Date_Filter")
            {
                Caption = 'Date Filter', Comment = 'Record list will filtered based on date';

                actionref("Today_filter"; "TodayFilter") { }
                actionref("Prev_filter"; "PrevTodayFilter") { }
                actionref("Nex_filter"; "NextTodayFilter") { }
            }
        }
        // Add to an existing group (here addlast(Processing) — any group is fine)
        addbefore("Create &Sales Invoice")
        {
            action(TodayFilter)
            {
                Caption = 'Today';
                ApplicationArea = All;
                Image = Workdays;

                trigger OnAction()
                begin
                    Rec.SetRange("Planning Date", Today);
                    CurrFilterDate := Today;
                    CurrPage.Update();
                end;
            }
            action(PrevTodayFilter)
            {
                Caption = 'Previous Day';
                ApplicationArea = All;
                Image = PreviousSet;

                trigger OnAction()
                begin
                    CurrFilterDate := CalcDate('<-1D>', CurrFilterDate);
                    Rec.SetRange("Planning Date", CurrFilterDate);
                    CurrPage.Update();
                end;
            }
            action(NextTodayFilter)
            {
                Caption = 'Next Day';
                ApplicationArea = All;
                Image = NextSet;

                trigger OnAction()
                begin
                    CurrFilterDate := CalcDate('<1D>', CurrFilterDate);
                    Rec.SetRange("Planning Date", CurrFilterDate);
                    CurrPage.Update();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        myInt: Integer;
    begin
        Rec.SetRange("Planning Date", Today);
        CurrFilterDate := Today;
        ShowJobNo := Rec.GetFilter("Job No.") = '';
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if CurrFilterDate <> 0D then begin
            Rec."Planning Date" := CurrFilterDate;
            Rec.SetRange("Planning Date", CurrFilterDate);
        end;
    end;



    var
        CurrFilterDate: Date;
        ShowJobNo: Boolean;
}