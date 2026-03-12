
// =============================================
// 60006 Codeunit "Date Span Enginexx"
// =============================================
codeunit 60006 "Date Span Engine"
{

    // Public API ------------------------------------------------

    procedure AddNode(var Nodes: Record "Date Span Node" temporary; NodeId: Code[20]; ParentId: Code[20];
                      Level: Enum "Date Span Level"; StartDate: Date; EndDate: Date; Lock: Enum "Date Span Lock"; CaptionTxt: Text[100])
    begin
        Nodes.Init();
        Nodes."Node ID" := NodeId;
        Nodes."Parent ID" := ParentId;
        Nodes.Level := Level;
        Nodes."Start Date" := StartDate;
        Nodes."End Date" := EndDate;
        Nodes.Lock := Lock;
        Nodes.Caption := CaptionTxt;
        Nodes.Insert(true);
    end;

    /// User changed a range on some level (Job/Task/PlanningLine/DayTask).
    /// Rules:
    /// 1) Day Tasks are truth: you may not change parent to exclude descendant day tasks.
    /// 2) Parents must cover their children; may be wider.
    /// 3) Locks prevent changing start/end; if locked and a child requires expansion -> error.
    procedure ApplyUserChange(var Nodes: Record "Date Span Node" temporary; NodeId: Code[20]; NewStart: Date; NewEnd: Date)
    var
        Node: Record "Date Span Node" temporary;
        MinD: Date;
        MaxD: Date;
    begin
        GetNode(Nodes, NodeId, Node);

        // Apply locks to the requested new values
        ApplyLocks(Node, NewStart, NewEnd);

        ValidateRange(Node);

        // If this node has descendant DayTasks, do not allow excluding them
        if HasAnyDescendantDayTask(Nodes, NodeId) then begin
            GetDescendantDayTaskFootprint(Nodes, NodeId, MinD, MaxD);
            if (MinD <> 0D) and (Node."Start Date" > MinD) then
                Error('Change not allowed: %1 would start after existing DayTasks (%2).', Node.Caption, MinD);
            if (MaxD <> 0D) and (Node."End Date" < MaxD) then
                Error('Change not allowed: %1 would end before existing DayTasks (%2).', Node.Caption, MaxD);
        end;

        // Persist the node change
        UpdateNode(Nodes, Node);

        // Now force parents to span children (bottom-up)
        NormalizeParentsToChildren(Nodes);
    end;

    /// Recompute all parent spans from bottom-up (use after bulk changes)
    procedure RecalculateAll(var Nodes: Record "Date Span Node" temporary)
    begin
        NormalizeParentsToChildren(Nodes);
    end;

    // Core logic ------------------------------------------------

    local procedure NormalizeParentsToChildren(var Nodes: Record "Date Span Node" temporary)
    begin
        // Bottom-up order: DayTask -> Planning -> Task -> Job (i.e., update parents at each step)
        NormalizeLevelParents(Nodes, Enum::"Date Span Level"::"Job Planning Line");
        NormalizeLevelParents(Nodes, Enum::"Date Span Level"::"Job Task");
        NormalizeLevelParents(Nodes, Enum::"Date Span Level"::Job);
    end;

    /// For each parent at the given level, compute min/max of its direct children and expand parent if needed.
    local procedure NormalizeLevelParents(var Nodes: Record "Date Span Node" temporary; ParentLevel: Enum "Date Span Level")
    var
        Parent: Record "Date Span Node" temporary;
        Child: Record "Date Span Node" temporary;
        ReqStart: Date;
        ReqEnd: Date;
        NewStart: Date;
        NewEnd: Date;
    begin
        Parent.Copy(Nodes, true);
        Parent.SetRange(Level, ParentLevel);

        if Parent.FindSet() then
            repeat
                // Find direct children
                Child.Copy(Nodes, true);
                Child.SetRange("Parent ID", Parent."Node ID");

                ReqStart := 0D;
                ReqEnd := 0D;

                if Child.FindSet() then
                    repeat
                        if (ReqStart = 0D) or (Child."Start Date" < ReqStart) then
                            ReqStart := Child."Start Date";
                        if (ReqEnd = 0D) or (Child."End Date" > ReqEnd) then
                            ReqEnd := Child."End Date";
                    until Child.Next() = 0;

                // No children => nothing to normalize
                if (ReqStart = 0D) and (ReqEnd = 0D) then
                    continue;

                // Parent may be wider; only expand if needed
                NewStart := Parent."Start Date";
                NewEnd := Parent."End Date";

                if NewStart = 0D then
                    NewStart := ReqStart;
                if NewEnd = 0D then
                    NewEnd := ReqEnd;

                if ReqStart < NewStart then
                    NewStart := ReqStart;
                if ReqEnd > NewEnd then
                    NewEnd := ReqEnd;

                if (NewStart <> Parent."Start Date") or (NewEnd <> Parent."End Date") then begin
                    // Respect locks: if lock blocks required expansion => error
                    if (Parent.Lock in [Enum::"Date Span Lock"::LockStart, Enum::"Date Span Lock"::LockBoth]) and (NewStart <> Parent."Start Date") then
                        Error('Cannot expand start of %1 because Start Date is locked.', Parent.Caption);
                    if (Parent.Lock in [Enum::"Date Span Lock"::LockEnd, Enum::"Date Span Lock"::LockBoth]) and (NewEnd <> Parent."End Date") then
                        Error('Cannot expand end of %1 because End Date is locked.', Parent.Caption);

                    Parent."Start Date" := NewStart;
                    Parent."End Date" := NewEnd;
                    ValidateRange(Parent);
                    UpdateNode(Nodes, Parent);
                end;
            until Parent.Next() = 0;
    end;

    local procedure HasAnyDescendantDayTask(var Nodes: Record "Date Span Node" temporary; NodeId: Code[20]): Boolean
    var
        Q: Record "Date Span Node" temporary;
    begin
        // Any DayTask with (transitive) parent = NodeId
        Q.Copy(Nodes, true);
        Q.SetRange(Level, Enum::"Date Span Level"::"Day Task");
        if not Q.FindSet() then
            exit(false);

        repeat
            if IsDescendantOf(Nodes, Q."Node ID", NodeId) then
                exit(true);
        until Q.Next() = 0;

        exit(false);
    end;

    local procedure GetDescendantDayTaskFootprint(var Nodes: Record "Date Span Node" temporary; NodeId: Code[20]; var MinD: Date; var MaxD: Date)
    var
        Q: Record "Date Span Node" temporary;
    begin
        MinD := 0D;
        MaxD := 0D;

        Q.Copy(Nodes, true);
        Q.SetRange(Level, Enum::"Date Span Level"::"Day Task");

        if Q.FindSet() then
            repeat
                if IsDescendantOf(Nodes, Q."Node ID", NodeId) then begin
                    if (MinD = 0D) or (Q."Start Date" < MinD) then
                        MinD := Q."Start Date";
                    if (MaxD = 0D) or (Q."End Date" > MaxD) then
                        MaxD := Q."End Date";
                end;
            until Q.Next() = 0;
    end;

    local procedure IsDescendantOf(var Nodes: Record "Date Span Node" temporary; ChildNodeId: Code[20]; PossibleAncestorId: Code[20]): Boolean
    var
        Cur: Record "Date Span Node" temporary;
        Safety: Integer;
    begin
        Safety := 0;
        GetNode(Nodes, ChildNodeId, Cur);

        while (Cur."Parent ID" <> '') and (Safety < 50) do begin
            if Cur."Parent ID" = PossibleAncestorId then
                exit(true);

            GetNode(Nodes, Cur."Parent ID", Cur);
            Safety += 1;
        end;

        exit(false);
    end;

    local procedure ApplyLocks(var Node: Record "Date Span Node" temporary; NewStart: Date; NewEnd: Date)
    begin
        case Node.Lock of
            Enum::"Date Span Lock"::None:
                begin
                    Node."Start Date" := NewStart;
                    Node."End Date" := NewEnd;
                end;
            Enum::"Date Span Lock"::LockStart:
                begin
                    if NewStart <> Node."Start Date" then
                        error('Start Date of %1 is locked and cannot be changed.', Node.Caption);
                    Node."End Date" := NewEnd;
                end;
            Enum::"Date Span Lock"::LockEnd:
                begin
                    // End stays, Start can change
                    Node."Start Date" := NewStart;
                    if NewEnd <> Node."End Date" then
                        error('End Date of %1 is locked and cannot be changed.', Node.Caption);
                end;
            Enum::"Date Span Lock"::LockBoth:
                begin
                    // Ignore both changes
                    error('Both Start Date and End Date of %1 are locked and cannot be changed.', Node.Caption);
                end;
        end;
    end;

    local procedure ValidateRange(Node: Record "Date Span Node" temporary)
    begin
        if (Node."Start Date" <> 0D) and (Node."End Date" <> 0D) and (Node."Start Date" > Node."End Date") then
            Error('Invalid range on %1: Start Date %2 is after End Date %3.', Node.Caption, Node."Start Date", Node."End Date");
    end;

    local procedure GetNode(var Nodes: Record "Date Span Node" temporary; NodeId: Code[20]; var Node: Record "Date Span Node" temporary)
    begin
        Node.Copy(Nodes, true);
        if not Node.Get(NodeId) then
            Error('Node not found: %1', NodeId);
    end;

    local procedure UpdateNode(var Nodes: Record "Date Span Node" temporary; Node: Record "Date Span Node" temporary)
    begin
        if not Nodes.Get(Node."Node ID") then
            Error('Node not found for update: %1', Node."Node ID");

        Nodes := Node;
        Nodes.Modify(true);
    end;

}
