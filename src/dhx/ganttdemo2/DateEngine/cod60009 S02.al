codeunit 60009 "DSTS Scenario S02"
{

    procedure Execute(var Engine: Codeunit "Date Span Engine"; var Nodes: Record "Date Span Node" temporary; var Msg: Text[2048])
    begin
        Msg := '';

        BuildTreeTwoPlanningLines(Engine, Nodes);
        Engine.RecalculateAll(Nodes);

        // Baseline footprint from DTs:
        // PL1 = 10..12 Jan
        // PL2 = 20..21 Jan
        // TASK/JOB = 10..21 Jan
        AssertNodeRange(Nodes, 'TASK1', DMY2Date(10, 1, 2026), DMY2Date(21, 1, 2026), 'Baseline TASK span');
        AssertNodeRange(Nodes, 'JOB1', DMY2Date(10, 1, 2026), DMY2Date(21, 1, 2026), 'Baseline JOB span');

        // User changes middle level: expand PL1 wider
        Engine.ApplyUserChange(Nodes, 'PL1', DMY2Date(5, 1, 2026), DMY2Date(25, 1, 2026));

        // PL1 should be exactly what user set (unlocked)
        AssertNodeRange(Nodes, 'PL1', DMY2Date(5, 1, 2026), DMY2Date(25, 1, 2026), 'PL1 user change applied');

        // Ancestors must expand to cover PL1 + PL2
        AssertNodeRange(Nodes, 'TASK1', DMY2Date(5, 1, 2026), DMY2Date(25, 1, 2026), 'TASK expanded due to PL1');
        AssertNodeRange(Nodes, 'JOB1', DMY2Date(5, 1, 2026), DMY2Date(25, 1, 2026), 'JOB expanded due to PL1');

        // PL2 + its daytasks must remain the same
        AssertNodeRange(Nodes, 'PL2', DMY2Date(20, 1, 2026), DMY2Date(21, 1, 2026), 'PL2 unchanged');

        Msg := 'OK: middle-level change expands only ancestors; siblings unchanged.';
    end;

    local procedure BuildTreeTwoPlanningLines(var Engine: Codeunit "Date Span Engine"; var Nodes: Record "Date Span Node" temporary)
    begin
        Nodes.DeleteAll();

        Engine.AddNode(Nodes, 'JOB1', '', Enum::"Date Span Level"::Job, 0D, 0D, Enum::"Date Span Lock"::None, 'Job 1');
        Engine.AddNode(Nodes, 'TASK1', 'JOB1', Enum::"Date Span Level"::"Job Task", 0D, 0D, Enum::"Date Span Lock"::None, 'Task 1');

        Engine.AddNode(Nodes, 'PL1', 'TASK1', Enum::"Date Span Level"::"Job Planning Line", 0D, 0D, Enum::"Date Span Lock"::None, 'Planning Line 1');
        Engine.AddNode(Nodes, 'PL2', 'TASK1', Enum::"Date Span Level"::"Job Planning Line", 0D, 0D, Enum::"Date Span Lock"::None, 'Planning Line 2');

        // DayTasks under PL1
        Engine.AddNode(Nodes, 'DT1', 'PL1', Enum::"Date Span Level"::"Day Task",
            DMY2Date(10, 1, 2026), DMY2Date(12, 1, 2026), Enum::"Date Span Lock"::None, 'DT1');

        // DayTasks under PL2
        Engine.AddNode(Nodes, 'DT2', 'PL2', Enum::"Date Span Level"::"Day Task",
            DMY2Date(20, 1, 2026), DMY2Date(21, 1, 2026), Enum::"Date Span Lock"::None, 'DT2');
    end;

    local procedure AssertNodeRange(var Nodes: Record "Date Span Node" temporary; NodeId: Code[20]; ExpStart: Date; ExpEnd: Date; Context: Text[200])
    var
        N: Record "Date Span Node" temporary;
    begin
        N.Copy(Nodes, true);
        if not N.Get(NodeId) then
            Error('Node not found: %1', NodeId);

        if (N."Start Date" <> ExpStart) or (N."End Date" <> ExpEnd) then
            Error('%1. Node %2 expected %3..%4 but got %5..%6',
                Context, NodeId, ExpStart, ExpEnd, N."Start Date", N."End Date");
    end;
}
