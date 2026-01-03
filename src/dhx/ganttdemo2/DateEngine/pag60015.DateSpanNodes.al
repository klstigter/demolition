page 60015 "Date Span Nodes"
{
    Caption = 'Date Span Nodes';
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Date Span Node";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Nodes)
            {
                field("Node ID"; Rec."Node ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique identifier for the node.';
                }
                field("Parent ID"; Rec."Parent ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the parent node identifier.';
                }
                field(Level; Rec.Level)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the hierarchical level of the node.';
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the start date of the date span.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the end date of the date span.';
                }
                field(Lock; Rec.Lock)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the lock status of the node.';
                }
                field(Caption; Rec.Caption)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the caption or display name of the node.';
                }
            }
        }
    }

    procedure LoadTestData(ScenarionameId: enum "Date Span Scenario Id")
    var
        TestSuite: Codeunit "Date Span Test Suite";
        TestContext: Codeunit "Date Span Test Context";
        Scenario: Interface "Date Span Scenario";
        S01: codeunit "DSTS Scenario S01";
        Engine: Codeunit "Date Span Engine";
        Node: Record "Date Span Node";
        TEMPNode: Record "Date Span Node" temporary;
    begin
        case ScenarionameId of
            ScenarionameId::S01_TOP_DOWN_UNLOCKED:
                begin
                    S01.loaddata(Engine, TEMPNode);

                end;
            else
                Error('Unknown scenario id: %1', ScenarionameId);
        end;
        Rec.Reset();
        Rec.DeleteAll();

        if TEMPNode.FindSet() then
            repeat
                Rec := TEMPNode;
                Rec.Insert();
            until TEMPNode.Next() = 0;
        if Rec.FindFirst() then;
    end;

    procedure LoadFromRecord(var Source: Record "Date Span Node" temporary)
    begin
        if rec.findset then
            repeat
                Source := rec;
                Source.insert();
            until rec.next() = 0;

    end;
}
