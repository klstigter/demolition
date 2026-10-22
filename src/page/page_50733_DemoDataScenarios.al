page 50733 "Demo Data Scenarios"
{
    Caption = 'Demo Data Scenarios';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Demo Data Scenarios Opt";
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the automatically assigned entry number.';
                }
                field("Date"; Rec."Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the date of the scenario, set automatically when the description is entered.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies a description of the scenario.';
                }
                field(HasXmlData; HasXmlData)
                {
                    ApplicationArea = All;
                    Caption = 'Has XML Data';
                    Editable = false;
                    ToolTip = 'Specifies whether XML demo data has been uploaded for this scenario.';
                }
                field(Applied; Rec.Applied)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies when the scenario was last applied.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UploadXml)
            {
                ApplicationArea = All;
                Caption = 'Upload XML';
                ToolTip = 'Upload an XML demo data file into this scenario, replacing any existing data.';
                Image = Import;

                trigger OnAction()
                var
                    InStr: InStream;
                    FileName: Text;
                begin
                    if Rec."Entry No." = 0 then
                        exit;
                    if UploadIntoStream(UploadLbl, '', 'XML Files (*.xml)|*.xml', FileName, InStr) then begin
                        Rec.SetXmlFromStream(InStr);
                        Rec.Modify(true);
                        HasXmlData := Rec.HasXml();
                        CurrPage.Update(false);
                    end;
                end;
            }
            action(DownloadXml)
            {
                ApplicationArea = All;
                Caption = 'Download XML';
                ToolTip = 'Download the XML demo data of this scenario.';
                Image = Export;

                trigger OnAction()
                var
                    InStr: InStream;
                    FileName: Text;
                begin
                    if not Rec.HasXml() then
                        Error(NoXmlErr);
                    Rec.GetXmlStream(InStr);
                    FileName := StrSubstNo('DemoData_%1.xml', Rec."Entry No.");
                    DownloadFromStream(InStr, '', '', '', FileName);
                end;
            }
            action(ApplyDemoData)
            {
                ApplicationArea = All;
                Caption = 'Apply Demo Data';
                ToolTip = 'Apply the XML demo data of this scenario to the company.';
                Image = Apply;

                trigger OnAction()
                var
                    ApplyReport: Report "Apply Demo Data Scenario";
                begin
                    if not Rec.HasXml() then
                        Error(NoXmlErr);
                    ApplyReport.SetScenario(Rec."Entry No.");
                    ApplyReport.RunModal();
                    if ApplyReport.WasApplied() then begin
                        Rec.Get(Rec."Entry No.");
                        Rec.Applied := CurrentDateTime();
                        Rec.Modify();
                        CurrPage.Update(false);
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(UploadXml_ref; UploadXml) { }
                actionref(DownloadXml_ref; DownloadXml) { }
                actionref(ApplyDemoData_ref; ApplyDemoData) { }
            }
        }
    }

    var
        HasXmlData: Boolean;
        UploadLbl: Label 'Upload demo data XML';
        NoXmlErr: Label 'This scenario has no XML demo data. Use Upload XML first.';

    trigger OnAfterGetRecord()
    begin
        HasXmlData := Rec.HasXml();
    end;
}
