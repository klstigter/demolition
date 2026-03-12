codeunit 60010 "DSTS Scenario S03"
{
    procedure Execute(var Engine: Codeunit "Date Span Engine"; var Nodes: Record "Date Span Node" temporary; var Msg: Text[2048])
    var
        Job: Record "Date Span Node" temporary;
        Task: Record "Date Span Node" temporary;
        Plan: Record "Date Span Node" temporary;
        Dt: Record "Date Span Node" temporary;

        StartD: Date;
        EndD: Date;
    begin
        // Scenario idea:
        // - Day Tasks are truth.
        // - User expands Planning Line -> parents must expand.
        // - User tries to shrink Task excluding DayTask -> must be blocked (expected error).

        Nodes.DeleteAll();

        // Build tree
        Engine.AddNode(Nodes, 'JOB1', '', Enum::"Date Span Level"::Job,
            DMY2DATE(1, 1, 2026), DMY2DATE(31, 1, 2026), Enum::"Date Span Lock"::None, 'Job JOB1');

        Engine.AddNode(Nodes, 'TASK1', 'JOB1', Enum::"Date Span Level"::"Job Task",
            DMY2DATE(5, 1, 2026), DMY2DATE(20, 1, 2026), Enum::"Date Span Lock"::None, 'Task TASK1');

        Engine.AddNode(Nodes, 'PLAN1', 'TASK1', Enum::"Date Span Level"::"Job Planning Line",
            DMY2DATE(8, 1, 2026), DMY2DATE(15, 1, 2026), Enum::"Date Span Lock"::None, 'Planning PLAN1');

        Engine.AddNode(Nodes, 'DT1', 'PLAN1', Enum::"Date Span Level"::"Day Task",
            DMY2DATE(10, 1, 2026), DMY2DATE(12, 1, 2026), Enum::"Date Span Lock"::None, 'DayTask DT1');

        // 1) Expand planning line beyond current task range -> task must expand (parents normalize bottom-up)
        Engine.ApplyUserChange(Nodes, 'PLAN1', DMY2DATE(3, 1, 2026), DMY2DATE(25, 1, 2026));

        GetNode(Nodes, 'TASK1', Task);
        if Task."Start Date" <> DMY2DATE(3, 1, 2026) then
            Error('S03: Expected TASK1 start to expand to %1, got %2', DMY2DATE(3, 1, 2026), Task."Start Date");
        if Task."End Date" <> DMY2DATE(25, 1, 2026) then
            Error('S03: Expected TASK1 end to expand to %1, got %2', DMY2DATE(25, 1, 2026), Task."End Date");

        // 2) Try to shrink TASK1 so it would exclude existing DayTask (DT1 10..12) -> must ERROR
        StartD := DMY2DATE(13, 1, 2026);
        EndD := DMY2DATE(20, 1, 2026);

        if TryApply(Engine, Nodes, 'TASK1', StartD, EndD) then
            Error('S03: Expected shrinking TASK1 to be blocked (would exclude DayTasks), but it succeeded.');

        Msg := 'S03 ok: planning expansion cascaded up; shrinking task excluding DayTasks was blocked as expected.';
    end;

    [TryFunction]
    local procedure TryApply(var Engine: Codeunit "Date Span Engine"; var Nodes: Record "Date Span Node" temporary; NodeId: Code[20]; NewStart: Date; NewEnd: Date)
    begin
        Engine.ApplyUserChange(Nodes, NodeId, NewStart, NewEnd);
    end;

    local procedure GetNode(var Nodes: Record "Date Span Node" temporary; NodeId: Code[20]; var Node: Record "Date Span Node" temporary)
    begin
        Node.Copy(Nodes, true);
        if not Node.Get(NodeId) then
            Error('S03: Node not found: %1', NodeId);
    end;
}
