interface "Date Span Scenario"

{
    procedure GetName(): Text;
    procedure Run(var Nodes: Record "Date Span Node" temporary; var Ctx: Codeunit "Date Span Test Context");
}
