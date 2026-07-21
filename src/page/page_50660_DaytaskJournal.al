page 50660 "Day Planning Journal"
{
    Caption = 'Day Planning Journal';
    PageType = Worksheet;
    SourceTable = "DayPlanning Journal Line";
    UsageCategory = Tasks;
    ApplicationArea = Jobs;
    AutoSplitKey = false;
    DelayedInsert = true;
    SaveValues = true;

    layout
    {
        area(content)
        {
            group(Control1)
            {
                ShowCaption = false;
                field(CurrentTemplateName; CurrentTemplateName)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Template Name';
                    Lookup = true;
                    ToolTip = 'Specifies the name of the journal template used for the DayPlanning posting batch.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        JobJnlTemplate: Record "Job Journal Template";
                    begin
                        JobJnlTemplate.Reset();
                        if PAGE.RunModal(0, JobJnlTemplate) = ACTION::LookupOK then begin
                            Text := JobJnlTemplate.Name;
                            CurrentTemplateName := JobJnlTemplate.Name;
                            SetTemplate(CurrentTemplateName);
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        SetTemplate(CurrentTemplateName);
                    end;
                }
                field(CurrentBatchName; CurrentBatchName)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Batch Name';
                    Lookup = true;
                    ToolTip = 'Specifies the name of the journal batch used for DayPlanning posting. The batch defines the no. series for document numbers.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        JobJnlBatch: Record "Job Journal Batch";
                    begin
                        JobJnlBatch.SetRange("Journal Template Name", CurrentTemplateName);
                        if PAGE.RunModal(0, JobJnlBatch) = ACTION::LookupOK then begin
                            Text := JobJnlBatch.Name;
                            CurrentBatchName := JobJnlBatch.Name;
                            SetBatch(CurrentBatchName);
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        SetBatch(CurrentBatchName);
                    end;
                }
            }

            repeater(Lines)
            {
                field("DayPlanning Date"; Rec."DayPlanning Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the date of the Day planning.';
                    Editable = false;
                }
                field("DayPlanning Line No."; Rec."DayPlanning Line No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the line number of the Day planning.';
                    Editable = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the document number that will be used when the line is posted.';
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the project number from the Day Planning.';
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the project task number from the Day Planning.';
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the resource number assigned to this Day Planning.';
                }
                field(Hours; Rec."Hours")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of assigned hours to post for this Day Planning.';
                }
                field("Skill"; Rec.Skill)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the skill required for this Day Planning.';
                }
                field("Invoice Resource No."; Rec."Invoice Resource No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the invoice resource number assigned to this Day Planning.';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the Global Dimension 1 that is linked to the journal line.';
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the Global Dimension 2 that is linked to the journal line.';
                }
                field("Dimension Set ID"; Rec."Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension set assigned to the journal line.';
                }
            }
        }
        area(FactBoxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetDayPlanning)
            {
                ApplicationArea = Jobs;
                Caption = 'Get Day Realized';
                Image = SelectEntries;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Retrieve unposted Day Plannings and insert them as journal lines. Filters available for date, project, project task and resource.';

                trigger OnAction()
                var
                    DayPlanningSelectionRep: Report "DayPlanning Selection";
                begin
                    CheckTemplateAndBatch();
                    DayPlanningSelectionRep.SetJournalBatch(CurrentTemplateName, CurrentBatchName);
                    DayPlanningSelectionRep.RunModal();
                    CurrPage.Update(false);
                end;
            }
            action(PreviewPosting)
            {
                ApplicationArea = Jobs;
                Caption = 'Preview Posting';
                Image = ViewPostedOrder;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Review the result of posting the DayPlanning journal lines before the actual posting is done.';

                trigger OnAction()
                var
                    DayPlanningJnlPost: Codeunit "DayPlanning Journal Post";
                begin
                    CheckTemplateAndBatch();
                    DayPlanningJnlPost.PreviewPost(CurrentTemplateName, CurrentBatchName);
                end;
            }
            action(Post)
            {
                ApplicationArea = Jobs;
                Caption = 'Post';
                Image = PostOrder;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ShortCutKey = 'F9';
                ToolTip = 'Transfer the DayPlanning journal lines to project journal lines and post them. Day Plannings are marked as Posted after successful completion.';

                trigger OnAction()
                var
                    DayPlanningJnlPost: Codeunit "DayPlanning Journal Post";
                    ConfirmMsg: Label 'Do you want to post the DayPlanning journal lines?';
                begin
                    CheckTemplateAndBatch();
                    if not Confirm(ConfirmMsg, false) then
                        exit;
                    DayPlanningJnlPost.Post(CurrentTemplateName, CurrentBatchName);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(ShowDimensions)
            {
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Image = Dimensions;
                ToolTip = 'View or edit the dimension set for the selected journal line.';
                ShortCutKey = 'Alt+D';

                trigger OnAction()
                begin
                    Rec.ShowDimensions();
                    CurrPage.SaveRecord();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        // Restore saved template/batch or pick defaults
        if CurrentTemplateName = '' then
            SetTemplate(CurrentTemplateName);
    end;

    trigger OnAfterGetRecord()
    begin
        // Keep filter in sync with the current template/batch header
    end;

    var
        CurrentTemplateName: Code[10];
        CurrentBatchName: Code[10];
        TemplateAndBatchRequiredErr: Label 'You must specify a Template Name and Batch Name before you can use this function.';

    local procedure SetTemplate(TemplateName: Code[10])
    var
        JobJnlTemplate: Record "Job Journal Template";
    begin
        if TemplateName <> '' then
            if not JobJnlTemplate.Get(TemplateName) then
                TemplateName := '';
        if TemplateName = '' then begin
            JobJnlTemplate.Reset();
            if JobJnlTemplate.FindFirst() then
                TemplateName := JobJnlTemplate.Name;
        end;
        CurrentTemplateName := TemplateName;
        CurrentBatchName := '';
        Rec.FilterGroup(2);
        Rec.SetRange("Template Name", CurrentTemplateName);
        Rec.FilterGroup(0);
        SetBatch(CurrentBatchName);
    end;

    local procedure SetBatch(BatchName: Code[10])
    var
        JobJnlBatch: Record "Job Journal Batch";
    begin
        if (BatchName <> '') and (CurrentTemplateName <> '') then
            if not JobJnlBatch.Get(CurrentTemplateName, BatchName) then
                BatchName := '';
        if (BatchName = '') and (CurrentTemplateName <> '') then begin
            JobJnlBatch.SetRange("Journal Template Name", CurrentTemplateName);
            if JobJnlBatch.FindFirst() then
                BatchName := JobJnlBatch.Name;
        end;
        CurrentBatchName := BatchName;
        Rec.FilterGroup(2);
        Rec.SetRange("Batch Name", CurrentBatchName);
        Rec.FilterGroup(0);
        CurrPage.Update(false);
    end;

    local procedure CheckTemplateAndBatch()
    begin
        if (CurrentTemplateName = '') or (CurrentBatchName = '') then
            Error(TemplateAndBatchRequiredErr);
    end;
}
