page 50625 "Job Information FactBox"
{
    Caption = 'Job Information';
    PageType = CardPart;
    SourceTable = "Job Task";

    layout
    {
        area(content)
        {
            field("Job No."; Rec."Job No.")
            {
                ApplicationArea = Jobs;
                Caption = 'Job';
                ToolTip = 'Specifies the job number. Click to open the job card.';

                trigger OnDrillDown()
                var
                    Job: Record Job;
                begin
                    if Job.Get(Rec."Job No.") then
                        Page.Run(Page::"Job Card", Job);
                end;
            }
            field(JobDescription; JobDescription)
            {
                ApplicationArea = Jobs;
                Caption = 'Job Description';
                ToolTip = 'Specifies the description of the job.';
                Editable = false;
            }
        }
    }

    var
        JobDescription: Text[100];

    trigger OnAfterGetCurrRecord()
    begin
        UpdateJobDescription();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateJobDescription();
    end;

    local procedure UpdateJobDescription()
    var
        Job: Record Job;
    begin
        if Job.Get(Rec."Job No.") then
            JobDescription := Job.Description
        else
            JobDescription := '';
    end;
}
