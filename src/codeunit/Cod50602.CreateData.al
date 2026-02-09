codeunit 50602 "Create Demo Data"
{
    trigger OnRun()
    var
        job: Record Job;
    begin
        //if not job.get('JOB001') then
        CreateJobTask(CreateJob());
    end;

    var
        myInt: Integer;

    local procedure CreateJob(): Code[20]
    var
        Job: Record Job;
        customer: Record Customer;
    begin
        customer.FindFirst();
        job."No." := 'JOB001';
        job.Description := 'Radome repair';
        job.validate("Sell-to Customer No.", customer."No.");
        if not job.Insert() then job.Modify();
        exit(job."No.");

        // Your code here
    end;

    Local procedure CreateJobTask(JobNo: Code[20])
    var
        JobTask: Record "Job Task";
        Job: Record Job;
        Indent: codeunit "Job Task Indent";
        Date1: date;

    begin
        date1 := calcdate('<WD1-1W>', Today);

        Job.get(JobNo);
        JobTask."Job No." := Job."No.";
        JobTask."Job Task No." := '0';
        JobTask.Description := 'Repair Radome';
        jobtask."PlannedStartDate" := date1;
        JobTask.Validate("PlannedEndDate", CalcDate('+3W', date1));
        JobTask."Job Task Type" := JobTask."Job Task Type"::Heading;
        if not JobTask.Insert() then JobTask.Modify();

        JobTask."Job Task No." := '1';
        JobTask.Description := 'Pre Processing Tasks';
        jobtask."PlannedStartDate" := CalcDate('1D', date1);
        JobTask.Validate("PlannedEndDate", CalcDate('+2D', date1));
        JobTask."Job Task Type" := JobTask."Job Task Type"::"Begin-Total";
        if not JobTask.Insert() then JobTask.Modify();

        JobTask."Job Task No." := '1010';
        JobTask.Description := 'Inbound Inspection';
        jobtask."PlannedStartDate" := CalcDate('2D', date1);
        JobTask.Validate("PlannedEndDate", CalcDate('3D', date1));
        JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
        if not JobTask.Insert() then JobTask.Modify();

        JobTask."Job Task No." := '1020';
        JobTask.Description := 'Quote & Approval';
        jobtask."PlannedStartDate" := CalcDate('3D', date1);
        JobTask.Validate("PlannedEndDate", CalcDate('+4D', date1));
        JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
        if not JobTask.Insert() then JobTask.Modify();

        JobTask."Job Task No." := '1999';
        JobTask.Description := 'Pre Processing Tasks';
        jobtask."PlannedStartDate" := CalcDate('1D', date1);
        JobTask.Validate("PlannedEndDate", CalcDate('+1W', date1));
        JobTask."Job Task Type" := JobTask."Job Task Type"::"End-Total";
        if not JobTask.Insert() then JobTask.Modify();

        JobTask."Job Task No." := '2';
        JobTask.Description := 'Repair';
        jobtask."PlannedStartDate" := CalcDate('+1W', date1);
        JobTask.Validate("PlannedEndDate", CalcDate('+2W', date1));
        JobTask."Job Task Type" := JobTask."Job Task Type"::"Begin-Total";
        if not JobTask.Insert() then JobTask.Modify();

        JobTask."Job Task No." := '2010';
        JobTask.Description := 'Spare Parts Procurement';
        jobtask."PlannedStartDate" := CalcDate('+1W+1D', date1);
        JobTask.Validate("PlannedEndDate", CalcDate('+1W+2D', date1));
        JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
        if not JobTask.Insert() then JobTask.Modify();

        JobTask."Job Task No." := '2020';
        JobTask.Description := 'Remove old and install new parts';
        jobtask."PlannedStartDate" := CalcDate('+1W+2D', date1);
        JobTask.Validate("PlannedEndDate", CalcDate('+1W+3D', date1));
        JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
        if not JobTask.Insert() then JobTask.Modify();

        JobTask."Job Task No." := '2030';
        JobTask.Description := 'Cat and bodywork';
        jobtask."PlannedStartDate" := CalcDate('+1W+3D', date1);
        JobTask.Validate("PlannedEndDate", CalcDate('+2W+3D', date1));
        JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
        if not JobTask.Insert() then JobTask.Modify();

        JobTask."Job Task No." := '2999';
        JobTask.Description := 'Pre Processing Tasks';
        jobtask."PlannedStartDate" := CalcDate('1W', date1);
        JobTask.Validate("PlannedEndDate", CalcDate('+2W+3D', date1));
        JobTask."Job Task Type" := JobTask."Job Task Type"::"End-Total";
        if not JobTask.Insert() then JobTask.Modify();

        JobTask."Job Task No." := '3';
        JobTask.Description := 'Post Processing Tasks';
        jobtask."PlannedStartDate" := CalcDate('+2W+3D', date1);
        JobTask.Validate("PlannedEndDate", CalcDate('+3W+2D', date1));
        JobTask."Job Task Type" := JobTask."Job Task Type"::"Begin-Total";
        if not JobTask.Insert() then JobTask.Modify();

        JobTask."Job Task No." := '3010';
        JobTask.Description := 'Testing';
        jobtask."PlannedStartDate" := CalcDate('+2W+3D', date1);
        JobTask.Validate("PlannedEndDate", CalcDate('+2W+4D', date1));
        JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
        if not JobTask.Insert() then JobTask.Modify();

        JobTask."Job Task No." := '3020';
        JobTask.Description := 'Certification';
        jobtask."PlannedStartDate" := CalcDate('+3W+2D', date1);
        JobTask.Validate("PlannedEndDate", CalcDate('+3W+3D', date1));
        JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
        if not JobTask.Insert() then JobTask.Modify();

        JobTask."Job Task No." := '3030';
        JobTask.Description := 'Outbound Shipping';
        jobtask."PlannedStartDate" := CalcDate('+2W+3D', date1);
        JobTask.Validate("PlannedEndDate", CalcDate('+3W+2D', date1));
        JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
        if not JobTask.Insert() then JobTask.Modify();

        JobTask."Job Task No." := '3999';
        JobTask.Description := 'Post Processing Tasks';
        jobtask."PlannedStartDate" := CalcDate('2W+2D', date1);
        JobTask.Validate("PlannedEndDate", CalcDate('+3W', date1));
        JobTask."Job Task Type" := JobTask."Job Task Type"::"End-Total";
        if not JobTask.Insert() then JobTask.Modify();

        JobTask."Job Task No." := '9999';
        JobTask.Description := 'Repair Radome';
        jobtask."PlannedStartDate" := date1;
        JobTask.Validate("PlannedEndDate", CalcDate('+3W', date1));
        JobTask."Job Task Type" := JobTask."Job Task Type"::Total;
        if not JobTask.Insert() then JobTask.Modify();

        Indent.IndentJobTasks(JobTask);
    end;
}