page 50606 "DDSIA Incoming Check"
{
    Caption = 'Incoming Check';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "DDSIA Incoming Check";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Date Time"; Rec."Date Time")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteSelected)
            {
                Caption = 'Delete Selected';
                ApplicationArea = All;
                trigger OnAction()
                var
                    SelectedRecs: Record "DDSIA Incoming Check";
                    Clbl: Label 'Selected record will be delete';
                begin
                    if not confirm(Clbl) then
                        exit;
                    CurrPage.SetSelectionFilter(SelectedRecs);
                    if SelectedRecs.FindSet() then
                        SelectedRecs.DeleteAll();
                end;
            }
            action(ShowData)
            {
                Caption = 'Show Data';
                ApplicationArea = All;
                trigger OnAction()
                var
                    InS: InStream;
                    FileName: Text;
                    lbl: Label 'The %1 has not a value';
                begin
                    Rec.CalcFields("Blob Data");
                    if not Rec."Blob Data".HasValue then begin
                        Message(lbl, Rec.FieldCaption("Blob Data"));
                        exit;
                    end;
                    Rec."Blob Data".CreateInStream(InS);
                    FileName := '_data.txt';
                    DownloadFromStream(InS, '', '', '', FileName);
                end;
            }
        }
    }
}