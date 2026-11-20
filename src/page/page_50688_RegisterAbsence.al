page 50688 "Register Absence"
{
    Caption = 'Register Absence';
    PageType = Worksheet;
    SourceTable = "Register Absence";
    UsageCategory = Tasks;
    ApplicationArea = All;
    Editable = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource this absence line applies to.';
                }
                field(ResourceName; ResourceName)
                {
                    ApplicationArea = All;
                    Caption = 'Resource Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the resource.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the absence date.';
                }
                field("Absence Reason Code"; Rec."Absence Reason Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reason for the absence.';
                    LookupPageId = "Causes of Absence";
                }
                field(Hours; Rec.Hours)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of hours the resource is absent.';
                }
                field("Existing Capacity"; Rec."Existing Capacity")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the remaining capacity for this Resource and Date, net of any absence already posted - 0 or less means this absence cannot be posted.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Post)
            {
                ApplicationArea = All;
                Caption = 'Post';
                Image = Post;
                InFooterBar = true;
                ToolTip = 'Validate and post all absence lines on this worksheet into Res. Capacity Entry.';

                trigger OnAction()
                var
                    ResourceAbsenceMgt: Codeunit "Resource Absence Mgt.";
                begin
                    ResourceAbsenceMgt.PostRegisterAbsence(Rec);
                end;
            }
        }
        area(Promoted)
        {
            actionref(Post_Promoted; Post) { }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetResourceName();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        RegisterAbsence: Record "Register Absence";
    begin
        ResourceName := '';
        RegisterAbsence.Reset();
        if RegisterAbsence.FindLast() then
            Rec."Line No." := RegisterAbsence."Line No." + 10000
        else
            Rec."Line No." := 10000;

        // Filter-based inheritance (RunPageLink/SubPageLink/SetTableView, various filter
        // groups) proved unreliable in practice for this page - it never actually delivered
        // "Resource No." to a new line. DefaultResourceNo is set explicitly, via SetDefaultResourceNo,
        // by whatever page opens this worksheet (page 50684's "Register Absence" action calls
        // it right before Run()) - a plain stored value, no filter-group guessing involved.
        if (Rec."Resource No." = '') and (DefaultResourceNo <> '') then
            Rec.Validate("Resource No.", DefaultResourceNo);

        SetResourceName();
    end;

    procedure SetDefaultResourceNo(ResourceNo: Code[20])
    begin
        DefaultResourceNo := ResourceNo;
    end;

    local procedure SetResourceName()
    var
        Resource: Record Resource;
    begin
        if Resource.Get(Rec."Resource No.") then
            ResourceName := Resource.Name
        else
            ResourceName := '';
    end;

    var
        ResourceName: Text[100];
        DefaultResourceNo: Code[20];
}
