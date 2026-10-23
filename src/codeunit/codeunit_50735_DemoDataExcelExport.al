codeunit 50735 "Demo Data Excel Export"
{
    // Turns the XML of a Demo Data Scenario into an Excel workbook: sheet 1 is a statistics summary,
    // then one sheet per table element found in the XML (a record element = an element that has at
    // least one field element, i.e. a child without child elements). Nested records get a "Parent"
    // column holding the first field value of their parent record.

    procedure DownloadAsExcel(var Scenario: Record "Demo Data Scenarios Opt")
    var
        ExcelBuf: Record "Excel Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        XmlDoc: XmlDocument;
        Root: XmlElement;
        InStr: InStream;
        OutStr: OutStream;
        SheetNames: List of [Text];
        SheetCols: Dictionary of [Text, List of [Text]];
        SheetNested: Dictionary of [Text, Text];
        SheetName: Text;
        FileName: Text;
    begin
        if not Scenario.HasXml() then
            Error(NoXmlErr);
        Scenario.GetXmlStream(InStr);
        XmlDocument.ReadFrom(InStr, XmlDoc);
        XmlDoc.GetRoot(Root);

        CollectSheets(Root, '', SheetNames, SheetCols, SheetNested);

        WriteSummary(ExcelBuf, Root);
        ExcelBuf.CreateNewBook(SummarySheetLbl);
        ExcelBuf.WriteSheet(SummarySheetLbl, CompanyName(), UserId());

        foreach SheetName in SheetNames do
            WriteRecordSheet(ExcelBuf, Root, CopyStr(SheetName, 1, 31), SheetCols.Get(SheetName), SheetNested.Get(SheetName), SheetName);

        ExcelBuf.CloseBook();
        TempBlob.CreateOutStream(OutStr);
        ExcelBuf.SaveToStream(OutStr, true);
        TempBlob.CreateInStream(InStr);
        FileName := StrSubstNo('DemoData_%1.xlsx', Scenario."Entry No.");
        DownloadFromStream(InStr, '', '', '', FileName);
    end;

    // ---- Excel -> XML (reverse of DownloadAsExcel) ----

    // Rebuilds the demo data XML from a workbook made by DownloadAsExcel and stores it in the scenario.
    // The XML structure is fixed (it mirrors xmlport "DemoData"); the sheets only supply the records.
    procedure ConvertExcelToXml(var Scenario: Record "Demo Data Scenarios Opt"; var ExcelStream: InStream; ExcelFileName: Text)
    var
        ExcelBuf: Record "Excel Buffer" temporary;
        NameBuf: Record "Name/Value Buffer" temporary;
        ExcelBlob: Codeunit "Temp Blob";
        XmlBlob: Codeunit "Temp Blob";
        XmlDoc: XmlDocument;
        Root: XmlElement;
        Decl: XmlDeclaration;
        ExcelOut: OutStream;
        ExcelIn: InStream;
        XmlOut: OutStream;
        XmlIn: InStream;
        Sheets: List of [Text];
        Containers: List of [Text];
        ParentSheets: List of [Text];
        Wrappers: List of [Text];
        SheetContainer: Dictionary of [Text, Text];
        SheetFirstField: Dictionary of [Text, Text];
        SheetFound: Boolean;
        i: Integer;
        NewName: Text;
        Imported: Integer;
    begin
        XmlDoc := XmlDocument.Create();
        Decl := XmlDeclaration.Create('1.0', 'utf-8', 'no');
        XmlDoc.SetDeclaration(Decl);
        Root := XmlElement.Create('DemoData');
        XmlDoc.Add(Root);

        // Keep a copy of the workbook: every sheet is read from a fresh stream.
        ExcelBlob.CreateOutStream(ExcelOut);
        CopyStream(ExcelOut, ExcelStream);
        ExcelBlob.CreateInStream(ExcelIn);
        ExcelBuf.GetSheetsNameListFromStream(ExcelIn, NameBuf);

        InitStructure(Sheets, Containers, ParentSheets, Wrappers);
        for i := 1 to Sheets.Count() do begin
            NameBuf.Reset();
            NameBuf.SetRange(Value, Sheets.Get(i));
            SheetFound := not NameBuf.IsEmpty();
            if not SheetFound then begin
                NameBuf.SetRange(Value);
                NameBuf.SetRange(Name, Sheets.Get(i));
                SheetFound := not NameBuf.IsEmpty();
            end;
            if SheetFound then begin
                ExcelBlob.CreateInStream(ExcelIn);
                Imported += ImportSheet(ExcelBuf, ExcelIn, Root, Sheets.Get(i), Containers.Get(i), ParentSheets.Get(i), Wrappers.Get(i), SheetContainer, SheetFirstField);
            end;
        end;
        if Imported = 0 then
            Error(NoSheetsErr);

        XmlBlob.CreateOutStream(XmlOut);
        XmlDoc.WriteTo(XmlOut);
        XmlBlob.CreateInStream(XmlIn);
        Scenario.SetXmlFromStream(XmlIn);
        NewName := ExcelFileName;
        if LowerCase(NewName).EndsWith('.xlsx') then
            NewName := CopyStr(NewName, 1, StrLen(NewName) - 5) + '.xml';
        Scenario."XML File Name" := CopyStr(NewName, 1, MaxStrLen(Scenario."XML File Name"));
        Scenario.Modify(true);
    end;

    // Order matters: parents before children, and sections in the same order as the xmlport schema.
    local procedure InitStructure(var Sheets: List of [Text]; var Containers: List of [Text]; var ParentSheets: List of [Text]; var Wrappers: List of [Text])
    begin
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'BaseCalendar', 'MasterData/Calendar', '', '');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'BaseCalendarChange', '', 'BaseCalendar', '');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'WorkHourTemplate', 'MasterData/WorkHour', '', '');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'SkillCode', 'MasterData/Skills', '', '');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'NoSeries', 'MasterData/Numbering', '', '');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'NoSeriesLine', '', 'NoSeries', '');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'ProjectType', 'MasterData/ProjectTypes', '', '');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'ResourceGroup', 'MasterData/ResourceGroups', '', '');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'UnitOfMeasure', 'MasterData/UoMs', '', '');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'GenProductPostingGroup', 'MasterData/GenProd', '', '');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'VATProductPostingGroup', 'MasterData/VATProd', '', '');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'Customer', 'MasterData/Customers', '', '');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'Vendor', 'MasterData/Vendors', '', '');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'Resource', 'MasterData/Resources', '', '');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'ResourceSkill', '', 'Resource', 'ResourceSkills');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'DailyOptimizerSetup', '', '', '');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'Job', 'Jobs', '', '');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'JobTask', '', 'Job', '');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'DayPlanning', 'DayPlannings', '', '');
        AddStructure(Sheets, Containers, ParentSheets, Wrappers, 'Capacity', 'Capacities', '', '');
    end;

    local procedure AddStructure(var Sheets: List of [Text]; var Containers: List of [Text]; var ParentSheets: List of [Text]; var Wrappers: List of [Text]; SheetName: Text; Container: Text; ParentSheet: Text; Wrapper: Text)
    begin
        Sheets.Add(SheetName);
        Containers.Add(Container);
        ParentSheets.Add(ParentSheet);
        Wrappers.Add(Wrapper);
    end;

    // Reads one sheet (row 1 = header, then one record per row) and adds its records to the XML. Returns the record count.
    local procedure ImportSheet(var ExcelBuf: Record "Excel Buffer" temporary; var ExcelIn: InStream; Root: XmlElement; SheetName: Text; Container: Text; ParentSheet: Text; Wrapper: Text; var SheetContainer: Dictionary of [Text, Text]; var SheetFirstField: Dictionary of [Text, Text]): Integer
    var
        ColNames: Dictionary of [Integer, Text];
        RowVals: Dictionary of [Integer, Text];
        CurRow: Integer;
        MaxCol: Integer;
        Count: Integer;
        FirstCol: Integer;
    begin
        ExcelBuf.DeleteAll();
        ExcelBuf.OpenBookStream(ExcelIn, SheetName);
        ExcelBuf.ReadSheet();
        SheetContainer.Add(SheetName, Container);
        FirstCol := 1;
        if ParentSheet <> '' then
            FirstCol := 2;

        if ExcelBuf.FindSet() then
            repeat
                if ExcelBuf."Row No." = 1 then begin
                    ColNames.Add(ExcelBuf."Column No.", ExcelBuf."Cell Value as Text");
                    if ExcelBuf."Column No." > MaxCol then
                        MaxCol := ExcelBuf."Column No.";
                    if ExcelBuf."Column No." = FirstCol then
                        SheetFirstField.Add(SheetName, ExcelBuf."Cell Value as Text");
                end else begin
                    if ExcelBuf."Row No." <> CurRow then begin
                        if CurRow <> 0 then
                            Count += AddRecord(Root, SheetName, Container, ParentSheet, Wrapper, ColNames, MaxCol, RowVals, SheetContainer, SheetFirstField);
                        CurRow := ExcelBuf."Row No.";
                        Clear(RowVals);
                    end;
                    RowVals.Set(ExcelBuf."Column No.", ExcelBuf."Cell Value as Text");
                end;
            until ExcelBuf.Next() = 0;
        if CurRow <> 0 then
            Count += AddRecord(Root, SheetName, Container, ParentSheet, Wrapper, ColNames, MaxCol, RowVals, SheetContainer, SheetFirstField);
        ExcelBuf.CloseBook();
        exit(Count);
    end;

    local procedure AddRecord(Root: XmlElement; SheetName: Text; Container: Text; ParentSheet: Text; Wrapper: Text; ColNames: Dictionary of [Integer, Text]; MaxCol: Integer; RowVals: Dictionary of [Integer, Text]; var SheetContainer: Dictionary of [Text, Text]; var SheetFirstField: Dictionary of [Text, Text]): Integer
    var
        RecElem: XmlElement;
        ParentElem: XmlElement;
        WrapElem: XmlElement;
        Node: XmlNode;
        Value: Text;
        XPath: Text;
        ParentKey: Text;
        HasData: Boolean;
        Col: Integer;
        FirstCol: Integer;
    begin
        FirstCol := 1;
        if ParentSheet <> '' then
            FirstCol := 2;
        RecElem := XmlElement.Create(SheetName);
        for Col := FirstCol to MaxCol do
            if ColNames.ContainsKey(Col) then begin
                Value := '';
                if RowVals.ContainsKey(Col) then
                    Value := RowVals.Get(Col);
                if Value <> '' then
                    HasData := true;
                RecElem.Add(XmlElement.Create(ColNames.Get(Col), '', Value));
            end;
        if not HasData then
            exit(0);

        if ParentSheet = '' then begin
            ContainerElement(Root, Container).Add(RecElem);
            exit(1);
        end;

        if RowVals.ContainsKey(1) then
            ParentKey := RowVals.Get(1);
        XPath := '/DemoData/';
        if SheetContainer.Get(ParentSheet) <> '' then
            XPath += SheetContainer.Get(ParentSheet) + '/';
        XPath += ParentSheet + '[' + SheetFirstField.Get(ParentSheet) + '="' + ParentKey + '"]';
        if not Root.SelectSingleNode(XPath, Node) then
            Error(OrphanErr, SheetName, ParentSheet, ParentKey);
        ParentElem := Node.AsXmlElement();
        if Wrapper = '' then
            ParentElem.Add(RecElem)
        else begin
            if ParentElem.SelectSingleNode(Wrapper, Node) then
                WrapElem := Node.AsXmlElement()
            else begin
                WrapElem := XmlElement.Create(Wrapper);
                ParentElem.Add(WrapElem);
            end;
            WrapElem.Add(RecElem);
        end;
        exit(1);
    end;

    // Returns (creating when missing) the element at a path like 'MasterData/Calendar' below Root; '' = Root itself.
    local procedure ContainerElement(Root: XmlElement; Path: Text): XmlElement
    var
        Cur: XmlElement;
        Next: XmlElement;
        Node: XmlNode;
        Segment: Text;
    begin
        Cur := Root;
        if Path = '' then
            exit(Cur);
        foreach Segment in Path.Split('/') do
            if Cur.SelectSingleNode(Segment, Node) then
                Cur := Node.AsXmlElement()
            else begin
                Next := XmlElement.Create(Segment);
                Cur.Add(Next);
                Cur := Next;
            end;
        exit(Cur);
    end;

    local procedure IsLeaf(Elem: XmlElement): Boolean
    begin
        exit(Elem.GetChildElements().Count() = 0);
    end;

    local procedure IsRecord(Elem: XmlElement): Boolean
    var
        Children: XmlNodeList;
        Child: XmlNode;
    begin
        // These two only contain sections, which may be empty (leaf) elements - never a record themselves.
        if Elem.Name() in ['DemoData', 'MasterData'] then
            exit(false);
        Children := Elem.GetChildElements();
        foreach Child in Children do
            if IsLeaf(Child.AsXmlElement()) then
                exit(true);
        exit(false);
    end;

    // Walks the XML: registers each record element name (document order) with its field columns.
    local procedure CollectSheets(Elem: XmlElement; ParentName: Text; var SheetNames: List of [Text]; var SheetCols: Dictionary of [Text, List of [Text]]; var SheetNested: Dictionary of [Text, Text])
    var
        Children: XmlNodeList;
        Child: XmlNode;
        ChildElem: XmlElement;
        Cols: List of [Text];
    begin
        Children := Elem.GetChildElements();
        if IsRecord(Elem) then begin
            if not SheetCols.ContainsKey(Elem.Name()) then begin
                SheetNames.Add(Elem.Name());
                SheetCols.Add(Elem.Name(), Cols);
                SheetNested.Add(Elem.Name(), ParentName);
            end;
            Cols := SheetCols.Get(Elem.Name());
            foreach Child in Children do begin
                ChildElem := Child.AsXmlElement();
                if IsLeaf(ChildElem) then begin
                    if not Cols.Contains(ChildElem.Name()) then
                        Cols.Add(ChildElem.Name());
                end else
                    CollectSheets(ChildElem, Elem.Name(), SheetNames, SheetCols, SheetNested);
            end;
            SheetCols.Set(Elem.Name(), Cols);
        end else
            foreach Child in Children do
                CollectSheets(Child.AsXmlElement(), ParentName, SheetNames, SheetCols, SheetNested);
    end;

    local procedure WriteRecordSheet(var ExcelBuf: Record "Excel Buffer" temporary; Root: XmlElement; XlSheetName: Text; Cols: List of [Text]; ParentName: Text; ElemName: Text)
    var
        Nodes: XmlNodeList;
        RecNode: XmlNode;
        Col: Text;
    begin
        ExcelBuf.DeleteAll();
        ExcelBuf.ClearNewRow();
        ExcelBuf.NewRow();
        if ParentName <> '' then
            AddText(ExcelBuf, ParentHeader(ParentName), true);
        foreach Col in Cols do
            AddText(ExcelBuf, Col, true);

        // [*] = has child elements, so a record is matched but a same-named field element is not.
        Root.SelectNodes('//' + ElemName + '[*]', Nodes);
        foreach RecNode in Nodes do
            if HasValue(RecNode.AsXmlElement()) then begin
                ExcelBuf.NewRow();
                if ParentName <> '' then
                    AddText(ExcelBuf, FirstFieldValue(ParentRecord(RecNode.AsXmlElement())), false);
                foreach Col in Cols do
                    AddText(ExcelBuf, FieldValue(RecNode.AsXmlElement(), Col), false);
            end;

        ExcelBuf.SelectOrAddSheet(XlSheetName);
        ExcelBuf.WriteSheet(XlSheetName, CompanyName(), UserId());
    end;

    // Skips the empty placeholder records the export writes for e.g. resources without skills.
    local procedure HasValue(Rec: XmlElement): Boolean
    var
        Children: XmlNodeList;
        Child: XmlNode;
    begin
        Children := Rec.GetChildElements();
        foreach Child in Children do
            if IsLeaf(Child.AsXmlElement()) then
                if Child.AsXmlElement().InnerText() <> '' then
                    exit(true);
        exit(false);
    end;

    // Nearest ancestor that is a record (skips wrapper groups such as ResourceSkills).
    local procedure ParentRecord(Rec: XmlElement): XmlElement
    var
        Up: XmlElement;
        Cur: XmlElement;
    begin
        Cur := Rec;
        while Cur.AsXmlNode().GetParent(Up) do begin
            if IsRecord(Up) then
                exit(Up);
            Cur := Up;
        end;
        exit(Rec);
    end;

    local procedure ParentHeader(ParentName: Text): Text
    begin
        case ParentName of
            'BaseCalendar':
                exit('Base Calendar Code');
            'NoSeries':
                exit('No. Series Code');
            'Resource':
                exit('Resource No.');
            'Job':
                exit('Project No.');
        end;
        exit(ParentName);
    end;

    local procedure FieldValue(Rec: XmlElement; FieldName: Text): Text
    var
        Node: XmlNode;
    begin
        if Rec.SelectSingleNode(FieldName, Node) then
            exit(Node.AsXmlElement().InnerText());
        exit('');
    end;

    local procedure FirstFieldValue(Rec: XmlElement): Text
    var
        Children: XmlNodeList;
        Child: XmlNode;
    begin
        Children := Rec.GetChildElements();
        foreach Child in Children do
            if IsLeaf(Child.AsXmlElement()) then
                exit(Child.AsXmlElement().InnerText());
        exit('');
    end;

    local procedure AddText(var ExcelBuf: Record "Excel Buffer" temporary; Value: Text; Bold: Boolean)
    begin
        ExcelBuf.AddColumn(Value, false, '', Bold, false, false, '', ExcelBuf."Cell Type"::Text);
    end;

    // A nested child is either a record itself or a wrapper group (e.g. ResourceSkills) around records: return the record name.
    local procedure NestedRecordName(Elem: XmlElement): Text
    var
        Children: XmlNodeList;
        First: XmlNode;
    begin
        if IsRecord(Elem) then
            exit(Elem.Name());
        Children := Elem.GetChildElements();
        if Children.Get(1, First) then
            exit(First.AsXmlElement().Name());
        exit(Elem.Name());
    end;

    local procedure AddCount(var ExcelBuf: Record "Excel Buffer" temporary; Label: Text; Count: Integer)
    begin
        AddText(ExcelBuf, Label, false);
        ExcelBuf.AddColumn(Count, false, '', false, false, false, '0', ExcelBuf."Cell Type"::Number);
    end;

    // ---- Summary sheet ----

    local procedure WriteSummary(var ExcelBuf: Record "Excel Buffer" temporary; Root: XmlElement)
    var
        Children: XmlNodeList;
        Child: XmlNode;
        ChildElem: XmlElement;
        Sections: XmlNodeList;
        Section: XmlNode;
    begin
        ExcelBuf.NewRow();
        AddText(ExcelBuf, SummaryTitleLbl, true);
        ExcelBuf.NewRow();
        ExcelBuf.NewRow();
        AddText(ExcelBuf, DataLbl, true);
        AddText(ExcelBuf, NumberOfRecordsLbl, true);
        Children := Root.GetChildElements();
        foreach Child in Children do begin
            ChildElem := Child.AsXmlElement();
            if ChildElem.Name() = 'MasterData' then begin
                ExcelBuf.NewRow();
                AddText(ExcelBuf, MasterDataLbl, true);
                Sections := ChildElem.GetChildElements();
                foreach Section in Sections do
                    SummarizeSection(ExcelBuf, Section.AsXmlElement(), 1);
            end else
                SummarizeSection(ExcelBuf, ChildElem, 0);
        end;
    end;

    // One line "<Section> = <number of top-level records>", then one indented line per nested record type.
    local procedure SummarizeSection(var ExcelBuf: Record "Excel Buffer" temporary; Sec: XmlElement; Level: Integer)
    var
        Records: XmlNodeList;
        Rec: XmlNode;
        RecChildren: XmlNodeList;
        RecChild: XmlNode;
        NestedNames: List of [Text];
        NestedName: Text;
        Nodes: XmlNodeList;
        Count: Integer;
        Indent: Text;
    begin
        Indent := PadStr('', Level * 4, ' ');
        ExcelBuf.NewRow();
        if IsRecord(Sec) then begin
            // The section element is itself a record (e.g. Daily Optimizer Setup).
            AddCount(ExcelBuf, Indent + Sec.Name(), 1);
            exit;
        end;
        Records := Sec.GetChildElements();
        Count := Records.Count();
        AddCount(ExcelBuf, Indent + Sec.Name(), Count);

        foreach Rec in Records do begin
            RecChildren := Rec.AsXmlElement().GetChildElements();
            foreach RecChild in RecChildren do
                if not IsLeaf(RecChild.AsXmlElement()) then begin
                    NestedName := NestedRecordName(RecChild.AsXmlElement());
                    if not NestedNames.Contains(NestedName) then
                        NestedNames.Add(NestedName);
                end;
        end;
        foreach NestedName in NestedNames do begin
            Sec.SelectNodes('.//' + NestedName + '[*]', Nodes);
            Count := 0;
            foreach Rec in Nodes do
                if HasValue(Rec.AsXmlElement()) then
                    Count += 1;
            ExcelBuf.NewRow();
            AddCount(ExcelBuf, Indent + '    ' + NestedName, Count);
        end;
    end;

    var
        NoXmlErr: Label 'This scenario has no XML demo data.';
        NoSheetsErr: Label 'The Excel file contains none of the expected demo data sheets. Use a file created with Download as Excel.';
        OrphanErr: Label 'Sheet %1: a row refers to %2 %3, which does not exist on the %2 sheet.';
        SummarySheetLbl: Label 'Summary';
        SummaryTitleLbl: Label 'Demo data summary';
        MasterDataLbl: Label 'Master Data';
        DataLbl: Label 'Data';
        NumberOfRecordsLbl: Label 'Number of Records';
}
