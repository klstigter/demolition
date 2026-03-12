page 60016 "Date Span Document"
{
    Caption = 'Date Span Document';
    PageType = Document;
    ApplicationArea = All;
    UsageCategory = Documents;
    SourceTable = "Date Span Node";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Scenario"; ScenarionameId)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique identifier for the node.';
                }

            }
            group(tekst)
            {
                Caption = 'What is tested';
                field(""; Description)

                {
                    ApplicationArea = All;
                    ToolTip = 'what is tested in the scenario';
                    Editable = false;
                    MultiLine = true;
                }

            }

            part(ChildNodes; "Date Span Nodes")
            {
                ApplicationArea = All;
                Caption = 'All Nodes';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(LoadTestData)
            {
                Caption = 'Load Test Data';
                ApplicationArea = All;
                Image = TestFile;

                trigger OnAction()
                var
                    S01: codeunit "DSTS Scenario S01";

                begin
                    // Example: Build sample hierarchy
                    CurrPage.ChildNodes.Page.LoadTestData(ScenarionameId);
                    case ScenarionameId of
                        ScenarionameId::S01_TOP_DOWN_UNLOCKED:
                            begin
                                Description := S01.loaddescription();

                            end;
                        else
                            Error('Unknown scenario id: %1', ScenarionameId);
                    end;

                    CurrPage.Update();

                end;
            }

            action(RecalculateAll)
            {
                Caption = 'Recalculate All';
                ApplicationArea = All;
                Image = Calculate;

                trigger OnAction()
                var
                    Engine: Codeunit "Date Span Engine";
                    TempNode: Record "Date Span Node" temporary;
                begin
                    GetAllNodes(TempNode);
                    Engine.RecalculateAll(TempNode);
                    LoadNodes(TempNode);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        AllNodes: Record "Date Span Node" temporary;
        ScenarionameId: enum "Date Span Scenario Id";
        Description: Text[2048];

    procedure LoadNodes(var SourceNodes: Record "Date Span Node" temporary)
    begin
        AllNodes.Reset();
        AllNodes.DeleteAll();

        if SourceNodes.FindSet() then
            repeat
                AllNodes := SourceNodes;
                AllNodes.Insert();
            until SourceNodes.Next() = 0;

        Rec.Reset();
        Rec.DeleteAll();

        if AllNodes.FindSet() then
            repeat
                Rec := AllNodes;
                Rec.Insert();
            until AllNodes.Next() = 0;

        if Rec.FindFirst() then;
        CurrPage.ChildNodes.Page.LoadFromRecord(AllNodes);
    end;

    procedure GetAllNodes(var TargetNodes: Record "Date Span Node" temporary)
    begin
        TargetNodes.Reset();
        TargetNodes.DeleteAll();

        if AllNodes.FindSet() then
            repeat
                TargetNodes := AllNodes;
                TargetNodes.Insert();
            until AllNodes.Next() = 0;
    end;
}
