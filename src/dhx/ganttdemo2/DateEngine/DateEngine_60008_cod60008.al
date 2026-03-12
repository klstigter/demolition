codeunit 60008 "DSTS Scenario S01"
{

    procedure loaddata(var Engine: Codeunit "Date Span Engine"; var Nodes: Record "Date Span Node" temporary)
    begin
        BuildBaseTree(Engine, Nodes);

        // 1) Parents must normalize to cover DayTasks
        Engine.RecalculateAll(Nodes);
        //test record        AssertNodeRange(Nodes, 'JOB1', DMY2Date(10, 1, 2026), DMY2Date(22, 1, 2026), 'After recalculation, JOB should span DT footprint');

    end;

    procedure loaddescription() str: Text[2048]
    var
        Char13: Char;
        Char10: Char;
    begin
        Char13 := 13;
        Char10 := 10;
        str := 'Scenario S01: record JOB 1 with one Task, one Planning Line and two DayTasks underneath.' +
          Char13 + Char10 + 'Top-down unlocked structure with DayTasks as truth. Tests that widening/shrinking works as expected.' +
        ' 1- Widening top level is allowed. Startdate from 10-1-2026 to 1-1-2026 ' +
        ' 2- Shrinking top level that would exclude existing DayTasks is blocked.';
    end;

    procedure Execute(var Engine: Codeunit "Date Span Engine"; var Nodes: Record "Date Span Node" temporary; var Msg: Text[2048])
    var
        d1: Date;
        d2: Date;
    begin
        Msg := '';

        // Dates
        d1 := DMY2Date(10, 1, 2026); // 10 Jan 2026
        d2 := DMY2Date(22, 1, 2026); // 22 Jan 2026

        loaddata(Engine, Nodes);

        // 1) Widen top level: allowed
        Engine.ApplyUserChange(Nodes, 'JOB1', DMY2Date(1, 1, 2026), DMY2Date(31, 1, 2026));
        AssertNodeRange(Nodes, 'JOB1', DMY2Date(1, 1, 2026), DMY2Date(31, 1, 2026), 'JOB widen should be applied');

        // 2) Shrink top level excluding DT1 -> must fail
        if TryApply(Engine, Nodes, 'JOB1', DMY2Date(15, 1, 2026), DMY2Date(31, 1, 2026)) then
            Error('Expected shrink to fail (would exclude existing DayTasks), but it succeeded.');

        Msg := 'OK: widen allowed; shrink excluding daytasks correctly blocked.';
    end;

    local procedure BuildBaseTree(var Engine: Codeunit "Date Span Engine"; var Nodes: Record "Date Span Node" temporary)
    begin
        Nodes.DeleteAll();

        // Job
        Engine.AddNode(Nodes, 'JOB1', '', Enum::"Date Span Level"::Job, 0D, 0D, Enum::"Date Span Lock"::None, 'Job 1');

        // Task
        Engine.AddNode(Nodes, 'TASK1', 'JOB1', Enum::"Date Span Level"::"Job Task", 0D, 0D, Enum::"Date Span Lock"::None, 'Task 1');

        // Planning line
        Engine.AddNode(Nodes, 'PL1', 'TASK1', Enum::"Date Span Level"::"Job Planning Line", 0D, 0D, Enum::"Date Span Lock"::None, 'Planning Line 1');

        // DayTasks (truth)
        Engine.AddNode(Nodes, 'DT1', 'PL1', Enum::"Date Span Level"::"Day Task",
            DMY2Date(10, 1, 2026), DMY2Date(12, 1, 2026), Enum::"Date Span Lock"::None, 'DayTask 1');

        Engine.AddNode(Nodes, 'DT2', 'PL1', Enum::"Date Span Level"::"Day Task",
            DMY2Date(20, 1, 2026), DMY2Date(22, 1, 2026), Enum::"Date Span Lock"::None, 'DayTask 2');
    end;

    [TryFunction]
    local procedure TryApply(var Engine: Codeunit "Date Span Engine"; var Nodes: Record "Date Span Node" temporary; NodeId: Code[20]; NewStart: Date; NewEnd: Date)
    begin
        Engine.ApplyUserChange(Nodes, NodeId, NewStart, NewEnd);
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
